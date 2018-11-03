module Siplib
    # dependent packages
    using SparseArrays
    using Printf
    using Random
    using MathProgBase
    using StructJuMP
    using Distributions
    using Combinatorics
    using DelimitedFiles
#    using PyPlot

    # include Siplib utility sources
    include("./writer.jl")
    include("./utility.jl")
    include("./generator.jl")
    include("./analyzer.jl")
    include("./solver.jl")

    global problem = Symbol[]
    global param_set = Dict{Symbol, Array{Array{Any}}}()
    global numParams = Dict{Symbol,Int}()
    global noteParams = Dict{Symbol,String}()

    setGlobalVariables()
    includeModelingScripts()
    setParamSet()

    export getInstanceName,                 # returns Instance name using problem & parameters
           getModel,                        # only returns JuMP.Model object
           getExtensiveFormModel,           # returns an extensive form JuMP.Model
           getSingleScenarioModel,          # returns a single scenario extensive form JuMP.Model object from a StructJuMP object
           generateSMPS,                    # generate SMPS files & return JuMP.Model object (to use returned object, set splice=false)
           generateMPS,                     # generate MPS file with optional .dec file (set decfile=true) & return JuMP.Model object (to use returned object, set splice=false)
           writeSMPS,                       # convert JuMP.Model object to SMPS files
           writeMPS,                        # convert JuMP.Model object to MPS files (if decfile=true, generate .dec file together)
#           plotConstrMatrix,                # plot constraint matrix of the extensive form
#           plotFirstStageBlock,             # plot block A (first stage only)
#           plotSecondStageBlock,            # plot block W (second stage only)
#           plotTechnologyBlock,             # plot block T (complicating block)
#           plotAllBlocks,                   # plot block A, W, T simultaneously
#           plotAll,
           generateSparsityPlots,           # save all sparsity plots into "plot" folder (default)
           getSparsity,
           getSize,
           lprelaxModel!,
           problem,
           numParams,
           noteParams,
           param_set,
           arrayParams,
           WS,                              # Solve to obtain the wait-and-see solution
           EEV,                             # Solve to obtain the EEV solution
           EF,                              # Solve the extensive form recourse problem
           EV,                              # Solve the expected value problem
           LP,                               # Solve the LP-relaxed problem (default relax level: 3 (full LP-relaxation))
           generateBasicInstances

end # end module Siplib

#=
using Main.Siplib
using CPLEX

generateSMPS(:CHEM,[1000])
generateSMPS(:DCAP,[3,3,3,10])
generateSMPS(:DCAP,[3,3,3,10],lprelax=2,genericnames=false)
generateMPS(:DCAP,[3,3,3,10],ev=true,genericnames=false)
generateMPS(:DCAP,[3,3,3,10],ss=true,genericnames=false)

model = getModel(:DCAP,[3,3,3,10])
EF(model, CplexSolver())
EV(model, CplexSolver())
LP(model,CplexSolver(),level=2)

model = getModel(:AIRLIFT,[200])
model = getModel(:CARGO, [3])
model = getModel(:CHEM, [3])
model = getModel(:DCAP,[3,3,3,10])
model = getModel(:MPTSPs,["D0",50,100],seed=1)
model = getModel(:PHONE, [100])
model = getModel(:SDCP,[5,10,"FallWD",1])
model = getModel(:SIZES,[3])
model = getModel(:SMKP,[10,2])
model = getModel(:SSLP,[4,4,5])
model = getModel(:SUC,["FallWD",1])

LP(model, CplexSolver(),level=2)
EV(model,CplexSolver())
WS(model, CplexSolver(), ss_timelimit=60.0)
RP(model, CplexSolver(), output=true, timelimit=120.0)
EEV(model, CplexSolver(), ev_timelimit=60.0)

