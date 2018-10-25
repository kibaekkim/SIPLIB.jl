#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/SMKP/SS/SMKP_120_40_SS39.mps" "optimize" "write" "$solution_dir/SMKP/SS_CPLEX/SMKP_120_40_SS39_CPLEX_sol.txt" "sol" > "$log_dir/SMKP/EV_CPLEX/SMKP_120_40_SS39_CPLEX_log.txt"  
