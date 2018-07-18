#################################
## Generating instances: Start ##
#################################

## Instance name (S is always the number of scenarios)
### DCAP_R_N_T_S: param_set = (R::Int, N::Int, T::Int)
### MPTSPs_D_N_S: param_set = (D::Int, N::Int)
### SIZES_S: param_set = ()
### SMKP_I_S: param_set = (I::Int)
### SSLP_I_J_S: param_set = (I::Int, J::Int)
### SUCW_D_S: param_set = (D::String)  # D ∈ ("FallWD", "FallWE", "SpringWD", "SpringWE", "SummerWD", "SummerWE", "WinterWD", "WinterWE")

# include generator file
THIS_FILE_PATH = dirname(@__FILE__)
include("$THIS_FILE_PATH/../src/Siplib.jl")
using Siplib

##############################
## parameter setting: Start ##
##############################
param_set = Dict{Symbol, Array{Array{Any}}}()

# DCAP
param = [[2,3,3], [2,4,3], [3,3,2], [3,4,2]]
nS = [200,300,500]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:DCAP] = param_array

# MPTSPs
param = [["D0",50], ["D1",50], ["D2",50], ["D3",50]]
nS = [100]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:MPTSPs] = param_array

# SMKP
param = [[120]]
nS = [20, 40, 60, 80, 100]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:SMKP] = param_array

# SIZES
param = [[]]
nS = [3, 5, 10, 100]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:SIZES] = param_array


# SSLP
param = [[5,25], [5,50], [10,50], [15,45]]
nS = [50, 100]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:SSLP] = param_array

# SUC
param = ["FallWD", "FallWE", "SpringWD", "SpringWE", "SummerWD", "SummerWE", "WinterWD", "WinterWE"]
nS = [10]
param_array = Any[]
for p in param
    for n in nS
        temp_array = Any[]
        push!(temp_array, p)
        push!(temp_array, n)
        push!(param_array, temp_array)
    end
end
param_set[:SUC] = param_array

############################
## parameter setting: End ##
############################


###################################
##  Generating instances: Start  ##
###################################

SMPS_PATH = "$THIS_FILE_PATH/../experiment/SMPS"
#for prob in [:DCAP, :MPTSPs, :SMKP, :SIZES, :SSLP, :SUC]
for prob in [:DCAP]
    for param in param_set[prob]
        generateSMPS(prob, param, SMPS_PATH*"/$(String(prob))", genericnames=false)
        generateSMPS(prob, param, SMPS_PATH*"/$(String(prob))", genericnames=false, lprelax=2)
    end
end

#generateSMPS(:DCAP, [2,2,2,2], SMPS_PATH*"/$(String(:DCAP))")

#################################
##  Generating instances: End  ##
#################################
