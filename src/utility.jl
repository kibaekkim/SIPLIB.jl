function getInstanceName(problem::Symbol, params_arr::Any)::String
    INSTANCE_NAME = String(problem)
    for p in 1:nParams[problem]
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

function plotMatrix(mat, INSTANCE_NAME::String="matrix", DIR_NAME::String="$(dirname(@__FILE__))/../plot")
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
