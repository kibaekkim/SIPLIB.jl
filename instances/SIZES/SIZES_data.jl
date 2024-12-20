mutable struct SIZESData

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

    SIZESData() = new()
end

function SIZESData(nS::Integer, seed::Integer)::SIZESData

    Random.seed!(seed)
    data = SIZESData()

    # ---------------------------------------------
    # Read files and set parameters on data
    # ---------------------------------------------
    DATA_PATH = "$(dirname(@__FILE__))/DATA/oneperioddata.csv"
    file_array = readdlm(DATA_PATH, ',')

    D1 = file_array[8:17, 3]
    data.P = file_array[8:17, 2]
    data.r = file_array[4,1]
    data.f = file_array[6,1]
    c1 = file_array[2,1]

    nN = length(D1)
    nT = 2

    data.N = 1:nN
    data.S = 1:nS
    data.T = 1:nT

    #---------------------------------------------------------
    # Generate scenario data (random demand for each period)
    #---------------------------------------------------------

    data.C = fill(c1, nT)
    if nS == 1
        demand_variability = [1.0]
    else
        demand_variability = range(0.5, step=1.5, length=nS)
    end
    data.D = zeros(nN, nT, nS)
    for s in data.S
        data.D[:,1,s] = D1
        data.D[:,2,s] = rand(Uniform(0.5,1.5))*D1*demand_variability[s]
    end

    data.Pr = ones(nS)/nS

    return data
end
