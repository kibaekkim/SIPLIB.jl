module SMPS

using ..ScenarioTree

using SparseArrays
using Printf

export write

"""
    writeSMPS(model::JuMP.Model, INSTANCE_NAME::String, DIR_NAME::String; smpsfile::Bool)

model (necessary, positional): JuMP.Model-type object input.
INSTANCE_NAME (optional, positional): Name of the instance (DEFAULT: "instance")
DIR_NAME (optional, positional): The path in which SMPS files are stored. (DEFAULT: "../instance/")
genericnames (optional, keyword): 'true' if you want to let Siplib automatically generate: VAR1, VAR2, ... . 'false' if you want to maintain the original (readable) variable names. (DEFAULT: true)
splice (optional, keyword): 'true' then data in the model is spliced after writing SMPS files so you cannot re-use the object. 'false' if you want to re-use the JuMP.Model object.  (DEFAULT: true)
smpsfile (optional, keyword): 'true' if you want to generate .smps file together (for SCIP 6.0).

"""

function write(scendata::ScenTreeData,
        INSTANCE_NAME::String="noname", DIR_NAME::String=".";
        smpsfile::Bool=false)

    FILE_NAME = "$DIR_NAME/$INSTANCE_NAME"
    @info("Writing SMPS files for $INSTANCE_NAME")

    # Write .cor file && Store core data
    mdata_core = writeCore(FILE_NAME, scendata)

    # Write .tim and .sto files
    writeTime(FILE_NAME, scendata)
    writeStoc(FILE_NAME, scendata, mdata_core)
    
    # Generate .smps file if smpsfile == true
    if smpsfile == true
        fp_smps = open("$FILE_NAME.smps", "w")
        println(fp_smps, "$INSTANCE_NAME.cor")
        println(fp_smps, "$INSTANCE_NAME.tim")
        println(fp_smps, "$INSTANCE_NAME.sto")
        close(fp_smps)
    end

    return
end

function writeCore(FILE_NAME, scendata::ScenTreeData)::ModelData

    if length(scendata.root.children) == 0
        @error("Scenario tree does not have any scenario.")
    end

    @info("Writing core file ... ")

    # get the root and its child nodes
    root = scendata.root.model

    # The objective sense should be global.
    objsense = root.objsense

    node = scendata.root
    obj = node.model.obj; rhs = node.model.rhs; sense = node.model.sense;
    clbd = node.model.clbd; cubd = node.model.cubd;
    ctype = node.model.ctype; cname = node.model.cname;
    mat = node.model.mat;

    while length(node.children) > 0
        node = collect(values(node.children))[1]
        nodedata = node.model

        nrows_core, ncols_core = size(mat)
        nrows_child, ncols_child = size(nodedata.mat)

        obj = [obj; nodedata.obj]
        rhs = [rhs ; nodedata.rhs]
        sense = [sense; nodedata.sense]
        clbd = [clbd; nodedata.clbd]
        cubd = [cubd; nodedata.cubd]
        ctype = ctype * nodedata.ctype
        cname = [cname; nodedata.cname]    # for column name
        mat = [[mat zeros(nrows_core, ncols_child-ncols_core)] ; nodedata.mat]
    end

    # TODO: Do we need to reserve space for nonzero elements?

    core = ModelData(mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)

    writeMPS(FILE_NAME, core, ext="cor")

    return core
end

