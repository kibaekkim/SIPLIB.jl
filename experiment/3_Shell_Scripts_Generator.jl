#using Siplib

THIS_FILE_PATH = dirname(@__FILE__)
DIR = "$THIS_FILE_PATH/shell_scripts/sh_files_to_submit_jobs"
mkdir(DIR)

param_set = arrayParams()
for prob in problem
    mkdir("$DIR/$prob")
    for param in param_set[prob]
#        generateSMPS(prob, param, SMPS_PATH*"/$(String(prob))", genericnames=false)
        fp = open("$DIR/$prob/$(getInstanceName(prob,param)).sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J SIPLIB_$(getInstanceName(prob,param))")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
        println(fp, "#SBATCH --ntasks-per-node=36")
        println(fp, "#SBATCH -t 01:20:00")
        println(fp, "")
        println(fp, "export prob=$prob")
        println(fp, "export de_param=/home/choy/Siplib/experiment/DSP/parameters/de_3h.txt")
        println(fp, "export dd_param=/home/choy/Siplib/experiment/DSP/parameters/dd_3h.txt")
        println(fp, "export num_cores_only=/home/choy/Siplib/experiment/DSP/parameters/num_cores_only.txt")
        println(fp, "")
        println(fp, """/home/choy/DSP/build/bin/runDsp --param "\$num_cores_only" --algo de --smps "\$\{filename\%.*\}" --soln "../logs/\$prob/\$(basename \$\{filename\%.*\})_cplex" > "../logs/\$prob/\$(basename \$\{filename\%.*\})_cplex.log.txt";""")
        close(fp)
    end
end
