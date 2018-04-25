# main file to generate SSLP instance with parameters

## include files
cd(dirname(Base.source_path()))
include("./sslp_models.jl")
include("../../../src/SmpsWriter.jl")
include("../../../src/SparsityAnalyzer.jl")
using SmpsWriter, SparsityAnalyzer

## set parameters for instance
nJ = 5    # number of potential server locations
nI = 10    # number of clients
nS = 3   # number of scenarios

## set file name and path
INSTANCE = "SSLP_$(nJ)_$(nI)_$(nS)"
PLOT_PATH = "../../../plot/$INSTANCE.pdf"
SMPS_PATH = "../SMPS/$INSTANCE"

## generate JuMP.Model
model = sslp(nJ, nI, nS)

## sparsity analyze
SparsityAnalyzer.plotConstraintMatrix(model, INSTANCE, PLOT_PATH)
#SparsityAnalyzer.calcSparsity(model, INSTANCE)

## write SMPS files
SmpsWriter.writeSmps(model, SMPS_PATH)
