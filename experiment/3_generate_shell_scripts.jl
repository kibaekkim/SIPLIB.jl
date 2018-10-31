THIS_FILE_PATH = dirname(@__FILE__)
include("$THIS_FILE_PATH/../src/Siplib.jl")
using Siplib

mkdir("$THIS_FILE_PATH/sbatch_scripts")

# for EF_DSP_de
mkdir("$THIS_FILE_PATH/sbatch_scripts/EF_DSP_de")
for prob in problem
    mkdir("$THIS_FILE_PATH/sbatch_scripts/EF_DSP_de/$prob")
    for param in param_set[prob]
        fp = open("$THIS_FILE_PATH/sbatch_scripts/EF_DSP_de/$prob/$(getInstanceName(prob,param)).sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J EF_DSP_de")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
#        println(fp, "#SBATCH -t 01:10:00")
        println(fp, "")
        println(fp, "export parameter_file=$THIS_FILE_PATH/solver_parameters/param_EF_DSP_de.txt")
        println(fp, "export solution_dir=$THIS_FILE_PATH/solutions")
        println(fp, "export log_dir=$THIS_FILE_PATH/logs")
        println(fp, "")
#        println(fp, "rm -r \$solution_dir/$prob/EF_DSP_de/$(getInstanceName(prob,param))*")
#        println(fp, "rm -r \$log_dir/$prob/EF_DSP_de/$(getInstanceName(prob,param))*")
        println(fp, """runDsp --algo de --smps $THIS_FILE_PATH/FULL_INSTANCE/$prob/EF/$(getInstanceName(prob,param)) --param \$parameter_file --soln "\$solution_dir/$prob/EF_DSP_de/$(getInstanceName(prob,param))_EF_DSP_de_sol" > "\$log_dir/$prob/EF_DSP_de/$(getInstanceName(prob,param))_EF_DSP_de_log.txt" """)
        close(fp)
    end
end

# for EF_DSP_dd
mkdir("$THIS_FILE_PATH/sbatch_scripts/EF_DSP_dd")
for prob in problem
    mkdir("$THIS_FILE_PATH/sbatch_scripts/EF_DSP_dd/$prob")
    for param in param_set[prob]
        fp = open("$THIS_FILE_PATH/sbatch_scripts/EF_DSP_dd/$prob/$(getInstanceName(prob,param)).sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J EF_DSP_dd")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
#        println(fp, "#SBATCH -t 01:10:00")
        println(fp, "")
        println(fp, "export parameter_file=$THIS_FILE_PATH/solver_parameters/param_EF_DSP_dd.txt")
        println(fp, "export solution_dir=$THIS_FILE_PATH/solutions")
        println(fp, "export log_dir=$THIS_FILE_PATH/logs")
        println(fp, "")
#        println(fp, "rm -r \$solution_dir/$prob/EF_DSP_dd/$(getInstanceName(prob,param))*")
#        println(fp, "rm -r \$log_dir/$prob/EF_DSP_dd/$(getInstanceName(prob,param))*")
        if param[end] >= 36
            println(fp, """mpiexec -n 36 runDsp --algo dd --smps $THIS_FILE_PATH/FULL_INSTANCE/$prob/EF/$(getInstanceName(prob,param)) --param \$parameter_file --soln "\$solution_dir/$prob/EF_DSP_dd/$(getInstanceName(prob,param))_EF_DSP_dd_sol" > "\$log_dir/$prob/EF_DSP_dd/$(getInstanceName(prob,param))_EF_DSP_dd_log.txt" """)
        else
            println(fp, """mpiexec -n $(param[end]) runDsp --algo dd --smps $THIS_FILE_PATH/FULL_INSTANCE/$prob/EF/$(getInstanceName(prob,param)) --param \$parameter_file --soln "\$solution_dir/$prob/EF_DSP_dd/$(getInstanceName(prob,param))_EF_DSP_dd_sol" > "\$log_dir/$prob/EF_DSP_dd/$(getInstanceName(prob,param))_EF_DSP_dd_log.txt" """)
        end
        close(fp)
    end
end

# for LD_DSP_dd
mkdir("$THIS_FILE_PATH/sbatch_scripts/LD_DSP_dd")
for prob in problem
    mkdir("$THIS_FILE_PATH/sbatch_scripts/LD_DSP_dd/$prob")
    for param in param_set[prob]
        fp = open("$THIS_FILE_PATH/sbatch_scripts/LD_DSP_dd/$prob/$(getInstanceName(prob,param)).sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J LD_DSP_dd")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
#        println(fp, "#SBATCH -t 01:10:00")
        println(fp, "")
        println(fp, "export parameter_file=$THIS_FILE_PATH/solver_parameters/param_LD_DSP_dd.txt")
        println(fp, "export solution_dir=$THIS_FILE_PATH/solutions")
        println(fp, "export log_dir=$THIS_FILE_PATH/logs")
        println(fp, "")
#        println(fp, "rm -r \$solution_dir/$prob/LD_DSP_dd/$(getInstanceName(prob,param))*")
#        println(fp, "rm -r \$log_dir/$prob/LD_DSP_dd/$(getInstanceName(prob,param))*")
        if param[end] >= 36
            println(fp, """mpiexec -n 36 runDsp --algo dd --smps $THIS_FILE_PATH/FULL_INSTANCE/$prob/EF/$(getInstanceName(prob,param)) --param \$parameter_file --soln "\$solution_dir/$prob/LD_DSP_dd/$(getInstanceName(prob,param))_LD_DSP_dd_sol" > "\$log_dir/$prob/LD_DSP_dd/$(getInstanceName(prob,param))_LD_DSP_dd_log.txt" """)
        else
            println(fp, """mpiexec -n $(param[end]) runDsp --algo dd --smps $THIS_FILE_PATH/FULL_INSTANCE/$prob/EF/$(getInstanceName(prob,param)) --param \$parameter_file --soln "\$solution_dir/$prob/LD_DSP_dd/$(getInstanceName(prob,param))_LD_DSP_dd_sol" > "\$log_dir/$prob/LD_DSP_dd/$(getInstanceName(prob,param))_LD_DSP_dd_log.txt" """)
        end
        close(fp)
    end
