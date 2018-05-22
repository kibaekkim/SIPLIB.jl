module Siplib
    # using packages
    using Distributions
    using JuMP
    using StructJuMP
    using PyPlot
#    using Dsp  # for DSP solver, bug exist (compatibility issue with JuMP & StructJuMP)
#    using MPI

    # global variables (predetermined parameters)
    ## number of parameters for each problem
    global nParam = Dict(:DCAP=>4, :MPTSPs=>3, :SIZES=>1, :SMKP=>2, :SSLP=>3, :SUC=>2)
    ## MPTSP
    global RADIUS = 7.0      # MPTSPs: default radius of the area
    global NK = 3            # MPTSPs: default number of paths between two nodes
    global VC = 40.0         # MPTSPs: default deterministic velocity profile for central node
    global VS = 80.0         # MPTSPs: default deterministic velocity profile for suburban node
    ## SMKP
    global NXZ = 50          # SMKP: default number of xz-knapsack
    global NXY = 5           # SMKP: default number of xy-knapsacks


    # include JuMP.Modeling sources
    include("./problems/DCAP/dcap_models.jl")
    include("./problems/MPTSPs/mptsps_models.jl")
    include("./problems/SIZES/sizes_models.jl")
    include("./problems/SMKP/smkp_models.jl")
    include("./problems/SSLP/sslp_models.jl")
    include("./problems/SUC/suc_models.jl")

    # include Siplib utility sources
    include("./SmpsWriter.jl")
    include("./utility.jl")
    include("./generator.jl")
    include("./analyzer.jl")
#    include("./solver.jl")

    export getInstanceName,         # return Instance name using problem & parameters
           writeSmps,               # write SMPS files from JuMP.Model
           writeSmps_with_splice,   # for memory-efficiency. not proper in case of reusing JuMP.Model-object.
           writeSMPS,               # alias
           writeSMPS_with_splice,   # alias
           getJuMPModel,            # only return JuMP.Model object
           generateSMPS,            # return JuMP.Model object as well as generate SMPS files
           plotConstrMatrix,        # plot constraint matrix of the extensive form
           plotFirstStageBlock,     # plot block A (first stage only)
           plotSecondStageBlock,    # plot block W (second stage only)
           plotComplicatingBlock,   # plot block T (complicating block)
           plotAllBlocks,           # plot block A, W, T simultaneously
           plotAll,
           getSparsity,
           getSize

end # end module Siplib


using Siplib

#=
param_arr = [2,2,2,2]
problem = :DCAP
INSTANCE = getInstanceName(problem,param_arr)
model = getJuMPModel(problem, param_arr)
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
