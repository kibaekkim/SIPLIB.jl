mutable struct SSLPData

    # Sets
    J
    I
    S
    Z

    # Parameters
    c
    q
    q0
    d
    u
    v
    w
    Jz
    h
    Pr

    SSLPData() = new()
end

function SSLPData(nJ::Int, nI::Int, nS::Int, seed::Int)::SSLPData

    srand(seed)
    data = SSLPData()

    data.J = 1:nJ
    data.I = 1:nI
    data.S = 1:nS
    data.Z = []

    data.c = rand(40:80,nJ)
    data.q = rand(0:25,nI,nJ)
    data.q0 = ones(nJ)*1000
    data.d = data.q
    data.u = 1.5*sum(data.d)/nJ
    data.v = nJ
    data.w = NaN
    data.Jz = []
    data.h = rand(0:1,nI,nS)
    data.Pr = ones(nS)/nS

    return data
end
