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

function lprelaxModel(m::JuMP.Model, level::Int)
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
    end
end

function getSingleScenarioModelData(mdata_all::Array{ModelData}, s::Int)::ModelData

    # get # of first-stage rows and columns
    nrows1, ncols1 = size(mdata_all[1].mat)

    # get # of rows and columns for the scenario block
    nrows2, ncols = size(mdata_all[s+1].mat)
    ncols2 = ncols - ncols1

    # core data (includes 1st stage & 2nd stage's 1st scenario data)
    objsense = mdata_all[1].objsense
    obj      = [mdata_all[1].obj  ; mdata_all[s+1].obj]
    rhs      = [mdata_all[1].rhs  ; mdata_all[s+1].rhs]
    sense    = [mdata_all[1].sense; mdata_all[s+1].sense]
    clbd     = [mdata_all[1].clbd ; mdata_all[s+1].clbd]
    cubd     = [mdata_all[1].cubd ; mdata_all[s+1].cubd]
    ctype    = mdata_all[1].ctype * mdata_all[s+1].ctype
    cname    = [mdata_all[1].cname ; mdata_all[s+1].cname]    # for column name
    mat      = [[mdata_all[1].mat zeros(nrows1, ncols-ncols1)] ; mdata_all[s+1].mat]

    return ModelData(mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)
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
