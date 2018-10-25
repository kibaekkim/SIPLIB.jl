#=
Source:
  Ntaimo, L. and S. Sen, "The 'million-variable' march for stochastic combinatorial optimization," Journal of Global Optimization, 2005.

I: set of clients
J: set of servers
Z: set of zones
c[j]: cost of locating a server at location j
q[i,j]: revenue from client i being served by server at location j
q0[j]: overflow penalty
d[i,j]: client i resource demand from server at location j
u: server capacity
v: an upper bound on the total number of servers that can be located
w[z]: minimum number of servers to be located in zone z
Jz[z]: the subset of server locations that belong to zone z
h[i,s]: 1 if client i is present in scenario s, 0 otherwise
p[s]: probability of occurance for scenario s
x[j]: 1 if a server is located at site j, 0 otherwise
y[i,j]: 1 if client i is served by a server at location j, 0 otherwise
y0[j]: any overflows that are not served due to limitations in server capacity
=#

function sslp(m::Int, n::Int, S::Int, seed::Int=1)::JuMP.Model

    srand(seed)
    I = 1:n
    J = 1:m
    Z = []
    c = rand(40:80,m)
    q = rand(0:25,n,m)
    q0 = ones(m)*1000
    d = q
    u = 1.5*sum(d)/m
    v = m
    w = NaN
    Jz = []
    h = rand(0:1,n,S)
    p = ones(S)/S

    model = StructuredModel(num_scenarios=S)
    @variable(model, x[j=J], Bin)
    @objective(model, Min, sum(c[j]*x[j] for j in J))
    @constraint(model, sum(x[j] for j in J) <= v)
    @constraint(model, [z=Z], sum(x[j] for j in Jz[z]) >= w[z])
    for s in 1:S
        sb = StructuredModel(parent=model, id = s, prob = p[s])
        @variable(sb, y[i=I,j=J], Bin)
        @variable(sb, y0[j=J] >= 0)
        @objective(sb, Min, -sum(q[i,j]*y[i,j] for i in I for j in J) + sum(q0[j]*y0[j] for j in J))
        @constraint(sb, [j=J], sum(d[i,j]*y[i,j] for i in I) - y0[j] <= u*x[j])
        @constraint(sb, [i=I], sum(y[i,j] for j in J) == h[i,s])
    end

    return model
end