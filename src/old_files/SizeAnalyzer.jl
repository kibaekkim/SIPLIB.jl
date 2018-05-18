#######################################################################################################################
## This module reads StructJuMP-type object and return a InstanceSizeInfo-type object that contains size information ##
#######################################################################################################################

# include SmpsWriter (to use the function SmpsWriter.getStructModelData)
include("$(dirname(@__FILE__))/SmpsWriter.jl")

module SizeAnalyzer

    using JuMP, StructJuMP, SmpsWriter

    export getInstanceSizeInfo, convertISItoVector

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
        nrows1, ncols1 = size(mdata_all[1].mat)
        nrows2, ncols = size(mdata_all[2].mat)
        ncols2 = ncols - ncols1

        nrows_de = nrows1 + num_scenarios(m)*nrows2
        ncols_de = ncols1 + num_scenarios(m)*ncols2
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

end

#=


include("../TestSets/DCAP/JULIA/dcap_models.jl")

## set parameters for instance
nR = 2      # number of items
nN = 3      # number of tasks
nT = 3      # number of time periods
nS = 100000 # number of scenarios

## set file name and path
INSTANCE = "DCAP_$(nR)_$(nN)_$(nT)_$(nS)"
m = dcap(nR,nN,nT,nS)

ISI = getInstanceSizeInfo(INSTANCE, m)

=#
