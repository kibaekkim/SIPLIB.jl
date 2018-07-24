module Siplib
    # dependent packages
    using StructJuMP
    using Distributions
    using PyPlot

    # include Siplib utility sources
    include("./writer.jl")
    include("./utility.jl")
    include("./generator.jl")
    include("./analyzer.jl")
#    include("./solver.jl")

    global problem = Symbol[]
    global numParams = Dict{Symbol,Int}()
    global noteParams = Dict{Symbol,String}()

    setGlobalVariables()
    includeModelingScripts()

    export getInstanceName,                 # return Instance name using problem & parameters
           getModel,                        # only returns JuMP.Model object
           generateSMPS,                    # generate SMPS files & return JuMP.Model object (to use returned object, set splice=false)
           generateMPS,                     # generate MPS file with optional .dec file (set decfile=true) & return JuMP.Model object (to use returned object, set splice=false)
           writeSMPS,                       # convert JuMP.Model object to SMPS files
           writeMPS,                        # convert JuMP.Model object to MPS files (if decfile=true, generate .dec file together)
           plotConstrMatrix,                # plot constraint matrix of the extensive form
           plotFirstStageBlock,             # plot block A (first stage only)
           plotSecondStageBlock,            # plot block W (second stage only)
           plotTechnologyBlock,             # plot block T (complicating block)
           plotAllBlocks,                   # plot block A, W, T simultaneously
           plotAll,
           generateSparsityPlots,           # save all sparsity plots into "plot" folder (default)
           getSparsity,
           getSize,
           lprelaxModel,
           problem,
           numParams,
           noteParams

end # end module Siplib
#=
using Siplib

m = generateSMPS(:SSLP, [5,5,3], smpsfile=true, genericnames=false, splice=false)
generateSMPS(:DCAP, [5,5,5,3], smpsfile=true, genericnames=false)
generateSMPS(:SSLP, [5,5,3], smpsfile=true, genericnames=false)
generateSMPS(:SSLP, [5,5,3], smpsfile=true, genericnames=false)
generateSMPS(:SSLP, [5,5,3], smpsfile=true, genericnames=false)
generateSMPS(:SSLP, [5,5,3], smpsfile=true, genericnames=false)

m = getModel(:DCAP, [3,3,3,10])
m = getModel(:MPTSPs, ["D0",5,10])
m = getModel(:SIZES, 10)
m = getModel(:SMKP, [10,10])
m = getModel(:SSLP, [3,3,3])
m = getModel(:SUC, ["WinterWD", 1])


DATA_PATH = "$(dirname(@__FILE__))/problem_info.csv"
file_array = readdlm(DATA_PATH, ',')
arr= file_array[2:end,1]

x = Symbol(arr[1])
size(file_array)

function setGlobalVariables(PROBLEM_INFO_PATH::String)

    file_array = readdlm(PROBLEM_INFO_PATH, ',')

    problem = Symbol[]
    numParams = Dict{Symbol,Int}()
    noteParams = Dict{Symbol,String}()

    for i in 2:size(file_array)[1]
        push!(problem, Symbol(file_array[i,1]))
        numParams[problem[end]] = file_array[i,2]
        noteParams[problem[end]] = file_array[i,3]
    end

    return (problem, numParams, noteParams)
end

DATA_PATH = "$(dirname(@__FILE__))/problem_info.csv"
global a,b,c = setGlobalVariables(DATA_PATH)

function setGlobalVariables(PROBLEM_INFO_PATH::String)

    file_array = readdlm(PROBLEM_INFO_PATH, ',')

    problem = Symbol[]
    nParams = Int[]
    noteParams = String[]


    for i in 2:size(file_array)[1]
        push!(problem, Symbol(file_array[i,1]))
        push!(nParams, file_array[i,2])
        push!(noteParams, file_array[i,3])
    end

    return problem, nParams, noteParams

end

global a,b,c = setGlobalVariables(DATA_PATH)




m = getModel(:MPTSPs, ["D0",10,10])


getSparsity(:SSLP, [3,3,10])
generateSparsityPlots(:SSLP, [3,3,10])

problem = :SIZES
params_arr = [1]
INSTANCE_NAME = getInstanceName(problem, params_arr)
model = getModel(problem, params_arr)
plotFirstStageBlock(model)
plotSecondStageBlock(model)
plotTechnologyBlock(model)
plotConstrMatrix(model, INSTANCE_NAME)
plotAll(model, INSTANCE_NAME)

problem = :MPTSPs
params_arr = ["D0",4,1]
INSTANCE_NAME = getInstanceName(problem, params_arr)
model = getModel(problem, params_arr)
plotConstrMatrix(model, INSTANCE_NAME)

plotAll(model, INSTANCE_NAME)

plotFirstStageBlock(model)
plotSecondStageBlock(model)
plotTechnologyBlock(model)
plotConstrMatrix(model)


m = generateSMPS(:MPTSPs, ["D0",5,1], seed=1, lprelax=0, genericnames=false, splice=false)

print(m)

writeSMPS
m = getModel(:MPTSPs, ["D0",10,10], lprelax=0)
m = getModel(:SIZES, [10], lprelax=0)
m = getModel(:SMKP, [10,10], lprelax=3)
m = getModel(:SSLP, [3,3,3], lprelax=3)
m = getModel(:SUC, ["FallWD",1], lprelax=3)

m = getModel(:MPTSPs, ["D0",10,10])
typeof(m[:phi])
fieldnames(m[:phi])
m[:phi].tupledict


JuMP.setcategory()

for i in m[:phi].tupledict
    println(i[2])
end

m = getModel(:DCAP, [3,3,3,3])
typeof(m[:x])
fieldnames(m[:x])
in(:innerArray , fieldnames(m[:x]))

