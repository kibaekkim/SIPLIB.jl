# main file to generate MPTSPs instance with parameters

## global parameters
const RADIUS = 7.0      # radius of the area
const NK = 3            # number of paths between two nodes
const VC = 40.0         # deterministic velocity profile for central node
const VS = 80.0         # deterministic velocity profile for suburban node

## include files
cd(dirname(Base.source_path()))
include("./mptsps_models.jl")
include("../../../src/SmpsWriter.jl")
include("../../../src/SparsityAnalyzer.jl")
using SmpsWriter, SparsityAnalyzer

## set parameters for instance
D = "D0"                # node distribution strategy (D0, D1, D2 ,D3)
nN = 5                 # number of nodes
nS = 3                # number of scenarios (any integer)

## set file name and path
INSTANCE = "MPTSPs_$(D)_$(nN)_$(nS)"
PLOT_PATH = "../../../plot/$INSTANCE.pdf"
SMPS_PATH = "../SMPS/$INSTANCE"

## generate JuMP.Model
model = mptsps_flow(D, nN, nS)

## sparsity analyze
SparsityAnalyzer.plotConstraintMatrix(model, INSTANCE, PLOT_PATH)
#SparsityAnalyzer.calcSparsity(model, INSTANCE)

## write SMPS files
SmpsWriter.writeSmps(model, SMPS_PATH)
