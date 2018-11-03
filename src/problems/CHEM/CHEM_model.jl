#=
Source:
=#

#using StructJuMP

function CHEM(nS::Int, seed::Int=1)::JuMP.Model

    # set random seed (default=1)
    Random.seed!(seed)

    # generate & store instance data
    ## sets
    I = 1:4
    J = 1:3
    R = 1:7
    T = 1:2
    S = 1:nS

    ## deterministic parameters
    delta = 0
#    co = zeros(length(I),length(J),length(T))
#    Co = zeros(length(I),length(J),length(T))
    p = 4*ones(length(I),length(J))
    fp = ones(length(R),length(I))
    fc = ones(length(R),length(I))
    m = [100 200 150; 100 200 150; 100 200 150; 100 200 150]
    H = [80 80]
    Amax = 400*ones(length(R),length(T))
    C = [2500 2600; 3000 3100; 2800 2900]
    vb = [23 24; 25 26; 0 0; 0 0; 0 0; 0 0; 0 0]
    Qb = [200 200;250 250;0 0; 0 0; 0 0; 0 0;0 0]

    tasks = Dict()
    tasks[1] = [1,4]
    tasks[2] = [1,4]
    tasks[3] = [2,3]

    equip = Dict()
    equip[1] = [1,2]
    equip[2] = [3]
    equip[3] = [3]
    equip[4] = [1,2]

    prod = Dict()
    prod[1] = []
    prod[2] = []
    prod[3] = [1]
    prod[4] = [2]
    prod[5] = [2]
    prod[6] = [3]
    prod[7] = [4]

    cons = Dict()
    cons[1] = [1]
    cons[2] = [1,3]
    cons[3] = [2]
    cons[4] = []
    cons[5] = [3]
    cons[6] = [4]
    cons[7] = []

    ## stochastic parameters
    Qs = zeros(length(R),length(T),length(S))
    Qs[4,:,:] = rand(Uniform(0,150),length(T),length(S))
    Qs[7,:,:] = rand(Uniform(0,200),length(T),length(S))
    vs = zeros(length(R),length(T),length(S))
    vs[4,:,:] = rand(Uniform(50,60),length(T),length(S))
    vs[7,:,:] = rand(Uniform(70,80),length(T),length(S))

    Pr = ones(nS)/nS

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## 1st stage
    @variable(model, A[r=R,t=T] >= 0)
    @variable(model, qb[r=R,t=T] >= 0)
    @variable(model, qs[r=R,t=T] >= 0)
    @variable(model, B[i=I,j=J,t=T] >= 0)
    @variable(model, n[j=J,t=T] >= 0, Int)
    @variable(model, y[i=I,j=J,t=T] >= 0, Int)
    @objective(model, Max, sum(-sum(vb[r,t]*qb[r,t] for r in [1,2]) - sum(C[j,t]*n[j,t+delta] for j in J) for t in T))
    @constraint(model, [j=J,t=T], sum(p[i,j]*y[i,j,t] for i in tasks[j]) <= H[t]*sum(n[j,tau] for tau in 1:t))
    #@constraint(model, [t=T], sum(sum(co[i,j,t]*y[i,j,t] for i in tasks[j]) j in J) <= Co*sum(sum(n[j,tau] for tau in 1:t) for j in J))
    @constraint(model, [r=R,t=T[2:end]], A[r,t] == A[r,t-1] + sum(sum(fp[r,i]*B[i,j,t] for j in equip[i]) for i in prod[r])
                                                            - sum(sum(fc[r,i]*B[i,j,t] for j in equip[i]) for i in cons[r])
                                                            - qs[r,t] + qb[r,t])
    @constraint(model, [r=R,t=T], A[r,t] <= Amax[r,t])
    @constraint(model, [i=I,j=J,t=T], B[i,j,t] <= m[i,j]*y[i,j,t])
    @constraint(model, [r=R,t=T], qb[r,t] <= Qb[r,t])
    #@constraint(model, [j=J], sum(C[j,t]*n[j,t] for j in J) + sum(vb[r,t]*qb[r,t] for r in R) <= MC[t])

    ## 2nd stage
    for sigma in S
        sb = StructuredModel(parent=model, id = sigma, prob = Pr[sigma])
        @variable(sb, qszero[r=R,t=T] >= 0)
        @variable(sb, qsplus[r=R,t=T] >= 0)
        @objective(sb, Max, sum(sum(vs[r,t,sigma]*qszero[r,t] for r in [4,7]) for t in T))
        @constraint(sb, [r=R,t=T], qs[r,t] == qszero[r,t] + qsplus[r,t])
        @constraint(sb, [r=R,t=T], qszero[r,t] <= Qs[r,t,sigma])
    end

    return model
end
