import JuMP.writeMPS

mutable struct ModelData
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

function prepConstrMatrix(m::JuMP.Model, splice::Bool=true)
    if !haskey(m.ext, :Stochastic)
        error("This is not a StructJuMP model.")
        return JuMP.prepConstrMatrix(m)
    end

    if getparent(m) == nothing # i.e., this model is parent
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

                # if splice is true, splice stochastic block
                if splice == true
                    splice!(aff.vars, id)
                    splice!(aff.coeffs, id)
                end
            end
        end
    end

    return sparse(rind, cind, value, length(m.linconstr), getparent(m).numCols + m.numCols)
end

function getModelData(m::JuMP.Model, genericnames::Bool=true, splice::Bool=true)::ModelData

    # Get a column-wise sparse matrix
    mat = prepConstrMatrix(m, splice)

    # column type
    ctype = ""
    for i = 1:length(m.colCat)
        if m.colCat[i] == :Int
            ctype = ctype * "I";
        elseif m.colCat[i] == :Bin
            ctype = ctype * "B";
        else
            ctype = ctype * "CON";
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

    # if genericnames == false, get original variable names
    if genericnames == false
        cname = String[]
        for i in 1:length(m.colCat)
            push!(cname, JuMP.getname(m,i))
        end
    else genericnames == true
        cname = String[]
    end

    return ModelData(mat, rhs, sense, obj, m.objSense, m.colLower, m.colUpper, ctype, cname)
end

function getStructModelData(m::JuMP.Model, genericnames::Bool=true, splice::Bool=true)::Array{ModelData,1}

    println("Reading all data from StructJuMP model")

    # create the model data array
    #mdata_all = Array{ModelData,1}()
    mdata_all = ModelData[]
    # get model data for the first stage
    @time begin
        mdata = getModelData(m, genericnames, splice)
    end
    push!(mdata_all, mdata)

    # @show Threads.nthreads()
    # println("You can set the number of threads as follows:\n\texport JULIA_NUM_THREADS=4")

    # get model data for the second stage
#    @time Threads.@threads for i = 1:num_scenarios(m) # multi-threading sometimes causes error.
    for i = 1:num_scenarios(m)
        mdata = getModelData(getchildren(m)[i], genericnames, splice)
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

