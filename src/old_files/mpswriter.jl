
# MPS writer (+ optional dec file) for a stochastic model instance
function writeMPS(m::JuMP.Model, INSTANCE_NAME::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../instance"; genericnames::Bool=true, splice::Bool=true, decfile::Bool=false)

    FILE_NAME = "$DIR_NAME/$INSTANCE_NAME"

    if !decfile
        println("Writing MPS file for $INSTANCE_NAME.")
    else
        println("Writing MPS and .dec files for $INSTANCE_NAME.")
    end

    # Check if m is a StructJuMP model
    if !haskey(m.ext, :Stochastic)
        JuMP.writeMPS(m, "$FILE_NAME.mps")
        warn("This is not a stochastic model. $FILE_NAME.mps is generated.")
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
        warn("Scenario data in JuMP.Model object was spliced. Set the optional argument 'splice=false' if you want to re-use the object.")
    end

    return
end


prob = :DCAP
param_arr = [3,3,3,5]
m = getModel(prob, param_arr)

writeMPS(m, Siplib.getInstanceName(prob,param_arr), genericnames=false, decfile=true)
writeMPS(m, Siplib.getInstanceName(prob,param_arr), genericnames=true)

generateSMPS(:DCAP, [3,3,3,5])

str = "asdf/abcd.mps"

basename(str)
str[end-2:end]
str = splice!(str, str[end-2:end])
replace("Sherlock Holmes", "e" => "ee")

replace(str, ".mps" => ".dec")
