# main file to generate SUCW instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./sucw_models.jl")
include("../../../src/SmpsWriter.jl")

## set parameters for instance
SD = "FallWD"       # Season-Day
nS = 15             # number of scenarios

## write SMPS files
INSTANCE = "SUCW_$(SD)_$(nS)"
SMPS_PATH = "../SMPS/$INSTANCE"
model = sucw(SD, nS)
SmpsWriter.writeSmps(model, SMPS_PATH)
