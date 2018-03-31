# main file to generate SMKP instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./smkp_models.jl")
include("../../../src/SmpsWriter.jl")

## set parameters for instance
nI = 120   # number of items
nS = 9999  # number of scenarios (any integer)

## write SMPS files
INSTANCE = "SMKP_$(nI)_$(nS)"
SMPS_PATH = "../SMPS/$INSTANCE"
model = smkp(nI, nS)
SmpsWriter.writeSmps(model, SMPS_PATH)
