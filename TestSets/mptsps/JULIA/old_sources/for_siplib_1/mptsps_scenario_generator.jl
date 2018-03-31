cd(dirname(Base.source_path()))
include("./mptsps_functions.jl")

# predefined parameters
const RADIUS = 7.0  # radius of the area
const NK = 3        # number of paths between two nodes
const VC = 40.0     # deterministic velocity profile for central node
const VS = 80.0     # deterministic velocity profile for suburban node

# instance parameters
D = "D2"            # node distribution strategy (one of {D0, D1, D2 D3})
nN = 50             # number of nodes
nS = 50             # number of scenarios

# make data storing directory
DATA_DIR = "../DATA/MPTSPs_$(D)_N$(nN)_S$(nS)"
mkdir(DATA_DIR)

# generate instance
Nodes = generate_nodes(D, nN)
Cs = generate_scenario_data(Nodes, D, nN, nS)
store_problem_data(DATA_DIR, Nodes, Cs, D, nN, nS)
store_scenario_data(DATA_DIR, Cs, D, nN, nS)
