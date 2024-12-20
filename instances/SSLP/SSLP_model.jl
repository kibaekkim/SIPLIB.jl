#=
Source:
  Ntaimo, L. and S. Sen, "The 'million-variable' march for stochastic combinatorial optimization," Journal of Global Optimization, 2005.

Input:
  nJ: number of servers
  nI: number of clients
  nS: number of scenarios

Sets:
  I: clients
  J: servers
  Z: zones

Variables (1st Stage):
  x[j]: 1 if a server is located at site j, 0 otherwise

Variables (2nd Stage):
  y[i,j]: 1 if client i is served by a server at location j, 0 otherwise
  y0[j]: any overflows that are not served due to limitations in server capacity

Parameters (general):
  c[j]: cost of locating a server at location j
  q[i,j]: revenue from client i being served by server at location j
  q0[j]: overflow penalty
  d[i,j]: client i resource demand from server at location j
  u: server capacity
  v: an upper bound on the total number of servers that can be located
  w[z]: minimum number of servers to be located in zone z
  Jz[z]: the subset of server locations that belong to zone z
  p[s]: probability of occurrence for scenario s

Parameters (scenario):
  h[i,s]: 1 if client i is present in scenario s, 0 otherwise
=#

using StructJuMP
using Random

function SSLP(nJ::Int, nI::Int, nS::Int, seed::Int=1)::StructuredModel

    Random.seed!(seed)

    J = 1:nJ
    I = 1:nI
    S = 1:nS
    Z = []

    c = rand(40:80,nJ)
    q = rand(0:25,nI,nJ)
    q0 = ones(nJ)*1000
    d = q
    u = 1.5*sum(d)/nJ
    v = nJ
    w = NaN
    Jz = []
    h = rand(0:1,nI,nS)
    Pr = ones(nS)/nS

    # construct JuMP.Model
    model = StructuredModel(num_scenarios=nS)

    ## 1st stage
    @variable(model, x[j=J], Bin)
    @objective(model, Min, sum(c[j]*x[j] for j in J))
    @constraint(model, sum(x[j] for j in J) <= v)
    @constraint(model, [z=Z], sum(x[j] for j in Jz[z]) >= w[z])

    ## 2nd stage
    for s in S
        sb = StructuredModel(parent=model, id = s, prob = Pr[s])
        @variable(sb, y[i=I,j=J], Bin)
        @variable(sb, y0[j=J] >= 0)
        @objective(sb, Min, -sum(q[i,j]*y[i,j] for i in I for j in J) + sum(q0[j]*y0[j] for j in J))
        @constraint(sb, [j=J], sum(d[i,j]*y[i,j] for i in I) - y0[j] <= u*x[j])
        @constraint(sb, [i=I], sum(y[i,j] for j in J) == h[i,s])
    end

    return model
end
