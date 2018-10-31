mutable struct SMKPData

    # Sets
    I   # items
    J   # xz-knapsacks
    K   # xy-knapsacks
    Pr  # scenarios

    # Parameters
    A
    E
    T
    W
    b
    h
    c
    d
    q

    SMKPData() = new()
end

function SMKPData(nI::Int, nS::Int, seed::Int, nXZ::Int=NXZ, nXY::Int=NXY)::SMKPData

    Random.seed!(seed)
    data = SMKPData()

    # Sets
    data.I = 1:nI    # number of items
    data.J = 1:nXZ   # number of xz-knapsacks
    data.K = 1:nXY   # number of xy-knapsacks
    data.Pr = ones(nS)/nS

    # Parameters
    U = 1:100   # Uniform distribution parameter
    data.A = rand(U, nXZ, nI)
    data.E = rand(U, nXZ, nI)
    data.T = rand(U, nXY, nI)
    data.W = rand(U, nXY, nI)
    data.b = (3/4) * (data.A * ones(nI) + data.E * ones(nI))
    data.h = (3/4) * (data.T * ones(nI) + data.W * ones(nI))
    data.c = rand(U, 1, nI)
    data.d = rand(U, 1, nI)
    data.q = rand(U, nS, nI)

    return data
end
