using .ScenarioTree
using .SMPS

using JuMP
using MathOptInterface
using StructJuMP
using SparseArrays
using Printf

const SJ = StructJuMP
const MOI = MathOptInterface

sense_from_moi(set::MOI.LessThan) = 'L'
sense_from_moi(set::MOI.GreaterThan) = 'G'
sense_from_moi(set::MOI.EqualTo) = 'E'
sense_from_moi(set::MOI.Interval) = 'L'

rhs_from_moi(set::MOI.LessThan) = set.upper
rhs_from_moi(set::MOI.GreaterThan) = set.lower
rhs_from_moi(set::MOI.EqualTo) = set.value
rhs_from_moi(set::MOI.Interval) = set.upper

function write_smps(m::StructuredModel,
        INSTANCE_NAME::String="noname", DIR_NAME::String=".";
        smpsfile::Bool=false)

    println("Reading all data from StructJuMP model")
    @info("Only two-stage models are supported with StructJuMP.")

    nodeid = 1

    tree = ScenTreeData(get_model_data(m), 2)

    # get the second-stage model
    nscen = SJ.num_scenarios(m)
    for i = 1:nscen
        add_node_to_tree(tree, tree.root, SJ.getprobability(m)[i],
            get_model_data(SJ.getchildren(m)[i]))
    end

    nrows1, ncols1 = size(tree.root.model.mat)
    nrows2, ncols  = size(tree.root.children[1].model.mat)
    ncols2 = ncols - ncols1
    @printf("  Number of scenarios: %d\n", nscen)
    @printf("   First stage: vars (%d), cons (%d)\n", ncols1, nrows1)
    @printf("  Second stage: vars (%d), cons (%d)\n", ncols2, nrows2)
    @printf("      In total: vars (%d), cons (%d)\n", ncols1 + ncols2*nscen, nrows1 + nrows2*nscen)

    SMPS.write(tree, INSTANCE_NAME, DIR_NAME, smpsfile=smpsfile)
end

function get_model_data(m::StructuredModel)::ModelData

    # Get a column-wise sparse matrix
    mat, rhs, sense = get_constraint_matrix(m)

    # column information
    clbd = Vector{Float64}(undef, num_variables(m))
    cubd = Vector{Float64}(undef, num_variables(m))
    ctype = ""
    cname = Vector{String}(undef, num_variables(m))
    for i in 1:num_variables(m)
        vref = SJ.StructuredVariableRef(m, i)
        v = m.variables[vref.idx]
        if v.info.integer
            ctype = ctype * "I"
        elseif v.info.binary
            ctype = ctype * "B"
        else
            ctype = ctype * "C"
        end
        clbd[vref.idx] = v.info.has_lb ? v.info.lower_bound : -Inf
        cubd[vref.idx] = v.info.has_ub ? v.info.upper_bound : Inf
        cname[vref.idx] = m.varnames[vref.idx]
    end

    # objective coefficients
    obj = zeros(num_variables(m))
    for (v,coef) in objective_function(m).terms
        obj[v.idx] = coef
    end

    objsense = objective_sense(m) == MOI.MIN_SENSE ? :Min : :Max

    return ModelData(mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)
end

function get_constraint_matrix(m::StructuredModel)

    is_parent = SJ.getparent(m) == nothing ? true : false

    num_rows = 0 # need to count
    num_cols = num_variables(m)
    if !is_parent
        num_cols += num_variables(SJ.getparent(m))
    end

    # count the number of nonzero elements
    nnz = 0
    for (i,cons) in m.constraints
        nnz += length(cons.func.terms)
        num_rows += 1
    end

    rind = Vector{Int}(undef, nnz)
    cind = Vector{Int}(undef, nnz)
    value = Vector{Float64}(undef, nnz)
    rhs = Vector{Float64}(undef, num_rows)
    sense = Vector{Char}(undef, num_rows)

    pos = 1
    for (i,cons) in m.constraints
        for (var,coef) in cons.func.terms
            rind[pos] = i
            if is_parent
                cind[pos] = var.idx
            elseif JuMP.owner_model(var) == SJ.getparent(m)
                cind[pos] = var.idx
            else
                cind[pos] = var.idx + num_variables(SJ.getparent(m))
            end
            value[pos] = coef
            pos += 1
        end

        # rhs and sense
        rhs[i] = rhs_from_moi(cons.set)
        sense[i] = sense_from_moi(cons.set)
    end
    @assert(pos-1==nnz)

    return sparse(rind, cind, value, num_rows, num_cols), rhs, sense
end
