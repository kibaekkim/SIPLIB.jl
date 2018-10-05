function includeModelingScripts()
    for prob in problem
        include("$(dirname(@__FILE__))/problems/$(String(prob))/$(String(prob))_model.jl")
    end
end

function setGlobalVariables()
    file_array = readdlm("$(dirname(@__FILE__))/problem_info.csv", ',')
    for i in 2:size(file_array)[1]
        push!(problem, Symbol(file_array[i,1]))
        numParams[problem[end]] = file_array[i,2]
        noteParams[problem[end]] = file_array[i,3]
    end
end

function getInstanceName(problem::Symbol, params_arr::Any)::String
    INSTANCE_NAME = String(problem)
    for p in 1:numParams[problem]
        INSTANCE_NAME *= "_$(params_arr[p])"
    end
    return INSTANCE_NAME
end

function lprelaxModel!(m::JuMP.Model, level::Int)
    # no LP relaxation
    if level == 0
        return m
    # First-stage only LP relaxation
    elseif level == 1
        for vdata in m.varData
            varsymbol = vdata[2].name
            if in(:innerArray , fieldnames(m[varsymbol]))
                for var in m[varsymbol].innerArray
                    if getcategory(var) != :Cont
                        setcategory(var, :Cont)
                    end
                end
            elseif in(:tupledict , fieldnames(m[varsymbol]))
                for key in m[varsymbol].tupledict
                    if getcategory(key[2]) != :Cont
                        setcategory(key[2], :Cont)
                    end
                end
            end
        end
        return m
    # Second-stage only LP relaxation
    elseif level == 2
        for s = 1:num_scenarios(m)
            for vdata in getchildren(m)[s].varData
                varsymbol = vdata[2].name
                if in(:innerArray, fieldnames(getchildren(m)[s][varsymbol]))
                    for var in getchildren(m)[s][varsymbol].innerArray
                        if getcategory(var) != :Cont
                            setcategory(var, :Cont)
                        end
                    end
                elseif in(:tupledict, fieldnames(getchildren(m)[s][varsymbol]))
                    for key in getchildren(m)[s][varsymbol].tupledict
                        if getcategory(key[2]) != :Cont
                            setcategory(key[2], :Cont)
                        end
                    end
                end
            end
        end
        return m
    # Fully LP relaxation
    elseif level == 3
        lprelaxModel(m, 1)
        lprelaxModel(m, 2)
        return m
    else
        warn("Please use one of the (0: no relax, 1: 1st-stage only, 2: 2nd-stage only, 3: full relax) for the LP-relaxation level argument.")
        return
    end
end

function category(c::Char)
    if c == 'C'
        return :Cont
    elseif c == 'B'
        return :Bin
    else # c == 'E'
        return :Int
    end
end

# from ModelData array, returns EF JuMP.Model
function getExtensiveFormModel(mdata_all::Array{ModelData}; return_x::Bool=false)
    # save the number of scenarios
    nS = length(mdata_all)-1
    # copy first-stage
    m1 = mdata_all[1]

    # get the number of first-stage rows and columns
    nrows1, ncols1 = size(m1.mat)
    # get the number of rows and columns for the scenario block
    nrows2, ncols = size(mdata_all[2].mat)
    ncols2 = ncols - ncols1

    # declare an Extensive Form Model
    efm = JuMP.Model()

    # variables
    ## declare variables constainers
    x = []  # first-stage
    y = []  # second-stage

    ## declare variables
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
        if isempty(m2.cname)
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

    # objective
    aff = AffExpr(x,m1.obj,0)
#=
    aff2 = (1/nS)*AffExpr(y[1],mdata_all[2].obj,0)
    for s in 2:nS
        append!(aff2, (1/nS)*AffExpr(y[s], mdata_all[s+1].obj, 0))
    end
=#
    for s in 1:nS
        append!(aff, (1/nS)*AffExpr(y[s], mdata_all[s+1].obj, 0))
    end
    @objective(efm, m1.objsense, aff)
    #@objective(efm, m1.objsense, aff)

    # constraints
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

    ## second-stage
    for s in 1:nS
        m2 = mdata_all[s+1]
        for i in 1:nrows2
            aff = AffExpr(x, m2.mat[i,1:ncols1], 0)
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

    if !return_x
        return efm
    else
        return (efm, x)
    end
end

# this function returns a single scenario (s-th scenario) extensive formed JuMP.Model object.
function getSingleScenarioModel(model::JuMP.Model, s::Int, genericnames::Bool=true, splice::Bool=true)::JuMP.Model
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end
    mdata_all = ModelData[]
    push!(mdata_all, getModelData(model, genericnames, splice))
    push!(mdata_all, getModelData(model.ext[:Stochastic].children[s], genericnames, splice))

    return getExtensiveFormModel(mdata_all)
