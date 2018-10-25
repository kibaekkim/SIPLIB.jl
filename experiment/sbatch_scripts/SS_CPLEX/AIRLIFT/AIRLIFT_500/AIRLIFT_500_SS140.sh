#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/AIRLIFT/SS/AIRLIFT_500_SS140.mps" "optimize" "write" "$solution_dir/AIRLIFT/SS_CPLEX/AIRLIFT_500_SS140_CPLEX_sol.txt" "sol" > "$log_dir/AIRLIFT/EV_CPLEX/AIRLIFT_500_SS140_CPLEX_log.txt"  
