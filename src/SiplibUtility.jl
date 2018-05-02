#################################
## Generating instances: Start ##
#################################

## Instance name (S is always the number of scenarios)
### DCAP_R_N_T_S: param_set = (R::Int, N::Int, T::Int)
### MPTSPs_D_N_S: param_set = (D::Int, N::Int)
### SIZES_S: param_set = ()
### SMKP_I_S: param_set = (I::Int)
### SSLP_I_J_S: param_set = (I::Int, J::Int)
### SUCW_D_S: param_set = (D::String)  # D ∈ ("FallWD", "FallWE", "SpringWD", "SpringWE", "SummerWD", "SummerWE", "WinterWD", "WinterWE")

# include generator file
cd(dirname(@__FILE__))
include("./SiplibInstanceGenerator.jl")
SMPS_PATH = "$(pwd())/../experiment/SMPS"

#=
# DCAP
problem = "DCAP"
params_set = [(2,3,3), (2,4,3), (3,3,2), (3,4,2)]
nS_set = [500, 1000, 10000, 100000]
FILE_PATH = "$SMPS_PATH/$problem"
for params in params_set
    for nS in nS_set
        generateInstance(FILE_PATH, problem, params, nS)
    end
end

# MPTSPs
## global parameters
const RADIUS = 7.0      # radius of the area
const NK = 3            # number of paths between two nodes
const VC = 40.0         # deterministic velocity profile for central node
const VS = 80.0         # deterministic velocity profile for suburban node

problem = "MPTSPs"
params_set = [("D0",50), ("D1",50), ("D2",50), ("D3",50), ("D0",100), ("D1",100), ("D2",100), ("D3",100)]
nS_set = [100, 200, 300, 400, 500]
FILE_PATH = "$SMPS_PATH/$problem"
for params in params_set
    for nS in nS_set
        generateInstance(FILE_PATH, problem, params, nS)
    end
end

=#

# SIZES
problem = "SIZES"
params_set = [()] # no user-modifiable parameter
nS_set = [10, 100, 1000, 10000, 100000, 1000000]
FILE_PATH = "$SMPS_PATH/$problem"
for params in params_set
    for nS in nS_set
        generateInstance(FILE_PATH, problem, params, nS)
    end
end

# SMKP
## global parameters
const NXZ = 50      # number of xz-knapsack, default: 50
const NXY = 5       # number of xy-knapsacks, default: 5

problem = "SMKP"
params_set = [(120,)]
nS_set = [20, 100, 1000, 10000, 100000]
FILE_PATH = "$SMPS_PATH/$problem"
for params in params_set
    for nS in nS_set
        generateInstance(FILE_PATH, problem, params, nS)
    end
end

# SSLP
problem = "SSLP"
params_set = [(5,25), (5,50), (10,50), (15,45)]
nS_set = [100, 1000, 10000, 100000]
FILE_PATH = "$SMPS_PATH/$problem"
for params in params_set
    for nS in nS_set
        generateInstance(FILE_PATH, problem, params, nS)
    end
end

# SUCW
problem = "SUCW"
params_set = [("FallWD",), ("FallWE",), ("SpringWD",), ("SpringWE",), ("SummerWD",), ("SummerWE",), ("WinterWD",), ("WinterWE",)]
nS_set = [10, 100, 1000]
FILE_PATH = "$SMPS_PATH/$problem"
for params in params_set
    for nS in nS_set
        generateInstance(FILE_PATH, problem, params, nS)
    end
end


#################################
##  Generating instances: End  ##
#################################
