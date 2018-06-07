function DCAPData(nR::Int, nN::Int, nT::Int, nS::Int, seed::Int)::DCAPData

    srand(seed)

    data = DCAPData()

    data.R = 1:nR
    data.N = 1:nN
    data.T = 1:nT
    data.S = 1:nS

    # generate data
    data.a = rand(nR, nT) * 5 + 5
    data.b = rand(nR, nT) * 40 + 10
    data.c = rand(nR, nN, nT, nS) * 5 + 5
    data.c0 = rand(nN, nT, nS) * 500 + 500
    data.d = rand(nN, nT, nS) + 0.5
    data.Pr = ones(nS)/nS

    return data
end
