using JuMP, StructJuMP

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

function sizesdata_small(nScenarios::Integer)::SIZESModelData
    # sizes with only 3 types of items
    sizes = SIZESModelData()

    # ---------------------------------------------
    # Read data files and set parameters on sizes
    # ---------------------------------------------
    cd(dirname(Base.source_path()))
    DATA_PATH = "../DATA/oneperioddata.csv"
    data_array = readdlm(DATA_PATH, ',')
    nSleeveType = 3
    D1 = data_array[8:8 + nSleeveType - 1, 3]
    sizes.P = data_array[8:8 + nSleeveType - 1, 2]
    sizes.r = data_array[4,1]
    sizes.s = data_array[6,1]
    c1 = data_array[2,1]

    nN = length(D1)
    nL = nScenarios
    nT = 2

    sizes.N = 1:nN
    sizes.T = 1:nT
    sizes.L = 1:nL

    #---------------------------------------------------------
    # Generate scenario data (random demand for each period)
    #---------------------------------------------------------

    sizes.C = fill(c1, nT, nL)
    demand_variability = linspace(0.5, 1.5, nL)
    sizes.D = zeros(nN, nT, nL)
    for l in sizes.L
        sizes.D[:,1,l] = D1
        sizes.D[:,2,l] = D1*demand_variability[l]
    end

    sizes.Pr = ones(nL)/nL

    return sizes
end

function sizesdata(nScenarios::Integer)::SIZESModelData

    sizes = SIZESModelData()

    # ------------------------------------------
    # Read data files and set parameters on sizes
    # ------------------------------------------
    cd(dirname(Base.source_path()))
    DATA_PATH = "../DATA/oneperioddata.csv"
    data_array = readdlm(DATA_PATH, ',')

    D1 = data_array[8:17, 3]
    sizes.P = data_array[8:17, 2]
    sizes.r = data_array[4,1]
    sizes.s = data_array[6,1]
    c1 = data_array[2,1]

    nN = length(D1)
    nL = nScenarios
    nT = 2

    sizes.N = 1:nN
    sizes.T = 1:nT
    sizes.L = 1:nL

    sizes.C = fill(c1, nT, nL)
    demand_variability = linspace(0.5, 1.5, nL)
    sizes.D = zeros(nN, nT, nL)
    for l in sizes.L
        sizes.D[:,1,l] = D1
        sizes.D[:,2,l] = D1*demand_variability[l]
    end

    sizes.Pr = ones(nL)/nL

    return sizes
end



# TEST

nScenarios = 2
sizes = sizesdata_small(nScenarios)
model = StructuredModel(num_scenarios = nScenarios)

@variables model begin
    x[i = sizes.N, j = sizes.N, t = sizes.T, l = sizes.L] >= 0, Int
    y[i = sizes.N, t = sizes.T] >= 0, Int
    z[i = sizes.N, t = sizes.T, l = sizes.L], Bin
end

@objective(model, Min, sum(sizes.P[i]*y[i,t] for i in sizes.N for t in sizes.T)
                        + sum(sizes.Pr[l]*(sum((sum(sizes.s*z[i,t,l] for i in sizes.N) + sizes.r*sum(x[i,j,t,l] for i in sizes.N[2:end] for j in 1:i-1)) for t in sizes.T[2:end])) for l in sizes.L))

@constraints model begin
    [t = sizes.T, l = sizes.L], sum(y[i,t] for i in sizes.N) <= sizes.C[t,l]
    [j = sizes.N, t = sizes.T, l = sizes.L], sum(x[i,j,t,l] for i in sizes.N[j:end]) >= sizes.D[j,t,l]
    [i = sizes.N, t = sizes.T, l = sizes.L], sum(x[i,j,t2,l] for t2 in 1:t for j in 1:i) <= sum(y[i,t2] for t2 in 1:t)
    [i = sizes.N, t = sizes.T, l = sizes.L], y[i,t] <= sizes.C[t,l]*z[i,t,l]
end

using CPLEX

b = writeLP(model, "SIZES_2.lp")
a = writeMPS(model, "../SMPS/SIZES_MPS.mps")

setsolver(model, CplexSolver(CPXPARAM_TimeLimit = 100))
solve(model)

println("Obj = $(getobjectivevalue(model))")
println("Solutions:")
for i in sizes.N
    for t in sizes.T
        if getvalue(y[i,t]) >= 1
            println("y[$i,$t] = $(getvalue(y[i,t]))")
        end
    end
end
