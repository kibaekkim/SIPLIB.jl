# main file to generate SSLP instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./sslp_models.jl")
include("../../../src/SmpsWriter.jl")

## set parameters for instance
nJ = 10    # number of potential server locations
nI = 50    # number of clients
nS = 100   # number of scenarios

## write SMPS files
INSTANCE = "SSLP_$(nJ)_$(nI)_$(nS)"
SMPS_PATH = "../SMPS/$INSTANCE"
model = sslp(nJ, nI, nS)
SmpsWriter.writeSmps(model, SMPS_PATH)
