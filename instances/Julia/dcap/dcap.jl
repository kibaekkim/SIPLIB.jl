#=
Source:
  S. Ahmed and R. Garcia. "Dynamic Capacity Acquisition and Assignment under Uncertainty," Annals of Operations Research, vol.124, pp. 267-283, 2003

m: number of resources
n: number of jobs
T: number of time periods
S: number of scenarios
f[i,t]:
c[i,j,t]:
d[j,t,s]:
=#

function dcap(m::Int, n::Int, T::Int, S::Int, seed::Int=1)::JuMP.Model

    srand(seed)
    f
    c
    d

    model = StructuredModel(num_scenarios=S)
    @variable(model, x[i=1:m,t=1:T] >= 0)
    @objective(model, Min, sum(f[i,t]*x[i,t] for i in 1:m for t in 1:T))
    for s in 1:S
        sb = StructuredModel(parent=model, id = s, prob = p[s])
        @variable(sb, y[i=1:m, j=1:n, t=1:T], Bin)
        @objective(sb, Min, sum(c[i,j,t]*y[i,j,t] for i in 1:m for j in 1:n for t in 1:T))
        @constraint(sb, [i=1:m, t=1:T], -sum(x[i,tau] for tau in 1:t) + sum(d[j,t,s]*y[i,j,t] for j = 1:n) <= 0)
        @constraint(sb, [j=1:n, t=1:T], sum(y[i,j,t] for i in 1:m) == 1)
    end

    return model
end
