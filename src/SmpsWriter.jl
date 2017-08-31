#=
This module implements SMPS writer for stochastic (mixed-integer) linear programming problems.

The problem of interest is

min   c_0^T x_0 + \sum_{j=1}^J p_j c_j^T x_j
s.t.  A_0 x_0           (sign_0) b_0
      A_j x_0 + B_j x_j (sign_j) h_j for j = 1,...,J,
      clbd_j <= x_j <= cubd_j for j = 0,1,...,J

where (sign_j) represents either <=, >=, or ==, and 
      (Bounds) define the column bounds.

It may take long time to generate a large number of scenarios. To reduce the time you can use multithreads.

For example, set the folloing environment variable in terminal.
    export JULIA_NUM_THREADS=16
=#

module SmpsWriter

using StructJuMP

export writeAll, writeSmps, writeMps

type ModelData
    mat::SparseMatrixCSC{Float64}
    rhs::Vector{Float64}
    sense::Vector{Symbol}
    obj::Vector{Float64}
    objsense::Symbol
    clbd::Vector{Float64}
    cubd::Vector{Float64}
    ctype::String
end

function writeAll(m::JuMP.Model, filename::String="SmpsWriter")
    # Check if this is a StructJuMP model
    if !haskey(m.ext, :Stochastic)
        writeMPS(m, "$filename.mps")
        warn("This is not a stochastic model. $filename.mps was geneerated.")
        return
    end

    # Get StructJuMP model data
    mdata_all = getStructModelData(m)

    # Create and write a core model
    mdata_core = writeCore(filename, mdata_all)

    # Write tim and sto files
    writeTime(filename, mdata_all[1].mat)
    writeStoc(filename, num_scenarios(m), getprobability(m), mdata_all, mdata_core)

    # Write MPS file
    writeMps(m, mdata_all, filename)

    return
end

# write SMPS files (cor, tim, and sto)
function writeSmps(m::JuMP.Model, filename::String="SmpsWriter")

    # Check if this is a StructJuMP model
    if !haskey(m.ext, :Stochastic)
        writeMPS(m, "$filename.mps")
        warn("This is not a stochastic model. $filename.mps was geneerated.")
        return
    end

    # Get StructJuMP model data
    mdata_all = getStructModelData(m)

    # Create and write a core model
    mdata_core = writeCore(filename, mdata_all)

    # Write tim and sto files
    writeTime(filename, mdata_all[1].mat)
    writeStoc(filename, num_scenarios(m), getprobability(m), mdata_all, mdata_core)

    return
end

function writeMps(m::JuMP.Model, filename::String="SmpsWriter")

    if !haskey(m.ext, :Stochastic)
        writeMPS(m, "$filename.mps")
        return
    end

    mdata_all = getStructModelData(m)

    writeMps(m, mdata_all, filename)

    return
end

function writeMps(m::JuMP.Model, mdata_all::Array{ModelData,1}, filename::String="SmpsWriter")

    print("Writing MPS file ...")

    # @show full(mat_all[1])
    nrows0, ncols0 = size(mdata_all[1].mat)
    nrows1, ncols = size(mdata_all[2].mat)
    ncols1 = ncols - ncols0

    mat   = [mdata_all[1].mat zeros(nrows0, ncols1*num_scenarios(m))]
    mat   = [mat ; zeros(nrows1*num_scenarios(m), ncols0+ncols1*num_scenarios(m))]
    rhs   = mdata_all[1].rhs
    sense = mdata_all[1].sense
    obj   = mdata_all[1].obj
    clbd  = mdata_all[1].clbd
    cubd  = mdata_all[1].cubd
    ctype = mdata_all[1].ctype

    for s = 1:num_scenarios(m)
        # @show full(mat_all[s+1])
        mat_rows = rowvals(mdata_all[s+1].mat)
        mat_vals = nonzeros(mdata_all[s+1].mat)
        for j in 1:ncols
            for i in nzrange(mdata_all[s+1].mat,j)
                if j > ncols0
                    mat[nrows0 + (s-1)*nrows1 + mat_rows[i], (s-1)*ncols1 + j] = mat_vals[i]
                else
                    mat[nrows0 + (s-1)*nrows1 + mat_rows[i], j] = mat_vals[i]
                end
            end
        end

        rhs   = [rhs  ; mdata_all[s+1].rhs]
        sense = [sense; mdata_all[s+1].sense]
        obj   = [obj  ; mdata_all[s+1].obj * getprobability(m)[s]]
        clbd  = [clbd ; mdata_all[s+1].clbd]
        cubd  = [cubd ; mdata_all[s+1].cubd]
        ctype = ctype * mdata_all[s+1].ctype
    end

    objsense = mdata_all[1].objsense

    writeMps("$filename.mps", filename, mat, rhs, sense, obj, objsense, clbd, cubd, ctype)

    println("done")

    return