# general purpose MPS writing function (e.g., writing .cor file)
function writeMPS(FILE_NAME, mdata::ModelData; ext="mps")

    mat = mdata.mat; rhs = mdata.rhs; sense = mdata.sense;
    obj = mdata.obj; objsense = mdata.objsense;
    clbd = mdata.clbd; cubd = mdata.cubd; ctype = mdata.ctype; cname = mdata.cname

    nrows, ncols = size(mat)
    if objsense == :Max
        obj *= -1
        @info("The problem is converted to minimization problem.")
    end

    # .mps file
    fp = open("$FILE_NAME.$ext", "w")

    # 123456789 123456789
    println(fp, "NAME          $(basename(FILE_NAME))")

    @info("Generic names (e.g., CON1, CON2) are used for constraints.")
    println(fp, "ROWS")
    println(fp, " N  OBJ")
    for i in 1:nrows
        @printf(fp, " %s  CON%d\n", sense[i], i)
    end

    marker_started = false
    mat_rows = rowvals(mat)
    mat_vals = nonzeros(mat)

    println(fp, "COLUMNS")
    for j in 1:ncols

        if !marker_started && in(ctype[j], "BI")
            @printf(fp,"    MARKER    'MARKER'                'INTORG'\n")
            marker_started = true
        end

        if abs(obj[j]) > 0 || length(nzrange(mat,j)) > 0
            # @printf(fp, "    %-8s", "VAR"*string(j))
            @printf(fp, "    %-8s", cname[j])
            pos = 1
            if abs(obj[j]) > 0
                @printf(fp, "  %-8s", "OBJ")
                @printf(fp, "  %-12f", obj[j])
                pos += 1
            end

            for i in nzrange(mat,j)
                if pos >= 3
                    @printf(fp, "\n    %-8s", cname[j])
                    pos = 1
                end
                @printf(fp, "  %-8s", "CON"*string(mat_rows[i]))
                @printf(fp, "  %-12f", mat_vals[i])
                pos += 1
            end
            @printf(fp, "\n")
        else # abs(obj[j]) == 0 && length(nzrange(mat,j)) == 0
            @info("The JuMP model contains unused variable. Remove this to reduce file size.")
            # @printf(fp, "    %-8s", "VAR"*string(j))
            @printf(fp, "    %-8s", cname[j])
            @printf(fp, "  %-8s", "OBJ")
            @printf(fp, "  %-12f", 0)
            @printf(fp, "\n")
        end

        if marker_started
            if j == ncols || !in(ctype[j+1], "BI")
                #@printf(fp, "    %-8s  %-8s  %-12s\n", "MARKER", "'MARKER'", "'INTEND'")
                @printf(fp,"    MARKER    'MARKER'                 'INTEND'\n")
                marker_started = false
            end
        end
    end

    println(fp, "RHS")
    pos = 1
    @printf(fp, "    %-8s", "RHS")
    for i in 1:nrows
        if isapprox(rhs[i], 0)
            continue
        end
        if pos >= 3
            @printf(fp, "\n    %-8s", "RHS")
            pos = 1
        end
        @printf(fp, "  %-8s", "CON"*string(i))
        @printf(fp, "  %-12f", rhs[i])
        pos += 1
    end
    @printf(fp, "\n")

    println(fp, "BOUNDS")

    for j in 1:ncols
        # integer
        if ctype[j] == 'I'
            if clbd[j] <= -Inf
                if cubd[j] >= Inf
                    @printf(fp, " FR %-8s  %-8s\n", "BOUND", cname[j])
                else # cubd[j] < Inf
                    @printf(fp, " MI %-8s  %-8s\n", "BOUND", cname[j])
                    @printf(fp, " UI %-8s  %-8s  %-12f\n", "BOUND", cname[j], cubd[j])
                end
            elseif clbd[j] == 0
                if cubd[j] >= Inf
                    @printf(fp, " LI %-8s  %-8s  %-12f\n", "BOUND", cname[j], 0)
                else # cubd[j] < Inf
                    @printf(fp, " UI %-8s  %-8s  %-12f\n", "BOUND", cname[j], cubd[j])
                end
            else # clbd[j] > -Inf
                @printf(fp, " LI %-8s  %-8s  %-12f\n", "BOUND", cname[j], clbd[j])
                if cubd[j] < Inf
                    @printf(fp, " UI %-8s  %-8s  %-12f\n", "BOUND", cname[j], cubd[j])
                end
            end
            continue
        end

        # binary
        if ctype[j] == 'B'
            @printf(fp, " BV %-8s  %-8s\n", "BOUND", cname[j])
            continue
        end

        if clbd[j] == cubd[j]
            @printf(fp, " FX %-8s  %-8s  %-12f\n", "BOUND", cname[j], clbd[j])
            continue
        end

        if clbd[j] <= -Inf
            if cubd[j] >= Inf
                @printf(fp, " FR %-8s  %-8s\n", "BOUND", cname[j])
            else
                @printf(fp, " MI %-8s  %-8s\n", "BOUND", cname[j])
                if cubd[j] != 0
                    @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", cname[j], cubd[j])
                end
            end
        elseif clbd[j] == 0
            # cubd[j] >= Inf is default.
            if cubd[j] < Inf
                @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", cname[j], cubd[j])
            end
        else # clbd[j] > -Inf
            @printf(fp, " LO %-8s  %-8s  %-12f\n", "BOUND", cname[j], clbd[j])
            if cubd[j] < Inf
                @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", cname[j], cubd[j])
            end
        end
    end
    println(fp, "ENDATA")
    close(fp)
end