generateSMPS(:AIRLIFT, [10], smpsfile=true)
generateSMPS(:CARGO, [3], smpsfile=true)
generateSMPS(:CHEM, [10], smpsfile=true)
generateSMPS(:DCAP, [3,3,3,5], smpsfile=true)
generateSMPS(:MPTSPs, ["D0",10,100], smpsfile=true)
generateSMPS(:PHONE, [10], smpsfile=true)
generateSMPS(:SDCP, [5,10,"FallWD",1], smpsfile=true)
generateSMPS(:SIZES, [10], smpsfile=true)
generateSMPS(:SMKP, [10,10], smpsfile=true)
generateSMPS(:SSLP, [4,4,5], smpsfile=true)
generateSMPS(:SUC, ["FallWD",1], smpsfile=true)

# save the number of scenarios
nS = model.ext[:Stochastic].num_scen

# Step 1: get expected value problem and save the first-stage solution
mdata_all = Siplib.getStructModelData(model, false, false)
m1 = mdata_all[1]
m2 = mdata_all[2]
avg_mat = m2.mat
avg_rhs = m2.rhs
avg_obj = m2.obj
avg_clbd = m2.clbd
avg_cubd = m2.cubd
for s in 2:nS
    avg_mat += mdata_all[s+1].mat
    avg_rhs += mdata_all[s+1].rhs
    avg_obj += mdata_all[s+1].obj
    avg_clbd += mdata_all[s+1].clbd
    avg_cubd += mdata_all[s+1].cubd
end
avg_mat = avg_mat/nS
avg_obj = avg_obj/nS
avg_rhs = avg_rhs/nS
avg_clbd = avg_clbd/nS
avg_cubd = avg_cubd/nS

mdata_all_evp = Siplib.ModelData[]
push!(mdata_all_evp, m1)
push!(mdata_all_evp, Siplib.ModelData(avg_mat,avg_rhs,m2.sense,avg_obj,m2.objsense,avg_clbd,avg_cubd,m2.ctype,m2.cname))
evp, x = getExtensiveFormModel(mdata_all_evp, return_x=true)

print(evp)

Siplib.setsolver(evp, CplexSolver())
Siplib.solve(evp)










model = getModel(:SDCP,[5,10,"FallWD",3])
RP(model, CplexSolver())

print(model)
generateSMPS(:CARGO,[100])


using Siplib
using CPLEX

generateSMPS(:MPTSPs,["D0",10,10],genericnames=false,smpsfile=true)

model = getModel(:MPTSPs,["D0",10,10])


EEV(model, CplexSolver())
print(model.)


generateSMPS(:PHONE,[5],genericnames=false)
generateSMPS(:PHONE,[1000],genericnames=false)

model = getModel(:PHONE, [100])
model.varData
print(model.)
EEV(model, CplexSolver(), output=true)


model = getModel(:SMKP,[120,10])
model = getModel(:DCAP,[3,4,5,10])
model = getModel(:SSLP,[5,5,10])
WS(model, CplexSolver(), ss_timelimit=10.0)
RP(model, CplexSolver(), timelimit=20.0, output=true)
EEV(model, CplexSolver(), genericnames=false, output=true)
generateSMPS(:SSLP,[5,5,10],genericnames=false)
model = getExtensiveFormModel(model,genericnames=false)
Siplib.writeMPS(model)

function getAveragedScenarioModel(model::JuMP.Model, genericnames::Bool=true)::JuMP.Model
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end
    # extract model data
    mdata_all = Siplib.getStructModelData(model, genericnames, false)
    m1 = mdata_all[1]

    # average up 2nd-stage data
    avg_mat =
    avg_obj
    avg_rhs
    for

end
model = getModel(:DCAP,[3,4,5,10])





WS(model, CplexSolver())
using JuMP
model = getModel(:DCAP,[3,4,5,10])
WS(model, CplexSolver())

efm = getExtensiveFormModel(model)
setsolver(efm, CplexSolver())
status = solve(efm)
efm.objVal

generateSMPS(:DCAP,[3,4,5,10])

# extract model data
mdata_all = Siplib.getStructModelData(model, false, false)
nS = length(mdata_all)-1
## copy first-stage
m1 = mdata_all[1]

# get the number of first-stage rows and columns
nrows1, ncols1 = size(m1.mat)
# get the number of rows and columns for the scenario block
nrows2, ncols = size(mdata_all[2].mat)
ncols2 = ncols - ncols1

