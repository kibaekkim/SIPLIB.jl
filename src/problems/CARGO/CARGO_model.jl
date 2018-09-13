function CARGO(nS::Int, seed::Int=1)::JuMP.Model

    # internal function definitions
    function U(m::Char, n::Char, Route::Array{String})
        set = []
        for r in 1:length(Route)
            if (Route[r][1] == m && Route[r][2] == n) || (Route[r][2] == m && Route[r][3] == n) || (Route[r][1] == m && Route[r][3] == n)
                push!(set, r)
            end
        end
        return set
    end

    function V(j::Int, n::Char, Route::Array{String})
        set = []
        for r in 1:length(Route)
            if Route[r][j] == n
                push!(set, r)
            end
        end
        return set
    end

    function W(n::Char, Route::Array{String})
        set = []
        for r in 1:length(Route)
            if in(n,Route[r])
                push!(set, r)
            end
        end
        return set
    end

    function h(route::String, a::Int, FlightHours::Array{Matrix{Float64}}, Ndict::Dict{Char,Int64})
        sum = 0
        for j in 1:length(route)-1
            sum += FlightHours[a][Ndict[route[j]],Ndict[route[j+1]]]
        end
        return sum
    end

    function Pair(pi::Int, Route::Array{String}, Ndict::Dict{Char,Int64})
        set = []
        push!(set,(Ndict[Route[pi][1]],Ndict[Route[pi][2]]))
        push!(set,(Ndict[Route[pi][2]],Ndict[Route[pi][3]]))
        return set
    end

    function v(pi::Int, j::Int, Route::Array{String}, Ndict::Dict{Char,Int64})
        return Ndict[Route[pi][j]]
    end

    # set random seed (default=1)
    srand(seed)

    # generate & store instance data
    # sets
    nS = 5
    N = 1:4
    P = 1:26
    A = 1:2
    S = 1:nS

    # data
    Ndict = Dict('A'=>1,'B'=>2,'C'=>3,'E'=>4)
    Node = ['A','B','C','E']
    Route = ["ABA","ABE","ABC","ACA","ACE","ACB","BAB","BAC","BCA","BCB","BCE","BEB","BEC","ECE","ECB","ECA","EBE","EBC","EBA","CAC","CAB","CBC","CBA","CBE","CEC","CEB"]
    FlightHours = [[0 5 7 0; 5 0 4 8; 7 4 0 5; 0 8 5 0],  [0 6 8.4 0; 6 0 4.8 9.6; 8.4 4.8 0 6; 0 9.6 6 0]]

    l = 3
    q = 1
    rho = 1300
    f = zeros(length(N),length(N))
    sigma = 25*ones(length(N))
    hmin = zeros(length(A))
    hmax = [480, 240]
    c = [5,4]
    delta = [8,6]
    b = rand(Uniform(3,12),length(N),length(N),length(S))
    Pr = ones(nS)/nS

    model = StructuredModel(num_scenarios=nS)
    @variable(model, x[pi=P,a=A]>=0, Int)
    @objective(model, Min, sum(sum(c[a]*h(Route[pi],a,FlightHours,Ndict)*x[pi,a] for a in A) for pi in P))
    @constraint(model, [m=N,n=N], sum(sum(x[pi,a] for pi in U(Node[m],Node[n],Route)) for a in A) >= f[m,n])
    @constraint(model, [n=N], sum(sum(x[pi,a] for pi in W(Node[n],Route)) for a in A) <= sigma[n])
    @constraint(model, [a=A,n=N], sum(x[pi,a] for pi in V(1,Node[n],Route)) == sum(x[pi,a] for pi in V(l,Node[n],Route)))
    @constraint(model, [a=A], sum(x[pi,a]*h(Route[pi],a,FlightHours,Ndict) for pi in P) >= hmin[a])
    @constraint(model, [a=A], sum(x[pi,a]*h(Route[pi],a,FlightHours,Ndict) for pi in P) <= hmax[a])
    for s in S
        sb = StructuredModel(parent=model, id = s, prob = Pr[s])
        @variable(sb, d[pi=P,m=N,n=N]>=0, Cont)
        @variable(sb, t[pi=P,m=N,k=N,n=N]>=0, Cont)
        @variable(sb, r[pi=P,k=N,n=N]>=0, Cont)
        @variable(sb, y[m=N,n=N]>=0, Cont)
        @variable(sb, z[pi=P,j=1:l-1]>=0, Cont)
        @objective(sb, Min, q*sum(sum(d[pi,m,n]+r[pi,m,n]+sum(t[pi,m,n,k] for k in N) for (m,n) in Pair(pi,Route,Ndict)) for pi in P) + rho*sum(sum(y[m,n] for n in N) for m in N))
        @constraint(sb, [m=N,n=N], sum(d[pi,m,n]+sum(t[pi,m,k,n] for k in N) for pi in P) + y[m,n] >= b[m,n,s])
        @constraint(sb, [k=N,n=N], sum(sum(t[pi,m,k,n] for m in N) for pi in P) == sum(r[pi,k,n] for pi in P))
        @constraint(sb, [pi=P], sum(d[pi,v(pi,1,Route,Ndict),k] + r[pi,v(pi,1,Route,Ndict),k] + sum(t[pi,v(pi,1,Route,Ndict),k,n] for n in N) for k in N) == sum(delta[a]*x[pi,a] for a in A) - z[pi,1])
        @constraint(sb, [pi=P,j=2:l-1], sum(d[pi,v(pi,j,Route,Ndict),k] + r[pi,v(pi,j,Route,Ndict),k] + sum(t[pi,v(pi,j,Route,Ndict),k,n] for n in N) for k in N)
                                - sum(d[pi,k,v(pi,j,Route,Ndict)] + r[pi,k,v(pi,j,Route,Ndict)] + sum(t[pi,k,v(pi,j,Route,Ndict),n] for n in N) for k in N)
                                == z[pi,j-1] - z[pi,j])
        @constraint(sb, [pi=P,m=N,n=N; !in(pi,U(Node[m],Node[n],Route))], d[pi,m,n] == 0)
        @constraint(sb, [pi=P,m=N,k=N,n=N; !in(pi,U(Node[m],Node[k],Route))], t[pi,m,k,n] == 0)
        @constraint(sb, [pi=P,k=N,n=N; !in(pi,U(Node[k],Node[n],Route))], r[pi,k,n] == 0)
    end

    return model