#function writeTime(FILE_NAME, mdata1::ModelData, genericnames::Bool=true)
function writeTime(FILE_NAME, scendata::ScenTreeData)

    @info("Writing time file ... ")

    fp = open("$FILE_NAME.tim", "w")

    #            123456789 123456789
    println(fp, "TIME          ", basename(FILE_NAME))
    println(fp, "PERIODS       IMPLICIT")

    node = scendata.root
    @printf(fp, "    %-8s  %-8s  PERIOD1\n", node.model.cname[1], "CON1")
    while length(node.children) > 0
        start_cons = size(node.model.mat, 1) + 1
        node = node.children[1]
        @printf(fp, "    %-8s  %-8s  PERIOD2\n", node.model.cname[1], "CON$(start_cons)")
    end

    println(fp, "ENDATA")

    close(fp)
end

function writeStoc(FILE_NAME, tree::ScenTreeData, core::ModelData)

    @info("Writing stochastic file ... ")
    @info("Scenario tree has $(tree.num_stages) stages.")

    # Create a set of leaf nodes by depth-first-search
    leaf_node_ids = collect_leaf_node_ids(tree)
    @info("Found $(length(leaf_node_ids)) scenarios in the scenario tree")

    # Create the first scenario path from the first leaf node
    scen_path = Vector{Int}(undef, tree.num_stages)
    first_leaf_id = leaf_node_ids[1]
    leaf = tree.node[first_leaf_id]
    for t in 1:tree.num_stages
        scen_path[tree.num_stages-t+1] = leaf.id
        leaf = leaf.parent
    end

    # row/column start index for each stage
    rstart = Vector{Int}(undef, tree.num_stages)
    cstart = Vector{Int}(undef, tree.num_stages)
    rstart[1] = 1; cstart[1] = 1
    for stage in 2:tree.num_stages
        rstart[stage] = rstart[stage-1] + length(tree.node[scen_path[stage-1]].model.rhs)
        cstart[stage] = cstart[stage-1] + length(tree.node[scen_path[stage-1]].model.clbd)
    end

    fp = open("$FILE_NAME.sto", "w")

    #            123456789 123456789
    println(fp, "STOCH         ", basename(FILE_NAME))
    println(fp, "SCENARIOS")

    # This assumes that the leaf nodes are added in a certain order.
    for (scen,leaf_id) in enumerate(leaf_node_ids)

        # get the current node and the stage
        node = tree.node[leaf_id]
        t = tree.num_stages

        while (node.id != scen_path[t])
            scen_path[t] = node.id
            node = node.parent
            t -= 1
        end

        # find branch stage
        branch_stage = scen == 1 ? t : t + 1

        # find parent scenario
        parent_scenario = scen - 1

        # calculate probability
        probability = 1.0
        for stage in 2:tree.num_stages
            probability *= tree.node[scen_path[stage]].probability
        end

        @info("Writing scenario path: $(scen_path) with probability $probability")

        # write stochastic data
        @printf(fp, " SC %-8s  %-8s  %-8f  PERIOD%d\n",
            "SCEN_"*string(scen),
            parent_scenario == 0 ? "'ROOT'" : "SCEN_" * string(parent_scenario),
            probability, branch_stage)

        # ROWS
        for stage in branch_stage:tree.num_stages
            for (i,v) in enumerate(tree.node[scen_path[stage]].model.rhs)
                if v != core.rhs[rstart[stage]+i-1]
                    @printf(fp, "    %-8s  %-8s  %-12f\n", 
                        "RHS", "CON"*string(rstart[stage]+i-1), v)
                    core.rhs[rstart[stage]+i-1] = v
                end
            end
        end

        # COLUMNS (OBJ)
        for stage in branch_stage:tree.num_stages
            for (i,v) in enumerate(tree.node[scen_path[stage]].model.obj)
                if v != core.obj[cstart[stage]+i-1]
                    @printf(fp, "    %-8s  %-8s  %-12f\n", core.cname[cstart[stage]+i-1], "OBJ", v)
                    core.obj[cstart[stage]+i-1] = v
                end
            end
        end

        # COLUMNS (CON)
        mod_I = Vector{Int}() 
        mod_J = Vector{Int}()
        mod_V = Vector{Float64}()
        rows_core = rowvals(core.mat)
        vals_core = nonzeros(core.mat)
        # @show core.mat
        for stage in branch_stage:tree.num_stages
            mat_scen = tree.node[scen_path[stage]].model.mat
            # @show (stage,mat_scen)
            rows = rowvals(mat_scen)
            vals = nonzeros(mat_scen)
            nrows_scen, ncols_scen = size(mat_scen)
            for j in 1:ncols_scen
                for i in nzrange(mat_scen, j)
                    if core.mat[rstart[stage]+rows[i]-1,j] != vals[i]
                        push!(mod_I, rstart[stage]+rows[i]-1)
                        push!(mod_J, j)
                        push!(mod_V, vals[i])
                    end
                end
                # for i in nzrange(core.mat, j)
                #     if rows_core[i]-rstart[stage]+1 > 0 &&
                #         rows_core[i]-rstart[stage]+1 <= nrows_scen &&
                #         mat_scen[rows_core[i]-rstart[stage]+1,j] != vals_core[i]

                #         push!(mod_I, rows_core[i])
                #         push!(mod_J, j)
                #         push!(mod_V, vals_core[i])
                #     end
                # end
            end
            # for (n,i) in enumerate(mod_I)
            #     @show (mod_I[n],mod_J[n],mod_V[n])
            # end
        end

        core_mod = sparse(mod_I, mod_J, mod_V)
        rows_mod = rowvals(core_mod)
        vals_mod = nonzeros(core_mod)
        nrows_mod, ncols_mod = size(core_mod)
        for j in 1:ncols_mod, i in nzrange(core_mod, j)
            @printf(fp, "    %-8s  %-8s  %-12f\n", 
                core.cname[j], "CON"*string(rows_mod[i]), vals_mod[i])
            core.mat[rows_mod[i],j] = vals_mod[i]
        end
    end
    @info("End of stochastic file")
    
    println(fp, "ENDATA")

    close(fp)
