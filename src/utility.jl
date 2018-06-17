function getInstanceName(problem::Symbol, param_arr::Any)::String
    INSTANCE = String(problem)
    for p in 1:nParam[problem]
        INSTANCE *= "_$(param_arr[p])"
    end
    return INSTANCE
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
