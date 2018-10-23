# I want to run DSP-de to solve RP of all problems written in SMPS format, and save logs & solutions into siplib/experiment/logs folder

for prob in {AIRLIFT, CARGO, CHEM, DCAP, MPTSPs, PHONE, SDCP, SIZES, SMKP, SSLP, SUC}
 for filename in /home/choy/Siplib/experiment/FULL_INSTANCE/
  echo $prob
 done
done

for prob in "AIRLIFT" "CARGO" "CHEM" "DCAP" "MPTSPs" "PHONE" "SDCP" "SIZES" "SMKP" "SSLP" "SUC"; do
  echo "$prob"
done


for prob in AIRLIFT CARGO CHEM DCAP MPTSPs PHONE SDCP SIZES SMKP SSLP SUC; do
  echo "/home/choy/Siplib/experiment/FULL_INSTANCE/$prob"
done

for prob in AIRLIFT CARGO CHEM DCAP MPTSPs PHONE SDCP SIZES SMKP SSLP SUC; do
 base_set="/home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/$prob/RP/*.cor"
 for base in $base_set; do
  echo ${base%.*}
 done
done




#for prob in AIRLIFT CARGO CHEM DCAP MPTSPs PHONE SDCP SIZES SMKP SSLP SUC; do
for prob in AIRLIFT; do
 base_set="/home/yongkyu/GitRepositories/siplib/experiment/FULL_INSTANCE/$prob/RP/*.cor"
 for base in $base_set; do
  echo ${base%.*}
  fname=`basename ${base%.*}`
  echo $fname
  #srun -A NEXTGENOPT -p bdwall -N 1 --ntasks-per-node=36 -t 00:05:00 runDsp --algo de --smps ${base%.*} --param $parameter_file --soln "$solution_dir/$prob/RP_CPLEX/${base%.*}_RP_CPLEX_sol" > "$log_dir/$prob/RP_CPLEX/${base%.*}_RP_CPLEX_log.txt"
 done
done

