# Example to generate SMPS files and MPS file (for deterministic equivalent form)

# StructJuMP package is required.
# Pkg.add("StructJuMP")
using StructJuMP

# Required package to write SMPS files
include("../../src/SmpsWriter.jl")
using SmpsWriter

# Read Julia model
include("sslp/sslp.jl")

# Generate sslp model instance with parameters (m,n,s)
m = sslp(5,25,50)

# Write SMPS files
writeSmps(m, "../SMPS/sslp_5_25_50")

# Write the deterministic equivalent form in MPS file
writeMps(m, "../MPS/sslp_5_25_50")
