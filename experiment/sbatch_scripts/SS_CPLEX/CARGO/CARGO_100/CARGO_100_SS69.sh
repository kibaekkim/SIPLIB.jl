#!/bin/bash
#SBATCH -J SIPLIB
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1

export solution_dir=/home/yongkyu/GitRepositories/siplib/experiment/solutions
export log_dir=/home/yongkyu/GitRepositories/siplib/experiment/logs

cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read /home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/CARGO/SS/CARGO_100_SS69.mps" "optimize" "write" "$solution_dir/CARGO/SS_CPLEX/CARGO_100_SS69_CPLEX_sol.txt" "sol" > "$log_dir/CARGO/EV_CPLEX/CARGO_100_SS69_CPLEX_log.txt"  
