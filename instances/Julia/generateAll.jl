# Example to generate SMPS files and MPS file (for deterministic equivalent form)

# StructJuMP package is required.
# Pkg.add("StructJuMP")
using StructJuMP

# Required package to write SMPS files
include("../../src/SmpsWriter.jl")
using SmpsWriter

# Read Julia model
include("sslp/sslp.jl")

function generate_sslp(m,n,s)
    # Generate sslp model instance with parameters (m,n,s)
    model = sslp(m,n,s)
    # Write SMPS files
    writeSmps(model, "../SMPS/sslp_$m\_$n\_$s")
end

generate_sslp(5,25,50)
generate_sslp(5,25,100)
generate_sslp(5,50,50)
generate_sslp(5,50,100)
generate_sslp(10,50,50)
generate_sslp(10,50,100)
generate_sslp(10,50,500)
generate_sslp(10,50,1000)
generate_sslp(10,50,2000)
generate_sslp(15,45,5)
generate_sslp(15,45,10)
generate_sslp(15,45,15)
