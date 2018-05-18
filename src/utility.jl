function getInstanceName(problem::Symbol, param_arr::Any)::String
    INSTANCE = String(problem)
    for p in 1:nParam[problem]
        INSTANCE *= "_$(param_arr[p])"
    end
    return INSTANCE
end
