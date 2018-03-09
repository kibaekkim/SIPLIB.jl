#=
Source:
  Perboli et al., "A Progressive Hedging Method for the Multi-path Travelling Salesman Problem with Stochastic Travel Times, vol.28, pp. 65-86, 2017

Note:
  Two lines (50, 104) for the 'subtour elimination' is commented
  since it causes out of memory when finding power set of set of nodes .
=#
using JuMP, StructJuMP

type MPTSPsModel
    # Sets
    N   # set of nodes of the graph : i,j ∈ N
    U   # set of subsets of nodes in N : u ∈ U
    K   # set of paths between the pair of nodes : k ∈ K
    S   # set of time scenarios : s ∈ S

    # Parameters
    Cs  # nonnegative unit random travel time cost under the time scenario s ∈ S : Cs[s][i][j][k]
    Ce  # nonnegative estimation of the mean unit travel time cost : Ce[i][j]
    Δ   # the error on the travel time cost estimated for the path k ∈ K under time scenario s ∈ S : Δ[i][j][k][s] ≡ Cs[i][j][k][s] - Ce[i][j]
    π   # probability distribution of scenario s ∈ S : π[s] ≡ 1/nScenario

    MPTSPsModel() = new()
end

function mptspsdata(nScenarios::Integer, Graph::String)::MPTSPsModel

    # Function for subtour elimination
    function powerset{Int}(S::Vector{Int})
        set = Vector{Int}[[]]
        for s in S, i in eachindex(set)
            push!(set, [set[i] ; s])
        end
        return set
    end

    # Set paths
    DATA_DIR = "../DATA/MPTSPs"
    GRAPH_DIR = "$DATA_DIR/MPTSPs_$Graph"  #

    tsp = MPTSPsModel()

    # ------------------------------------------
    # Read data files and set parameters on tsp
    # ------------------------------------------
    tsp.N = 1:readdlm("$GRAPH_DIR/prob.txt")[4,2]
    tsp.K = 1:readdlm("$GRAPH_DIR/prob.txt")[5,2]
    tsp.S = 1:nScenarios
    #tsp.U = powerset(convert(Array{Int},tsp.N)) # for subtour elimination

    tsp.Cs = Array{Array{Array{Float64}}}[]
    for s in tsp.S
        SCENARIO_PATH = "$GRAPH_DIR/Scenario$(s).dat"
        scenario_array = readdlm(SCENARIO_PATH)[2:end]
        C = Array{Array{Float64}}[]
        v = 1
        for i in tsp.N
            arr_1 = Array{Float64}[]
            for j in tsp.N
                arr_2 = Float64[]
                for k in tsp.K
                    push!(arr_2, scenario_array[v])
                    v += 1
                end
                push!(arr_1, arr_2)
            end
            push!(C, arr_1)
        end
        push!(tsp.Cs, C)
    end

    tsp.Ce = Array{Float64}[]
    for i in tsp.N
        push!(tsp.Ce, Float64[])
        for j in tsp.N
             push!(tsp.Ce[i], sum(sum(tsp.Cs[s][i][j][:]) for s in tsp.S)*(1/length(tsp.K))*(1/nScenarios))
        end
    end

    tsp.Δ = deepcopy(tsp.Cs)
    for s in tsp.S
        for i in tsp.N, j in tsp.N, k in tsp.K
            tsp.Δ[s][i][j][k] -= tsp.Ce[i][j]
        end
    end

    tsp.π = [1/nScenarios for s in tsp.S]

    return tsp
end

function mptsps_subtour(nScenarios::Integer, Graph::String)::JuMP.Model
    # get model data
    tsp = mptspsdata(nScenarios, Graph)

    # construct JuMP.Model
    model = StructuredModel(num_scenarios=nScenarios)
    @variable(model, y[i=tsp.N,j=tsp.N], Bin)
    @objective(model, Min, sum(tsp.Ce[i][j]*y[i,j] for i in tsp.N for j in tsp.N))
    @constraints model begin
        [i=tsp.N], sum(y[i,j] for j in tsp.N if j ∉ i) == 1
        [j=tsp.N], sum(y[i,j] for i in tsp.N if i ∉ j) == 1
        #[u=tsp.U[2:end-1]], sum(y[i,j] for i in u for j in tsp.N if j ∉ u) >= 1 # subtour elimination constraints
    end

    for s in tsp.S
        sb = StructuredModel(parent=model, id = s, prob = tsp.π[s])
        @variable(sb, x[s=tsp.S,i=tsp.N,j=tsp.N,k=tsp.K], Bin)
        @objective(sb, Min, sum(tsp.Δ[s][i][j][k]*x[s,i,j,k] for i in tsp.N for j in tsp.N for k in tsp.K))
        @constraint(sb, [i=tsp.N, j=tsp.N], sum(x[s,i,j,k] for k in tsp.K) == y[i,j])
    end

    return model
end

# test ( nScenario ∈ [1,...,100] and Graph ∈ {"D0_50", "D1_50", "D1_100", "D2_50", "D3_50"} )
model = mptsps_subtour(3, "D0_50")
