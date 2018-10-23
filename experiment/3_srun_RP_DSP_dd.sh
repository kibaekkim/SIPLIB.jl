export parameter_file=/home/choy/Siplib/experiment/solver_parameters/DSP_param_RP_dd.txt
export solution_dir=/home/choy/Siplib/experiment/solutions
export log_dir=/home/choy/Siplib/experiment/logs

for prob in AIRLIFT CARGO CHEM DCAP MPTSPs PHONE SDCP SIZES SMKP SSLP SUC; do
 instance_set="/home/choy/Siplib/experiment/FULL_INSTANCE/$prob/RP/*.cor"
 for instance in $instance_set; do
  bname=`basename ${instance%.*}`
  srun -A NEXTGENOPT -p bdwall -N 1 -t 01:10:00 mpiexec -n 36 runDsp --algo dd --smps ${instance%.*} --param $parameter_file --soln "$solution_dir/$prob/RP_DSP_dd/${bname}_RP_DSP_dd_sol" > "$log_dir/$prob/RP_DSP_dd/${bname}_RP_DSP_dd_log.txt" &
 done
done