end


function plotMatrix(mat, INSTANCE_NAME::String="matrix", DIR_NAME::String="$(dirname(@__FILE__))/../plot", close::Bool=false)
    PyPlot.@pyimport matplotlib.patches as pcs
    fig, ax = PyPlot.subplots()

    R,C,V = findnz(mat)
    for (x,y) in zip(C,R)
        ax[:add_artist](pcs.Rectangle(xy=(x-1, y-1), width=0.9, height=0.9, color="black"))
    end
    ax[:set_xlim](0.0, size(mat)[2])
    ax[:set_ylim](0.0, size(mat)[1])
    ax[:invert_yaxis]()
    ax[:set_xticks]([])
    ax[:set_yticks]([])
    ax[:set_aspect]("equal")
#    ax[:set_aspect](Float64(size(mat)[1])/Float64(size(mat)[2]))
    PyPlot.tight_layout()
    PyPlot.savefig("$DIR_NAME/$INSTANCE_NAME.pdf")
    if close
        PyPlot.close()
    end
end

function arrayParams()
    param_set = Dict{Symbol, Array{Array{Any}}}()

    # AIRLIFT
    param = [[]]
    nS = [200, 300, 500, 1000]
    param_array = Any[]
    for p in param
        for n in nS
            push!(param_array, copy(p))
            push!(param_array[end], n)
        end
    end
    param_set[:AIRLIFT] = param_array

    # CARGO
    param = [[]]
    nS = [10, 50, 100]
    param_array = Any[]
    for p in param
        for n in nS
            push!(param_array, copy(p))
            push!(param_array[end], n)
        end
    end
    param_set[:CARGO] = param_array

    # CHEM
    param = [[]]
    nS = [200, 300, 500, 1000]
    param_array = Any[]
    for p in param
        for n in nS
            push!(param_array, copy(p))
            push!(param_array[end], n)
        end
    end
    param_set[:CHEM] = param_array

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

    # PHONE
    param = [[]]
    nS = [200, 300, 500, 1000]
    param_array = Any[]
    for p in param
        for n in nS
            push!(param_array, copy(p))
            push!(param_array[end], n)
        end
    end
    param_set[:PHONE] = param_array

    # SDCP
    param = [[5,10,"FallWD"], [5,10,"FallWE"], [5,10,"SpringWD"], [5,10,"SpringWE"], [5,10,"SummerWD"], [5,10,"SummerWE"], [5,10,"WinterWD"], [5,10,"WinterWE"]]
    nS = [10]
    param_array = Any[]
    for p in param
        for n in nS
            push!(param_array, copy(p))
            push!(param_array[end], n)
        end
    end
    param_set[:SDCP] = param_array

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
#    param = [[5,25], [5,50], [10,50], [15,45]]
    param = [[5,25], [5,50]]
    nS = [50, 100]
    param_array = Any[]
    for p in param
        for n in nS
            push!(param_array, copy(p))
            push!(param_array[end], n)
        end
    end
    push!(param_array, [10,50,50])
    push!(param_array, [10,50,100])
    push!(param_array, [10,50,500])
    push!(param_array, [10,50,1000])
    push!(param_array, [10,50,2000])
    push!(param_array, [10,45,5])
    push!(param_array, [10,45,10])
    push!(param_array, [10,45,15])
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

    return param_set
end

function generateBasicInstances(DIR::String="")
    if DIR == ""
        THIS_FILE_PATH = dirname(@__FILE__)
        mkdir("$THIS_FILE_PATH/../instance/SMPS")
        SMPS_PATH = "$THIS_FILE_PATH/../instance/SMPS"
        param_set = arrayParams()
        for prob in problem
            cd("$SMPS_PATH")
            mkdir("$prob")
            for param in param_set[prob]
                generateSMPS(prob, param, SMPS_PATH*"/$(String(prob))", genericnames=false)
            end
        end
    else
        mkdir("$DIR/SMPS")
        SMPS_PATH = "$DIR/SMPS"
        param_set = arrayParams()
        for prob in problem
            cd("$SMPS_PATH")
            mkdir("$prob")
            for param in param_set[prob]
                generateSMPS(prob, param, SMPS_PATH*"/$(String(prob))", genericnames=false)
            end
        end
    end
end


#=
mdata = getModelData(getchildren(m)[s], genericnames, splice)
push!(mdata_all, mdata)


m = getModel(:DCAP, [3,3,3,3])
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
