type Size
    InstanceName::String    # instance name
    nCont1::Int             # number of continuous variables in 1st stage
    nBin1::Int              # number of binary variables in 1st stage
    nInt1::Int              # number of integer variables in 1st stage
    nCont2::Int             # number of continuous variables in 2nd stage
    nBin2::Int              # number of binary variables in 2nd stage
    nInt2::Int              # number of integer variables in 2nd stage
    nCont::Int              # number of continuous variables in total
    nBin::Int               # number of binary variables in total
    nInt::Int               # number of integer variables in total
    nRow::Int               # number of rows in coefficient matrix in extensive form
    nCol::Int               # number of columns in coefficient matrix in extensive form
    nNz::Int                # number of nonzero values in coefficient matrix in extensive form
    Size() = new()
end

type Sparsity
    InstanceName::String    # instance name
    nRow1::Int              # number of rows in 1st stage-only block (block A)
    nCol1::Int              # number of columns in 1st stage-only block (block A)
    nNz1::Int               # number of nonzero values in 1st stage-only block (block A)
    sparsity1::Float64      # sparsity ([0,1] scale) of 1st stage-only block (block A)
    nRow2::Int              # number of rows in 2nd stage-only block (block W)
    nCol2::Int              # number of columns in 2nd stage-only block (block W)
    nNz2::Int               # number of nonzero values in 2nd stage-only block (block W)
    sparsity2::Float64      # sparsity ([0,1] scale) of 2nd stage-only block (block W)
    nRowC::Int              # number of rows in complicating block (block T)
    nColC::Int              # number of columns in complicating block (block T)
    nNzC::Int               # number of nonzero values in complicating block (block T)
    sparsityC::Float64      # sparsity ([0,1] scale) of complicating block (block T)
    nRow::Int               # number of rows in total
    nCol::Int               # number of columns in total
    nNz::Int                # number of nonzero values in total
    sparsity::Float64       # sparsity ([0,1] scale) in total
    Sparsity() = new()
end

