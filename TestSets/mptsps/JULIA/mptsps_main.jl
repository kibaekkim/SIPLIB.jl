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

## set parameters for instance
D = "D0"                # node distribution strategy (D0, D1, D2 ,D3)
nN = 50                 # number of nodes
nS = 10                 # number of scenarios (any integer)

## write SMPS files
INSTANCE = "MPTSPs_$(D)_$(nN)_$(nS)"
SMPS_PATH = "../SMPS/$INSTANCE"
model = mptsps_flow(D, nN, nS)
SmpsWriter.writeSmps(model, SMPS_PATH)
