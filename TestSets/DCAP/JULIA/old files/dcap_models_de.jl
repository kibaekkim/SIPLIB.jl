using JuMP, CPLEX

seed, nR, nN, nT, nS = 1, 2, 3, 3, 200
srand(seed)
R = 1:nR
N = 1:nN
T = 1:nT
S = 1:nS

A = rand(nR, nT) * 5 + 5
B = rand(nR, nT) * 40 + 10
C = rand(nR, nN, nT, nS) * 5 + 5
C0 = rand(nN, nT, nS) * 500 + 500
D = rand(nN, nT, nS) + 0.5
#M = [maximum([sum(D[:,t,s]) for s in S]) for t in T]
Pr = ones(nS)/nS

model = Model(solver = CplexSolver(CPXPARAM_TimeLimit = 30))
@variable(model, x[i=R,t=T] >= 0)
@variable(model, u[i=R,t=T], Bin)
@variable(model, y[i=R, j=N, t=T, s=S], Bin)
@variable(model, z[j=N,t=T,s=S] >= 0)
#@constraint(model, [i=R,t=T], x[i,t] - M[t]*u[i,t] <= 0)
#@constraint(model, [i=R,t=T], x[i,t] - 9999999999999*u[i,t] <= 0)
@constraint(model, [i=R,t=T], x[i,t] - u[i,t] <= 0)
@constraint(model, [i=R, t=T, s=S], sum(D[j,t,s]*y[i,j,t,s] for j in N) <= sum(x[i,tau] for tau in 1:t))
@constraint(model, [j=N, t=T, s=S], sum(y[i,j,t,s] for i in R) + z[j,t,s] == 1)

@objective(model, Min, sum(A[i,t]*x[i,t] + B[i,t]*u[i,t] for i in R for t in T)
                        + sum(Pr[s]*(sum(C[i,j,t,s]*y[i,j,t,s] for i in R for j in N for t in T)
                                    + sum(C0[j,t,s]*z[j,t,s] for j in N for t in T)) for s in S) )

status = solve(model)
getobjectivevalue(model)
