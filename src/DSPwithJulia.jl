using Dsp
using MPI

PROB_NAME = "DCAP"
PARAMETER = "_3_3_3_500"
INSTANCE_NAME = string(PROB_NAME,PARAMETER)

# Assumming we have mysmps.cor, mysmps.tim, and mysmps.sto
cd(dirname(Base.source_path()))
readSmps("../TestSets/$PROB_NAME/SMPS/$SMPS_FILE_NAME")

solve_types = [:Extensive, :Dual, :Benders]
#alg = :Dual # one of [:Dual, :Benders, :Extensive]
#optimize(solve_type = solve_types[1], param = "myparam.txt")
#optimize(solve_type = solve_types[1])
optimize(solve_type = solve_types[1], param = "./DSP/default.txt")
println(getprimobjval())
println(getdualobjval())
