cd(dirname(@__FILE__))

# include utility files
include("./SmpsWriter.jl")
include("./SparsityAnalyzer.jl")

# include JuMP modeling files
include("../TestSets/DCAP/JULIA/dcap_models.jl")
include("../TestSets/MPTSPs/JULIA/mptsps_models.jl")
include("../TestSets/SIZES/JULIA/sizes_models.jl")
include("../TestSets/SMKP/JULIA/smkp_models.jl")
include("../TestSets/SSLP/JULIA/sslp_models.jl")
include("../TestSets/SUCW/JULIA/sucw_models.jl")

using SmpsWriter, SparsityAnalyzer

# generate instance in SMPS format
function generateInstance(FILE_PATH::String, problem::String, params::Any, nS::Int)

    # set instance name
    INSTANCE = problem
    for param in params
        INSTANCE = INSTANCE * "_" * "$param"
    end
    INSTANCE = INSTANCE * "_" * "$nS"

    # generate instance
    if problem == "DCAP"
        model = dcap(params[1], params[2], params[3], nS)
    elseif problem == "MPTSPs"
        model = mptsps_flow(params[1], params[2], nS)
    elseif problem == "SIZES"
        model = sizes(nS)
    elseif problem == "SMKP"
        model = smkp(params[1], nS)
    elseif problem == "SSLP"
        model = sslp(params[1], params[2], nS)
    elseif problem == "SUCW"
        model = sucw(params[1], nS)
    end

    # save instance
    SmpsWriter.writeSmps(model, "$FILE_PATH/$INSTANCE")
end

#=
FILE_PATH = "/home/yoc/GitLab/Argonne/SIPLIB/experiment/SMPS"
problem = "SIZES"
param_set = ()
nS = 10
generateInstance(FILE_PATH, problem, param_set, nS)
=#
