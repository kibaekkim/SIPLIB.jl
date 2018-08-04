"""
    getModel(problem::Symbol, params_arr::Any ; seed::Int=1)

Returns JuMP.Model-type object.
    problem (necessary, positional): One of (:AIRLIFT, :DCAP, :MPTSPs, :SDCP, :SIZES, :SMKP, :SSLP, :SUC)
    params_arr (necessary, positional): One of ([S], [R,N,T,S] , [D, N, S] , [K, P, D, S], [S] , [I, S] , [I, J, S] , [D, S])
    seed (optional, keyword): Any integer (DEFAULT=1)
"""
function getModel(problem::Symbol, params_arr::Any ; seed::Int=1)::JuMP.Model

    modeling_function = Base.getfield(Siplib, problem)

    if length(params_arr) == numParams[problem]
        model = modeling_function(params_arr... , seed)
        return model
    else
        warn("The number of parameter is wrong. Please use correct set of parameters.")
        return
    end

end

# getModel(): no optional arguments version
getModel(problem::Symbol, params_arr::Any, _seed::Int) = getModel(problem, params_arr, seed = _seed)

# convert a StructModel to normal model that can be solved by any MIP solver
function getExtensiveFormModel(model::JuMP.Model ; genericnames::Bool=true, splice::Bool=true)::JuMP.Model
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

    mdata_all = getStructModelData(model, genericnames, splice)
    return getExtensiveFormModel(mdata_all)
end

# getExtensiveFormModel(): no optional arguments version
getExtensiveFormModel(model::JuMP.Model, _genericnames::Bool, _splice::Bool) = getExtensiveFormModel(model, genericnames=_genericnames, splice=_splice)

"""
    generateSMPS(problem::Symbol, params_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance" ; seed::Int=1, varname::Bool=false, splice::Bool=true, smpsfile::Bool=false)

Generates SMPS files and Returns JuMP.Model-type object.
    problem (necessary, positional): One of (:AIRLIFT, :DCAP, :MPTSPs, :SDCP, :SIZES, :SMKP, :SSLP, :SUC)
    params_arr (necessary, positional): One of ([S], [R,N,T,S] , [D, N, S] , [K, P, D, S], [S] , [I, S] , [I, J, S] , [D, S])
    DIR_NAME (optional, positional): Directory where SMPS files are stored (DEFAULT: Siplib/instance)
    seed (optional, keyword): Any integer (DEFAULT=1)
    lprelax (optional, keyword): One of (0, 1, 2, 3) (0: no relax, 1: first-stage only, 2: second-stage only, 3: fully LP relax)
    genericnames (optional, keyword): 'true' if you want to let Siplib automatically generate: VAR1, VAR2, ... . 'false' if you want to maintain the original (readable) variable names. (DEFAULT: true)
    splice (optional, keyword): 'true' then data in the model is spliced after writing SMPS files so you cannot re-use the object. 'false' if you want to re-use the JuMP.Model object.  (DEFAULT: true)
    smpsfile (optional, keyword): 'true' if you want to generate .smps file together (for SCIP 6.0).
"""
function generateSMPS(problem::Symbol, params_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance" ;
                    seed::Int=1, lprelax::Int=0, genericnames::Bool=true, splice::Bool=true, smpsfile::Bool=false, FIRST_STAGE_SOLUTION_FILE::String="")

@time begin
    INSTANCE_NAME = getInstanceName(problem, params_arr)
    model = getModel(problem, params_arr, seed)

    if lprelax != 0
        INSTANCE_NAME *= "_LP$(lprelax)"
        lprelaxModel!(model,lprelax)
        writeSMPS(model, INSTANCE_NAME, DIR_NAME, genericnames, splice, smpsfile)
    # generating EEV instance given the first-stage solutions (expected result of using the first-stage solution obtained from EVP)
    elseif FIRST_STAGE_SOLUTION_FILE != ""
        writeSMPS(model, INSTANCE_NAME, DIR_NAME, genericnames, splice, smpsfile)
    else
        writeSMPS(model, INSTANCE_NAME, DIR_NAME, genericnames, splice, smpsfile)
    end

end

    return model
end

"""
    generateMPS(problem::Symbol, params_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance" ; seed::Int=1, varname::Bool=false, splice::Bool=true, decfile::Bool=false)

Generates MPS file (with optional .dec file) and Returns JuMP.Model-type object.
"""
function generateMPS(problem::Symbol, params_arr::Any, DIR_NAME::String="$(dirname(@__FILE__))/../instance" ;
                    seed::Int=1, lprelax::Int=0, genericnames::Bool=true, splice::Bool=true, decfile::Bool=false, ss::Bool=false, ev::Bool=false)

@time begin

    INSTANCE_NAME = getInstanceName(problem, params_arr)
    model = getModel(problem, params_arr, seed)
    # LP relaxation
    if lprelax != 0
        INSTANCE_NAME *= "_LP$(lprelax)"
        lprelaxModel!(model,lprelax)
        writeMPS(model, INSTANCE_NAME, DIR_NAME, genericnames, splice, decfile)
    # Genarating single scenario instances (to get WS solution)
    elseif ss == true
        INSTANCE_NAME *= "_SS"
        mdata_all = getStructModelData(model, genericnames, splice)
        for s in 1:model.ext[:Stochastic].num_scen
            mdata_ss = getSingleScenarioModelData(mdata_all, s)
            writeMPS("$(DIR_NAME)/$(INSTANCE_NAME)$s.mps", INSTANCE_NAME*"$s", mdata_ss, genericnames)
        end
    # Generating EVP instance (expected value problem)
    elseif ev == true
        writeMPS(model, INSTANCE_NAME, DIR_NAME, genericnames, splice, decfile)
    else
        writeMPS(model, INSTANCE_NAME, DIR_NAME, genericnames, splice, smpsfile)
    end

end

    return model
end

#generateMPS(:DCAP, [3,3,3,100], ssp=true) : this will generate 100 MPS files each with single scenario (DCAP_3_3_3_100_SSP1.mps, DCAP_3_3_3_100_SSP2.mps, ...)

#generateMPS(:DCAP, [3,3,3,100], evp=true) : this will generate 1 MPS file with the averaged scenario, i.e., expected value problem (EVP) (DCAP_3_3_3_100_EVP.mps)

#generateSMPS(:DCAP, [3,3,3,100], FIRST_STAGE_SOLUTION="first_stage_solution.txt") : this will generate 1 set of SMPS files where the first stage variables are fixed. (DCAP_3_3_3_100_EEV.cor, ...)
