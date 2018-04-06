# main file to generate DCAP instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./dcap_models.jl")
include("../../../src/SmpsWriter.jl")
using SmpsWriter

## set parameters for instance
nR = 2      # number of items
nN = 3      # number of tasks
nT = 3      # number of time periods
nS = 200    # number of scenarios

## write SMPS files
INSTANCE = "DCAP_$(nR)_$(nN)_$(nT)_$(nS)"
SMPS_PATH = "../SMPS/$INSTANCE"
model = dcap(nR, nN, nT, nS)
writeSmps(model, SMPS_PATH)