end

#=
function getSingleScenarioModelData(mdata_all::Array{ModelData}, s::Int)::ModelData

    # get # of first-stage rows and columns
    nrows1, ncols1 = size(mdata_all[1].mat)

    # get # of rows and columns for the scenario block
    nrows2, ncols = size(mdata_all[s+1].mat)
    ncols2 = ncols - ncols1

    # core data (includes 1st stage & 2nd stage's s-th scenario data)
    objsense = mdata_all[1].objsense
    obj      = [mdata_all[1].obj  ; mdata_all[s+1].obj]
    rhs      = [mdata_all[1].rhs  ; mdata_all[s+1].rhs]
    sense    = [mdata_all[1].sense; mdata_all[s+1].sense]
    clbd     = [mdata_all[1].clbd ; mdata_all[s+1].clbd]
    cubd     = [mdata_all[1].cubd ; mdata_all[s+1].cubd]
    ctype    = mdata_all[1].ctype * mdata_all[s+1].ctype
    cname    = [mdata_all[1].cname ; mdata_all[s+1].cname]    # for column name
    mat      = [[mdata_all[1].mat zeros(nrows1, ncols-ncols1)] ; mdata_all[s+1].mat]

    return ModelData(mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)
end

function getExpectedValueModelData(mdata_all::Array{ModelData}, roundRHS::Bool)::ModelData
    # save the number of scenarios
    nS = length(mdata_all)-1

    m1 = mdata_all[1]
    m2 = mdata_all[2]
    avg_mat = m2.mat
    avg_rhs = m2.rhs
    avg_obj = m2.obj
    avg_clbd = m2.clbd
    avg_cubd = m2.cubd
    for s in 2:nS
        avg_mat += mdata_all[s+1].mat
        avg_rhs += mdata_all[s+1].rhs
        avg_obj += mdata_all[s+1].obj
        avg_clbd += mdata_all[s+1].clbd
        avg_cubd += mdata_all[s+1].cubd
    end

    avg_mat = avg_mat/nS
    avg_obj = avg_obj/nS
    avg_rhs = avg_rhs/nS
    avg_clbd = avg_clbd/nS
    avg_cubd = avg_cubd/nS

    # get # of first-stage rows and columns
    nrows1, ncols1 = size(m1.mat)

    # get # of rows and columns for the scenario block
    nrows2, ncols = size(m2.mat)
    ncols2 = ncols - ncols1

    # core data (includes 1st stage & 2nd stage's s-th scenario data)
    objsense = m1.objsense
    obj      = [m1.obj  ; avg_obj]
    rhs      = [m1.rhs  ; avg_rhs]
    sense    = [m1.sense; m2.sense]
    clbd     = [m1.clbd ; avg_clbd]
    cubd     = [m1.cubd ; avg_cubd]
    ctype    = m1.ctype * m2.ctype
    cname    = [m1.cname ; m2.cname]    # for column name
    mat      = [[m1.mat zeros(nrows1, ncols2)] ; avg_mat]

    if !roundRHS
        return ModelData(mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)
    else
        return ModelData(mat, round.(rhs), sense, obj, objsense, clbd, cubd, ctype, cname)
    end
