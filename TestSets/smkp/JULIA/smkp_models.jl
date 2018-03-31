# SMKP - Stochastic Multiple (binary) Knapsack Problem
#
# Source
#  Angulo et al., "Improving the integer L-shaped method," INFORMS JoC, vol.28 (3), pp. 483-499, 2016
#
# Decision variables
#  (1st stage, binary)  x[j], z[j]
#  (2nd stage, binary)  y[j]

using JuMP, StructJuMP

function smkp(nI::Int, nScenarios::Int, seed::Int=1)::JuMP.Model

    srand(seed)
    I = 1:nI    # number of items
    J = 1:50    # number of xz-knapsacks
    K = 1:5     # number of xy-knapsacks
    U = 1:100   # Uniform distribution parameter
    Pr = ones(nScenarios)/nScenarios

    A = rand(U, 50, nI)
    E = rand(U, 50, nI)
    T = rand(U, 5, nI)
    W = rand(U, 5, nI)
    b = (3/4) * (A * ones(nI) + E * ones(nI))
    h = (3/4) * (T * ones(nI) + W * ones(nI))
    c = rand(U, 1, nI)
    d = rand(U, 1, nI)
    q = rand(U, nScenarios, nI)

    model = StructuredModel(num_scenarios = nScenarios)
    @variables model begin
        x[i = I], Bin
        z[i = I], Bin
    end
    @objective(model, Min, sum(c[i]*x[i] for i in I) + sum(d[i]*z[i] for i in I))
    @constraint(model, [j = J], sum(A[j,i]*x[i] for i in I) + sum(E[j,i]*z[i] for i in I) >= b[j])
    for s in 1:nScenarios
        sb = StructuredModel(parent = model, id = s, prob = Pr[s])
        @variable(sb, y[i = I], Bin)
        @objective(sb, Min, sum(q[s,i]*y[i] for i in I))
        @constraint(sb, [k = K], sum(W[k,i]*y[i] for i in I) >= h[k] - sum(T[k,i]*x[i] for i in I))
    end

    return model
end
