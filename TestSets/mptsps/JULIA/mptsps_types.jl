type Node
    x::Float64
    y::Float64
    centrality::Bool
end

type MPTSPsModel
    # Sets
    N   # set of nodes of the graph : i,j ∈ N
    U   # set of subsets of nodes in N : u ∈ U
    K   # set of paths between the pair of nodes : p ∈ K
    S   # set of time scenarios : s ∈ S

    # Parameters
    Cs  # nonnegative unit random travel time cost under the time scenario s ∈ S : Cs[s][i][j][p]
    Ce  # nonnegative estimation of the mean unit travel time cost : Ce[i][j]
    E   # the error on the travel time cost estimated for the path k ∈ K under time scenario s ∈ S : E[s][i][j][p] ≡ Cs[s][i][j][p] - Ce[i][j]
    Pr  # probability distribution of scenario s ∈ S : Pr[s] ≡ 1/nScenario

    MPTSPsModel() = new()
end