end

# for LP2_DSP_de
mkdir("$THIS_FILE_PATH/sbatch_scripts/LP2_DSP_de")
for prob in problem
    mkdir("$THIS_FILE_PATH/sbatch_scripts/LP2_DSP_de/$prob")
    for param in param_set[prob]
        fp = open("$THIS_FILE_PATH/sbatch_scripts/LP2_DSP_de/$prob/$(getInstanceName(prob,param))_LP2.sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J LP2_DSP_de")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
#        println(fp, "#SBATCH -t 01:10:00")
        println(fp, "")
        println(fp, "export parameter_file=$THIS_FILE_PATH/solver_parameters/param_LP2_DSP_de.txt")
        println(fp, "export solution_dir=$THIS_FILE_PATH/solutions")
        println(fp, "export log_dir=$THIS_FILE_PATH/logs")
        println(fp, "")
#        println(fp, "rm -r \$solution_dir/$prob/LP2_DSP_de/$(getInstanceName(prob,param))*")
#        println(fp, "rm -r \$log_dir/$prob/LP2_DSP_de/$(getInstanceName(prob,param))*")
        println(fp, """runDsp --algo de --smps $THIS_FILE_PATH/FULL_INSTANCE/$prob/LP2/$(getInstanceName(prob,param))_LP2 --param \$parameter_file --soln "\$solution_dir/$prob/LP2_DSP_de/$(getInstanceName(prob,param))_LP2_DSP_de_sol" > "\$log_dir/$prob/LP2_DSP_de/$(getInstanceName(prob,param))_LP2_DSP_de_log.txt" """)
        close(fp)
    end
end

# for EV_CPLEX
mkdir("$THIS_FILE_PATH/sbatch_scripts/EV_CPLEX")
for prob in problem
    mkdir("$THIS_FILE_PATH/sbatch_scripts/EV_CPLEX/$prob")
    for param in param_set[prob]
        fp = open("$THIS_FILE_PATH/sbatch_scripts/EV_CPLEX/$prob/$(getInstanceName(prob,param))_EV.sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J EV_CPLEX")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
#        println(fp, "#SBATCH -t 01:10:00")
        println(fp, "")
        println(fp, "export solution_dir=$THIS_FILE_PATH/solutions")
        println(fp, "export log_dir=$THIS_FILE_PATH/logs")
        println(fp, "")
#        println(fp, "rm -r \$solution_dir/$prob/EV_CPLEX/$(getInstanceName(prob,param))*")
#        println(fp, "rm -r \$log_dir/$prob/EV_CPLEX/$(getInstanceName(prob,param))*")
        println(fp, """cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read $THIS_FILE_PATH/FULL_INSTANCE/$prob/EV/$(getInstanceName(prob,param))_EV.mps" "optimize" "write" "\$solution_dir/$prob/EV_CPLEX/$(getInstanceName(prob,param))_EV_CPLEX_sol.txt" "sol" > "\$log_dir/$prob/EV_CPLEX/$(getInstanceName(prob,param))_EV_CPLEX_log.txt"  """)
        close(fp)
    end
end

# for SS_CPLEX
mkdir("$THIS_FILE_PATH/sbatch_scripts/SS_CPLEX")
for prob in problem
    mkdir("$THIS_FILE_PATH/sbatch_scripts/SS_CPLEX/$prob")
    for param in param_set[prob]
        fp = open("$THIS_FILE_PATH/sbatch_scripts/SS_CPLEX/$prob/$(getInstanceName(prob,param))_SS.sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J SS")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
#        println(fp, "#SBATCH -t 01:10:00")
        println(fp, "")
        println(fp, "export solution_dir=$THIS_FILE_PATH/solutions")
        println(fp, "export log_dir=$THIS_FILE_PATH/logs")
        println(fp, "export DIR=$THIS_FILE_PATH/FULL_INSTANCE/$prob/SS/$(getInstanceName(prob,param))")
        println(fp, "")
#        println(fp, "rm -r \$solution_dir/$prob/SS_CPLEX/$(getInstanceName(prob,param))/$(getInstanceName(prob,param))*")
#        println(fp, "rm -r \$log_dir/$prob/SS_CPLEX/$(getInstanceName(prob,param))/$(getInstanceName(prob,param))*")
        println(fp, "for file in \$DIR/*; do")
        println(fp, " bname=`basename \${file%.*}`")
        #println(fp, """ cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read \$file" "optimize" "write" "$THIS_FILE_PATH/solutions/$prob/SS_CPLEX/$(getInstanceName(prob,param))/\${bname}_CPLEX_sol.txt" "sol" > "$THIS_FILE_PATH/logs/$prob/SS_CPLEX/$(getInstanceName(prob,param))/\${bname}_CPLEX_log.txt"  """)
        println(fp, """ cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read \$file" "optimize" > "$THIS_FILE_PATH/logs/$prob/SS_CPLEX/$(getInstanceName(prob,param))/\${bname}_CPLEX_log.txt"  """)
        println(fp, "done")
        close(fp)
    end
end
