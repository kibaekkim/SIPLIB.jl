#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/SSLP/SS/SSLP_10_50_2000_SS303.mps" "optimize" "write" "$solution_dir/SSLP/SS_CPLEX/SSLP_10_50_2000_SS303_CPLEX_sol.txt" "sol" > "$log_dir/SSLP/EV_CPLEX/SSLP_10_50_2000_SS303_CPLEX_log.txt"  
