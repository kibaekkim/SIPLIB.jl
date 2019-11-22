using StructJuMP
using Random

include("./SIZES_data.jl")

function SIZES(nS::Integer, seed::Int=1)::JuMP.Model

    # read & generate instance data
    data = SIZESData(nS, seed)

    # copy (for convenience)
    N, T, S, f, r, P, C, D, Pr = data.N, data.T, data.S, data.f, data.r, data.P, data.C, data.D, data.Pr

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## 1st stage
    @variable(model, y[i = N, t = T] >= 0, Int)
    @variable(model, z[i = N, t = T], Bin)
    @objective(model, Min, sum(P[i]*y[i,t] + f*z[i,t] for i in N for t in T) )
    @constraints model begin
        [t = T], sum(y[i,t] for i in N) <= C[t]
        [i = N, t = T], y[i,t] <= C[t]*z[i,t]
    end

    ## 2nd stage
    for s in S
        sb = StructuredModel(parent = model, id = s, prob = Pr[s])
        @variable(sb, x[i = N, j = N, t = T; i >= j] >= 0, Int)
        @objective(sb, Min, sum(( r*sum(sum(x[i,j,t] for j in N[1:i-1]) for i in N[2:end]) ) for t in T) )
        @constraint(sb, [j = N, t = T], sum(x[i,j,t2] for t2 in T[1:t] for i in N[j:end]) >= D[j,t,s] )
        @constraint(sb, [i = N, t = T], sum(x[i,j,t2] for t2 in T[1:t] for j in N[1:i]) <= sum(y[i,t2] for t2 in T[1:t]) )
    end

    return model
end
