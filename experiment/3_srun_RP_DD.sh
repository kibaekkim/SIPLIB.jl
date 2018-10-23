export parameter_file=/home/choy/Siplib/experiment/DSP_parameters/param_RP_DD.txt
export solution_dir=/home/choy/Siplib/experiment/solutions
export log_dir=/home/choy/Siplib/experiment/logs

#for prob in AIRLIFT CARGO CHEM DCAP MPTSPs PHONE SDCP SIZES SMKP SSLP SUC; do
for prob in AIRLIFT; do
 #base_set="/home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/$prob/RP/*.cor"
 base_set="/home/choy/Siplib/experiment/FULL_INSTANCE/$prob/RP/*.cor"
 for base in $base_set; do
  srun -A NEXTGENOPT -p bdwall -N 1 --ntasks-per-node=36 -t 00:05:00 runDsp --algo de --param $parameter_file --soln "$solution_dir/$prob/RP_DD/$(base)_RP_DD_sol" > "$log_dir/$prob/RP_DD/$(base)_RP_DD_log.txt"
 done
done
