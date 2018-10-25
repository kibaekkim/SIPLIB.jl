#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/PHONE/SS/PHONE_1000_SS122.mps" "optimize" "write" "$solution_dir/PHONE/SS_CPLEX/PHONE_1000_SS122_CPLEX_sol.txt" "sol" > "$log_dir/PHONE/EV_CPLEX/PHONE_1000_SS122_CPLEX_log.txt"  
