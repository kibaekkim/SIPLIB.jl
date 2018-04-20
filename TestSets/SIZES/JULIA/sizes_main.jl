# main file to generate MPTSPs instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./sizes_models.jl")
include("../../../src/SmpsWriter.jl")

## set parameters for instance
nS = 2         # number of scenarios

## write SMPS files
INSTANCE = "SIZES_$(nS)"  # for SIPLIB 2.0 instances
SMPS_PATH = "../SMPS/$INSTANCE"
model = @time sizes(nS)
SmpsWriter.writeSmps(model, SMPS_PATH)