# declare an Extensive Form model
efm = JuMP.Model()

# declare variables
x = []
y = []

if isempty(m1.cname)
    for j in 1:ncols1
        push!(x, @variable(efm, category = Siplib.category(m1.ctype[j]), lowerbound = m1.clbd[j], upperbound = m1.cubd[j]))
    end
else
    for j in 1:ncols1
        push!(x, @variable(efm, category = Siplib.category(m1.ctype[j]), lowerbound = m1.clbd[j], upperbound = m1.cubd[j], basename = m1.cname[j]))
    end
end

for s in 1:nS
    m2 = mdata_all[s+1]
    tempv = []
    if isempty(mdata_all[s+1].cname)
        for j in 1:ncols2
            push!(tempv, @variable(efm, category = Siplib.category(m2.ctype[j]), lowerbound = m2.clbd[j], upperbound = m2.cubd[j]))
        end
    else
        for j in 1:ncols2
            push!(tempv, @variable(efm, category = Siplib.category(m2.ctype[j]), lowerbound = m2.clbd[j], upperbound = m2.cubd[j], basename = "$(m2.cname[j])_$s"))
        end
    end
    push!(y,tempv)
end

# declare objective
aff = AffExpr(x,m1.obj,0)
for s in 1:nS
    m2 = mdata_all[s+1]
    append!(aff, (1/nS)*AffExpr(y[s], m2.obj, 0))
end
@objective(efm, m1.objsense, aff)

# declare constraints
## first-stage
for i in 1:nrows1
    if m1.sense[i] == :L
        @constraint(efm, AffExpr(x,m1.mat[i,:],0) <= m1.rhs[i])
    elseif m1.sense[i] == :G
        @constraint(efm, AffExpr(x,m1.mat[i,:],0) >= m1.rhs[i])
    else
        @constraint(efm, AffExpr(x,m1.mat[i,:],0) == m1.rhs[i])
    end
end

for s in 1:nS
    m2 = mdata_all[s+1]
    for i in 1:nrows2
        aff = AffExpr(x,m2.mat[i,1:ncols1],0)
        append!(aff, AffExpr(y[s],m2.mat[i,ncols1+1:end],0))
        if m2.sense[i] == :L
            @constraint(efm, aff <= m2.rhs[i])
        elseif m2.sense[i] == :G
            @constraint(efm, aff >= m2.rhs[i])
        else
            @constraint(efm, aff == m2.rhs[i])
        end
    end
end

setsolver(efm, CplexSolver())
status = solve(efm)
efm.objVal


# second-stage variable container
y = []

if genericnames == false
    # variables
    ## first-stage
    for j in 1:ncols1
        push!(x, @variable(ssm, category = category(m1.ctype[j]), lowerbound = m1.clbd[j], upperbound = m1.cubd[j], basename = m1.cname[j]))
    end
    ## second-stage
    for j in 1:ncols2
        push!(y, @variable(ssm, category = category(m2.ctype[j]), lowerbound = m2.clbd[j], upperbound = m2.cubd[j], basename = m2.cname[j]))
    end

    # objective
    @objective(ssm, m1.objsense, dot(x, m1.obj) + dot(y, m2.obj))

    # constraints
    ## first-stage
    for i in 1:nrows1
        if m1.sense[i] == :L
            @constraint(ssm, AffExpr(x,m1.mat[i,:],0) <= m1.rhs[i])
        elseif m1.sense[i] == :G
            @constraint(ssm, AffExpr(x,m1.mat[i,:],0) >= m1.rhs[i])
        else
            @constraint(ssm, AffExpr(x,m1.mat[i,:],0) == m1.rhs[i])
        end
    end
    ## second-stage
    for i in 1:nrows2
        aff = AffExpr(x,m2.mat[i,1:ncols1],0)
        aff2 = AffExpr(y,m2.mat[i,ncols1+1:end],0)
        append!(aff,aff2)
        if m2.sense[i] == :L
            @constraint(ssm, aff <= m2.rhs[i])
        elseif m2.sense[i] == :G
            @constraint(ssm, aff >= m2.rhs[i])
        else
            @constraint(ssm, aff == m2.rhs[i])
        end
    end
