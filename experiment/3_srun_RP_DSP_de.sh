export parameter_file=/home/choy/Siplib/experiment/solver_parameters/DSP_param_RP_de.txt
export solution_dir=/home/choy/Siplib/experiment/solutions
export log_dir=/home/choy/Siplib/experiment/logs

for prob in AIRLIFT CARGO CHEM DCAP MPTSPs PHONE SDCP SIZES SMKP SSLP SUC; do
 instance_set="/home/choy/Siplib/experiment/FULL_INSTANCE/$prob/RP/*.cor"
 for instance in $instance_set; do
  bname=`basename ${instance%.*}`
  srun -A NEXTGENOPT -p bdwall -N 1 -t 01:10:00 runDsp --algo de --smps ${instance%.*} --param $parameter_file --soln "$solution_dir/$prob/RP_DSP_de/${bname}_RP_DSP_de_sol" > "$log_dir/$prob/RP_DSP_de/${bname}_RP_DSP_de_log.txt" &
 done
done


