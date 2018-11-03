mutable struct MPTSPsData
    # Sets
    N   # set of nodes of the graph : i,j ∈ N
    K   # set of paths between the pair of nodes : p ∈ K
    S   # set of time scenarios : s ∈ S

    # Parameters
    Cs  # nonnegative unit random travel time cost under scenario s ∈ S : Cs[s][i][j][p]
    Ce  # nonnegative estimation of the mean unit travel time cost : Ce[i][j]
    E   # the error on the travel time cost estimated for the path k ∈ K under time scenario s ∈ S : E[s][i][j][p] ≡ Cs[s][i][j][p] - Ce[i][j]
    Pr  # probability distribution of scenario s ∈ S : Pr[s] ≡ 1/nScenario

    MPTSPsData() = new()
end

function MPTSPsData(d::String, nN::Int, nS::Int, seed::Int)::MPTSPsData

    data = MPTSPsData()

    data.N = 1:nN
    data.K = 1:NK
    data.S = 1:nS

    Nodes = generate_nodes(d, nN, seed)
    data.Cs = generate_scenario_data(Nodes, d, nN, nS, seed)
    data.Ce = Array{Float64}[]
    for i in data.N
        push!(data.Ce, Float64[])
        for j in data.N
             push!(data.Ce[i], sum(sum(data.Cs[s,i,j,:]) for s in data.S)*(1/length(data.K))*(1/nS))
        end
    end

    data.E = deepcopy(data.Cs)

    for s in data.S
        for i in data.N
            for j in data.N
                for k in data.K
                    data.E[s,i,j,k] -= data.Ce[i][j]
                end
            end
        end
    end

    data.Pr = [1/nS for s in data.S]

    return data
end

#####################################################
## Utility functions for generating MPTSPs data
#####################################################
mutable struct Node
    x::Float64
    y::Float64
    centrality::Bool
end

function euclidean_distance(P1::Node, P2::Node)
    return sqrt((P1.x-P2.x)^2 + (P1.y-P2.y)^2)
end

function isCentral(center::Node, P::Node)::Bool
    central_radius = center.x/2
    return euclidean_distance(center, P) <= central_radius ? true : false
end

function generate_nodes(d::String, nN::Int, seed::Int, radius::Float64=RADIUS)::Array{Node}    # nN: number of nodes, D: node partition strategy

    Random.seed!(seed)

    Nodes = Node[]
    center = Node(radius, radius, true)
    random_numbers = rand(Uniform(0.0, 2*radius), 2, 10000*nN)

    if d == "D0"
        n = 0
        cnt = 1
        while n < nN
            #temp = rand(Uniform(0.0, 2*radius),2)
            #rand_point = Node(temp[1],temp[2],false)
            temp = random_numbers[:,cnt]
            rand_point = Node(temp[1],temp[2],false)
            rand_point.centrality = isCentral(center, rand_point)
            if rand_point.centrality
                push!(Nodes, rand_point)
                n += 1
            end
            cnt += 1
        end
    elseif d == "D1"
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
    elseif d == "D2"
        cnt, n1, n2 = 0, 0, 0
        nN1, nN2 = Int(floor(nN*(3/4))), nN-Int(floor(nN*(3/4)))
        while n1 < nN1 || n2 < nN2
            #temp = rand(Uniform(0.0, 2*radius),2)
            temp = random_numbers[:,cnt+1]
            rand_point = Node(temp[1],temp[2],false)
            rand_point.centrality = isCentral(center, rand_point)
            if n1 < nN1 && rand_point.centrality
                push!(Nodes, rand_point)
                n1 += 1
            elseif n2 < nN2 && !rand_point.centrality
                push!(Nodes, rand_point)
                n2 += 1
            end
            cnt += 1
        end
    elseif d == "D3"
        cnt, n1, n2 = 0, 0, 0
        nN1, nN2 = Int(nN*(1/2)), nN-Int(nN*(1/2))
        while n1 < nN1 || n2 < nN2
            #temp = rand(Uniform(0.0, 2*radius),2)
            temp = random_numbers[:,cnt+1]
            rand_point = Node(temp[1],temp[2],false)
            rand_point.centrality = isCentral(center, rand_point)
            if n1 < nN1 && rand_point.centrality
                push!(Nodes, rand_point)
                n1 += 1
            elseif n2 < nN2 && !rand_point.centrality
                push!(Nodes, rand_point)
                n2 += 1
            end
            cnt += 1
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
end#

function generate_scenario_data(Nodes::Array{Node}, d::String, nN::Int, nS::Int, seed::Int, nK::Int=NK, radius::Float64=RADIUS, vc::Float64=VC, vs::Float64=VS)

    Random.seed!(seed)

    EC = calculate_euclidean_distances(Nodes)
    Cs = zeros(nS, nN, nN, nK)
    random_numbers_1 = rand(Uniform(vc/2,2*vc), nS, nN, nN, nK)
    random_numbers_2 = rand(Uniform(vc/2,2*vs), nS, nN, nN, nK)

    for s in 1:nS
        for i in 1:nN
            for j in i+1:nN
                if i != j
                    if Nodes[i].centrality == Nodes[j].centrality
                        if Nodes[i].centrality
                            for k in 1:nK
                                #Cs[s,i,j,k] = EC[i,j]/rand(Uniform(vc/2,2*vc))
                                Cs[s,i,j,k] = EC[i,j]/random_numbers_1[s,i,j,k]
                                Cs[s,j,i,k] = Cs[s,i,j,k]
                            end
                        elseif !Nodes[i].centrality
                            for k in 1:nK
                                #Cs[s,i,j,k] = EC[i,j]/rand(Uniform(vs/2,2*vs))
                                Cs[s,i,j,k] = EC[i,j]/random_numbers_2[s,i,j,k]
                                Cs[s,j,i,k] = Cs[s,i,j,k]
                            end
                        end
                    elseif Nodes[i].centrality != Nodes[j].centrality
                        for k in 1:Int(ceil(nK/3))
                            #Cs[s,i,j,k] = EC[i,j]/rand(Uniform(vc/2,2*vc))
                            Cs[s,i,j,k] = EC[i,j]/random_numbers_1[s,i,j,k]
                            Cs[s,j,i,k] = Cs[s,i,j,k]
                        end
                        for k in Int(ceil(nK/3))+1:nK
                            #Cs[s,i,j,k] = EC[i,j]/rand(Uniform(vs/2,2*vs))
                            Cs[s,i,j,k] = EC[i,j]/random_numbers_2[s,i,j,k]
                            Cs[s,j,i,k] = Cs[s,i,j,k]
                        end
                    end
                end
            end
        end
    end

    return 3600*Cs
end


function store_scenario_data(DIR::String, Cs::Array{Float64,4}, d, nN, nS)

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
