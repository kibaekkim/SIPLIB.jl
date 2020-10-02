"""
This writes an additional data in <filename>.dro file
    for distributionally robust stochastic optimization based on Wasserstein ambituity set.

NOTE: This file can be read by DSP.

The format is as follows:

line 1: wasserstein ball size
line 2: number of references
line 3-: wasserstein distance
"""
function write_wasserstein_dro(
    num_discretizations::Int,
    num_references::Int,
    reference_probability::Vector{Float64},
    wasserstein_distance::Array{Float64,2}, # Dimension: (num_references) times (num_discretizations + num_references)
    ϵ::Float64,
    filename::String
)
    m, n = size(wasserstein_distance)
    if m == num_references && n == num_discretizations + num_references
        @error "The dismension of wasserstein_distance does not match."
        return
    end

    fp = open("$filename.dro","w")
    println(fp, ϵ)
    println(fp, num_references)
    for s = 1:num_references
        if s > 1
            print(fp, ",")
        end
        print(fp, reference_probability[s])
    end
    print(fp, "\n")
    for i = 1:(num_discretizations+num_references)
        for s = 1:num_references
            if s > 1
                print(fp, ",")
            end
            print(fp, wasserstein_distance[s,i])
        end
        print(fp,"\n")
    end
    close(fp)
end
