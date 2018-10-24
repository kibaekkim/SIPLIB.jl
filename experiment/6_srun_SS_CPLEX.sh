export solution_dir=/home/choy/Siplib/experiment/solutions
export log_dir=/home/choy/Siplib/experiment/logs

for prob in AIRLIFT CARGO CHEM DCAP MPTSPs PHONE SDCP SIZES SMKP SSLP SUC; do
 instance_set="/home/choy/Siplib/experiment/FULL_INSTANCE/$prob/SS/*.mps"
 for instance in $instance_set; do
  bname=`basename ${instance%.*}`
  srun -A NEXTGENOPT -p bdwall -N 1 -t 00:00:10 cplex -c "set" "threads" "36" "set" "timelimit" "3600" "read $instance" "optimize" "write" "$solution_dir/$prob/SS_CPLEX/${bname}_CPLEX_sol.txt" "sol" > "$log_dir/$prob/SS_CPLEX/${bname}_CPLEX_log.txt" &
 done
done


