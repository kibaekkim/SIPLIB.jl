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
    param = [[5,25], [5,50], [10,50], [15,45]]
    nS = [50, 100]
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