end

writeMPS(FILE_NAME, INSTANCE_NAME, mdata::ModelData) = writeMPS(FILE_NAME, INSTANCE_NAME, mdata.mat, mdata.rhs, mdata.sense, mdata.obj, mdata.objsense, mdata.clbd, mdata.cubd, mdata.ctype, mdata.cname)

# MPS writer (+ dec file) for a stochastic model instance
function writeMPS(m::JuMP.Model,
        INSTANCE_NAME::String="noname",
        DIR_NAME::String=".";
        decfile::Bool=false)

    # check if model is stochastic (or structured) model
    if !haskey(m.ext, :Stochastic)
        @warn("Not a stochastic model.")
        return
    end

    FILE_NAME = "$DIR_NAME/$INSTANCE_NAME"

    if !decfile
        println("Writing MPS file for $INSTANCE_NAME")
    else
        println("Writing MPS with .dec file for $INSTANCE_NAME")
    end

    # Check if m is a StructJuMP model
    if !haskey(m.ext, :Stochastic)
        mps_model = MathOptFormat.MPS.Model()
        MOI.copy_to(mps_model, backend(m))
        MOI.write_to_file(mps_model, "$FILE_NAME.mps")
        @warn("This is not a stochastic model. $FILE_NAME.mps is generated.")
        return
    end

    # Extract and store StructJuMP model data
    mdata_all = getStructModelData(m, genericnames, splice)

    # Calculate dimensions
    nrows1, ncols1 = size(mdata_all[1].mat)
    nrows2, ncols = size(mdata_all[2].mat)
    ncols2 = ncols - ncols1

    # Preprocess data to make extensive form sparse coeff matrix
    objsense = mdata_all[1].objsense
    rhs      = [mdata.rhs for mdata in mdata_all]
    sense    = [mdata.sense for mdata in mdata_all]
    clbd     = [mdata.clbd for mdata in mdata_all]
    cubd     = [mdata.cubd for mdata in mdata_all]

    rhs = vcat(rhs...)
    sense = vcat(sense...)
    clbd = vcat(clbd...)
    cubd = vcat(cubd...)

    obj = mdata_all[1].obj
    for s in 2:length(mdata_all)
        obj = append!(obj, (1/(length(mdata_all)-1))*mdata_all[s].obj)
    end

    ctype = mdata_all[1].ctype
    for s in 2:length(mdata_all)
        ctype = ctype * mdata_all[s].ctype
    end

    cname = mdata_all[1].cname
    for s in 2:length(mdata_all)
        for str in mdata_all[s].cname
            push!(cname, str*"_$s") # tag a scenario index for each second-stage variable
        end
    end

    # Construct sparse coeff matrix of extensive form
    mat = mdata_all[1].mat
    for s in 2:length(mdata_all)
        mat = [mat zeros(nrows1+(s-2)*nrows2, ncols2) ; mdata_all[s].mat[1:nrows2,1:ncols1] zeros(nrows2,(s-2)*ncols2) mdata_all[s].mat[1:nrows2,ncols1+1:end]]
    end
    mdata_ef = ModelData(mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)

    # Generate .mps file
    writeMPS("$FILE_NAME.mps", basename(FILE_NAME), mdata_ef, genericnames)

    # Generate .dec file if dec == true
    if decfile == true
        fp_dec = open("$FILE_NAME.dec", "w")
        println(fp_dec, "PRESOLVED")
        println(fp_dec, "0")
        println(fp_dec, "NBLOCKS")
        println(fp_dec, "$(m.ext[:Stochastic].num_scen)")

        constr_counter = nrows1+1
        for s in 1:m.ext[:Stochastic].num_scen
            println(fp_dec, "BLOCK $s")
            for r in 1:nrows2
                println(fp_dec, "CON$constr_counter")
                constr_counter += 1
            end
        end

        println(fp_dec, "MASTERCONSS")
        for r in 1:nrows1
            println(fp_dec, "CON$r")
        end
        close(fp_dec)
    end

    println("done")

    if splice == true
        @warn("Scenario data in JuMP.Model object was spliced. Set the keyword argument 'splice=false' if you want to re-use the object.")
    end

    return
end

# writeMPS: no keyword arguments version
writeMPS(m, INSTANCE_NAME="instance", DIR_NAME="$(dirname(@__FILE__))/../instance",
            _genericnames::Bool=true, _splice::Bool=true, _decfile::Bool=false) = writeMPS(m, INSTANCE_NAME, DIR_NAME,
=#

end # end of module SMPS
