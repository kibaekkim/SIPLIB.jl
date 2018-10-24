# definition of data container
mutable struct DCAPData
    # Sets
    R   # set of resources (i ∈ R)
    N   # set of tasks (j ∈ N)
    T   # set of time periods (t ∈ T)
    S   # set of scenarios (s ∈ S)

    # Parameters
    a   # a[i,t]: variable cost for expanding capacity of resource i at time t
    b   # b[i,t]: fixed cost for expanding capacity of resource i at time t
    c   # c[i,j,t,s]: cost of processing task j using resource i in period t under scenario s
    c0  # c0[j,t,s]: penalty cost of failing to assign a resource to task j under scenario s
    d   # d[j,t,s]: processing requirement for task j in period t under scenario s
    Pr  # Pr[s]: probability of occurence of scenario s

    DCAPData() = new()
end

# data generating function
function DCAPData(nR::Int, nN::Int, nT::Int, nS::Int, seed::Int)::DCAPData

    srand(seed)
    data = DCAPData()

    data.R = 1:nR
    data.N = 1:nN
    data.T = 1:nT
    data.S = 1:nS

    data.a = rand(nR, nT) * 5 + 5
    data.b = rand(nR, nT) * 40 + 10
    data.c = rand(nR, nN, nT, nS) * 5 + 5
    data.c0 = rand(nN, nT, nS) * 500 + 500
    data.d = rand(nN, nT, nS) + 0.5
    data.Pr = ones(nS)/nS

    return data
end
