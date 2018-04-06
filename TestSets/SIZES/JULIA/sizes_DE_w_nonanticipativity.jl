using JuMP

type SIZESModel

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

    SIZESModel() = new()
end

function sizesdata(nScenarios::Integer)::SIZESModel

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

nScenarios = 10
sizes = sizesdata(nScenarios)
model = StructuredModel(num_scenarios = nScenarios)

@variables model begin
    x[i = sizes.N, j = sizes.N, t = sizes.T, l = sizes.L] >= 0, Int
    y[i = sizes.N, t = sizes.T, l = sizes.L] >= 0, Int
    z[i = sizes.N, t = sizes.T, l = sizes.L], Bin
end

@objective(model, Min, sum(sizes.Pr[l]*(sum((sum(sizes.s*z[i,t,l] + sizes.P[i]*y[i,t,l] for i in sizes.N) + sizes.r*sum(x[i,j,t,l] for i in sizes.N[2:end] for j in 1:i-1)) for t in sizes.T)) for l in sizes.L))

@constraints model begin
    [i = sizes.N, t = sizes.T, l1 = sizes.L, l2 = sizes.L[l1+1:end]], y[i,t,l1] == y[i,t,l2]
    [t = sizes.T, l = sizes.L], sum(y[i,t,l] for i in sizes.N) <= sizes.C[t,l]
    [j = sizes.N, t = sizes.T, l = sizes.L], sum(x[i,j,t,l] for i in sizes.N[j:end]) >= sizes.D[j,t,l]
    [i = sizes.N, t = sizes.T, l = sizes.L], sum(x[i,j,t2,l] for t2 in 1:t for j in 1:i) <= sum(y[i,t2,l] for t2 in 1:t)
    [i = sizes.N, t = sizes.T, l = sizes.L], y[i,t,l] <= sizes.C[t,l]*z[i,t,l]
end

using CPLEX

setsolver(model, CplexSolver(CPXPARAM_TimeLimit = 100))
solve(model)

println("Obj = $(getobjectivevalue(model))")
println("Solutions:")
l = 10
for i in sizes.N
    for t in sizes.T
        if getvalue(y[i,t,l]) >= 1
            println("y[$i,$t,$l] = $(getvalue(y[i,t,l]))")
        end
    end
end
