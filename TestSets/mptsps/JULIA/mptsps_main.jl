#=
Main file to generate MPTSPS instance (w/ or w/o storing data) with parameters
  - D: node distribution stratedy (D0, D1, D2 ,D3)
  - nN: number of nodes
  - nS: number of scenarios (any integer)
=#
cd(dirname(Base.source_path()))
include("./mptsps_functions.jl")
include("./mptsps_models.jl")
include("../../../src/SmpsWriter.jl")
using SmpsWriter

########################
# Parameters to set

D = "D0"
nN = 50
nS = 100
#INSTANCE = "MPTSPs_$(D)_N$(nN)_S$(nS)"  # for SIPLIB 2.0 instances
########################


# Write SMPS files (for SIPLIB 2.0)
SMPS_PATH = "../SMPS/$INSTANCE"
mkdir(SMPS_PATH)
model = @time mptsps_flow(INSTANCE)
@time SmpsWriter.writeSmps(model, SMPS_PATH)


# Write SMPS files (for SIPLIB)
D = "D0"
nN = 50
INSTANCE = "MPTSPs_$(D)_$(nN)"  # for SIPLIB instances
SMPS_PATH = "../SMPS/$INSTANCE"
mkdir(SMPS_PATH)
model = mptsps_flow_SIPLIB(100, INSTANCE)
SmpsWriter.writeSmps(model, SMPS_PATH)
