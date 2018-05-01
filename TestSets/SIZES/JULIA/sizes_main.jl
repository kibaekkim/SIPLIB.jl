# main file to generate MPTSPs instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./sizes_models.jl")
include("../../../src/SmpsWriter.jl")
include("../../../src/SparsityAnalyzer.jl")
using SmpsWriter, SparsityAnalyzer

## set parameters for instance
nS = 1000000         # number of scenarios

## set file name and path
INSTANCE = "SIZES_$(nS)"  # for SIPLIB 2.0 instances
PLOT_PATH = "../../../plot/$INSTANCE.pdf"
SMPS_PATH = "../SMPS/$INSTANCE"

## generate JuMP.Model
model = @time sizes(nS)

## sparsity analyze
#SparsityAnalyzer.plotConstraintMatrix(model, INSTANCE, PLOT_PATH)
#SparsityAnalyzer.calcSparsity(model, INSTANCE)

## write SMPS files
SmpsWriter.writeSmps(model, SMPS_PATH)
