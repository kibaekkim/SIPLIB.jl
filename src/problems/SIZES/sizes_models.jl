include("./sizes_types.jl")
include("./sizes_functions.jl")

function sizes(nScenarios::Integer, seed::Int=1)::JuMP.Model

    # read & generate model data
    sizes = sizesdata(nScenarios, seed)

    # sets
    N, T, S = sizes.N, sizes.T, sizes.S

    # parameters
    f, r, P, C, D, Pr = sizes.f, sizes.r, sizes.P, sizes.C, sizes.D, sizes.Pr

    model = StructuredModel(num_scenarios = nScenarios)
    @variable(model, y[i = N, t = T] >= 0, Int)
    @variable(model, z[i = N, t = T], Bin)
    @objective(model, Min, sum(P[i]*y[i,t] + f*z[i,t] for i in N for t in T) )
    @constraints model begin
        [t = T], sum(y[i,t] for i in N) <= C[t]
        [i = N, t = T], y[i,t] <= C[t]*z[i,t]
    end
    for s in S
        sb = StructuredModel(parent = model, id = s, prob = Pr[s])
        @variable(sb, x[i = N, j = N, t = T; i >= j] >= 0, Int)
        @objective(sb, Min, sum(( sizes.r*sum(sum(x[i,j,t] for j in N[1:i-1]) for i in N[2:end]) ) for t in T) )
        @constraint(sb, [j = N, t = T], sum(x[i,j,t2] for t2 in T[1:t] for i in N[j:end]) >= D[j,t,s] )
        @constraint(sb, [i = N, t = T], sum(x[i,j,t2] for t2 in T[1:t] for j in N[1:i]) <= sum(y[i,t2] for t2 in T[1:t]) )
    end

    return model
end
