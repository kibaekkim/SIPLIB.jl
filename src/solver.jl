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
function WS(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; output::Bool=false)
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

    num_notoptimal = 0 # counts the number of single scenario model that is not solved to optimality
    sum = 0.0
    for s in 1:model.ext[:Stochastic].num_scen
        if !output
            TT = STDOUT # save original STDOUT stream
            redirect_stdout()
        end

        ssm = getSingleScenarioModel(model,s)
        setsolver(ssm, solver)
        status = solve(ssm)
        if status != :Optimal
            num_notoptimal += 1
        end
        sum += ssm.objVal
        ssm = Model()
        if !output
            redirect_stdout(TT) # restore STDOUT
        end
    end

    if num_notoptimal != 0
        warn("$num_notoptimal single scenario model is not solved to optimality.")
    end

    return sum/model.ext[:Stochastic].num_scen
end

function EV()

end

function EEV()

end

function RP()

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
