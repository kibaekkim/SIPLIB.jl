#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/CHEM/SS/CHEM_1000_SS430.mps" "optimize" "write" "$solution_dir/CHEM/SS_CPLEX/CHEM_1000_SS430_CPLEX_sol.txt" "sol" > "$log_dir/CHEM/EV_CPLEX/CHEM_1000_SS430_CPLEX_log.txt"  
