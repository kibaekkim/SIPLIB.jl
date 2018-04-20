include("./sizes_types.jl")
using Distributions


function sizesdata(nScenarios::Integer)::SIZESModelData

    srand(1)
    sizes = SIZESModelData()

    # ---------------------------------------------
    # Read data files and set parameters on sizes
    # ---------------------------------------------
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
    sizes.L = 1:nL
    sizes.T = 1:nT

    #---------------------------------------------------------
    # Generate scenario data (random demand for each period)
    #---------------------------------------------------------

    sizes.C = fill(c1, nT)
    demand_variability = linspace(0.5, 1.5, nL)
    sizes.D = zeros(nN, nT, nL)
    for l in sizes.L
        sizes.D[:,1,l] = D1
        sizes.D[:,2,l] = rand(Uniform(0.5,1.5))*D1*demand_variability[l]
    end

    sizes.Pr = ones(nL)/nL

    return sizes
end