function plotConstrMatrix(model::JuMP.Model, INSTANCE::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../plot")

    mdata_all = getStructModelData(model)

    nrows1, ncols1 = size(mdata_all[1].mat)
    nrows2, ncols = size(mdata_all[2].mat)
    ncols2 = ncols - ncols1

    # assign a zero-valued constraint matrix for DE form
    mat_de  = [mdata_all[1].mat zeros(nrows1, ncols2*num_scenarios(model))]
    mat_de  = [mat_de ; zeros(nrows2*num_scenarios(model), ncols1+ncols2*num_scenarios(model))]

    for s = 1:num_scenarios(model)
        mat_rows = rowvals(mdata_all[s+1].mat)
        mat_vals = nonzeros(mdata_all[s+1].mat)
        for j in 1:ncols
            for i in nzrange(mdata_all[s+1].mat,j)
                if j > ncols1
                    mat_de[nrows1 + (s-1)*nrows2 + mat_rows[i], (s-1)*ncols2 + j] = mat_vals[i]
                else
                    mat_de[nrows1 + (s-1)*nrows2 + mat_rows[i], j] = mat_vals[i]
                end
            end
        end
    end

    plt = PyPlot
    plt.spy(mat_de)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()

    plt.savefig("$DIR_NAME/$INSTANCE.pdf")
    #plt.close()
end

function plotFirstStageBlock(model::JuMP.Model, INSTANCE::String="instance_block_A", DIR_NAME::String="$(dirname(@__FILE__))/../plot")

    mdata = getModelData(model)
    mat = mdata.mat
    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()

    plt.savefig("$DIR_NAME/$INSTANCE.pdf")
    #plt.close()
end

function plotSecondStageBlock(model::JuMP.Model, INSTANCE::String="instance_block_W", DIR_NAME::String="$(dirname(@__FILE__))/../plot")

    mdata1 = getModelData(model)
    mdata2 = getModelData(getchildren(model)[1])
    nrows1, ncols1 = size(mdata1.mat)
    nrows2, ncols = size(mdata2.mat)
    ncols2 = ncols - ncols1

    mat = mdata2.mat[: , ncols1+1:end]

    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()

    plt.savefig("$DIR_NAME/$INSTANCE.pdf")
    #plt.close()
end

function plotComplicatingBlock(model::JuMP.Model, INSTANCE::String="instance_block_T", DIR_NAME::String="$(dirname(@__FILE__))/../plot")
    mdata1 = getModelData(model)
    mdata2 = getModelData(getchildren(model)[1])
    nrows1, ncols1 = size(mdata1.mat)
    nrows2, ncols = size(mdata2.mat)
    ncols2 = ncols - ncols1

    mat = mdata2.mat[: , 1:ncols1]

    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()

    plt.savefig("$DIR_NAME/$INSTANCE.pdf")
    #plt.close()
end

function plotAllBlocks(model::JuMP.Model, INSTANCE::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../plot")
    mdata1 = getModelData(model)
    mdata2 = getModelData(getchildren(model)[1])
    nrows1, ncols1 = size(mdata1.mat)
    nrows2, ncols = size(mdata2.mat)
    ncols2 = ncols - ncols1

    # plot Block A
    mat = mdata1.mat
    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()
    plt.savefig("$DIR_NAME/$(INSTANCE)_block_A.pdf")
    plt.close()

    # plot Block W
    mat = mdata2.mat[: , ncols1+1:end]
    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()
    plt.savefig("$DIR_NAME/$(INSTANCE)_block_W.pdf")
    plt.close()

    # plot Block T
    mat = mdata2.mat[: , 1:ncols1]
    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()

    plt.savefig("$DIR_NAME/$(INSTANCE)_block_T.pdf")
    plt.close()
end

function plotAll(model::JuMP.Model, INSTANCE::String="instance", DIR_NAME::String="$(dirname(@__FILE__))/../plot")
    mdata1 = getModelData(model)
    mdata2 = getModelData(getchildren(model)[1])
    nrows1, ncols1 = size(mdata1.mat)
    nrows2, ncols = size(mdata2.mat)
    ncols2 = ncols - ncols1

    # plot Block A
    mat = mdata1.mat
    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()
    plt.savefig("$DIR_NAME/$(INSTANCE)_block_A.pdf")
    plt.close()

    # plot Block W
    mat = mdata2.mat[: , ncols1+1:end]
    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()
    plt.savefig("$DIR_NAME/$(INSTANCE)_block_W.pdf")
    plt.close()

    # plot Block T
    mat = mdata2.mat[: , 1:ncols1]
    plt = PyPlot
    plt.spy(mat)
    plt.xticks([])
    plt.yticks([])
    plt.tight_layout()

    plt.savefig("$DIR_NAME/$(INSTANCE)_block_T.pdf")
    plt.close()

    # plot extensive form block
    plotConstrMatrix(model, INSTANCE, DIR_NAME)
    plt.close()
end

function getSize(model::JuMP.Model, InstanceName::String="")::Size

    mdata1 = getModelData(model)
    mdata2 = getModelData(getchildren(model)[1])
    nrows1, ncols1 = size(mdata1.mat)
    nrows2, ncols = size(mdata2.mat)
    ncols2 = ncols - ncols1

    s = Size()

    s.InstanceName = InstanceName

    s.nCont1 = 0
    s.nBin1 = 0
    s.nInt1 = 0
    s.nCont2 = 0
    s.nBin2 = 0
    s.nInt2 = 0

    # calculate number of each variable
    for char in mdata1.ctype
        if char == 'C'
            s.nCont1  += 1
        elseif char == 'B'
            s.nBin1 += 1
        elseif char == 'I'
            s.nInt1 += 1
        end
    end

    for char in mdata2.ctype
        if char == 'C'
            s.nCont2 += 1
        elseif char == 'B'
            s.nBin2 += 1
        elseif char == 'I'
            s.nInt2 += 1
        end
    end

    s.nCont = s.nCont1 + nCont2 * num_scenarios(model)
    s.nBin = s.nBin1 + nBin2 * num_scenarios(model)
    s.nInt = s.nInt1 + nInt2 * num_scenarios(model)

    s.nRow = nrows1 + nrows2 * num_scenarios(model)
    s.nCol = ncols1 + ncols2 * num_scenarios(model)
    s.nNz = length(nonzeros(mdata1.mat)) + length(nonzeros(mdata2.mat)) * num_scenarios(model)

    return s
end

function getSparsity(model::JuMP.Model, InstanceName::String="")::Sparsity

    mdata1 = getModelData(model)
    mdata2 = getModelData(getchildren(model)[1])
    nrows1, ncols1 = size(mdata1.mat)
    nrows2, ncols = size(mdata2.mat)
    ncols2 = ncols - ncols1

    s = Sparsity()

    s.InstanceName = InstanceName

    s.nRow1 = nrows1
    s.nCol1 = ncols1
    s.nNz1 = length(nonzeros(mdata1.mat))
    s.sparsity1 = s.nNz1 / (s.nRow1 * s.nCol1)

    s.nRow2 = nrows2
    s.nCol2 = ncols2
    s.nNz2 = length(nonzeros(mdata2.mat[: , ncols1+1:end]))
    s.sparsity2 = s.nNz2 / (s.nRow2 * s.nCol2)

    s.nRowC = s.nRow2
    s.nColC = s.nCol1
    s.nNzC = length(nonzeros(mdata2.mat[: , 1:ncols1+1]))
    s.sparsityC = s.nNzC / (s.nRowC * s.nColC)

    s.nRow = s.nRow1 + s.nRow2 * num_scenarios(model)
    s.nCol = s.nCol1 + s.nCol2 * num_scenarios(model)
    s.nNz = s.nNz1 + (s.nNz2 + s.nNzC) * num_scenarios(model)
    s.sparsity = s.nNz / (s.nRow * s.nCol)

    return s
end

#=
type InstanceSizeInfo
    InstanceName::String
    # 1st stage variables
    numCont1::Int
    numBin1::Int
    numInt1::Int

    # 2nd stage variables (1 scenario)
    numCont2::Int
    numBin2::Int
    numInt2::Int

    # in total
    numCont::Int
    numBin::Int
    numInt::Int

    numRows::Int
    numCols::Int
    numNonzeros::Int
    nonzeroDensity::Float64

    InstanceSizeInfo() = new()
end

# TODO
type SMPSFileSizeInfo
    InstanceName::String
    coreFileSize::Float64
    timeFileSize::Float64
    stochFileSize::Float64

    SMPSFileSizeInfo() = new("", 0.0, 0.0, 0.0)
end

function getInstanceSizeInfo(INSTANCE::String, m::JuMP.Model)::InstanceSizeInfo

    ISI = InstanceSizeInfo()
    ISI.InstanceName = INSTANCE
    mdata_all = SmpsWriter.getStructModelData(m)

    # calculate density information
    nrows2, ncols2 = size(mdata_all[1].mat)
    nrows2, ncols = size(mdata_all[2].mat)
    ncols2 = ncols - ncols2

    nrows_de = nrows2 + num_scenarios(m)*nrows2
    ncols_de = ncols2 + num_scenarios(m)*ncols2
    numNonzeros = length(nonzeros(mdata_all[1].mat)) + length(nonzeros(mdata_all[2].mat))*num_scenarios(m)

    density = (numNonzeros)/(nrows_de*ncols_de)
    percentDensity = round(density*100, 4)

    ISI.numRows = nrows_de
    ISI.numCols = ncols_de
    ISI.numNonzeros = numNonzeros
    ISI.nonzeroDensity = percentDensity

    # calculate variable information
    numCont1 = 0
    numBin1 = 0
    numInt1 = 0
    numCont2 = 0
    numBin2 = 0
    numInt2 = 0

    for char in mdata_all[1].ctype
        if char == 'C'
            numCont1 += 1
        elseif char == 'B'
            numBin1 += 1
        elseif char == 'I'
            numInt1 += 1
        end
    end

    for char in mdata_all[2].ctype
        if char == 'C'
            numCont2 += 1
        elseif char == 'B'
            numBin2 += 1
        elseif char == 'I'
            numInt2 += 1
        end
    end

    ISI.numCont1 = numCont1
    ISI.numBin1 = numBin1
    ISI.numInt1 = numInt1

    ISI.numCont2 = numCont2
    ISI.numBin2 = numBin2
    ISI.numInt2 = numInt2

    ISI.numCont= numCont1 + numCont2*num_scenarios(m)
    ISI.numBin = numBin1 + numBin2*num_scenarios(m)
    ISI.numInt = numInt1 + numInt2*num_scenarios(m)

    return ISI
end

function convertISItoVector(ISI::InstanceSizeInfo)
    tempv = Any[]
    push!(tempv, ISI.InstanceName)
    push!(tempv, ISI.numCont1)
    push!(tempv, ISI.numBin1)
    push!(tempv, ISI.numInt1)
    push!(tempv, ISI.numCont2)
    push!(tempv, ISI.numBin2)
    push!(tempv, ISI.numInt2)
    push!(tempv, ISI.numCont)
    push!(tempv, ISI.numBin)
    push!(tempv, ISI.numInt)
    push!(tempv, ISI.numRows)
    push!(tempv, ISI.numCols)
    push!(tempv, ISI.numNonzeros)
    push!(tempv, ISI.nonzeroDensity)
    return tempv
end

=#
