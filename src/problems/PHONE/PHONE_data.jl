mutable struct PHONEData

    # Sets
    P   # set of point-to-point pairs, i ∈ P
    E   # set of edges (links), j ∈ E
    R   # set of routes for each point-to-point pair, r ∈ R(i)
    S   # set of scenarios : s ∈ S

    # Parameters
    a   # incidence matrix (i.e., a[i,r,j] = 1 if link j ∈ R(i))
    e   # initial capacity of the network
    d   # demand on each pair
    Pr

    PHONEData() = new()
end

function PHONEData(nS::Int, seed::Int=1)::PHONEData

    # helper function to enumerate all routes
    function next_possible_dest(v::Int, traj::Array{Int}, adjacency_matrix::Array{Float64,2})
        npd = []
        for j in 1:size(adjacency_matrix)[1]
            if adjacency_matrix[v,j] != 0.0 && !in(j, traj)
                push!(npd,j)
            end
        end
        return npd
    end

    # helper function to enumerate all routes (recursive)
    function allroutes(s::Int, d::Int, a::Array{Float64,2}, traj::Array{Int}, route_array::Array{Array{Int}})
        # set the source node
        if isempty(traj)
            push!(traj,s)
        end
        # recurse
        for node in next_possible_dest(s,traj,adjacency_matrix)
            if node == d
                push!(route_array, append!(copy(traj),node))
            else !isempty(next_possible_dest(node,traj,adjacency_matrix))
                allroutes(node, d, a, append!(copy(traj),node), route_array)
            end
        end
        return route_array
    end

    # helper function to save a dictionary for edge index
    function getEdgeIndexDict(file_array::Array{Any,2})
        dict = Dict{Tuple{Int,Int},Int}()
        for j in 1:size(file_array)[1]
            dict[(file_array[j,2],file_array[j,3])] = file_array[j,1]
            dict[(file_array[j,3],file_array[j,2])] = file_array[j,1]
        end
        return dict
    end

    srand(seed)
    data = PHONEData()

    # ---------------------------------------------
    # Read files and set parameters on data
    # ---------------------------------------------
    DATA_PATH = "$(dirname(@__FILE__))/DATA/initial_capacity.csv"
    data.e = readdlm(DATA_PATH, ',')[2:end,2]

    DATA_PATH = "$(dirname(@__FILE__))/DATA/adjacency_matrix.csv"
    adjacency_matrix = readdlm(DATA_PATH, ',')

    DATA_PATH = "$(dirname(@__FILE__))/DATA/edge_index.csv"
    file_array = readdlm(DATA_PATH, ',')[2:end,:]

    data.P = collect(Combinatorics.combinations(1:size(adjacency_matrix)[1],2))
    data.E = [[file_array[j,2],file_array[j,3]] for j in 1:size(file_array)[1]]
    data.R = [allroutes(pair[1],pair[2],adjacency_matrix,Int[],Array{Int}[]) for pair in data.P]
    data.S = 1:nS
    data.Pr = ones(nS)/nS
    data.d = rand(Uniform(1.0,9.9),length(data.P),nS)
    data.a = []
    edge_index = getEdgeIndexDict(file_array)
    for i in 1:length(data.P)
        push!(data.a, [])
        for r in 1:length(data.R[i])
            incidence = [0 for j in 1:length(data.E)]
            for start_node in 1:length(data.R[i][r])-1
                node1 = data.R[i][r][start_node]
                node2 = data.R[i][r][start_node+1]
                incidence[edge_index[(node1,node2)]]=1
            end
            push!(data.a[end],incidence)
        end
    end

    return data
end