function writeMPS(FILE_NAME, INSTANCE_NAME, mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname, genericnames::Bool=true)

    nrows, ncols = size(mat)
    if objsense == :Max
        obj *= -1
        warn("The problem is converted to minimization problem.")
    end

    fp = open(FILE_NAME, "w")

    #            123456789 123456789
    println(fp, "NAME          $INSTANCE_NAME")

    println(fp, "ROWS")
    println(fp, " N  OBJ")
    for i in 1:nrows
        @printf(fp, " %s  CON%d\n", sense[i], i)
    end

    marker_started = false
    mat_rows = rowvals(mat)
    mat_vals = nonzeros(mat)

    # if genericnames == false, write file with original (readable) variable name, else write all variables with the name VARxx
    if genericnames == false
        println(fp, "COLUMNS")
        for j in 1:ncols

            if !marker_started && in(ctype[j], "BI")
                @printf(fp,"    MARKER    'MARKER'                'INTORG'\n")
                marker_started = true
            end

            if abs(obj[j]) > 0 || length(nzrange(mat,j)) > 0
    #                @printf(fp, "    %-8s", "VAR"*string(j))
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
                println("Warning: The JuMP model contains unused variable. Remove this to reduce file size.")
    #                @printf(fp, "    %-8s", "VAR"*string(j))
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
        @printf(fp, "    %-8s", "rhs")
        for i in 1:nrows
            if pos >= 3
                @printf(fp, "\n    %-8s", "rhs")
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

    elseif genericnames == true

        println(fp, "COLUMNS")
        for j in 1:ncols

            if !marker_started && in(ctype[j], "BI")
                #@printf(fp, "    %-8s  %-8s  %-12s\n", "MARKER", "'MARKER'", "'INTORG'")
                @printf(fp,"    MARKER    'MARKER'                'INTORG'\n")
                marker_started = true
            end

            if abs(obj[j]) > 0 || length(nzrange(mat,j)) > 0
                @printf(fp, "    %-8s", "VAR"*string(j))
                pos = 1
                if abs(obj[j]) > 0
                    @printf(fp, "  %-8s", "OBJ")
                    @printf(fp, "  %-12f", obj[j])
                    pos += 1
                end

                for i in nzrange(mat,j)
                    if pos >= 3
                        @printf(fp, "\n    %-8s", "VAR"*string(j))
                        pos = 1
                    end
                    @printf(fp, "  %-8s", "CON"*string(mat_rows[i]))
                    @printf(fp, "  %-12f", mat_vals[i])
                    pos += 1
                end
                @printf(fp, "\n")
            else # abs(obj[j]) == 0 && length(nzrange(mat,j)) == 0
                println("Warning: The JuMP model contains unused variable. Remove this to reduce file size.")
                @printf(fp, "    %-8s", "VAR"*string(j))
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
        @printf(fp, "    %-8s", "rhs")
        for i in 1:nrows
            if pos >= 3
                @printf(fp, "\n    %-8s", "rhs")
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
                        @printf(fp, " FR %-8s  %-8s\n", "BOUND", "VAR"*string(j))
                    else # cubd[j] < Inf
                        @printf(fp, " MI %-8s  %-8s\n", "BOUND", "VAR"*string(j))
                        @printf(fp, " UI %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), cubd[j])
                    end
                elseif clbd[j] == 0
                    if cubd[j] >= Inf
                        @printf(fp, " LI %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), 0)
                    else # cubd[j] < Inf
                        @printf(fp, " UI %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), cubd[j])
                    end
                else # clbd[j] > -Inf
                    @printf(fp, " LI %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), clbd[j])
                    if cubd[j] < Inf
                        @printf(fp, " UI %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), cubd[j])
                    end
                end
                continue
            end

            # binary
            if ctype[j] == 'B'
                @printf(fp, " BV %-8s  %-8s\n", "BOUND", "VAR"*string(j))
                continue
            end

            if clbd[j] == cubd[j]
                @printf(fp, " FX %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), clbd[j])
                continue
            end

            if clbd[j] <= -Inf
                if cubd[j] >= Inf
                    @printf(fp, " FR %-8s  %-8s\n", "BOUND", "VAR"*string(j))
                else
                    @printf(fp, " MI %-8s  %-8s\n", "BOUND", "VAR"*string(j))
                    if cubd[j] != 0
                        @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), cubd[j])
                    end
                end
            elseif clbd[j] == 0
                # cubd[j] >= Inf is default.
                if cubd[j] < Inf
                    @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), cubd[j])
                end
            else # clbd[j] > -Inf
                @printf(fp, " LO %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), clbd[j])
                if cubd[j] < Inf
                    @printf(fp, " UP %-8s  %-8s  %-12f\n", "BOUND", "VAR"*string(j), cubd[j])
                end
            end
        end
    end
    println(fp, "ENDATA")
    close(fp)
end

writeMPS(FILE_NAME, INSTANCE_NAME, mdata::ModelData, genericnames::Bool=true) = writeMPS(FILE_NAME, INSTANCE_NAME, mdata.mat, mdata.rhs, mdata.sense, mdata.obj, mdata.objsense, mdata.clbd, mdata.cubd, mdata.ctype, mdata.cname, genericnames)

function writeCore(FILE_NAME, mdata_all::Array{ModelData,1}, genericnames::Bool=true)::ModelData

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

    mdata_core = ModelData(mat, rhs, sense, obj, objsense, clbd, cubd, ctype, cname)

    writeMPS("$FILE_NAME.cor", basename(FILE_NAME), mdata_core, genericnames)

    println("done")

    return mdata_core
end

function writeTime(FILE_NAME, mdata1::ModelData, genericnames::Bool=true)

    print("Writing time file ... ")

    fp = open("$FILE_NAME.tim", "w")

    mat1 = mdata1.mat

    start_cons2, start_vars2 = size(mat1)
    start_vars2 += 1
    start_cons2 += 1

    #            123456789 123456789
    println(fp, "TIME          ", basename(FILE_NAME))
    println(fp, "PERIODS       IMPLICIT")
    if genericnames == false
        @printf(fp, "    %-8s  %-8s  PERIOD1\n", mdata1.cname[1], "CON1")
        @printf(fp, "    %-8s  %-8s  PERIOD2\n", mdata1.cname[start_vars2], "CON"*string(start_cons2))
    elseif genericnames == true
        @printf(fp, "    %-8s  %-8s  PERIOD1\n", "VAR1", "CON1")
        @printf(fp, "    %-8s  %-8s  PERIOD2\n", "VAR"*string(start_vars2), "CON"*string(start_cons2))
    end
    println(fp, "ENDATA")

    close(fp)

    println("done")
end

function writeStoc(FILE_NAME, nscen, probability, mdata_all::Array{ModelData,1}, mdata_core::ModelData, genericnames::Bool=true)

    print("Writing stochastic file ... ")

    # get # of first-stage rows and columns
    nrows1, ncols1 = size(mdata_all[1].mat)
    nrows2, ncols = size(mdata_all[2].mat)
    ncols2 = ncols - ncols1

    coremat_rows = rowvals(mdata_core.mat)
    coremat_vals = nonzeros(mdata_core.mat)

    fp = open("$FILE_NAME.sto", "w")

    #            123456789 123456789
    println(fp, "STOCH         ", basename(FILE_NAME))
    println(fp, "SCENARIOS")

    for s in 1:nscen
      @printf(fp, " SC %-8s  %-8s  %-8f  PERIOD2\n", "SCEN"*string(s), "ROOT", probability[s])

      # row bounds
      for i in 1:nrows2
          if mdata_core.rhs[nrows1+i] != mdata_all[s+1].rhs[i]
              @printf(fp, "    %-8s  %-8s  %-12f\n", "rhs", "CON"*string(nrows1+i), mdata_all[s+1].rhs[i])
          end
      end

      mat_rows = rowvals(mdata_all[s+1].mat)
      mat_vals = nonzeros(mdata_all[s+1].mat)
      for j in 1:ncols
          # objective coefficients
          if j > ncols1 && mdata_core.obj[j] != mdata_all[s+1].obj[j-ncols1]
              if genericnames == false
                  @printf(fp, "    %-8s  %-8s  %-12f\n", mdata_core.cname[j], "OBJ", mdata_all[s+1].obj[j-ncols1])
              elseif genericnames == true
                  @printf(fp, "    %-8s  %-8s  %-12f\n", "VAR"*string(j), "OBJ", mdata_all[s+1].obj[j-ncols1])
              end
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
              if genericnames == false
                  @printf(fp, "    %-8s  %-8s  %-12f\n", mdata_core.cname[j], "CON"*string(i), rows_to_modify[i])
              elseif genericnames == true
                  @printf(fp, "    %-8s  %-8s  %-12f\n", "VAR"*string(j), "CON"*string(i), rows_to_modify[i])
              end
          end
      end
    end
    println(fp, "ENDATA")

    close(fp)

    println("done")
end



"""
    writeSMPS(model::JuMP.Model, INSTANCE_NAME::String, DIR_NAME::String; genericnames::Bool, splice::Bool)

model (necessary): JuMP.Model-type object input.
INSTANCE_NAME (optional): Name of the instance (DEFAULT: "instance")
DIR_NAME (optional): The path in which SMPS files are stored. (DEFAULT: "../instance/")
genericnames (optional): 'true' if you want to let Siplib automatically generate: VAR1, VAR2, ... . 'false' if you want to maintain the original (readable) variable names. (DEFAULT: true)
splice (optional): 'true' then data in the model is spliced after writing SMPS files so you cannot re-use the object. 'false' if you want to re-use the JuMP.Model object.  (DEFAULT: true)
"""
function writeSMPS(m::JuMP.Model, INSTANCE_NAME::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../instance"; genericnames::Bool=true, splice::Bool=true)

    FILE_NAME = "$DIR_NAME/$INSTANCE_NAME"
    println("Writing SMPS files for $INSTANCE_NAME.")

    # Check if m is a StructJuMP model
    if !haskey(m.ext, :Stochastic)
        JuMP.writeMPS(m, "$FILE_NAME.mps")
        warn("This is not a stochastic model. $FILE_NAME.mps is generated.")
        return
    end

    # Extract and store StructJuMP model data
    mdata_all = getStructModelData(m, genericnames, splice)

    # Write .cor file && Store core data
    mdata_core = writeCore(FILE_NAME, mdata_all, genericnames)

    # Write .tim and .sto files
    writeTime(FILE_NAME, mdata_all[1], genericnames)
    writeStoc(FILE_NAME, num_scenarios(m), getprobability(m), mdata_all, mdata_core, genericnames)

    if splice == true
        warn("Scenario data in JuMP.Model object was spliced. Set the optional argument 'splice=false' if you want to re-use the object.")
    end

    return
end

# writeSMPS: no optional arguments version
writeSMPS(m, INSTANCE_NAME="instance", DIR_NAME="$(dirname(@__FILE__))/../instance", _genericnames::Bool=true, _splice::Bool=true) = writeSMPS(m, INSTANCE_NAME, DIR_NAME, genericnames=_genericnames, splice=_splice)
