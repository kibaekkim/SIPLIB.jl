# Source
#  Perboli et al., "A Progressive Hedging Method for the Multi-path Travelling Salesman Problem with Stochastic Travel Times," vol.28, pp. 65-86, 2017

# Decision variables
#  (1st stage, real)    phi[i,j]: the flow on the arc (i,j) ∈ N × N
#  (1st stage, binary)  y[i,j] = 1 if node j ∈ N is visited just after node i ∈ N, 0 otherwise.
#  (2nd stage, binary)  x[s,i,j,p] = 1 if path p ∈ K between nodes (i,j) ∈ N × N  is selected at the second stage under scenario s ∈ S, 0 otherwise.

using JuMP, StructJuMP

type MPTSPsModel
    # Sets
    N   # set of nodes of the graph : i,j ∈ N
    K   # set of paths between the pair of nodes : k ∈ K
    S   # set of time scenarios : s ∈ S

    # Parameters
    Cs  # nonnegative unit random travel time cost under the time scenario s ∈ S : Cs[s][i][j][k]
    Ce  # nonnegative estimation of the mean unit travel time cost : Ce[i][j]
    E   # the error on the travel time cost estimated for the path k ∈ K under time scenario s ∈ S : E[i][j][k][s] ≡ Cs[i][j][k][s] - Ce[i][j]
    Pr   # probability distribution of scenario s ∈ S : Pr[s] ≡ 1/nScenario

    MPTSPsModel() = new()
end


function mptspsdata(nScenarios::Integer, Graph::String)::MPTSPsModel

    # Set paths
    cd(dirname(Base.source_path()))
    DATA_DIR = "../DATA/MPTSPs"
    GRAPH_DIR = "$DATA_DIR/MPTSPs_$Graph"  #

    tsp = MPTSPsModel()

    # ------------------------------------------
    # Read data files and set parameters on tsp
    # ------------------------------------------
    tsp.N = 1:readdlm("$GRAPH_DIR/prob.txt")[4,2]
    tsp.K = 1:readdlm("$GRAPH_DIR/prob.txt")[5,2]
    tsp.S = 1:nScenarios

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

    tsp.E = deepcopy(tsp.Cs)
    for s in tsp.S
        for i in tsp.N, j in tsp.N, k in tsp.K
            tsp.E[s][i][j][k] -= tsp.Ce[i][j]
        end
    end

    tsp.Pr = [1/nScenarios for s in tsp.S]

    return tsp
end

function mptsps_flow(nScenarios::Integer, Graph::String)::JuMP.Model
    # get model data
    tsp = mptspsdata(nScenarios, Graph)

    #construct JuMP.Model
    model = StructuredModel(num_scenarios = nScenarios)

    @variables model begin
        phi[i = tsp.N, j = tsp.N], Cont
        y[i = tsp.N, j = tsp.N], Bin
    end
    @objective(model, Min, sum(tsp.Ce[i][j]*y[i,j] for i in tsp.N for j in tsp.N))
    @constraints model begin
        [i = tsp.N], sum(y[i,j] for j in tsp.N if j != i) == 1
        [j = tsp.N], sum(y[i,j] for i in tsp.N if i != j) == 1
        [j = tsp.N ; j != 1], sum(phi[i,j] for i in tsp.N if i != j) - sum(phi[j,k] for k in tsp.N if k != j) == 1
        sum(phi[i,1] for i in tsp.N if i != 1) - sum(phi[1,k] for k in tsp.N if k != 1) == 1 - length(tsp.N)
        sum(phi[1,k] for k in tsp.N if k != 1) == length(tsp.N)
        [i = tsp.N, j = tsp.N], phi[i,j] <= length(tsp.N)*y[i,j]
    end

    ## add 2nd stage components
    for s in tsp.S
        sb = StructuredModel(parent = model, id = s, prob = tsp.Pr[s])
        @variable(sb, x[i = tsp.N, j = tsp.N, p = tsp.K], Bin)
        @objective(sb, Min, sum(tsp.E[s][i][j][p]*x[i,j,p] for i in tsp.N for j in tsp.N for p in tsp.K))
        @constraint(sb, [i = tsp.N, j = tsp.N], sum(x[i,j,p] for p in tsp.K) == y[i,j])
    end

    return model
end

model = mptsps_flow(10, "D0_50")


# test ( nScenario ∈ [1,...,100] and Graph ∈ {"D0_50", "D1_50", "D1_100", "D2_50", "D3_50"} )
using CPLEX
nScenarios, Graph = 100, "D1_100"
# construct model =====================#
tsp = mptspsdata(nScenarios, Graph)
model = StructuredModel(num_scenarios = nScenarios)
@variables model begin
    phi[i = tsp.N, j = tsp.N], Cont
    y[i = tsp.N, j = tsp.N], Bin
end
@objective(model, Min, sum(tsp.Ce[i][j]*y[i,j] for i in tsp.N for j in tsp.N))
@constraints model begin
    [i = tsp.N], sum(y[i,j] for j in tsp.N if j != i) == 1
    [j = tsp.N], sum(y[i,j] for i in tsp.N if i != j) == 1
    [j = tsp.N ; j != 1], sum(phi[i,j] for i in tsp.N if i != j) - sum(phi[j,k] for k in tsp.N if k != j) == 1
    sum(phi[i,1] for i in tsp.N if i != 1) - sum(phi[1,k] for k in tsp.N if k != 1) == 1 - length(tsp.N)
    sum(phi[1,k] for k in tsp.N if k != 1) == length(tsp.N)
    [i = tsp.N, j = tsp.N], phi[i,j] <= length(tsp.N)*y[i,j]
end
for s in tsp.S
    sb = StructuredModel(parent = model, id = s, prob = tsp.Pr[s])
    @variable(sb, x[i = tsp.N, j = tsp.N, p = tsp.K], Bin)
    @objective(sb, Min, sum(tsp.E[s][i][j][p]*x[i,j,p] for i in tsp.N for j in tsp.N for p in tsp.K))
    @constraint(sb, [i = tsp.N, j = tsp.N], sum(x[i,j,p] for p in tsp.K) == y[i,j])
end
# solve & print result =======================#
setsolver(model,CplexSolver(CPXPARAM_TimeLimit = 30))
solve(model)
println("Obj = $(getobjectivevalue(model))")
println("Solutions:")
for i in tsp.N
    for j in tsp.N
        if i != j && getvalue(y[i,j]) == 1
            println("y[$i,$j] = $(getvalue(y[i,j]))")
        end
    end
end
