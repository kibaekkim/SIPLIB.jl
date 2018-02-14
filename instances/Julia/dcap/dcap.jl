#=
Source:
  S. Ahmed and R. Garcia. "Dynamic Capacity Acquisition and Assignment under Uncertainty," Annals of Operations Research, vol.124, pp. 267-283, 2003

Input:
  m: number of resources
  n: number of tasks
  T: number of time periods
  S: number of scenarios

Sets:
  I: resources
  J: tasks
  P: time periods

Variables (1st Stage):
  x[i,t]: capacity acquired for resource i at period t
  u[i,t]: 1 if x[i,t] > 0, 0 otherwise

Variables (2nd Stage):
  y[i,j,t]: 1 if resource i is assigned to task j in period t, 0 otherwise  

Parameters (general):
  fx[i,t]: linear component of expansion cost for resource i at period t 
  fu[i,t]: fixed component of expansion cost for resource i at period t 
  c[i,j,t]: cost of assigning resource i to task j in period t
  z[j,t]: penalty incurred if task j in period t is not served
  
Parameters (scenario):
  d[j,t,s]: capacity required for to perform task j in period t in scenario s 
=#

function dcap(m::Int, n::Int, T::Int, S::Int, seed::Int=1)::JuMP.Model

    srand(seed)
    I = 1:m
    J = 1:n
    P = 1:T
    
    fx = rand(m, T) * 5 + 5
    fu = rand(m, T) * 40 + 10
    c = rand(m, n, T) * 5 + 5
    cz = rand(n, T) * 500 + 500
    d = rand(n, T, S) + 0.5
    p = ones(S)/S

    model = StructuredModel(num_scenarios=S)
    @variable(model, x[i=I,t=P] >= 0)
    @variable(model, u[i=I,t=P], Bin)
    @objective(model, Min, sum(fx[i,t]*x[i,t] + fu[i,t]*u[i,t] for i in I for t in P))
    @constraint(model, [i=I,t=P], x[i,t] - u[i,t] <= 0)
    for s in 1:S
        sb = StructuredModel(parent=model, id = s, prob = p[s])
        @variable(sb, y[i=I, j=J, t=P], Bin)
        @variable(sb, z[j=J,t=P] >= 0)
        @objective(sb, Min, sum(c[i,j,t]*y[i,j,t] for i in I for j in J for t in P) + sum(cz[j,t]*z[j,t] for j in J for t in P))
        @constraint(sb, [i=I, t=P], -sum(x[i,tau] for tau in 1:t) + sum(d[j,t,s]*y[i,j,t] for j in J) <= 0)
        @constraint(sb, [j=J, t=P], sum(y[i,j,t] for i in I) + z[j,t] == 1)
    end

    return model
end
