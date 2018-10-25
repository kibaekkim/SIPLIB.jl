#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/SDCP/SS/SDCP_5_10_SummerWE_10_SS6.mps" "optimize" "write" "$solution_dir/SDCP/SS_CPLEX/SDCP_5_10_SummerWE_10_SS6_CPLEX_sol.txt" "sol" > "$log_dir/SDCP/EV_CPLEX/SDCP_5_10_SummerWE_10_SS6_CPLEX_log.txt"  
