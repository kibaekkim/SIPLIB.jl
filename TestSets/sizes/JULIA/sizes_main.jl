cd(dirname(Base.source_path()))
include("./sizes_functions.jl")
include("./sizes_models.jl")
include("../../../src/SmpsWriter.jl")
using SmpsWriter

# Parameters to set
nScenarios = 20

# Write SMPS files (for SIPLIB 2.0)
INSTANCE = "SIZES$(nScenarios)"  # for SIPLIB 2.0 instances
SMPS_PATH = "../SMPS/$INSTANCE"
model = @time sizes(nScenarios)
@time SmpsWriter.writeSmps(model, SMPS_PATH)
