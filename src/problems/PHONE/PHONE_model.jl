include("./PHONE_data.jl")

function PHONE(nS::Integer, seed::Int=1)::JuMP.Model

    # read & generate instance data
    data = PHONEData(nS, seed)

    # sets
    P = 1:length(data.P)
    E = 1:length(data.E)
    R = [1:length(data.R[i]) for i in P] # 2 dim array
    S = 1:nS

    # parameters
    a, e, d, Pr = data.a, data.e, data.d, data.Pr

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## 1st stage
    @variable(model, x[j=E] >= 0, Int)
    @objective(model, Min, 0)
    @constraint(model, sum(x[j] for j in E) <= 3) # budget = 3

    ## 2nd stage
    for k in S
        sb = StructuredModel(parent = model, id = k, prob = Pr[k])
        @variable(sb, s[i=P] >= 0)
        @variable(sb, f[i=P, r=R[i]] >= 0, Int)
        @objective(sb, Min, sum(s[i] for i in P))
        @constraint(sb, [j=E], sum(data.a[i][r][j]*f[i,r] for i in P for r in R[i] for j in E) <= x[j] + e[j])
        @constraint(sb, [i=P], sum(f[i,r] for r in R[i]) + s[i] == d[i,k])
    end

    return model
end
