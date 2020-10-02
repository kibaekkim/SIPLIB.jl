"""
This writes an additional data in <filename>.dro file
    for distributionally robust stochastic optimization based on Wasserstein ambituity set.

NOTE: This file can be read by DSP.

The format is as follows:

line 1: wasserstein ball size
line 2: number of discretized points of support
line 3-: wasserstein distance
"""
function write_wasserstein_dro(
    reference_probability::Vector{Float64},
    wasserstein_distance::Array{Float64,2}, # Dimension: |discretization of support| times |references|
    ϵ::Float64,
    filename::String
)
    num_discretizations, num_references = size(wasserstein_distance)

    fp = open("$filename.dro","w")
    println(fp, ϵ)
    println(fp, num_discretizations)
    for s = 1:num_discretizations
        if s > 1
            print(fp, ",")
        end
        print(fp, reference_probability[s])
    end
    print(fp, "\n")
    for i = 1:(num_discretizations+num_references)
        for s = 1:num_discretizations
            if s > 1
                print(fp, ",")
            end
            print(fp, wasserstein_distance[s,i])
        end
        print(fp,"\n")
    end
    close(fp)
end
