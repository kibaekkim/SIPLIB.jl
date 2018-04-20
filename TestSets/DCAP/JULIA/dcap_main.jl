# main file to generate DCAP instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./dcap_models.jl")
include("../../../src/SmpsWriter.jl")
using SmpsWriter

## set parameters for instance
nR = 2      # number of items
nN = 2      # number of tasks
nT = 2      # number of time periods
nS = 2 # number of scenarios

## write SMPS files
INSTANCE = "DCAP_$(nR)_$(nN)_$(nT)_$(nS)"
SMPS_PATH = "../SMPS/$INSTANCE"
model = dcap(nR, nN, nT, nS)
SmpsWriter.writeSmps(model, SMPS_PATH)