end

#=
model = CARGO(10)
WS(model, CplexSolver())

using Distributions, StructJuMP

function U(m::Char, n::Char, Route::Array{String})
    set = []
    for r in 1:length(Route)
        if (Route[r][1] == m && Route[r][2] == n) || (Route[r][2] == m && Route[r][3] == n) || (Route[r][1] == m && Route[r][3] == n)
            push!(set, r)
        end
    end
    return set
end

function V(j::Int, n::Char, Route::Array{String})
    set = []
    for r in 1:length(Route)
        if Route[r][j] == n
            push!(set, r)
        end
    end
    return set
end

function W(n::Char, Route::Array{String})
    set = []
    for r in 1:length(Route)
        if in(n,Route[r])
            push!(set, r)
        end
    end
    return set
end

function h(route::String, a::Int, FlightHours::Array{Matrix{Float64}}, Ndict::Dict{Char,Int64})
    sum = 0
    for j in 1:length(route)-1
        sum += FlightHours[a][Ndict[route[j]],Ndict[route[j+1]]]
    end
    return sum
end

function Pair(pi::Int, Route::Array{String}, Ndict::Dict{Char,Int64})
    set = []
    push!(set,(Ndict[Route[pi][1]],Ndict[Route[pi][2]]))
    push!(set,(Ndict[Route[pi][2]],Ndict[Route[pi][3]]))
    return set
end

function v(pi::Int, j::Int, Route::Array{String}, Ndict::Dict{Char,Int64})
    return Ndict[Route[pi][j]]
end


# sets
nS = 5
N = 1:4
P = 1:26
A = 1:2
S = 1:nS

# data
Ndict = Dict('A'=>1,'B'=>2,'C'=>3,'E'=>4)
Node = ['A','B','C','E']
Route = ["ABA","ABE","ABC","ACA","ACE","ACB","BAB","BAC","BCA","BCB","BCE","BEB","BEC","ECE","ECB","ECA","EBE","EBC","EBA","CAC","CAB","CBC","CBA","CBE","CEC","CEB"]
FlightHours = [[0 5 7 0; 5 0 4 8; 7 4 0 5; 0 8 5 0],  [0 6 8.4 0; 6 0 4.8 9.6; 8.4 4.8 0 6; 0 9.6 6 0]]

