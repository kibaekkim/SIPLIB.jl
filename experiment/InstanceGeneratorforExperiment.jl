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
SMPS_PATH = "$THIS_FILE_PATH/../experiment/SMPS"
include("$THIS_FILE_PATH/../src/Siplib.jl")
using Siplib

##############################
## parameter setting: Start ##
##############################
param_set = Dict{Symbol, Array{Array{Any}}}()

# DCAP
param = [[2,3,3], [2,4,3], [3,3,2], [3,4,2]]
nS = [1000, 3000, 5000, 7000, 9000]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:DCAP] = param_array

# MPTSPs
param = [["D0",50], ["D1",50], ["D2",50], ["D3",50], ["D0",100], ["D1",100], ["D2",100], ["D3",100]]
nS = [100, 300, 500, 700, 900]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:MPTSPs] = param_array

# SIZES
param = [[]]
nS = [1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:SIZES] = param_array

# SMKP
param = [[120]]
nS = [500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:SMKP] = param_array

# SSLP
param = [[5,25], [5,50], [10,50], [15,45]]
nS = [1000, 2000, 3000, 4000, 5000]
param_array = Any[]
for p in param
    for n in nS
        push!(param_array, copy(p))
        push!(param_array[end], n)
    end
end
param_set[:SSLP] = param_array

# SSLP
param = ["FallWD", "FallWE", "SpringWD", "SpringWE", "SummerWD", "SummerWE", "WinterWD", "WinterWE"]
nS = [10, 20, 30, 40, 50]
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

for prob in problem
    for param in param_set[prob]
        generateSMPS_with_name_splice(prob, param, SMPS_PATH*"/$(String(prob))")
    end
end

#generateSMPS(:DCAP, [2,2,2,2], SMPS_PATH*"/$(String(:DCAP))")

#################################
##  Generating instances: End  ##
#################################
