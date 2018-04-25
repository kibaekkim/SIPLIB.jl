# main file to generate SMKP instance with parameters

## global parameters
const NXZ = 50      # number of xz-knapsack, default: 50
const NXY = 5       # number of xy-knapsacks, default: 5

## include files
cd(dirname(Base.source_path()))
include("./smkp_models.jl")
include("../../../src/SmpsWriter.jl")
include("../../../src/SparsityAnalyzer.jl")
using SmpsWriter, SparsityAnalyzer

## set parameters for instance
nI = 10  # number of items
nS = 3  # number of scenarios (any integer)

## set file name and path
INSTANCE = "SMKP_$(nI)_$(nS)"
PLOT_PATH = "../../../plot/$INSTANCE.pdf"
SMPS_PATH = "../SMPS/$INSTANCE"

## generate JuMP.Model
model = smkp(nI, nS)

## sparsity analyze
SparsityAnalyzer.plotConstraintMatrix(model, INSTANCE, PLOT_PATH)
#SparsityAnalyzer.calcSparsity(model, INSTANCE)

## write SMPS files
SmpsWriter.writeSmps(model, SMPS_PATH)