end

function writeMps(filename, probname, mat, rhs, sense, obj, objsense, clbd, cubd, ctype)

    nrows, ncols = size(mat)
    if objsense == :Max
        obj *= -1
        warn("The problem is converted to minimization problem.")
    end

    fp = open(filename, "w")

    #            123456789 123456789
    println(fp, "NAME          $probname")

    println(fp, "ROWS")
    println(fp, " N  obj")
    for i in 1:nrows
        @printf(fp, " %s  c%d\n", sense[i], i)
    end

    marker_started = false
    mat_rows = rowvals(mat)
    mat_vals = nonzeros(mat)
    println(fp, "COLUMNS")
    for j in 1:ncols

        if !marker_started && in(ctype[j], "BI")
            @printf(fp, "    %-8s  %-8s  %-12s\n", "MARKER", "'MARKER'", "'INTORG'")
            marker_started = true
        end

        @printf(fp, "    %-8s", "x"*string(j))
        pos = 1
        if abs(obj[j]) > 0
            @printf(fp, "  %-8s", "obj")
            @printf(fp, "  %-12f", obj[j])
            pos += 1
        end

        for i in nzrange(mat,j)
            if pos >= 3
                @printf(fp, "\n    %-8s", "x"*string(j))
                pos = 1
            end
            @printf(fp, "  %-8s", "c"*string(mat_rows[i]))
            @printf(fp, "  %-12f", mat_vals[i])
            pos += 1
        end
        @printf(fp, "\n")

        if marker_started
            if j == ncols || !in(ctype[j+1], "BI")
                @printf(fp, "    %-8s  %-8s  %-12s\n", "MARKER", "'MARKER'", "'INTEND'")
                marker_started = false
            end
        end
    end

    println(fp, "RHS")
    pos = 1
    @printf(fp, "    %-8s", "rhs")
    for i in 1:nrows
        if pos >= 3
            @printf(fp, "\n    %-8s", "rhs")
            pos = 1
        end
        @printf(fp, "  %-8s", "c"*string(i))
        @printf(fp, "  %-12f", rhs[i])
        pos += 1
    end
    @printf(fp, "\n")

    println(fp, "BOUNDS")
    for j in 1:ncols

        if ctype[j] == 'B'
            @printf(fp, " BV BOUND  %-8s\n", "x"*string(j))
            continue
        end

        if clbd[j] == cubd[j]
            @printf(fp, " FX %-8s  %-8s  %-12f\n", "BOUND", "x"*string(j), clbd[j])
            continue
        end

        if clbd[j] <= -Inf
            if cubd[j] >= Inf
                @printf(fp, " FR BOUND  %-8s\n", "x"*string(j))
            else
                @printf(fp, " MI %-8s  %-8s\n", "BOUND", "x"*string(j))
                if cubd[j] != 0
                    @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", "x"*string(j), cubd[j])
                end
            end
        elseif clbd[j] == 0
            # cubd[j] >= Inf is default.
            if cubd[j] < Inf
                @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", "x"*string(j), cubd[j])
            end
        else # clbd[j] > -Inf
            @printf(fp, " LO %-8s  %-8s  %-12f\n", "BOUND", "x"*string(j), clbd[j])
            if cubd[j] < Inf
                @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", "x"*string(j), cubd[j])
            end
        end
    end

    println(fp, "ENDATA")
    close(fp)
end

writeMps(filename, probname, mdata::ModelData) = writeMps(filename, probname, mdata.mat, mdata.rhs, mdata.sense, mdata.obj, mdata.objsense, mdata.clbd, mdata.cubd, mdata.ctype)

