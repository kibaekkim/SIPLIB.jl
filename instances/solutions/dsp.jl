#=
This script reads SMPS files and solves the model using DSP.
Hence, this requires to install DSP and Dsp.jl.

Kibaek Kim
=#

# Dsp.jl is required.
# Of course, DSP solver is required too.
using Dsp

if length(ARGS) != 1
	error("Requires one argument.")
end

# command-line arguments
smps  = ARGS[1] # smps file instance name
ofile = basename(smps) # output file name
@show ofile

readSmps(smps)

# type of solution methods
solve_types = [:Dual, :Benders, :Extensive]

# solve the model defined in SMPS files 
# with the choice of algorithm 
# and parameter setting.
optimize(solve_type = solve_types[1], param = "param.txt")

@show getprimobjval() # Dsp.model.primVal
@show getdualobjval() # Dsp.model.dualVal
@show getsolutiontime()

# write simple soultion file in the form of
# (instance, primal objective, dual objective, solution time)
fp = open(ofile, "w")
@printf(fp, "%s,%e,%e,%e\n", smps, getprimobjval(), getdualobjval(), getsolutiontime())
close(fp)

