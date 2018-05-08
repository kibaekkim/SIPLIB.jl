# include generator file
THIS_FILE_PATH = dirname(@__FILE__)
include("$(dirname(@__FILE__))/../src/SizeAnalyzer.jl")
include("$(dirname(@__FILE__))/../src/SiplibInstanceGenerator.jl")
SMPS_PATH = "$(dirname(@__FILE__))/../experiment/SMPS"
using SizeAnalyzer, DataFrames, CSV

##############################
## parameter setting: Start ##
##############################
params_set_DCAP = [(2,3,3), (2,4,3), (3,3,2), (3,4,2)]
nS_set_DCAP = [500, 1000, 5000, 10000]

params_set_MPTSPs = [("D0",50), ("D1",50), ("D2",50), ("D3",50), ("D0",100), ("D1",100), ("D2",100), ("D3",100)]
nS_set_MPTSPs = [100, 500, 1000]

params_set_SIZES = [()]
nS_set_SIZES = [100, 500, 1000, 2000, 4000]

params_set_SMKP = [(120,)]
nS_set_SMKP = [20, 100, 200, 400, 800]

params_set_SSLP = [(5,25), (5,50), (10,50), (15,45)]
nS_set_SSLP = [100, 500, 1000, 2000, 4000, 8000]

params_set_SUCW = [("FallWD",), ("FallWE",), ("SpringWD",), ("SpringWE",), ("SummerWD",), ("SummerWE",), ("WinterWD",), ("WinterWE",)]
nS_set_SUCW = [10, 50 ,100]
############################
## parameter setting: End ##
############################

# construct a DataFrame object
df = DataFrame(instance=Any[], cont1=Any[], bin1=Any[], int1=Any[], cont2=Any[], bin2=Any[], int2=Any[], cont=Any[], bin=Any[], int=Any[], rows=Any[], cols=Any[], nonzeros=Any[], density=Any[])

# generate JuMP models and save instance size information

# DCAP
problem = "DCAP"
params_set = params_set_DCAP
nS_set = nS_set_DCAP
for params in params_set
    for nS in nS_set

        # set instance name
        INSTANCE = problem
        for param in params
            INSTANCE = INSTANCE * "_" * "$param"
        end
        INSTANCE = INSTANCE * "_" * "$nS"

        # generate JuMP.Model
        m = generateInstance(problem, params, nS)
        ISI = getInstanceSizeInfo(INSTANCE, m)
        push!(df, convertISItoVector(ISI))

    end
end

# MPTSPs
## global parameters
const RADIUS = 7.0      # radius of the area
const NK = 3            # number of paths between two nodes
const VC = 40.0         # deterministic velocity profile for central node
const VS = 80.0         # deterministic velocity profile for suburban node

problem = "MPTSPs"
params_set = params_set_MPTSPs
nS_set = nS_set_MPTSPs
for params in params_set
    for nS in nS_set

        # set instance name
        INSTANCE = problem
        for param in params
            INSTANCE = INSTANCE * "_" * "$param"
        end
        INSTANCE = INSTANCE * "_" * "$nS"

        # generate JuMP.Model
        m = generateInstance(problem, params, nS)
        ISI = getInstanceSizeInfo(INSTANCE, m)
        push!(df, convertISItoVector(ISI))

    end
end

# SIZES
problem = "SIZES"
params_set = params_set_SIZES # no user-modifiable parameter
nS_set = nS_set_SIZES
for params in params_set
    for nS in nS_set

        # set instance name
        INSTANCE = problem
        for param in params
            INSTANCE = INSTANCE * "_" * "$param"
        end
        INSTANCE = INSTANCE * "_" * "$nS"

        # generate JuMP.Model
        m = generateInstance(problem, params, nS)
        ISI = getInstanceSizeInfo(INSTANCE, m)
        push!(df, convertISItoVector(ISI))

    end
end

# SMKP
## global parameters
const NXZ = 50      # number of xz-knapsack, default: 50
const NXY = 5       # number of xy-knapsacks, default: 5

problem = "SMKP"
params_set = params_set_SMKP
nS_set = nS_set_SMKP
for params in params_set
    for nS in nS_set

        # set instance name
        INSTANCE = problem
        for param in params
            INSTANCE = INSTANCE * "_" * "$param"
        end
        INSTANCE = INSTANCE * "_" * "$nS"

        # generate JuMP.Model
        m = generateInstance(problem, params, nS)
        ISI = getInstanceSizeInfo(INSTANCE, m)
        push!(df, convertISItoVector(ISI))

    end
end

# SSLP
problem = "SSLP"
params_set = params_set_SSLP
nS_set = nS_set_SSLP
for params in params_set
    for nS in nS_set

        # set instance name
        INSTANCE = problem
        for param in params
            INSTANCE = INSTANCE * "_" * "$param"
        end
        INSTANCE = INSTANCE * "_" * "$nS"

        # generate JuMP.Model
        m = generateInstance(problem, params, nS)
        ISI = getInstanceSizeInfo(INSTANCE, m)
        push!(df, convertISItoVector(ISI))

    end
end

# SUCW
problem = "SUCW"
params_set = params_set_SUCW
nS_set = nS_set_SUCW
FILE_PATH = "$SMPS_PATH/$problem"
for params in params_set
    for nS in nS_set

        # set instance name
        INSTANCE = problem
        for param in params
            INSTANCE = INSTANCE * "_" * "$param"
        end
        INSTANCE = INSTANCE * "_" * "$nS"

        # generate JuMP.Model
        m = generateInstance(problem, params, nS)
        ISI = getInstanceSizeInfo(INSTANCE, m)
        push!(df, convertISItoVector(ISI))

    end
end



CSV.write("$(dirname(@__FILE__))/analysis/data_frame.csv" , df)
