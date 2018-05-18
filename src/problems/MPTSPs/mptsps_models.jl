include("./mptsps_types.jl")
include("./mptsps_functions.jl")

function mptsps_flow(D::String, nN::Integer, nS::Integer, seed::Int=1)::JuMP.Model

    # generate model data
    tsp = mptspsdata(D, nN, nS, seed)

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## add 1st stage components
    @variables model begin
        phi[i = tsp.N, j = tsp.N; i != 1] >= 0, Cont
        y[i = tsp.N, j = tsp.N; i != j], Bin
    end
    @objective(model, Min, sum(tsp.Ce[i][j]*y[i,j] for i in tsp.N for j in tsp.N if i != j))
    @constraints model begin
        [i = tsp.N], sum(y[i,j] for j in tsp.N if j != i) == 1
        [j = tsp.N], sum(y[i,j] for i in tsp.N if i != j) == 1
        [l = tsp.N ; l != 1], sum(phi[l,j] for j in tsp.N) - sum(phi[i,l] for i in tsp.N if i != 1) == 1
        [i = tsp.N, j = tsp.N ; i != 1 && i != j], phi[i,j] <= (length(tsp.N)-1)*y[i,j]
    end

    ## add 2nd stage components
    for s in tsp.S
        sb = StructuredModel(parent = model, id = s, prob = tsp.Pr[s])
        @variable(sb, x[i = tsp.N, j = tsp.N, k = tsp.K; i != j], Bin)
        @objective(sb, Min, sum(tsp.E[s,i,j,k]*x[i,j,k] for i in tsp.N for j in tsp.N for k in tsp.K if i != j))
        @constraint(sb, [i = tsp.N, j = tsp.N; i != j], sum(x[i,j,k] for k in tsp.K) == y[i,j])
    end

    return model
end
