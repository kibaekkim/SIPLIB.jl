include("./mptsps_types.jl")
using Distributions

function euclidean_distance(P1::Node, P2::Node)
    return sqrt((P1.x-P2.x)^2 + (P1.y-P2.y)^2)
end

function isCentral(center::Node, P::Node)::Bool
    central_radius = center.x/2
    return euclidean_distance(center, P) <= central_radius ? true : false
end

function generate_nodes(D::String, nN::Int, seed::Int, radius::Float64=RADIUS)::Array{Node}    # nN: number of nodes, D: node partition strategy

    rand(seed)

    Nodes = Node[]
    center = Node(radius, radius, true)

    if D == "D0"
        n = 0
        while n < nN
            temp = rand(Uniform(0.0, 2*radius),2)
            rand_point = Node(temp[1],temp[2],false)
            rand_point.centrality = isCentral(center, rand_point)
            if rand_point.centrality
                push!(Nodes, rand_point)
                n += 1
            end
        end
    elseif D == "D1"
        n = 0
        while n < nN
            temp = rand(Uniform(0.0, 2*radius),2)
            rand_point = Node(temp[1],temp[2],false)
            rand_point.centrality = isCentral(center, rand_point)
            if !rand_point.centrality
                push!(Nodes, rand_point)
                n += 1
            end
        end
    elseif D == "D2"
        n1, n2 = 0, 0
        nN1, nN2 = Int(floor(nN*(3/4))), nN-Int(floor(nN*(3/4)))
        while n1 < nN1 || n2 < nN2
            temp = rand(Uniform(0.0, 2*radius),2)
            rand_point = Node(temp[1],temp[2],false)
            rand_point.centrality = isCentral(center, rand_point)
            if n1 < nN1 && rand_point.centrality
                push!(Nodes, rand_point)
                n1 += 1
            elseif n2 < nN2 && !rand_point.centrality
                push!(Nodes, rand_point)
                n2 += 1
            end
        end
    elseif D == "D3"
        n1, n2 = 0, 0
        nN1, nN2 = Int(nN*(1/2)), nN-Int(nN*(1/2))
        while n1 < nN1 || n2 < nN2
            temp = rand(Uniform(0.0, 2*radius),2)
            rand_point = Node(temp[1],temp[2],false)
            rand_point.centrality = isCentral(center, rand_point)
            if n1 < nN1 && rand_point.centrality
                push!(Nodes, rand_point)
                n1 += 1
            elseif n2 < nN2 && !rand_point.centrality
                push!(Nodes, rand_point)
                n2 += 1
            end
        end
    end

    return Nodes
end

function calculate_euclidean_distances(Nodes::Array{Node})::Matrix{Float64}

    nN = length(Nodes)
    EC = zeros(nN,nN)

    for i in 1:nN
        for j in i+1:nN
            if i != j
                EC[i,j] = euclidean_distance(Nodes[i], Nodes[j])
                EC[j,i] = EC[i,j]
            end
        end
    end

    return EC
end

function generate_scenario_data(Nodes::Array{Node}, D::String, nN::Int, nS::Int, seed::Int, nK::Int=NK, radius::Float64=RADIUS, vc::Float64=VC, vs::Float64=VS)

    rand(seed)

    EC = calculate_euclidean_distances(Nodes)
    Cs = zeros(nS, nN, nN, nK)

    for s in 1:nS
        for i in 1:nN
            for j in i+1:nN
                if i != j
                    if Nodes[i].centrality == Nodes[j].centrality
                        if Nodes[i].centrality
                            for k in 1:nK
                                Cs[s,i,j,k] = EC[i,j]/rand(Uniform(vc/2,2*vc))
                                Cs[s,j,i,k] = Cs[s,i,j,k]
                            end
                        elseif !Nodes[i].centrality
                            for k in 1:nK
                                Cs[s,i,j,k] = EC[i,j]/rand(Uniform(vs/2,2*vs))
                                Cs[s,j,i,k] = Cs[s,i,j,k]
                            end
                        end
                    elseif Nodes[i].centrality != Nodes[j].centrality
                        for k in 1:Int(ceil(nK/3))
                            Cs[s,i,j,k] = EC[i,j]/rand(Uniform(vc/2,2*vc))
                            Cs[s,j,i,k] = Cs[s,i,j,k]
                        end
                        for k in Int(ceil(nK/3))+1:nK
                            Cs[s,i,j,k] = EC[i,j]/rand(Uniform(vs/2,2*vs))
                            Cs[s,j,i,k] = Cs[s,i,j,k]
                        end
                    end
                end
            end
        end
    end

    return 3600*Cs
end

function store_scenario_data(DIR::String, Cs::Array{Float64,4}, D, nN, nS)

    for s in 1:nS
        scenario_file = open("$DIR/Scenario$(s).dat", "w")
        write(scenario_file, "C_ijk\n")
        for i in 1:nN
            for j in 1:nN
                for k in 1:NK
                    write(scenario_file, "$(Int(round(Cs[s,i,j,k])))\n")
                end
            end
        end
        close(scenario_file)
    end
end

function mptspsdata(D::String, nN::Int, nS::Int, seed::Int)::MPTSPsModel

    tsp = MPTSPsModel()
    tsp.N = 1:nN
    tsp.K = 1:NK
    tsp.S = 1:nS

    Nodes = generate_nodes(D, nN, seed)
    tsp.Cs = generate_scenario_data(Nodes, D, nN, nS, seed)
    tsp.Ce = Array{Float64}[]
    for i in tsp.N
        push!(tsp.Ce, Float64[])
        for j in tsp.N
             push!(tsp.Ce[i], sum(sum(tsp.Cs[s,i,j,:]) for s in tsp.S)*(1/length(tsp.K))*(1/nS))
        end
    end

    tsp.E = deepcopy(tsp.Cs)
    for s in tsp.S
        for i in tsp.N, j in tsp.N, k in tsp.K
            tsp.E[s,i,j,] -= tsp.Ce[i][j]
        end
    end

    tsp.Pr = [1/nS for s in tsp.S]

    return tsp
end
