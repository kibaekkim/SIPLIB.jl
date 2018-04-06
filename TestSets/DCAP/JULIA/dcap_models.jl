#=
Source:
  S. Ahmed and R. Garcia. "Dynamic Capacity Acquisition and Assignment under Uncertainty," Annals of Operations Research, vol.124, pp. 267-283, 2003

Input:
  nR: number of resources
  nN: number of tasks
  nT: number of time periods
  nS: number of scenarios

Sets:
  R: resources
  N: tasks
  T: time periods

Variables (1st Stage):
  x[i,t]: capacity acquired for resource i at period t
  u[i,t]: 1 if x[i,t] > 0, 0 otherwise

Variables (2nd Stage):
  y[i,j,t]: 1 if resource i is assigned to task j in period t, 0 otherwise

Parameters (general):
  A[i,t]: linear component of expansion cost for resource i at period t
  B[i,t]: fixed component of expansion cost for resource i at period t
  C[i,j,t]: cost of assigning resource i to task j in period t
  C0[j,t]: penalty incurred if task j in period t is not served

Parameters (scenario):
  D[j,t,s]: capacity required for to perform task j in period t in scenario s
=#

using JuMP, StructJuMP

function dcap(nR::Int, nN::Int, nT::Int, nS::Int, seed::Int=1)::JuMP.Model

    #srand(seed)
    srand()
    R = 1:nR
    N = 1:nN
    T = 1:nT
    S = 1:nS

    A = rand(nR, nT) * 5 + 5
    B = rand(nR, nT) * 40 + 10
    C = rand(nR, nN, nT) * 5 + 5
    C0 = rand(nN, nT) * 500 + 500
    D = rand(nN, nT, nS) + 0.5
#    M = [maximum([sum(D[:,t,s]) for s in S]) for t in T]
    Pr = ones(nS)/nS

    model = StructuredModel(num_scenarios = nS)
    @variable(model, x[i=R,t=T] >= 0)
    @variable(model, u[i=R,t=T], Bin)
    @objective(model, Min, sum(A[i,t]*x[i,t] + B[i,t]*u[i,t] for i in R for t in T))
#    @constraint(model, [i=R,t=T], x[i,t] - M[t]*u[i,t] <= 0)
    @constraint(model, [i=R,t=T], x[i,t] - u[i,t] <= 0)
    for s in S
        sb = StructuredModel(parent=model, id = s, prob = Pr[s])
        @variable(sb, y[i=R, j=N, t=T], Bin)
        @variable(sb, z[j=N,t=T] >= 0)
        @objective(sb, Min, sum(C[i,j,t]*y[i,j,t] for i in R for j in N for t in T) + sum(C0[j,t]*z[j,t] for j in N for t in T))
        @constraint(sb, [i=R, t=T], -sum(x[i,tau] for tau in 1:t) + sum(D[j,t,s]*y[i,j,t] for j in N) <= 0)
        @constraint(sb, [j=N, t=T], sum(y[i,j,t] for i in R) + z[j,t] == 1)
    end

    return model
end
