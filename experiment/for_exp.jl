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
using Siplib, DataFrames, CSV

##############################
## parameter setting: Start ##
##############################
param_set = Dict{Symbol, Array{Array{Any}}}()

# DCAP
param = [[2,3,3], [2,4,3], [3,3,2], [3,4,2]]
nS = [200, 300, 500, 10000]
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
nS = [100]
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
nS = [3,5,10,10000]
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
nS = [20, 100, 300, 500, 1000]
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
nS = [50, 100, 2000]
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
nS = [10, 50, 100]
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
    df = DataFrame(problem=Any[], instance=Any[], cont1=Any[], bin1=Any[], int1=Any[], cont2=Any[], bin2=Any[], int2=Any[], cont=Any[], bin=Any[], int=Any[], rows=Any[], cols=Any[],
                        sparsity_A=Any[], sparsity_W=Any[], sparsity_T=Any[], sparsity_total=Any[], size_cor=Any[], size_tim=Any[], size_sto=Any[])
    for params_arr in param_set[prob]
        m = generateSMPS(prob, params_arr, SMPS_PATH*"/$(String(prob))", splice=false, genericnames=false)
        sz = getSize(m)
        sp = getSparsity(m)
        tempv = Any[]
        push!(tempv, String(prob))
        push!(tempv, getInstanceName(prob, params_arr))
        push!(tempv, sz.nCont1)
        push!(tempv, sz.nBin1)
        push!(tempv, sz.nInt1)
        push!(tempv, sz.nCont2)
        push!(tempv, sz.nBin2)
        push!(tempv, sz.nInt2)
        push!(tempv, sz.nCont)
        push!(tempv, sz.nBin)
        push!(tempv, sz.nInt)
        push!(tempv, sz.nRow)
        push!(tempv, sz.nCol)
        push!(tempv, round(sp.sparsity_A*100, 3))
        push!(tempv, round(sp.sparsity_W*100, 3))
        push!(tempv, round(sp.sparsity_T*100, 3))
        push!(tempv, round(sp.sparsity*100, 3))
        push!(tempv, round(filesize(SMPS_PATH*"/$(String(prob))/$(getInstanceName(prob, params_arr)).cor")/1000 , 3))
        push!(tempv, round(filesize(SMPS_PATH*"/$(String(prob))/$(getInstanceName(prob, params_arr)).tim")/1000 , 3))
        push!(tempv, round(filesize(SMPS_PATH*"/$(String(prob))/$(getInstanceName(prob, params_arr)).sto")/1000 , 3))
        print(tempv)
        push!(df,tempv)
    end
    CSV.write("$(dirname(@__FILE__))/analysis/instance_information_$(String(prob)).csv" , df)
end


#################################
##  Generating instances: End  ##
#################################
