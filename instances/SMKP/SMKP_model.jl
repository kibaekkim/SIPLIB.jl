# SMKP - Stochastic Multiple (binary) Knapsack Problem
#
# Source
#  Angulo et al., "Improving the integer L-shaped method," INFORMS JoC, vol.28 (3), pp. 483-499, 2016
#
# Decision variables
#  (1st stage, binary)  x[j], z[j]
#  (2nd stage, binary)  y[j]
using StructJuMP
using Random

include("./SMKP_data.jl")

## predetermined parameters
global NXZ = 50          # SMKP: default number of xz-knapsack
global NXY = 5           # SMKP: default number of xy-knapsacks

function SMKP(nI::Int, nS::Int, seed::Int=1, nXZ::Int=NXZ, nXY::Int=NXY)::StructuredModel

    # generate instance data
    data = SMKPData(nI, nS, seed)

    # copy (for convenience)
    I, J, K, Pr, A, E, T, W = data.I, data.J, data.K, data.Pr, data.A, data.E, data.T, data.W
    b, h, c, d, q = data.b, data.h, data.c, data.d, data.q

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## 1st stage
    @variables model begin
        x[i = I], Bin
        z[i = I], Bin
    end
    @objective(model, Min, sum(c[i]*x[i] for i in I) + sum(d[i]*z[i] for i in I))
    @constraint(model, [j = J], sum(A[j,i]*x[i] for i in I) + sum(E[j,i]*z[i] for i in I) >= b[j])

    ## 2nd stage
    for s in 1:nS
        sb = StructuredModel(parent = model, id = s, prob = Pr[s])
        @variable(sb, y[i = I], Bin)
        @objective(sb, Min, sum(q[s,i]*y[i] for i in I))
        @constraint(sb, [k = K], sum(W[k,i]*y[i] for i in I) >= h[k] - sum(T[k,i]*x[i] for i in I))
    end

    return model
end
