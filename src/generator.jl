# return JuMP.Model only
# please add more problems in this function
function getJuMPModel(problem::Symbol, param_arr::Any)::JuMP.Model

    if problem == :DCAP
        if length(param_arr) == nParam[problem] # with default random seed=1
            return dcap(param_arr[1], param_arr[2], param_arr[3], param_arr[4])
        elseif length(param_arr) == nParam[problem] + 1 # last argument is random seed.
            return dcap(param_arr[1], param_arr[2], param_arr[3], param_arr[4], param_arr[5])
        end
    elseif problem == :MPTSPs
        if length(param_arr) == nParam[problem] # with default random seed=1
            return mptsps_flow(param_arr[1], param_arr[2], param_arr[3])
        elseif length(param_arr) == nParam[problem] + 1 # last argument is random seed.
            return mptsps_flow(param_arr[1], param_arr[2], param_arr[3], param_arr[4])
        end
    elseif problem == :SIZES
        if length(param_arr) == nParam[problem] # with default random seed=1
            return sizes(param_arr[1])
        elseif length(param_arr) == nParam[problem] + 1 # last argument is random seed.
            return sizes(param_arr[1], param_arr[2])
        end
    elseif problem == :SMKP
        if length(param_arr) == nParam[problem] # with default random seed=1
            return smkp(param_arr[1], param_arr[2])
        elseif length(param_arr) == nParam[problem] + 1 # last argument is random seed.
            return smkp(param_arr[1], param_arr[2], param_arr[3])
        end
    elseif problem == :SSLP
        if length(param_arr) == nParam[problem] # with default random seed=1
            return sslp(param_arr[1], param_arr[2], param_arr[3])
        elseif length(param_arr) == nParam[problem] + 1 # last argument is random seed.
            return sslp(param_arr[1], param_arr[2], param_arr[3], param_arr[4])
        end
    elseif problem == :SUC  # SUC does not have random seed. Stochastic wind data is already generated and given in data folder.
        if length(param_arr) == nParam[problem]
            return suc(param_arr[1], param_arr[2])
        end
    else
        warn("Your parameter input is wrong. Please use correct parameters.")
    end
end

# this function does the followings simultaneously:
# - return JuMP.Model
# - generate SMPS files (default folder: SIPLIB/instance)
function generateSMPS(problem::Symbol, param_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance")::JuMP.Model
    model = getJuMPModel(problem, param_arr)
    INSTANCE = getInstanceName(problem, param_arr)
    writeSmps(model, INSTANCE, DIR_NAME)
    return model
end

function generateSMPS_with_splice(problem::Symbol, param_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance")::JuMP.Model
    model = getJuMPModel(problem, param_arr)
    INSTANCE = getInstanceName(problem, param_arr)
    writeSmps_with_splice(model, INSTANCE, DIR_NAME)
    return model
end

function generateSMPS_with_name(problem::Symbol, param_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance")::JuMP.Model
    model = getJuMPModel(problem, param_arr)
    INSTANCE = getInstanceName(problem, param_arr)
    writeSmps_with_name(model, INSTANCE, DIR_NAME)
    return model
end

function generateSMPS_with_name_splice(problem::Symbol, param_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance")::JuMP.Model
    model = getJuMPModel(problem, param_arr)
    INSTANCE = getInstanceName(problem, param_arr)
    writeSmps_with_name_splice(model, INSTANCE, DIR_NAME)
    return model
end

function writeSMPS(m::JuMP.Model, INSTANCE::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../instance")
    writeSmps_with_name(m, INSTANCE, DIR_NAME)
end

function writeSMPS_with_name(m::JuMP.Model, INSTANCE::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../instance")
    writeSmps_with_name(m, INSTANCE, DIR_NAME)
end

function writeSMPS_with_splice(m::JuMP.Model, INSTANCE::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../instance")
    writeSmps_with_splice(m, INSTANCE, DIR_NAME)
end
