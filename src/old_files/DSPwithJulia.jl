PROB_NAME = "DCAP"
PARAMETER = "_3_3_3_500"
INSTANCE_NAME = string(PROB_NAME,PARAMETER)

# Assumming we have mysmps.cor, mysmps.tim, and mysmps.sto
cd(dirname(Base.source_path()))
readSmps("../TestSets/$PROB_NAME/SMPS/$SMPS_FILE_NAME")

using Dsp
cd(dirname(Base.source_path()))
SMPS_PATH = "../experiment/SMPS/DCAP/DCAP_2_3_3_500"
parameter_file = "../experiment/DSP/parameters.txt"
readSmps(SMPS_PATH)
optimize(solve_type = :Dual, param = parameter_file)

solve_types = [:Extensive, :Dual, :Benders]
#alg = :Dual # one of [:Dual, :Benders, :Extensive]
#optimize(solve_type = solve_types[1], param = "myparam.txt")
#optimize(solve_type = solve_types[1])
optimize(solve_type = solve_types[1], param = "./DSP/default.txt")
println(getprimobjval())
println(getdualobjval())
