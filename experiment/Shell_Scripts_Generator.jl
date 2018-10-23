#using Siplib

THIS_FILE_PATH = dirname(@__FILE__)   # /siplib/experiment
DIR = "$THIS_FILE_PATH/shell_scripts" # make folder: /siplib/experiment/shell_scripts
#mkdir(DIR)

# Shell script for solving RP using CPLEX (DSP de)
mkdir("$DIR/RP_CPLEX")
for prob in problem
    mkdir("$DIR/RP_CPLEX/$prob")
    for param in param_set[prob]
        fp = open("$DIR/RP_CPLEX/$prob/$(getInstanceName(prob,param)).sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J SIPLIB_$(getInstanceName(prob,param))")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
        println(fp, "#SBATCH --ntasks-per-node=36")
        println(fp, "#SBATCH -t 01:20:00")
        println(fp, "")
        println(fp, "export prob=$prob")

        println(fp, "export num_cores_only=/home/choy/Siplib/experiment/DSP/parameters/num_cores_only.txt")
        println(fp, "")
        println(fp, """/home/choy/DSP/build/bin/runDsp --param "\$num_cores_only" --algo de --smps "\$\{filename\%.*\}" --soln "../logs/\$prob/\$(basename \$\{filename\%.*\})_cplex" > "../logs/\$prob/\$(basename \$\{filename\%.*\})_cplex.log.txt";""")
        close(fp)
    end
end

# Shell script for solving RP using DSP (dual decomposition)
mkdir("$DIR/RP_DSP")
for prob in problem
    mkdir("$DIR/RP_DSP/$prob")
    for param in param_set[prob]
        fp = open("$DIR/RP_DSP/$prob/$(getInstanceName(prob,param)).sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J SIPLIB_$(getInstanceName(prob,param))")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
        println(fp, "#SBATCH --ntasks-per-node=36")
        println(fp, "#SBATCH -t 01:20:00")
        println(fp, "")
        println(fp, "export prob=$prob")

        println(fp, "export num_cores_only=/home/choy/Siplib/experiment/DSP/parameters/num_cores_only.txt")
        println(fp, "")
        println(fp, """/home/choy/DSP/build/bin/runDsp --param "\$num_cores_only" --algo de --smps "\$\{filename\%.*\}" --soln "../logs/\$prob/\$(basename \$\{filename\%.*\})_cplex" > "../logs/\$prob/\$(basename \$\{filename\%.*\})_cplex.log.txt";""")
        close(fp)
    end
end

# Shell script for solving LP2 using CPLEX (DSP de)
mkdir("$DIR/RP_DSP")
for prob in problem
    mkdir("$DIR/RP_DSP/$prob")
    for param in param_set[prob]
        fp = open("$DIR/RP_DSP/$prob/$(getInstanceName(prob,param)).sh", "w")
        println(fp, "#!/bin/bash")
        println(fp, "#SBATCH -J SIPLIB_$(getInstanceName(prob,param))")
        println(fp, "#SBATCH -p bdwall")
        println(fp, "#SBATCH -A NEXTGENOPT")
        println(fp, "#SBATCH -N 1")
        println(fp, "#SBATCH --ntasks-per-node=36")
        println(fp, "#SBATCH -t 01:20:00")
        println(fp, "")
        println(fp, "export prob=$prob")

        println(fp, "export num_cores_only=/home/choy/Siplib/experiment/DSP/parameters/num_cores_only.txt")
        println(fp, "")
        println(fp, """/home/choy/DSP/build/bin/runDsp --param "\$num_cores_only" --algo de --smps "\$\{filename\%.*\}" --soln "../logs/\$prob/\$(basename \$\{filename\%.*\})_cplex" > "../logs/\$prob/\$(basename \$\{filename\%.*\})_cplex.log.txt";""")
        close(fp)
    end
end

# Shell script for solving single scenario problems using CPLEX (DSP de)

# Shell script for solving EEV (expected value problem) using CPLEX (DSP de)
