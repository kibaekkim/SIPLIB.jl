THIS_FILE_PATH = dirname(@__FILE__)
include("$THIS_FILE_PATH/../src/Siplib.jl")
using Siplib
using CSV
using DataFrames

function parse_obj(FILE::String)
    line_array = readlines(FILE)
    for line in line_array
        range1 = search(line, "MIP - Integer optimal")
        if length(range1) != 0
            range2 = search(line, "Objective")
            return float(line[range2[end]+4:end])
        end
    end
end

csv = readdlm("$THIS_FILE_PATH/computation_report_solvers.csv", ',')

instance_name = csv[3:end,1]
cplex_obj = csv[3:end,2]
obj_dict = Dict(zip(instance_name,cplex_obj))
df = DataFrame(instance=String[], EF=Any[], LP2_Obj=Any[], LP2_Relax_Gap=Any[])

for prob in problem
    for param in param_set[prob]
        instance = getInstanceName(prob,param)
        LOG_FILE = "$THIS_FILE_PATH/logs/$prob/LP2_DSP_de/$(instance)_LP2_DSP_de_log.txt"
        lp2_obj = float(readlines(LOG_FILE)[end-1][15:end])
        gap = abs(obj_dict[instance]-lp2_obj)/abs(obj_dict[instance])*100
        push!(df,[instance,round(obj_dict[instance],4),round(lp2_obj,4),round(gap,4)])
        #push!(df,[instance,"%.2f" % gap])
    end
end

CSV.write("$THIS_FILE_PATH/tables/LP2_GAP.csv" , df)
