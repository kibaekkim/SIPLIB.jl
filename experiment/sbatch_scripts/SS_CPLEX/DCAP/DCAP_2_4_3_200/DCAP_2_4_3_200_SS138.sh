#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/DCAP/SS/DCAP_2_4_3_200_SS138.mps" "optimize" "write" "$solution_dir/DCAP/SS_CPLEX/DCAP_2_4_3_200_SS138_CPLEX_sol.txt" "sol" > "$log_dir/DCAP/EV_CPLEX/DCAP_2_4_3_200_SS138_CPLEX_log.txt"  
