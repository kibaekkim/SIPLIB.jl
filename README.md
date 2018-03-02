# SIPLIB 2.0 #

This project is to collect families of SMIP test sets in Julia files and SMPS format. 

Mathematical model for each test set is written in three different formats: Julia, SMPS, MPS.

Using Julia language, mathematical program can be modeled as a'JuMP.Model'-type object which is defined in 'JuMP' package. Some structured mathematical model can also be modeled as 'JuMP.Model'-type object by combining 'StructuredJuMP' package with 'JuMP'.

Once we have a source code for creating the model objects, it is easy to modify the model and convert to SMPS/MPS-type files.

# Converting JuMP.Model to SMPS Example

Please see ./instances/Julia/example.jl

# StructJuMP to SMPS

In 'src' folder, you will find a source code (SmpsWriter.jl) that converts StructJuMP model to SMPS files. 
 
