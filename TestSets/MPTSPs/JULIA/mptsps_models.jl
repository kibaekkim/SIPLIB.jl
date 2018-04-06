include("./mptsps_types.jl")
include("./mptsps_functions.jl")
using JuMP, StructJuMP

function mptsps_flow(D::String, nN::Integer, nS::Integer)::JuMP.Model

    # generate model data
    tsp = mptspsdata(D, nN, nS)

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## add 1st stage components
    @variables model begin
        phi[i = tsp.N, j = tsp.N] >= 0, Cont
        y[i = tsp.N, j = tsp.N], Bin
    end
    @objective(model, Min, sum(tsp.Ce[i][j]*y[i,j] for i in tsp.N for j in tsp.N))
    @constraints model begin
        [i = tsp.N], sum(y[i,j] for j in tsp.N if j != i) == 1
        [j = tsp.N], sum(y[i,j] for i in tsp.N if i != j) == 1
        [l = tsp.N ; l != 1], sum(phi[l,j] for j in tsp.N) - sum(phi[i,l] for i in tsp.N if i != 1) == 1
        [i = tsp.N, j = tsp.N ; i != 1], phi[i,j] <= (length(tsp.N)-1)*y[i,j]
    end

    ## add 2nd stage components
    for s in tsp.S
        sb = StructuredModel(parent = model, id = s, prob = tsp.Pr[s])
        @variable(sb, x[i = tsp.N, j = tsp.N, k = tsp.K], Bin)
        @objective(sb, Min, sum(tsp.E[s,i,j,k]*x[i,j,k] for i in tsp.N for j in tsp.N for k in tsp.K))
        @constraint(sb, [i = tsp.N, j = tsp.N], sum(x[i,j,k] for k in tsp.K) == y[i,j])
    end

    return model
end
