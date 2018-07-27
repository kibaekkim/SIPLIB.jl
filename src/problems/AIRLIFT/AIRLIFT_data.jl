mutable struct AIRLIFTData

    # Sets
    A   # set of aircraft types : i ∈ A
    R   # set of routes : j,k ∈ R
    S   # set of scenarios : s ∈ S

    # Parameters
    F       # the maximum number of flying hours for aircraft of type i available during the month
    a       #
    alpha   #
    b       #
    c       #
    gamma   #
    cplus   #
    cminus  #
    d       #
    Pr      #

    AIRLIFTData() = new()
end

function AIRLIFTData(nS::Integer, seed::Integer)::AIRLIFTData

    srand(seed)
    data = AIRLIFTData()

    # ---------------------------------------------
    # Read files and set parameters on data
    # ---------------------------------------------
    DATA_PATH = "$(dirname(@__FILE__))/DATA/numerical_data.csv"
    file_array = readdlm(DATA_PATH, ',')

    data.A = 1:2
    data.R = 1:2
    data.S = 1:nS

    data.F = 720
    data.a = file_array[3:4,2:3]
    data.b = file_array[3:4,4:5]
    data.c = file_array[3:4,6:7]
    switching_hour = file_array[3:4,8]
    switching_cost = file_array[3:4,9]

    data.alpha = zeros(length(data.A),length(data.R),length(data.R))
    for i in data.A, j in data.R, k in data.R
        data.alpha[i,j,k] = data.a[i,j] + switching_hour[i]
    end

    data.gamma = zeros(length(data.A),length(data.R),length(data.R))
    for i in data.A, j in data.R, k in data.R
        data.gamma[i,j,k] = data.c[i,j] + switching_cost[i]
    end

    data.cplus = file_array[3,10:11]
    data.cminus = file_array[3,12:13]

    #---------------------------------------------------------
    # Generate scenario data (random demand for each route)
    #---------------------------------------------------------

    # function for the desired Lognormal distribution
    function LogNormal_generator(desired_mean::Any, desired_std::Any)
        μ = desired_mean
        σ = desired_std
        param2 = sqrt(log((σ^2)/exp(2*log(μ)) + 1)) # param2 stands for 'μ' for LogNormal
        param1 = log(μ)-(param2^2)/2    # param1 stands for 'σ' for LogNormal
        return LogNormal(param1, param2)
    end

    data.d = zeros(2,nS)
    for s in data.S
        data.d[1,s] = rand(LogNormal_generator(1000,50))
        data.d[2,s] = rand(LogNormal_generator(1500,300))
    end

    data.Pr = ones(nS)/nS
    return data
end
