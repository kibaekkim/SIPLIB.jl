THIS_FILE_PATH = dirname(@__FILE__)
include("$THIS_FILE_PATH/../src/Siplib.jl")
using Siplib

mkdir("$THIS_FILE_PATH/FULL_INSTANCE")
mkdir("$THIS_FILE_PATH/logs")
mkdir("$THIS_FILE_PATH/solutions")
for prob in problem
    if prob != :SSLP
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob")
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/RP") # Recourse problem instances (SMPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/LP2") # LP2-relax problem instances (SMPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/SS") # Single scenario instances (MPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/EV") # Expected value problem instances (MPS)
        # make directories for logs & solutions in advance
        mkdir("$THIS_FILE_PATH/logs/$prob/RP_CPLEX")
        mkdir("$THIS_FILE_PATH/solutions/$prob/RP_CPLEX")
        mkdir("$THIS_FILE_PATH/logs/$prob/RP_DD")
        mkdir("$THIS_FILE_PATH/solutions/$prob/RP_DD")
        mkdir("$THIS_FILE_PATH/logs/$prob/LP2")
        mkdir("$THIS_FILE_PATH/solutions/$prob/LP2")
        mkdir("$THIS_FILE_PATH/logs/$prob/SS")
        mkdir("$THIS_FILE_PATH/solutions/$prob/SS")
        mkdir("$THIS_FILE_PATH/logs/$prob/EV")
        mkdir("$THIS_FILE_PATH/solutions/$prob/EV")
        for param in param_set[prob]
            generateSMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/RP", genericnames=false)
            generateSMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/LP2", genericnames=false, lprelax=2)
            generateMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/SS", genericnames=false, ss=true)
            generateMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/EV", genericnames=false, ev=true)
        end
    else # for SSLP, we must round RHS when generating EV instances
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob")
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/RP") # Recourse problem instances (SMPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/LP2") # LP2-relax problem instances (SMPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/SS") # Single scenario instances (MPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/EV") # Expected value problem instances (MPS)
        # make directories for logs & solutions in advance
        mkdir("$THIS_FILE_PATH/logs/$prob/RP_CPLEX")
        mkdir("$THIS_FILE_PATH/solutions/$prob/RP_CPLEX")
        mkdir("$THIS_FILE_PATH/logs/$prob/RP_DD")
        mkdir("$THIS_FILE_PATH/solutions/$prob/RP_DD")
        mkdir("$THIS_FILE_PATH/logs/$prob/LP2")
        mkdir("$THIS_FILE_PATH/solutions/$prob/LP2")
        mkdir("$THIS_FILE_PATH/logs/$prob/SS")
        mkdir("$THIS_FILE_PATH/solutions/$prob/SS")
        mkdir("$THIS_FILE_PATH/logs/$prob/EV")
        mkdir("$THIS_FILE_PATH/solutions/$prob/EV")
        for param in param_set[prob]
            generateSMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/RP", genericnames=false)
            generateSMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/LP2", genericnames=false, lprelax=2)
            generateMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/SS", genericnames=false, ss=true)
            generateMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/EV", genericnames=false, ev=true, roundRHS=true)
        end
    end
end
