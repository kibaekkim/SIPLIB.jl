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
df = DataFrame(instance=String[], EF=Any[], WS=Any[], REVPI=Any[])

for prob in problem
    for param in param_set[prob]
        instance = getInstanceName(prob,param)
        ws = 0.0
        for s in 1:param[end]
            LOG_FILE = "$THIS_FILE_PATH/logs/$prob/SS_CPLEX/$instance/$(instance)_SS$(s)_CPLEX_log.txt"
            ss_obj = parse_obj(LOG_FILE)
            ws += ss_obj
        end
        ws = ws/param[end]
        gap = abs(obj_dict[instance]-ws)/abs(obj_dict[instance])*100
        push!(df,[instance,obj_dict[instance],ws,round(gap,4)])
        #push!(df,[instance,"%.2f" % gap])
    end
end

CSV.write("$THIS_FILE_PATH/tables/REVPI.csv" , df)
