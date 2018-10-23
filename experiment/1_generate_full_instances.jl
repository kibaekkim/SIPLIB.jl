THIS_FILE_PATH = dirname(@__FILE__)
include("$THIS_FILE_PATH/../src/Siplib.jl")
using Siplib

mkdir("$THIS_FILE_PATH/FULL_INSTANCE")
for prob in problem
    if prob != :SSLP
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob")
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/RP") # Recourse problem instances (SMPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/LP2") # LP2-relax problem instances (SMPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/SS") # Single scenario instances (MPS)
        mkdir("$THIS_FILE_PATH/FULL_INSTANCE/$prob/EV") # Expected value problem instances (MPS)
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
        for param in param_set[prob]
            generateSMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/RP", genericnames=false)
            generateSMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/LP2", genericnames=false, lprelax=2)
            generateMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/SS", genericnames=false, ss=true)
            generateMPS(prob, param, "$THIS_FILE_PATH/FULL_INSTANCE/$prob/EV", genericnames=false, ev=true, roundRHS=true)
        end
    end
end

# make directories for logs & solutions in advance
mkdir("$THIS_FILE_PATH/logs")
mkdir("$THIS_FILE_PATH/solutions")
for prob in problem
    mkdir("$THIS_FILE_PATH/logs/$prob")
    mkdir("$THIS_FILE_PATH/solutions/$prob")
    mkdir("$THIS_FILE_PATH/logs/$prob/RP_DSP_de")
    mkdir("$THIS_FILE_PATH/solutions/$prob/RP_DSP_de")
    mkdir("$THIS_FILE_PATH/logs/$prob/RP_DSP_dd")
    mkdir("$THIS_FILE_PATH/solutions/$prob/RP_DSP_dd")
    mkdir("$THIS_FILE_PATH/logs/$prob/LP2_DSP_de")
    mkdir("$THIS_FILE_PATH/solutions/$prob/LP2_DSP_de")
    mkdir("$THIS_FILE_PATH/logs/$prob/SS_CPLEX")
    mkdir("$THIS_FILE_PATH/solutions/$prob/SS_CPLEX")
    mkdir("$THIS_FILE_PATH/logs/$prob/EV_CPLEX")
    mkdir("$THIS_FILE_PATH/solutions/$prob/EV_CPLEX")
end
