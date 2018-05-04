module SparsityAnalyzer

include("./SmpsWriter.jl")
using PyPlot, SmpsWriter

export plotConstraintMatrix, getSparsity

# this function 1) plots constriant matrix, 2) calculate sparsity
function plotConstraintMatrix(m::JuMP.Model, INSTANCE:: String="", PATH::String="")

    mdata_all = SmpsWriter.getStructModelData(m)

    nrows0, ncols0 = size(mdata_all[1].mat)
    nrows1, ncols = size(mdata_all[2].mat)
    ncols1 = ncols - ncols0

    # prepare consttraint matrix for DE form
    mat_de  = [mdata_all[1].mat zeros(nrows0, ncols1*num_scenarios(m))]
    mat_de  = [mat_de ; zeros(nrows1*num_scenarios(m), ncols0+ncols1*num_scenarios(m))]

    for s = 1:num_scenarios(m)
        mat_rows = rowvals(mdata_all[s+1].mat)
        mat_vals = nonzeros(mdata_all[s+1].mat)
        for j in 1:ncols
            for i in nzrange(mdata_all[s+1].mat,j)
                if j > ncols0
                    mat_de[nrows0 + (s-1)*nrows1 + mat_rows[i], (s-1)*ncols1 + j] = mat_vals[i]
                else
                    mat_de[nrows0 + (s-1)*nrows1 + mat_rows[i], j] = mat_vals[i]
                end
            end
        end
    end

    # calculate sparsity
    nrows_de, ncols_de = size(mat_de)
    denom = nrows_de*ncols_de
    num = length(nonzeros(mat_de))
    sparsity = num/denom
    print("Sparsity of the instance $INSTANCE: $(round(100*sparsity,2))%")

    plt = PyPlot
    plt.spy(mat_de)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()

    # if a user input PATH, save the figure to the PATH.
    if PATH != ""
        plt.savefig(PATH)
        plt.close()
    end

    return sparsity
end

# TODO: this function ONLY calculates sparsity
function calcSparsity(m::JuMP.Model, INSTANCE::String)

    mdata_all = SmpsWriter.getStructModelData(m)

    nrows0, ncols0 = size(mdata_all[1].mat)
    nrows1, ncols = size(mdata_all[2].mat)
    ncols1 = ncols - ncols0

    # prepare consttraint matrix for DE form
    mat_de   = [mdata_all[1].mat zeros(nrows0, ncols1*num_scenarios(m))]
    mat_de   = [mat_de ; zeros(nrows1*num_scenarios(m), ncols0+ncols1*num_scenarios(m))]

    for s = 1:num_scenarios(m)
        mat_rows = rowvals(mdata_all[s+1].mat)
        mat_vals = nonzeros(mdata_all[s+1].mat)
        for j in 1:ncols
            for i in nzrange(mdata_all[s+1].mat,j)
                if j > ncols0
                    mat_de[nrows0 + (s-1)*nrows1 + mat_rows[i], (s-1)*ncols1 + j] = mat_vals[i]
                else
                    mat_de[nrows0 + (s-1)*nrows1 + mat_rows[i], j] = mat_vals[i]
                end
            end
        end
    end

    return sparsity
end


end # end of module
