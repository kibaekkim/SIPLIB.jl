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
  S: scenarios

Variables (1st Stage):
  x[i,t]: capacity acquired for resource i at period t
  u[i,t]: 1 if x[i,t] > 0, 0 otherwise

Variables (2nd Stage):
  y[i,j,t]: 1 if resource i is assigned to task j in period t, 0 otherwise

Parameters (general):
  a[i,t]: linear component of expansion cost for resource i at period t
  b[i,t]: fixed component of expansion cost for resource i at period t
  c[i,j,t,s]: cost of assigning resource i to task j in period t
  c0[j,t,s]: penalty incurred if task j in period t is not served

Parameters (scenario):
  d[j,t,s]: capacity required for to perform task j in period t in scenario s
=#

include("./DCAP_data.jl")

function DCAP(nR::Int, nN::Int, nT::Int, nS::Int, seed::Int=1)::JuMP.Model

    # generate instance data
    data = DCAPData(nR, nN, nT, nS, seed)

    R, N, T, S = data.R, data.N, data.T, data.S
    a, b, c, c0, d, Pr = data.a, data.b, data.c, data.c0, data.d, data.Pr

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## 1st stage
    @variable(model, x[i=R,t=T] >= 0)
    @variable(model, u[i=R,t=T], Bin)
    @objective(model, Min, sum(a[i,t]*x[i,t] + b[i,t]*u[i,t] for i in R for t in T))
    @constraint(model, [i=R,t=T], x[i,t] - u[i,t] <= 0)

    ## 2nd stage
    for s in S
        sb = StructuredModel(parent=model, id = s, prob = Pr[s])
        @variable(sb, y[i=R, j=N, t=T], Bin)
        @variable(sb, z[j=N,t=T] >= 0)
        @objective(sb, Min, sum(c[i,j,t,s]*y[i,j,t] for i in R for j in N for t in T) + sum(c0[j,t,s]*z[j,t] for j in N for t in T))
        @constraint(sb, [i=R, t=T], -sum(x[i,tau] for tau in 1:t) + sum(d[j,t,s]*y[i,j,t] for j in N) <= 0)
        @constraint(sb, [j=N, t=T], sum(y[i,j,t] for i in R) + z[j,t] == 1)
    end

    return model
end
