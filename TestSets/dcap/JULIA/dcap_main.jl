# main file to generate DCAP instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./dcap_models.jl")
include("../../../src/SmpsWriter.jl")

## set parameters for instance
nR = 3      # number of items
nN = 3      # number of taskts
nT = 3      # number of time periods
nS = 500    # number of scenarios

## write SMPS files
INSTANCE = "DCAP_$(nR)_$(nN)_$(nT)_$(nS)"
SMPS_PATH = "../SMPS/$INSTANCE"
model = dcap(nR, nN, nT, nS)
SmpsWriter.writeSmps(model, SMPS_PATH)
