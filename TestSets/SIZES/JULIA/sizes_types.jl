type SIZESModelData

    # Sets
    N   # set of items : i,j ∈ N
    T   # set of time periods (stage) : t,t' ∈ T
    S   # set of scenarios : s ∈ S

    # Parameters
    D   # demand for each item i at time t under scenario s : D[i,t,s]
    P   # unit production cost for each item i : P[i]
    r   # unit cutting cost
    f   # fixed setup cost
    C   # production capacity at time t under scenario s : C[t,s]
    Pr  # probability distribution of scenario s : Pr[s]

    SIZESModelData() = new()
end
