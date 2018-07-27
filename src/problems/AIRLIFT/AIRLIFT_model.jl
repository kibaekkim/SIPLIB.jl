include("./AIRLIFT_data.jl")

function AIRLIFT(nS::Integer, seed::Int=1)::JuMP.Model

    # read & generate instance data
    data = AIRLIFTData(nS, seed)

    # copy (for convenience)
    A, R, S = data.A, data.R, data.S
    F, a, alpha, b, c, gamma = data.F, data.a, data.alpha, data.b, data.c, data.gamma
    cplus, cminus, d, Pr = data.cplus, data.cminus, data.d, data.Pr

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## 1st stage
    @variable(model, x[i = A, j = R] >= 0, Int)
    @objective(model, Min, sum(c[i,j]*x[i,j] for i in A for j in R))
    @constraint(model, [i = A], sum(a[i,j]*x[i,j] for j in R) <= F)

    ## 2nd stage
    for s in S
        sb = StructuredModel(parent = model, id = s, prob = Pr[s])
        @variable(sb, chi[i = A, j = R, k = R; k != j] >= 0, Int)
        @variable(sb, yplus[j = R] >= 0)
        @variable(sb, yminus[j = R] >= 0)
        @objective(sb, Min,
                sum((gamma[i,j,k]-c[i,j]*(alpha[i,j,k]/a[i,j]))*chi[i,j,k] for i in A for j in R for k in R if k != j)
                + sum(cplus[j]*yplus[j] + cminus[j]*yminus[j] for j in R)
        )
        @constraint(sb, [i = A, j = R], sum(alpha[i,j,k]*chi[i,j,k] for k in R if k != j) <= a[i,j]*x[i,j])
        @constraint(sb, [j = R],
                sum(b[i,j]*x[i,j] for i in A)
                - sum(b[i,j]*(alpha[i,j,k]/a[i,j])*chi[i,j,k] for i in A for k in R if k != j)
                + sum(b[i,j]*chi[i,k,j] for i in A for k in R if k != j) + yplus[j] - yminus[j]
                == d[j,s]
        )
    end

    return model
end
