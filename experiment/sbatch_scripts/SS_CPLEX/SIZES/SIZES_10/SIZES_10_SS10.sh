#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/SIZES/SS/SIZES_10_SS10.mps" "optimize" "write" "$solution_dir/SIZES/SS_CPLEX/SIZES_10_SS10_CPLEX_sol.txt" "sol" > "$log_dir/SIZES/EV_CPLEX/SIZES_10_SS10_CPLEX_log.txt"  