elseif genericnames == true
    # variables
    ## first-stage
    for j in 1:ncols1
        push!(x, @variable(ssm, category = category(m1.ctype[j]), lowerbound = m1.clbd[j], upperbound = m1.cubd[j]))
    end
    ## second-stage
    for j in 1:ncols2
        push!(y, @variable(ssm, category = category(m2.ctype[j]), lowerbound = m2.clbd[j], upperbound = m2.cubd[j]))
    end

    # objective
    @objective(ssm, m1.objsense, dot(x, m1.obj) + dot(y, m2.obj))

    # constraints
    ## first-stage
    for i in 1:nrows1
        if m1.sense[i] == :L
            @constraint(ssm, AffExpr(x,m1.mat[i,:],0) <= m1.rhs[i])
        elseif m1.sense[i] == :G
            @constraint(ssm, AffExpr(x,m1.mat[i,:],0) >= m1.rhs[i])
        else
            @constraint(ssm, AffExpr(x,m1.mat[i,:],0) == m1.rhs[i])
        end
    end
    ## second-stage
    for i in 1:nrows2
        aff = AffExpr(x,m2.mat[i,1:ncols1],0)
        aff2 = AffExpr(y,m2.mat[i,ncols1+1:end],0)
        append!(aff,aff2)
        if m2.sense[i] == :L
            @constraint(ssm, aff <= m2.rhs[i])
        elseif m2.sense[i] == :G
            @constraint(ssm, aff >= m2.rhs[i])
        else
            @constraint(ssm, aff == m2.rhs[i])
        end
    end
end








model = getModel(:DCAP,[3,4,5,10])

# extract model data
mdata_all = Siplib.getStructModelData(model, false, false)
m1 = mdata_all[1]

# average up 2nd-stage data
avg_mat = SparseMatrixCSC{Float64,Int64}
avg_obj = Any[]
avg_rhs = Any[]
for s in model.ext[:Stochastic].num_scen

end



m = getModel(:DCAP, [3,4,5,10])
ssm = getSingleScenarioModel(m,1)
JuMP.setsolver(ssm, CplexSolver())
status = solve(ssm)
ssm.objVal

m.ext[:Stochastic]

m = getModel(:DCAP, [3,4,5,10])
m = getModel(:SDCP, [5,10,"FallWD",3])
m1 = getSingleScenarioModel(m, 1, false)
print(m1)
WS(m, CplexSolver())


generateMPS(:AIRLIFT, [10], ss=true, genericnames=false)
generateMPS(:SDCP, [5,10,"FallWD",10], ssp=true, genericnames=false)


m = getModel(:DCAP, [3,4,5,10])
in(:Stochastic, m.ext.keys)
m1 = m.ext[:Stochastic].children[1]
mdata_all = Siplib.getStructModelData(m, false)

empty!(m.ext)
print(m)
m_par = m.ext[:Stochastic].children[1].ext[:Stochastic].parent
m.colNames
JuMP.setsolver(m,CplexSolver())
status = JuMP.solve(m)
JuMP.getObjectiveValue(m)
JuMP.getValue()

############
function category(c::Char)
    if c == 'C'
        return :Cont
    elseif c == 'B'
        return :Bin
    else
        return :Int
    end
end

m = getModel(:DCAP, [3,4,5,10])
m.ext[:Stochastic].children[1]
mdata_all = Siplib.getStructModelData(m, false)
m1 = mdata_all[1]
m2 = mdata_all[2]
# get # of first-stage rows and columns
nrows1, ncols1 = size(m1.mat)

# get # of rows and columns for the scenario block
nrows2, ncols = size(m2.mat)
ncols2 = ncols - ncols1

ef = Model(quiet=true)
x = []
y = []

for j in 1:ncols1
    push!(x, @variable(ef, category = category(m1.ctype[j]), lowerbound = m1.clbd[j], upperbound = m1.cubd[j], basename = m1.cname[j]))
end

