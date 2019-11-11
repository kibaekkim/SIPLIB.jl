module ScenarioTree

using SparseArrays

export ScenTreeData, ModelData, add_node_to_tree, collect_leaf_node_ids

"""
    This implements a scenario tree representation of stochastic programming
    model, where each tree node represents a stage model for a given scenario
    realization.
"""

mutable struct ModelData
    mat::SparseMatrixCSC{Float64}
    rhs::Vector{Float64}
    sense::Vector{Char}
    obj::Vector{Float64}
    objsense::Symbol
    clbd::Vector{Float64}
    cubd::Vector{Float64}
    ctype::String
    cname::Vector{String}
end

mutable struct ScenTreeNode
    id::Int
    depth::Int

    parent::Union{ScenTreeNode, Nothing}
    children::Vector{ScenTreeNode}

    probability::Float64
    model::ModelData
end

mutable struct ScenTreeData
    root::ScenTreeNode
    node::Vector{ScenTreeNode}
    node_counter::Int
    num_stages::Int
    function ScenTreeData(root::ModelData, num_stages::Int)
        t = new()
        t.root = ScenTreeNode(1, 1, nothing, [], 1.0, root)
        t.node = [t.root]
        t.node_counter = 1
        t.num_stages = num_stages
        return t
    end
end

function add_node_to_tree(tree::ScenTreeData, parent::ScenTreeNode, 
        probability::Float64, model::ModelData)
    node = ScenTreeNode(tree.node_counter+1, parent.depth+1, parent, [], probability, model)
    push!(tree.node, node)
    push!(parent.children, node)
    tree.node_counter += 1
end

function collect_leaf_node_ids(tree::ScenTreeData)
    visited = falses(length(tree.node))
    ids = depth_first_search(tree.root, Int[], visited)
end

function depth_first_search(node::ScenTreeNode, leaf_ids::Vector{Int}, visited::BitArray)
    visited[node.id] = true

    if length(node.children) == 0
        push!(leaf_ids, node.id)
    else
        for c in node.children
            if visited[c.id] == false
                leaf_ids = depth_first_search(c, leaf_ids, visited)
            end
        end
    end

    return leaf_ids
end

end # module ScenarioTree
