using JuMP, StructJuMP

function sizes(nScenarios::Integer)::JuMP.Model

    sizes = sizesdata(nScenarios)

    model = StructuredModel(num_scenarios = nScenarios)
    @variable(model, y[i = sizes.N, t = sizes.T] >= 0, Int)
    @objective(model, Min, sum(sizes.P[i]*y[i,t] for i in sizes.N for t in sizes.T))

    for l in sizes.L
        sb = StructuredModel(parent = model, id = l, prob = sizes.Pr[l])
        @variables sb begin
            x[i = sizes.N, j = sizes.N, t = sizes.T] >= 0, Int
            z[i = sizes.N, t = sizes.T], Bin
        end
        @objective(sb, Min, sum((sum(sizes.s*z[i,t] for i in sizes.N) + sizes.r*sum(x[i,j,t] for i in sizes.N[2:end] for j in 1:i-1)) for t in sizes.T[2:end]) )
        @constraints sb begin
            [t = sizes.T], sum(y[i,t] for i in sizes.N) <= sizes.C[t,l]
            [j = sizes.N, t = sizes.T], sum(x[i,j,t] for i in sizes.N[j:end]) >= sizes.D[j,t,l]
            [i = sizes.N, t = sizes.T], sum(x[i,j,t2] for t2 in 1:t for j in 1:i) <= sum(y[i,t2] for t2 in 1:t)
            [i = sizes.N, t = sizes.T], y[i,t] <= sizes.C[t,l]*z[i,t]
        end
    end

    return model
end
