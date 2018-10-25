export DIR=$PWD/sbatch_scripts/EV_CPLEX
for file in $DIR/*; do
 sbatch $file
done
