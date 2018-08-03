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

# this function returns a single scenario (s-th scenario) extensive formed JuMP.Model object.
function getSingleScenarioModel(model::JuMP.Model, s::Int, genericnames::Bool=true)::JuMP.Model
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

    # extract model data
    ## first-stage
    m1 = getModelData(model, genericnames, false)
    ## second-stage, s-th scenario
    m2 = getModelData(model.ext[:Stochastic].children[s], genericnames, false)

    # get # of first-stage rows and columns
    nrows1, ncols1 = size(m1.mat)
    # get # of rows and columns for the scenario block
    nrows2, ncols = size(m2.mat)
    ncols2 = ncols - ncols1

    # declare a single scenario Extensive Form model
    ssm = Model()

    # first-stage variable container
    x = []
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
                @constraint(ssm, dot(m1.mat[i,:],x) <= m1.rhs[i])
            elseif m1.sense[i] == :G
                @constraint(ssm, dot(m1.mat[i,:],x) >= m1.rhs[i])
            else
                @constraint(ssm, dot(m1.mat[i,:],x) == m1.rhs[i])
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
                @constraint(ssm, dot(m1.mat[i,:],x) <= m1.rhs[i])
            elseif m1.sense[i] == :G
                @constraint(ssm, dot(m1.mat[i,:],x) >= m1.rhs[i])
            else
                @constraint(ssm, dot(m1.mat[i,:],x) == m1.rhs[i])
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

    return ssm
end


function getEVPModelData()

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
