#=
This reads SMPS files and writes the model to MPS file.
This requires DSP and Dsp.jl.

Kibaek Kim
=#

using Dsp

if length(ARGS) = 2
	error("Require two arguments.")
end

# command-line arguments
smps = ARGS[1] # smps file name to read
mps  = ARGS[2] # mps file name to write

println("Reading SMPS files ... ")
@time readSmps(smps)

println("Writing MPS file ... ")
@time writeMps(mps)

println("DONE")

