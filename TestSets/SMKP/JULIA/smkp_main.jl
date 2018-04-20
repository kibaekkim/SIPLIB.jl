# main file to generate SMKP instance with parameters

## global parameters
const NXZ = 50      # number of xz-knapsack, default: 50
const NXY = 5       # number of xy-knapsacks, default: 5

## include files
cd(dirname(Base.source_path()))
include("./smkp_models.jl")
include("../../../src/SmpsWriter.jl")

## set parameters for instance
nI = 5  # number of items
nS = 3  # number of scenarios (any integer)

## write SMPS files
INSTANCE = "SMKP_$(nI)_$(nS)"
SMPS_PATH = "../SMPS/$INSTANCE"
model = smkp(nI, nS)
SmpsWriter.writeSmps(model, SMPS_PATH)