for j in 1:ncols2
    push!(y, @variable(ef, category = category(m2.ctype[j]), lowerbound = m2.clbd[j], upperbound = m2.cubd[j], basename = m2.cname[j]))
end

@objective(ef, m1.objsense, dot(x, m1.obj) + dot(y, m2.obj))

for i in 1:nrows1
    if m1.sense[i] == :L
        @constraint(ef, dot(m1.mat[i,:],x) <= m1.rhs[i])
    elseif m1.sense[i] == :G
        @constraint(ef, dot(m1.mat[i,:],x) >= m1.rhs[i])
    else
        @constraint(ef, dot(m1.mat[i,:],x) == m1.rhs[i])
    end
end

for i in 1:nrows2
    if m2.sense[i] == :L
        @constraint(ef, dot(m2.mat[i,1:ncols1],x) + dot(m2.mat[i,ncols1+1:end],y) <= m2.rhs[i])
    elseif m2.sense[i] == :G
        @constraint(ef, dot(m2.mat[i,1:ncols1],x) + dot(m2.mat[i,ncols1+1:end],y) >= m2.rhs[i])
    else
        @constraint(ef, dot(m2.mat[i,1:ncols1],x) + dot(m2.mat[i,ncols1+1:end],y) == m2.rhs[i])
    end
end

setsolver(ef,CplexSolver())
status = solve(ef)
ef.objVal

function getSingleScenarioEFModel(model::JuMP.Model, s::Int)::JuMP.Model
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

    m1 = Siplib.getModelData(model, false)
    m2 = Siplib.getModelData(model.ext[:Stochastic].children[s], false)

    # get # of first-stage rows and columns
    nrows1, ncols1 = size(m1.mat)
    # get # of rows and columns for the scenario block
    nrows2, ncols = size(m2.mat)
    ncols2 = ncols - ncols1

    # declare a single scenario Extensive Form model
    ssef = Model()

    # first-stage variable container
    x = []
    # second-stage variable container
    y = []

    # variables
    ## first-stage
    for j in 1:ncols1
        push!(x, @variable(ssef, category = category(m1.ctype[j]), lowerbound = m1.clbd[j], upperbound = m1.cubd[j], basename = m1.cname[j]))
    end
    ## second-stage
    for j in 1:ncols2
        push!(y, @variable(ssef, category = category(m2.ctype[j]), lowerbound = m2.clbd[j], upperbound = m2.cubd[j], basename = m2.cname[j]))
    end

    # objective
    @objective(ssef, m1.objsense, dot(x, m1.obj) + dot(y, m2.obj))

    # constraints
    ## first-stage
    for i in 1:nrows1
        if m1.sense[i] == :L
            @constraint(ssef, dot(m1.mat[i,:],x) <= m1.rhs[i])
        elseif m1.sense[i] == :G
            @constraint(ssef, dot(m1.mat[i,:],x) >= m1.rhs[i])
        else
            @constraint(ssef, dot(m1.mat[i,:],x) == m1.rhs[i])
        end
    end
    ## second-stage
    for i in 1:nrows2
        if m2.sense[i] == :L
            @constraint(ssef, dot(m2.mat[i,1:ncols1],x) + dot(m2.mat[i,ncols1+1:end],y) <= m2.rhs[i])
        elseif m2.sense[i] == :G
            @constraint(ssef, dot(m2.mat[i,1:ncols1],x) + dot(m2.mat[i,ncols1+1:end],y) >= m2.rhs[i])
        else
            @constraint(ssef, dot(m2.mat[i,1:ncols1],x) + dot(m2.mat[i,ncols1+1:end],y) == m2.rhs[i])
        end
    end

    return ssef
end

model = getModel(:DCAP, [3,4,5,10])
ssef = getSingleScenarioEFModel(model, 1)
setsolver(ssef,CplexSolver())
solve(ssef)
ssef.objVal

getSparsity(m)


generateSMPS(:DCLP,[5,10,"FallWD",5],genericnames=false,smpsfile=true)

m = generateSMPS(:AIRLIFT, [10], splice=false)

m.ext[:Stochastic].num_scen

print(m)

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
