# read SMPS files
function solveSMPSInstance(solve_type::Symbol,
                           INSTANCE::String,
                           DIR_NAME::String="$(dirname(@__FILE__))/../instance",
                           PARAMETER::String="$(dirname(@__FILE__))/solver_parameters/parameters.txt")

    readSmps("$DIR_NAME/$INSTANCE")
    status = optimize(solve_type = :Benders, param = PARAMETER) # solve_types = [:Extensive, :Dual, :Benders]

    return status
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
