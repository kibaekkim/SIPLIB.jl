include("./mptsps_types.jl")
using Distributions

function parse_nS(INSTANCE::String)
    str_nS = ""
    i = length(INSTANCE)
    while INSTANCE[i] != 'S'
        str_nS = string(INSTANCE[i], str_nS)
        i -= 1
    end
    return parse(Int64, str_nS)
end

function euclidean_distance(P1::Node, P2::Node)
    return sqrt((P1.x-P2.x)^2 + (P1.y-P2.y)^2)
end

function isCentral(center::Node, P::Node)::Bool
    central_radius = center.x/2
    return euclidean_distance(center, P) <= central_radius ? true : false
end

function generate_nodes(D::String, nN::Integer, radius::Float64=RADIUS)::Array{Node}    # N: number of nodes, D: node partition strategy

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

function generate_scenario_data(Nodes::Array{Node}, D::String, nN::Int, nS::Int, nK::Int=NK, radius::Float64=RADIUS, vc::Float64=VC, vs::Float64=VS)

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

function store_problem_data(DIR::String, Nodes::Array{Node}, Cs::Array{Float64,4}, D::String, nN::Int, nS::Int)

    prob_file = open("$DIR/prob.txt", "w")
    write(prob_file, "NAME MPTSPS_$(D)_$(nN)_$(nS)\n")
    write(prob_file, "COMMENT\n")
    write(prob_file, "TYPE MPTSPs\n")
    write(prob_file, "DIMENSION $nN\n")
    write(prob_file, "N_PATH $NK\n")
    write(prob_file, "EDGE_WEIGHT_TYPE : EXPLICIT\n")
    write(prob_file, "EDGE_DATA_FORMAT : EDGE_LIST\n")
    write(prob_file, "NODE_COORD_SECTION\n")

    for n in 1:nN
        write(prob_file, "$n $(Nodes[n].x) $(Nodes[n].y)\n")
    end

    Ce = Array{Float64}[]
    for i in 1:nN
        push!(Ce, Float64[])
        for j in 1:nN
             push!(Ce[i], sum(sum(Cs[s,i,j,:]) for s in 1:nS)*(1/NK)*(1/nS))
        end
    end

    write(prob_file, "EDGE_WEIGHT_SECTION\n")

    for i in 1:nN
        for j in 1:nN
            write(prob_file, "$i $j $(round(Int,Ce[i][j]))\n")
        end
    end

    write(prob_file, "EOF")
    close(prob_file)
end

function mptspsdata(INSTANCE::String)::MPTSPsModel

    nScenarios = parse_nS(INSTANCE)

    # Set paths
    cd(dirname(Base.source_path()))
    DATA_DIR = "../DATA"
    INSTANCE_DIR = "$DATA_DIR/$INSTANCE"  #

    tsp = MPTSPsModel()

    # ------------------------------------------
    # Read data files and set parameters on tsp
    # ------------------------------------------
    tsp.N = 1:readdlm("$INSTANCE_DIR/prob.txt")[4,2]
    tsp.K = 1:readdlm("$INSTANCE_DIR/prob.txt")[5,2]
    tsp.S = 1:nScenarios

    tsp.Cs = Array{Array{Array{Float64}}}[]
    for s in tsp.S
        SCENARIO_PATH = "$INSTANCE_DIR/Scenario$(s).dat"
        scenario_array = readdlm(SCENARIO_PATH)[2:end]
        C = Array{Array{Float64}}[]
        v = 1
        for i in tsp.N
            arr_1 = Array{Float64}[]
            for j in tsp.N
                arr_2 = Float64[]
                for k in tsp.K
                    push!(arr_2, scenario_array[v])
                    v += 1
                end
                push!(arr_1, arr_2)
            end
            push!(C, arr_1)
        end
        push!(tsp.Cs, C)
    end

    tsp.Ce = Array{Float64}[]
    for i in tsp.N
        push!(tsp.Ce, Float64[])
        for j in tsp.N
             push!(tsp.Ce[i], sum(sum(tsp.Cs[s][i][j][:]) for s in tsp.S)*(1/length(tsp.K))*(1/nScenarios))
        end
    end

    tsp.E = deepcopy(tsp.Cs)
    for s in tsp.S
        for i in tsp.N, j in tsp.N, k in tsp.K
            tsp.E[s][i][j][k] -= tsp.Ce[i][j]
        end
    end

    tsp.Pr = [1/nScenarios for s in tsp.S]

    return tsp
end


function mptspsdata_SIPLIB(nScenarios::Integer, INSTANCE::String)::MPTSPsModel

    # Set paths
    cd(dirname(Base.source_path()))
    DATA_DIR = "../DATA"
    INSTANCE_DIR = "$DATA_DIR/$INSTANCE"  #

    tsp = MPTSPsModel()

    # ------------------------------------------
    # Read data files and set parameters on tsp
    # ------------------------------------------
    tsp.N = 1:readdlm("$INSTANCE_DIR/prob.txt")[4,2]
    tsp.K = 1:readdlm("$INSTANCE_DIR/prob.txt")[5,2]
    tsp.S = 1:nScenarios

    tsp.Cs = Array{Array{Array{Float64}}}[]
    for s in tsp.S
        SCENARIO_PATH = "$INSTANCE_DIR/Scenario$(s).dat"
        scenario_array = readdlm(SCENARIO_PATH)[2:end]
        C = Array{Array{Float64}}[]
        v = 1
        for i in tsp.N
            arr_1 = Array{Float64}[]
            for j in tsp.N
                arr_2 = Float64[]
                for p in tsp.K
                    push!(arr_2, scenario_array[v])
                    v += 1
                end
                push!(arr_1, arr_2)
            end
            push!(C, arr_1)
        end
        push!(tsp.Cs, C)
    end

    tsp.Ce = Array{Float64}[]
    for i in tsp.N
        push!(tsp.Ce, Float64[])
        for j in tsp.N
             push!(tsp.Ce[i], sum(sum(tsp.Cs[s][i][j][:]) for s in tsp.S)*(1/length(tsp.K))*(1/nScenarios))
        end
    end

    tsp.E = deepcopy(tsp.Cs)
    for s in tsp.S
        for i in tsp.N, j in tsp.N, p in tsp.K
            tsp.E[s][i][j][p] -= tsp.Ce[i][j]
        end
    end

    tsp.Pr = [1/nScenarios for s in tsp.S]

    return tsp
end
