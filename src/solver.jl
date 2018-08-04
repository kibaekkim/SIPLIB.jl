#=
# read SMPS files
function solveSMPSInstance(solve_type::Symbol,
                           INSTANCE::String,
                           DIR_NAME::String="$(dirname(@__FILE__))/../instance",
                           PARAMETER::String="$(dirname(@__FILE__))/solver_parameters/parameters.txt")

    readSmps("$DIR_NAME/$INSTANCE")
    status = optimize(solve_type = :Benders, param = PARAMETER) # solve_types = [:Extensive, :Dual, :Benders]

    return status
end
=#

# calculate Wait-and-See solution (needs any MIP solver, e.g., using CPLEX)
function WS(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; output::Bool=false, splice::Bool=false)
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

#    println("Calculating the Wait-and-See solution ...")

    num_notoptimal = 0 # counts the number of single scenario model that is not solved to optimality
    sum = 0.0
    if !output
        TT = STDOUT # save original STDOUT stream
        redirect_stdout()
    end
    for s in 1:model.ext[:Stochastic].num_scen
#        tic()
#        println("Solving single scenario problem with scenario $s ...")
        ssm = getSingleScenarioModel(model, s, true, splice)
        setsolver(ssm, solver)
        status = solve(ssm)
        if status != :Optimal
            num_notoptimal += 1
        end
        sum += ssm.objVal
        ssm = Model()   # free memory?
#        toc()
    end
    if !output
        redirect_stdout(TT) # restore STDOUT
    end

    if num_notoptimal != 0
        warn("$num_notoptimal single scenario problem is not solved to optimality.")
    end

    return sum/model.ext[:Stochastic].num_scen
end


function EEV(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; output::Bool=false)
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

    # save the number of scenarios
    nS = model.ext[:Stochastic].num_scen

    # Step 1: get expected value problem and save the first-stage solution
    mdata_all = getStructModelData(model, false, false)
    m1 = mdata_all[1]
    m2 = mdata_all[2]
    avg_mat = m2.mat
    avg_rhs = m2.rhs
    avg_obj = m2.obj
    for s in 2:nS
        avg_mat += mdata_all[s+1].mat
        avg_rhs += mdata_all[s+1].rhs
        avg_obj += mdata_all[s+1].obj
    end
    avg_mat = avg_mat/nS
    avg_obj = avg_obj/nS
    avg_rhs = avg_rhs/nS
    mdata_all_2 = ModelData[]
    push!(mdata_all_2, m1)
    push!(mdata_all_2, ModelData(avg_mat,avg_rhs,m2.sense,avg_obj,m2.objsense,m2.clbd,m2.cubd,m2.ctype,m2.cname))
    evp, x = getExtensiveFormModel(mdata_all_2,return_x=true)
    setsolver(evp, solver)
    if !output
        TT = STDOUT # save original STDOUT stream
        redirect_stdout()
    end
    status = solve(evp)
    if !output
        redirect_stdout(TT) # restore STDOUT
    end
    ev_sol = getvalue(x)
    evp = Model()

    # Step 2: fix the first-stage variables and get EEV
    eev, x = getExtensiveFormModel(mdata_all,return_x=true)
    for j in 1:length(x)
        JuMP.fix(x[j],ev_sol[j])
    end

    setsolver(eev, solver)
    if !output
        TT = STDOUT # save original STDOUT stream
        redirect_stdout()
    end
    solve(eev)
    if !output
        redirect_stdout(TT) # restore STDOUT
    end
    EEV = eev.objVal
    eev = Model()
    return EEV
end

function RP(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; output::Bool=false, genericnames::Bool=true, splice::Bool=false)
    efrp = getExtensiveFormModel(model, genericnames, splice)
    setsolver(efrp, solver)

    if !output
        TT = STDOUT # save original STDOUT stream
        redirect_stdout()
    end

    status = solve(efrp)

    if !output
        redirect_stdout(TT) # restore STDOUT
    end

    RP = efrp.objVal
    efrp = Model()
    return RP
end

#=
# read JuMP.Model object
INSTANCE = "DCAP_5_5_5_2"
DIR_NAME = "$(dirname(@__FILE__))/../instance"
PARAMETER = "$(dirname(@__FILE__))/solver_parameters/parameters.txt"
model = getJuMPModelInstance(:DCAP, [5,5,5,2])
status = optimize(model, solve_type = :Extensive, param = PARAMETER)
optimize(solve_type = :Benders, param = PARAMETER)
=#