function getStructModelData(m::JuMP.Model)::Array{ModelData,1}

    println("Reading all data from StructJuMP model")

    # create the model data array
    mdata_all = Array{ModelData,1}()

    # get model data for the first stage
    @time begin
        mdata = getModelData(m)
    end
    push!(mdata_all, mdata)

    # @show Threads.nthreads()
    # println("You can set the number of threads as follows:\n\texport JULIA_NUM_THREADS=4")

    # get model data for the second stage
    @time Threads.@threads for i = 1:num_scenarios(m)
        mdata = getModelData(getchildren(m)[i])
        push!(mdata_all, mdata)
    end

    nrows0, ncols0 = size(mdata_all[1].mat)
    nrows1, ncols  = size(mdata_all[2].mat)
    ncols1 = ncols - ncols0
    @printf("   First stage: vars (%d), cons (%d)\n", ncols0, nrows0)
    @printf("  Second stage: vars (%d), cons (%d)\n", ncols1, nrows1)
    @printf("  Number of scenarios: %d\n", num_scenarios(m))

    return mdata_all
end

function getModelData(m::JuMP.Model)::ModelData
    # Get a column-wise sparse matrix
    mat = prepConstrMatrix(m)

    # column type
    ctype = ""
    for i = 1:length(m.colCat)
        if m.colCat[i] == :Int
            ctype = ctype * "I";
        elseif m.colCat[i] == :Bin
            ctype = ctype * "B";
        else
            ctype = ctype * "C";
        end
    end

    # objective coefficients
    obj = JuMP.prepAffObjective(m)

    # row bounds
    rlbd, rubd = JuMP.prepConstrBounds(m)
    rhs = Float64[]
    sense = Symbol[]
    for i = 1:length(rlbd)
        if rlbd[i] == rubd[i]
            push!(rhs, rlbd[i])
            push!(sense, :E)
        elseif rlbd[i] <= -Inf
            push!(rhs, rubd[i])
            push!(sense, :L)
        elseif rubd[i] >= Inf
            push!(rhs, rlbd[i])
            push!(sense, :G)
        else
            error("The current version does not support range constraints.")
        end
    end

    return ModelData(mat, rhs, sense, obj, m.objSense, m.colLower, m.colUpper, ctype)
end

function prepConstrMatrix(m::JuMP.Model)
    if !haskey(m.ext, :Stochastic)
        error("This is not a StructJuMP model.")
        return JuMP.prepConstrMatrix(m)
    end

    if getparent(m) == nothing
        return JuMP.prepConstrMatrix(m)
    else
        rind = Int[]
        cind = Int[]
        value = Float64[]
        for (nrow,con) in enumerate(m.linconstr)
            aff = con.terms
            for (var,id) in zip(reverse(aff.vars), length(aff.vars):-1:1)
                push!(rind, nrow)
                if m.linconstr[nrow].terms.vars[id].m == getparent(m)
                    push!(cind, var.col)
                elseif m.linconstr[nrow].terms.vars[id].m == m
                    push!(cind, getparent(m).numCols + var.col)
                end
                push!(value, aff.coeffs[id])
                splice!(aff.vars, id)
                splice!(aff.coeffs, id)
            end
        end
    end
    return sparse(rind, cind, value, length(m.linconstr), getparent(m).numCols + m.numCols)
end