l = 3
q = 1
rho = 1300
f = zeros(length(N),length(N))
sigma = 25*ones(length(N))
hmin = zeros(length(A))
hmax = [480, 240]
c = [5,4]
delta = [8,6]
b = rand(Uniform(3,12),length(N),length(N),length(S))
Pr = ones(nS)/nS

model = StructuredModel(num_scenarios=nS)
@variable(model, x[pi=P,a=A]>=0, Int)
@objective(model, Min, sum(sum(c[a]*h(Route[pi],a,FlightHours,Ndict)*x[pi,a] for a in A) for pi in P))
@constraint(model, [m=N,n=N], sum(sum(x[pi,a] for pi in U(Node[m],Node[n],Route)) for a in A) >= f[m,n])
@constraint(model, [n=N], sum(sum(x[pi,a] for pi in W(Node[n],Route)) for a in A) <= sigma[n])
@constraint(model, [a=A,n=N], sum(x[pi,a] for pi in V(1,Node[n],Route)) == sum(x[pi,a] for pi in V(l,Node[n],Route)))
@constraint(model, [a=A], sum(x[pi,a]*h(Route[pi],a,FlightHours,Ndict) for pi in P) >= hmin[a])
@constraint(model, [a=A], sum(x[pi,a]*h(Route[pi],a,FlightHours,Ndict) for pi in P) <= hmax[a])
for s in S
    sb = StructuredModel(parent=model, id = s, prob = Pr[s])
    @variable(sb, d[pi=P,m=N,n=N]>=0, Cont)
    @variable(sb, t[pi=P,m=N,k=N,n=N]>=0, Cont)
    @variable(sb, r[pi=P,k=N,n=N]>=0, Cont)
    @variable(sb, y[m=N,n=N]>=0, Cont)
    @variable(sb, z[pi=P,j=1:l-1]>=0, Cont)
    @objective(sb, Min, q*sum(sum(d[pi,m,n]+r[pi,m,n]+sum(t[pi,m,n,k] for k in N) for (m,n) in Pair(pi,Route,Ndict)) for pi in P) + rho*sum(sum(y[m,n] for n in N) for m in N))
    @constraint(sb, [m=N,n=N], sum(d[pi,m,n]+sum(t[pi,m,k,n] for k in N) for pi in P) + y[m,n] >= b[m,n,s])
    @constraint(sb, [k=N,n=N], sum(sum(t[pi,m,k,n] for m in N) for pi in P) == sum(r[pi,k,n] for pi in P))
    @constraint(sb, [pi=P], sum(d[pi,v(pi,1,Route,Ndict),k] + r[pi,v(pi,1,Route,Ndict),k] + sum(t[pi,v(pi,1,Route,Ndict),k,n] for n in N) for k in N) == sum(delta[a]*x[pi,a] for a in A) - z[pi,1])
#    @constraint(sb, [pi=P,j=2:l-1], sum(d[pi,v(pi,j,Route,Ndict),k] + r[pi,v(pi,j,Route,Ndict),k] + sum(t[pi,v(pi,j,Route,Ndict),k,n] for n in N) for k in N)
#                            - sum(d[pi,k,v(pi,j,Route,Ndict)] + r[pi,k,v(pi,j,Route,Ndict)] + sum(t[pi,k,v(pi,j,Route,Ndict),n] for n in N) for k in N)
#                            == z[pi,j-1] - z[pi,j])
    @constraint(sb, [pi=P,m=N,n=N; !in(pi,U(Node[m],Node[n],Route))], d[pi,m,n] == 0)
    @constraint(sb, [pi=P,m=N,k=N,n=N; !in(pi,U(Node[m],Node[k],Route))], t[pi,m,k,n] == 0)
    @constraint(sb, [pi=P,k=N,n=N; !in(pi,U(Node[k],Node[n],Route))], r[pi,k,n] == 0)
end



RP(model, CplexSolver())
EEV(model, CplexSolver())

Ndict['A']
Node[1]
in
!in(1,U(Node[1],Node[2],Route))

print(model)

writeSMPS(model)
=#
