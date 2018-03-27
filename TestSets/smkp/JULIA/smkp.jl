# SMKP - Stochastic Multiple (binary) Knapsack Problem
#
# Source
#  Angulo et al., "Improving the integer L-shaped method," INFORMS JoC, vol.28 (3), pp. 483-499, 2016
#
# Decision variables
#  (1st stage, binary)  x[j], z[j]
#  (2nd stage, binary)  y[j]

using JuMP, StructJuMP
#=
function smkp(nScenarios::Int=20, nDim::Int=120, seed::Int=1)::JuMP.Model

    srand(seed)
    I = 1:50
    J = 1:nDim
    K = 1:5
    U = 1:100 # Uniform distribution parameter
    Pr = ones(nScenarios)/nScenarios

    A = rand(U, 50, nDim)
    C = rand(U, 50, nDim)
    T = rand(U, 5, nDim)
    W = rand(U, 5, nDim)
    b = (3/4) * (A * ones(nDim) + C * ones(nDim))
    h = (3/4) * (T * ones(nDim) + W * ones(nDim))
    c = rand(U, 1, nDim)
    d = rand(U, 1, nDim)
    q = rand(U, nScenarios, nDim)

    model = StructuredModel(num_scenarios = nScenarios)
    @variables model begin
        x[j = J], Bin
        z[j = J], Bin
    end
    @objective(model, Min, sum(c[j]*x[j] for j in J) + sum(d[j]*z[j] for j in J))
    @constraint(model, [i = I], sum(A[i,j]*x[j] for j in J) + sum(C[i,j]*z[j] for j in J) >= b[i])
    for s in 1:nScenarios
        sb = StructuredModel(parent = model, id = s, prob = Pr[s])
        @variable(sb, y[j = J], Bin)
        @objective(sb, Min, sum(q[s,j]*y[j] for j in J))
        @constraint(sb, [k = K], sum(W[k,j]*y[j] for j in J) >= h[k] - sum(T[k,j]*x[j] for j in J))
    end

    return model
end
=#
function smkp(nScenarios::Int=20, nDim::Int=120, seed::Int=1)::JuMP.Model

    srand(seed)
    I = 1:nDim  # number of items
    J = 1:50    # number of xz-knapsacks
    K = 1:5     # number of xy-knapsacks
    U = 1:100   # Uniform distribution parameter
    Pr = ones(nScenarios)/nScenarios

    A = rand(U, 50, nDim)
    C = rand(U, 50, nDim)
    T = rand(U, 5, nDim)
    W = rand(U, 5, nDim)
    b = (3/4) * (A * ones(nDim) + C * ones(nDim))
    h = (3/4) * (T * ones(nDim) + W * ones(nDim))
    c = rand(U, 1, nDim)
    d = rand(U, 1, nDim)
    q = rand(U, nScenarios, nDim)

    model = StructuredModel(num_scenarios = nScenarios)
    @variables model begin
        x[i = I], Bin
        z[i = I], Bin
    end
    @objective(model, Min, sum(c[i]*x[i] for i in I) + sum(d[i]*z[i] for i in I))
    @constraint(model, [j = J], sum(A[j,i]*x[j] for i in I) + sum(C[j,i]*z[i] for i in I) >= b[j])
    for s in 1:nScenarios
        sb = StructuredModel(parent = model, id = s, prob = Pr[s])
        @variable(sb, y[j = J], Bin)
        @objective(sb, Min, sum(q[s,i]*y[i] for i in I))
        @constraint(sb, [k = K], sum(W[k,i]*y[i] for i in I) >= h[k] - sum(T[k,i]*x[i] for i in I))
    end

    return model
end


# test
nScenarios, nDim = 20, 120
seed = 1
srand(seed)

using CPLEX
setsolver(model,CplexSolver(CPXPARAM_TimeLimit = 30))
solve(model)
