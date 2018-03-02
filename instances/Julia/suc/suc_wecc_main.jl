#=
Main file to generate SUC instance with parameters
  - number of scenarios
  - day type
=#

include("suc_wecc.jl")
include("../../../src/SmpsWriter.jl")
using SmpsWriter

########################
# Parameters to set

nScenarios = 15
daytype    = "FallWD"

########################

@time begin
    model = suc_wecc(nScenarios, daytype)
end

# Write SMPS files
@time SmpsWriter.writeSmps(model, "../../SMPS/suc_wecc_$daytype\_$nScenarios")