JuMP.getcategory(m[:x].innerArray[1,1])

m[:phi].:meta

for vdata in m.varData
    varsymbol = vdata[2].name
    for var in m[varsymbol].innerArray
        if var != :Cont
            JuMP.setcategory(var, :Cont)
        end
    end
end


print(m)
StructJuMP.num_scenarios(m)

m1 = StructJuMP.getchildren(m)[1]
m1.varData
m1[:y].innerArray
for v in m1[:y].innerArray
    JuMP.setcategory(v, :Cont)
end

for s = 1:StructJuMP.num_scenarios(m)
    for vdata in StructJuMP.getchildren(m)[s].varData
        varsymbol = vdata[2].name
        for var in vdata[varsymbol].innerArray
            if var != :Cont
                JuMP.setcategory(var, :Cont)
            end
        end
    end
end



m2 = StructJuMP.getchildren(m)[2]
m2.varData
m2[:y].innerArray
for v in m2[:y].innerArray
    JuMP.setcategory(v, :Cont)
end




for vdata in m.varData
    varname = vdata[2].name
    #varname = m.varData[m[v]]
    for var in m[varname].innerArray
        if var != :Cont
            JuMP.setcategory(var,:Cont)
        end
    end
end

for vdata in m.varData
    varname = vdata[2].name
    #varname = m.varData[m[v]]
    for var in m[varname].innerArray
        println(JuMP.getcategory(var))
    end
end

=#




#=
m = getModel(:DCAP, [3,3,3,3])
typeof(m[:x])
fieldnames(m[:x])
m[:x]
fieldnames(m)
m.varData(m[:x])
typeof(m[:x])
typeof(m.varData)
m[:u]

m[:x]
m[:u]

m = getModel(:DCAP, [3,3,3,3])
for vdata in m.varData
    vdata.:ht[4].name # symbol
    println(vdata[1])
end
keys(m.varData)
m.varData

m.varData
m[:x].innerArray
for vdata in m.varData
    vdata.:ht[4].name
end
m.varData.ht[3]

for j in 1:length(m.varData)
    for v in m[]
end

m.





m.varData.:ndel
m.varData.:ht

fieldnames(m.varData)
m.varData.:ht[4].name
m.varData
JuMP.setcategory(m[:u].innerArray[1,2], :Cont)
JuMP.getcategory(m[:u].innerArray[1,3])

for v in m[:u].innerArray
    if v != :Cont
        JuMP.setcategory(v,:Cont)
    end
end


m[:x].innerArray
JuMP.setcategory(m[:x], :Cont)
m.varData
m.colCat
m.varCones
JuMP.getvariable(m,1)
JuMP.setcategory(:x, :Cont)
MathProgBase.getvartype(m)


m.ext
m1 = m.ext[:Stochastic].children[1]
print(fieldnames(m1))
m1.varData
m1.colCat
JuMP.JuMPContainerData(m1.varData)

for s in m1.colCat
    s = deepcopy(:Cont)
end

print(m1)
length(m1.colCat)
JuMP.getname(m1,1)
JuMP.getcategory(m1.)
JuMP.getVar()
JuMP.setcategory(JuMP.getname(m1,1),:Cont)

problem = :DCAP
f = Base.getfield(Siplib, problem)



param_arr = [3,2,2,5]
problem = :DCAP
INSTANCE = getInstanceName(problem,param_arr)
model = getModel(problem, param_arr)
tic()
writeSMPS(model, genericnames=true, splice=false)
toc()
JuMP.getvariable(m1)
JuMP.getName(model, 1)


model.colNames
typeof(model.varData)
print(model)
print(model.ext[:Stochastic].children[2])
c1 = model.ext[:Stochastic].children[1]
Siplib.getModelData(model)
Siplib.getStructModelData(model)
JuMP.getObjective(model)
JuMP.getObjective(model)
print(model.varData)
model.colNames
model.ext[:Stochastic].children[2].colNames
m2 = model.ext[:Stochastic].children[1]
m2.colNames
JuMP.getObjective(m2)

plotAll(model, INSTANCE)


param_arr = [5,5,5,2]
model = getJuMPModelInstance(:DCAP, param_arr)
model = generateSMPSInstance(:DCAP, param_arr)
model = generateSMPSInstance(:DCAP, param_arr, "/homes/choy/GitLab/Argonne/SIPLIB/instance")
writeSmps(model, "dcap2", "/homes/choy/GitLab/Argonne/SIPLIB/instance")
writeSmps(model)
plotConstrMatrix(model)
plotFirstStageBlock(model)
plotSecondStageBlock(model)
plotComplicatingBlock(model)
plotAllBlocks(model, "allblock")
getInstanceSparsity(model)
getInstanceSize(model)
solveSMPSInstance()


param_arr = ["D0",50,5]
getJuMPModelInstance(:MPTSPs, param_arr)
model = generateSMPSInstance(:MPTSPs, param_arr)
model = generateSMPSInstance(:MPTSPs, param_arr, "/homes/choy/GitLab/Argonne/SIPLIB/instance")

param_arr = [50]
getJuMPModelInstance(:SIZES, param_arr)

param_arr=[30,30]
model = getJuMPModelInstance(:SMKP, param_arr)
getInstanceSparsity(model)

param_arr = [3,3,3]
getJuMPModelInstance(:SSLP, param_arr)

param_arr = ["WinterWD", 1]
model = getJuMPModelInstance(:SUC, param_arr)
model = generateSMPSInstance(:SUC, param_arr)
model = generateSMPSInstance(:SUC, param_arr, "/homes/choy/GitLab/Argonne/SIPLIB/instance")
getInstanceSparsity(model)

=#