function writeCore(filename, mdata_all::Array{ModelData,1})::ModelData

    print("Writing core file ... ")

    # get # of first-stage rows and columns
    nrows0, ncols0 = size(mdata_all[1].mat)

    # get # of rows and columns for the scenario block
    nrows1, ncols = size(mdata_all[2].mat)
    ncols1 = ncols - ncols0

    # core data
    rhs      = [mdata_all[1].rhs  ; mdata_all[2].rhs]
    sense    = [mdata_all[1].sense; mdata_all[2].sense]
    obj      = [mdata_all[1].obj  ; mdata_all[2].obj]
    objsense = mdata_all[1].objsense
    clbd     = [mdata_all[1].clbd ; mdata_all[2].clbd]
    cubd     = [mdata_all[1].cubd ; mdata_all[2].cubd]
    ctype    = mdata_all[1].ctype * mdata_all[2].ctype
    mat      = [[mdata_all[1].mat zeros(nrows0, ncols-ncols0)] ; mdata_all[2].mat]
    @assert length(clbd) == ncols
    @assert length(obj) == ncols

    # reserve the nonzero spaces
    for s = 3:length(mdata_all)
        mat_rows = rowvals(mdata_all[s].mat)
        for j in 1:ncols1
            if obj[ncols0+j] == 0 && mdata_all[s].obj[j] != 0
                obj[ncols0+j] = 1
            end
            for i in nzrange(mdata_all[s].mat,j)
                if mat[nrows0+mat_rows[i],j] == 0.0
                    mat[nrows0+mat_rows[i],j] = 1
                end
            end
        end
        for i in 1:nrows1
            if rhs[nrows0+i] == 0 && mdata_all[s].rhs[i] != 0
                rhs[nrows0+i] = 1
            end
        end
    end

    mdata_core = ModelData(mat, rhs, sense, obj, objsense, clbd, cubd, ctype)
    writeMps("$filename.cor", basename(filename), mdata_core)

    println("done")

    return mdata_core
end

function writeTime(filename, mat0::SparseMatrixCSC{Float64})

    print("Writing time file ... ")

    fp = open("$filename.tim", "w")

    start_cons2, start_vars2 = size(mat0)
    start_vars2 += 1
    start_cons2 += 1

    #            123456789 123456789
    println(fp, "TIME          ", basename(filename))
    println(fp, "PERIOD        IMPLICIT")
    @printf(fp, "    %-8s  %-8s  PERIOD1\n", "x1", "obj")
    @printf(fp, "    %-8s  %-8s  PERIOD2\n", "x"*string(start_vars2), "c"*string(start_cons2))
    println(fp, "ENDATA")

    close(fp)

    println("done")
end

function writeStoc(filename, nscen, probability, mdata_all::Array{ModelData,1}, mdata_core::ModelData)

    print("Writing stochastic file ... ")

    # get # of first-stage rows and columns
    nrows0, ncols0 = size(mdata_all[1].mat)
    nrows1, ncols = size(mdata_all[2].mat)
    ncols1 = ncols - ncols0

    coremat_rows = rowvals(mdata_core.mat)
    coremat_vals = nonzeros(mdata_core.mat)

    fp = open("$filename.sto", "w")

    #            123456789 123456789
    println(fp, "STOCH         ", basename(filename))
    println(fp, "SCENARIOS")
    for s in 1:nscen
        @printf(fp, " SC %-8s  %-8s  %-8f  PERIOD2\n", "SCEN"*string(s), "ROOT", probability[s])
        
        # row bounds
        for i in 1:nrows1
            if mdata_core.rhs[nrows0+i] != mdata_all[s+1].rhs[i]
                @printf(fp, "    %-8s  %-8s  %-12f\n", "rhs", "c"*string(nrows0+i), mdata_all[s+1].rhs[i])
            end
        end

        mat_rows = rowvals(mdata_all[s+1].mat)
        mat_vals = nonzeros(mdata_all[s+1].mat)
        for j in 1:ncols
            # objective coefficients
            if j > ncols0 && mdata_core.obj[j] != mdata_all[s+1].obj[j-ncols0]
                @printf(fp, "    %-8s  %-8s  %-12f\n", "x"*string(j), "obj", mdata_all[s+1].obj[j-ncols0])
            end

            # constraint matrix
            rows_to_modify = Dict{Int,Float64}()
            for i in nzrange(mdata_all[s+1].mat,j)
                if mdata_core.mat[nrows0+mat_rows[i],j] != mat_vals[i]
                    rows_to_modify[nrows0+mat_rows[i]] = mat_vals[i]
                end
            end
            for i in nzrange(mdata_core.mat,j)
                if coremat_rows[i] > nrows0 && mdata_all[s+1].mat[coremat_rows[i]-nrows0,j] != coremat_vals[i]
                    rows_to_modify[coremat_rows[i]] = mdata_all[s+1].mat[coremat_rows[i]-nrows0,j]
                end
            end
            for i in sort(collect(keys(rows_to_modify)))
                @printf(fp, "    %-8s  %-8s  %-12f\n", "x"*string(j), "c"*string(i), rows_to_modify[i])
            end
        end
    end
    println(fp, "ENDATA")

    close(fp)

    println("done")
end

end

