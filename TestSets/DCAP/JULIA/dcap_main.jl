# main file to generate DCAP instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./dcap_models.jl")
include("../../../src/SmpsWriter.jl")
include("../../../src/SparsityAnalyzer.jl")
using SmpsWriter, SparsityAnalyzer

## set parameters for instance
nR = 3      # number of items
nN = 3      # number of tasks
nT = 3      # number of time periods
nS = 100 # number of scenarios

## set file name and path
INSTANCE = "DCAP_$(nR)_$(nN)_$(nT)_$(nS)"
PLOT_PATH = "../../../plot/$INSTANCE.pdf"
SMPS_PATH = "../SMPS/$INSTANCE"

## generate JuMP.Model
model = dcap(nR, nN, nT, nS)

## sparsity analyze
#SparsityAnalyzer.plotConstraintMatrix(model, INSTANCE, PLOT_PATH)
#SparsityAnalyzer.calcSparsity(model, INSTANCE)

## write SMPS files
writeSmps(model, SMPS_PATH)
