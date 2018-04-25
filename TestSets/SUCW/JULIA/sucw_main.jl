# main file to generate SUCW instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./sucw_models.jl")
include("../../../src/SmpsWriter.jl")
include("../../../src/SparsityAnalyzer.jl")
using SmpsWriter, SparsityAnalyzer

## set parameters for instance
SD = "FallWD"       # Season-Day
nS = 1             # number of scenarios

## set file name and path
INSTANCE = "SUCW_$(SD)_$(nS)"
PLOT_PATH = "../../../plot/$INSTANCE.pdf"
SMPS_PATH = "../SMPS/$INSTANCE"

## generate JuMP.Model
model = sucw(SD, nS)

## sparsity analyze
SparsityAnalyzer.plotConstraintMatrix(model, INSTANCE, PLOT_PATH)
#SparsityAnalyzer.calcSparsity(model, INSTANCE)

## write SMPS files
#SmpsWriter.writeSmps(model, SMPS_PATH)
