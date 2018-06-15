# please add more problems in this function
"""
    getModel(problem::Symbol, param_arr::Any ; seed::Int=1, lprelax::Int=0)

Returns JuMP.Model-type object.
    problem (necessary): One of (:DCAP, :MPTSPs, :SIZES, :SMKP, :SSLP, :SUC)
    param_arr (necessary): One of ([R,N,T,S] , [D, N, S] , [S] , [I, S] , [I, J, S] , [D, S])
    seed (optional): Any integer (DEFAULT=1)
    lprelax (optional): One of (0, 1, 2, 3) (0: no relax, 1: first-stage only, 2: second-stage only, 3: fully LP relax)
"""
function getModel(problem::Symbol, param_arr::Any ; seed::Int=1, lprelax::Int=0)::JuMP.Model

    modeling_function = Base.getfield(Siplib, problem)

    if length(param_arr) == nParam[problem]
        model = modeling_function(param_arr... , seed)
        return lprelaxModel(model, lprelax)
    else
        warn("The number of parameter is wrong. Please use correct set of parameters.")
        return
    end

end

# getModel: no optional arguments version
getModel(problem::Symbol, param_arr::Any, _seed::Int, _lprelax::Int) = getModel(problem, param_arr, seed = _seed, lprelax = _lprelax)

"""
    generateSMPS(problem::Symbol, param_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance" ; seed::Int=1, varname::Bool=false, splice::Bool=true)

Generates SMPS files and Returns JuMP.Model-type object.
    problem (necessary): One of (:DCAP, :MPTSPs, :SIZES, :SMKP, :SSLP, :SUC)
    param_arr (necessary): One of ([R,N,T,S] , [D, N, S] , [S] , [I, S] , [I, J, S] , [D, S])

    seed (optional): Any integer (DEFAULT=1)
    lprelax (optional): One of (0, 1, 2, 3) (0: no relax, 1: first-stage only, 2: second-stage only, 3: fully LP relax)
    genericnames (optional): 'true' if you want to let Siplib automatically generate: VAR1, VAR2, ... . 'false' if you want to maintain the original (readable) variable names. (DEFAULT: true)
    splice (optional): 'true' then data in the model is spliced after writing SMPS files so you cannot re-use the object. 'false' if you want to re-use the JuMP.Model object.  (DEFAULT: true)
"""
function generateSMPS(problem::Symbol, param_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance" ; seed::Int=1, lprelax::Int=0, genericnames::Bool=true, splice::Bool=true)

    model = getModel(problem, param_arr, seed, lprelax)
    INSTANCE_NAME = getInstanceName(problem, param_arr)
    if lprelax != 0
        INSTANCE_NAME *= "_LP$(lprelax)"
    end
    writeSMPS(model, INSTANCE_NAME, DIR_NAME, genericnames, splice)

    return model

end
