function sizesdata(nScenarios::Integer, seed::Integer)::SIZESModelData

    srand(seed)
    sizes = SIZESModelData()

    # ---------------------------------------------
    # Read data files and set parameters on sizes
    # ---------------------------------------------
    DATA_PATH = "$(dirname(@__FILE__))/data/oneperioddata.csv"
    data_array = readdlm(DATA_PATH, ',')

    D1 = data_array[8:17, 3]
    sizes.P = data_array[8:17, 2]
    sizes.r = data_array[4,1]
    sizes.f = data_array[6,1]
    c1 = data_array[2,1]

    nN = length(D1)
    nS = nScenarios
    nT = 2

    sizes.N = 1:nN
    sizes.S = 1:nS
    sizes.T = 1:nT

    #---------------------------------------------------------
    # Generate scenario data (random demand for each period)
    #---------------------------------------------------------

    sizes.C = fill(c1, nT)
    demand_variability = linspace(0.5, 1.5, nS)
    sizes.D = zeros(nN, nT, nS)
    for s in sizes.S
        sizes.D[:,1,s] = D1
        sizes.D[:,2,s] = rand(Uniform(0.5,1.5))*D1*demand_variability[s]
    end

    sizes.Pr = ones(nS)/nS

    return sizes
end
