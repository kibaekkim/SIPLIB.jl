struct DCAPData
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
