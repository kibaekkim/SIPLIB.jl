type SIZESModelData

    # Sets
    N   # set of items : i,j ∈ N
    T   # set of time periods (stage) : t,t' ∈ T
    L   # set of scenarios : l ∈ L

    # Parameters
    D   # demand for each item i at time t under scenario l : D[i,t,l]
    P   # unit production cost for each item i : P[i]
    r   # unit cutting cost
    s   # setup cost
    C   # production capacity at time t under scenario l : C[t,l]
    Pr  # probability distribution of scenario l : Pr[l]

    SIZESModelData() = new()
end
