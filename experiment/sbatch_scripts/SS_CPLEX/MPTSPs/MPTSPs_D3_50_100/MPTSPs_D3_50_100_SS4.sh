#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/MPTSPs/SS/MPTSPs_D3_50_100_SS4.mps" "optimize" "write" "$solution_dir/MPTSPs/SS_CPLEX/MPTSPs_D3_50_100_SS4_CPLEX_sol.txt" "sol" > "$log_dir/MPTSPs/EV_CPLEX/MPTSPs_D3_50_100_SS4_CPLEX_log.txt"  
