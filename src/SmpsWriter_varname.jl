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

#=
module SmpsWriter

    using StructJuMP

    export writeSmps, writeSmps_with_splice
=#
    type ModelData_with_name
        mat::SparseMatrixCSC{Float64}
        rhs::Vector{Float64}
        sense::Vector{Symbol}
        obj::Vector{Float64}
        objsense::Symbol
        clbd::Vector{Float64}
        cubd::Vector{Float64}
        ctype::String
        cname::Vector{String}
    end

    function writeSmps_with_name(m::JuMP.Model, INSTANCE::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../instance")

        filename = "$DIR_NAME/$INSTANCE"

        # Check if this is a StructJuMP model
        if !haskey(m.ext, :Stochastic)
            writeMPS(m, "$filename.mps")
            warn("This is not a stochastic model. $filename.mps was generated.")
            return
        end

        # Get StructJuMP model data
        mdata_all = getStructModelData_with_name(m)

        # Create and write a core model
        mdata_core = writeCore_with_name(filename, mdata_all)

        # Write tim and sto files
        writeTime_with_name(filename, mdata_all[1])
        writeStoc_with_name(filename, num_scenarios(m), getprobability(m), mdata_all, mdata_core)

        return
    end


    function writeSmps_with_name_splice(m::JuMP.Model, INSTANCE::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../instance")

        filename = "$DIR_NAME/$INSTANCE"

        # Check if this is a StructJuMP model
        if !haskey(m.ext, :Stochastic)
            writeMPS(m, "$filename.mps")
            warn("This is not a stochastic model. $filename.mps was generated.")
            return
        end

        # Get StructJuMP model data
        mdata_all = getStructModelData_with_name_splice(m)

        # Create and write a core model
        mdata_core = writeCore_with_name(filename, mdata_all)

        # Write tim and sto files
        writeTime_with_name(filename, mdata_all[1])
        writeStoc_with_name(filename, num_scenarios(m), getprobability(m), mdata_all, mdata_core)

        return
    end


    function writeMps_with_name(filename, probname, mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)

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
                #@printf(fp, "    %-8s  %-8s  %-12s\n", "MARKER", "'MARKER'", "'INTORG'")
                @printf(fp,"    MARKER    'MARKER'                'INTORG'\n")
                marker_started = true
            end

            if abs(obj[j]) > 0 || length(nzrange(mat,j)) > 0
#                @printf(fp, "    %-8s", "x"*string(j))
                @printf(fp, "    %-8s", cname[j])
                pos = 1
                if abs(obj[j]) > 0
                    @printf(fp, "  %-8s", "obj")
                    @printf(fp, "  %-12f", obj[j])
                    pos += 1
                end

                for i in nzrange(mat,j)
                    if pos >= 3
                        @printf(fp, "\n    %-8s", cname[j])
                        pos = 1
                    end
                    @printf(fp, "  %-8s", "c"*string(mat_rows[i]))
                    @printf(fp, "  %-12f", mat_vals[i])
                    pos += 1
                end
                @printf(fp, "\n")
            else # abs(obj[j]) == 0 && length(nzrange(mat,j)) == 0
                println("Warning: The JuMP model contains unused variable. Remove this to reduce file size.")
#                @printf(fp, "    %-8s", "x"*string(j))
                @printf(fp, "    %-8s", cname[j])
                @printf(fp, "  %-8s", "obj")
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
            ############## Integer part #######################################
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
            ####################################################################

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

    writeMps_with_name(filename, probname, mdata::ModelData_with_name) = writeMps_with_name(filename, probname, mdata.mat, mdata.rhs, mdata.sense, mdata.obj, mdata.objsense, mdata.clbd, mdata.cubd, mdata.ctype, mdata.cname)

    function getStructModelData_with_name(m::JuMP.Model)::Array{ModelData_with_name,1}

        println("Reading all data from StructJuMP model")

        # create the model data array
        mdata_all = ModelData_with_name[]
        # get model data for the first stage
        @time begin
            mdata = getModelData_with_name(m)
        end
        push!(mdata_all, mdata)

        # @show Threads.nthreads()
        # println("You can set the number of threads as follows:\n\texport JULIA_NUM_THREADS=4")

        # get model data for the second stage
    #    @time Threads.@threads for i = 1:num_scenarios(m) # multi-threading sometimes causes error.
        for i = 1:num_scenarios(m)
            mdata = getModelData_with_name(getchildren(m)[i])
            push!(mdata_all, mdata)
        end

        nrows1, ncols1 = size(mdata_all[1].mat)
        nrows2, ncols  = size(mdata_all[2].mat)
        ncols2 = ncols - ncols1
        @printf("   First stage: vars (%d), cons (%d)\n", ncols1, nrows1)
        @printf("  Second stage: vars (%d), cons (%d)\n", ncols2, nrows2)
        @printf("  Number of scenarios: %d\n", num_scenarios(m))

        return mdata_all
    end

    function getStructModelData_with_name_splice(m::JuMP.Model)::Array{ModelData_with_name,1}

        println("Reading all data from StructJuMP model")

        # create the model data array
        mdata_all = ModelData_with_name[]
        # get model data for the first stage
        @time begin
            mdata = getModelData_with_name(m)
        end
        push!(mdata_all, mdata)

        # @show Threads.nthreads()
        # println("You can set the number of threads as follows:\n\texport JULIA_NUM_THREADS=4")

        # get model data for the second stage
    #    @time Threads.@threads for i = 1:num_scenarios(m) # multi-threading sometimes causes error.
        for i = 1:num_scenarios(m)
            mdata = getModelData_with_name_splice(getchildren(m)[i])
            push!(mdata_all, mdata)
        end

        nrows1, ncols1 = size(mdata_all[1].mat)
        nrows2, ncols  = size(mdata_all[2].mat)
        ncols2 = ncols - ncols1
        @printf("   First stage: vars (%d), cons (%d)\n", ncols1, nrows1)
        @printf("  Second stage: vars (%d), cons (%d)\n", ncols2, nrows2)
        @printf("  Number of scenarios: %d\n", num_scenarios(m))

        return mdata_all
    end

    function getModelData_with_name(m::JuMP.Model)::ModelData_with_name
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

        # Get Variable Names
        cname = String[]
        for i in 1:length(m.colCat)
                push!(cname, JuMP.getName(m,i))
        end

        return ModelData_with_name(mat, rhs, sense, obj, m.objSense, m.colLower, m.colUpper, ctype, cname)
    end

    function getModelData_with_name_splice(m::JuMP.Model)::ModelData_with_name
        # Get a column-wise sparse matrix
        mat = prepConstrMatrix_with_splice(m)

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

        cname = String[]
        for i in 1:length(m.colCat)
                push!(cname, JuMP.getName(m,i))
        end

        return ModelData_with_name(mat, rhs, sense, obj, m.objSense, m.colLower, m.colUpper, ctype, cname)
    end

    function writeCore_with_name(filename, mdata_all::Array{ModelData_with_name,1})::ModelData_with_name

        print("Writing core file ... ")

        # get # of first-stage rows and columns
        nrows1, ncols1 = size(mdata_all[1].mat)

        # get # of rows and columns for the scenario block
        nrows2, ncols = size(mdata_all[2].mat)
        ncols2 = ncols - ncols1

        # core data (includes 1st stage & 2nd stage's 1st scenario data)
        rhs      = [mdata_all[1].rhs  ; mdata_all[2].rhs]
        sense    = [mdata_all[1].sense; mdata_all[2].sense]
        obj      = [mdata_all[1].obj  ; mdata_all[2].obj]
        objsense = mdata_all[1].objsense
        clbd     = [mdata_all[1].clbd ; mdata_all[2].clbd]
        cubd     = [mdata_all[1].cubd ; mdata_all[2].cubd]
        ctype    = mdata_all[1].ctype * mdata_all[2].ctype
        cname    = append!(mdata_all[1].cname, mdata_all[2].cname) # for column name
        mat      = [[mdata_all[1].mat zeros(nrows1, ncols-ncols1)] ; mdata_all[2].mat]
        @assert length(clbd) == ncols
        @assert length(obj) == ncols

        # reserve the nonzero spaces
        for s = 3:length(mdata_all)
            mat_rows = rowvals(mdata_all[s].mat)
            for j in 1:ncols2
                if obj[ncols1+j] == 0 && mdata_all[s].obj[j] != 0
                    obj[ncols1+j] = 1
                end
                for i in nzrange(mdata_all[s].mat,j)
                    if mat[nrows1+mat_rows[i],j] == 0.0
                        mat[nrows1+mat_rows[i],j] = 1
                    end
                end
            end
            for i in 1:nrows2
                if rhs[nrows1+i] == 0 && mdata_all[s].rhs[i] != 0
                    rhs[nrows1+i] = 1
                end
            end
        end

        mdata_core = ModelData_with_name(mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)

        writeMps_with_name("$filename.cor", basename(filename), mdata_core)

        println("done")

        return mdata_core
    end

    function writeTime_with_name(filename, mdata1::ModelData_with_name)

        print("Writing time file ... ")

        fp = open("$filename.tim", "w")

        mat1 = mdata1.mat

        start_cons2, start_vars2 = size(mat1)
        start_vars2 += 1
        start_cons2 += 1

        #            123456789 123456789
        println(fp, "TIME          ", basename(filename))
        println(fp, "PERIODS       IMPLICIT")
        @printf(fp, "    %-8s  %-8s  PERIOD1\n", mdata1.cname[1], "c1")
        @printf(fp, "    %-8s  %-8s  PERIOD2\n", mdata1.cname[start_vars2], "c"*string(start_cons2))
        println(fp, "ENDATA")

        close(fp)

        println("done")
    end

    function writeStoc_with_name(filename, nscen, probability, mdata_all::Array{ModelData_with_name,1}, mdata_core::ModelData_with_name)

        print("Writing stochastic file ... ")

        # get # of first-stage rows and columns
        nrows1, ncols1 = size(mdata_all[1].mat)
        nrows2, ncols = size(mdata_all[2].mat)
        ncols2 = ncols - ncols1

        coremat_rows = rowvals(mdata_core.mat)
        coremat_vals = nonzeros(mdata_core.mat)

        fp = open("$filename.sto", "w")

        #            123456789 123456789
        println(fp, "STOCH         ", basename(filename))
        println(fp, "SCENARIOS")

        for s in 1:nscen
            @printf(fp, " SC %-8s  %-8s  %-8f  PERIOD2\n", "SCEN"*string(s), "ROOT", probability[s])

            # row bounds
            for i in 1:nrows2
                if mdata_core.rhs[nrows1+i] != mdata_all[s+1].rhs[i]
                    @printf(fp, "    %-8s  %-8s  %-12f\n", "rhs", "c"*string(nrows1+i), mdata_all[s+1].rhs[i])
                end
            end

            mat_rows = rowvals(mdata_all[s+1].mat)
            mat_vals = nonzeros(mdata_all[s+1].mat)
            for j in 1:ncols
                # objective coefficients
                if j > ncols1 && mdata_core.obj[j] != mdata_all[s+1].obj[j-ncols1]
                    @printf(fp, "    %-8s  %-8s  %-12f\n", mdata_core.cname[j], "obj", mdata_all[s+1].obj[j-ncols1])
                end

                # constraint matrix
                rows_to_modify = Dict{Int,Float64}()
                for i in nzrange(mdata_all[s+1].mat,j)
                    if mdata_core.mat[nrows1+mat_rows[i],j] != mat_vals[i]
                        rows_to_modify[nrows1+mat_rows[i]] = mat_vals[i]
                    end
                end
                for i in nzrange(mdata_core.mat,j)
                    if coremat_rows[i] > nrows1 && mdata_all[s+1].mat[coremat_rows[i]-nrows1,j] != coremat_vals[i]
                        rows_to_modify[coremat_rows[i]] = mdata_all[s+1].mat[coremat_rows[i]-nrows1,j]
                    end
                end
                for i in sort(collect(keys(rows_to_modify)))
                    @printf(fp, "    %-8s  %-8s  %-12f\n", mdata_core.cname[j], "c"*string(i), rows_to_modify[i])
                end
            end
        end
        println(fp, "ENDATA")

        close(fp)

        println("done")
    end

#end
