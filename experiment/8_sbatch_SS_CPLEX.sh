export DIR=$PWD/sbatch_scripts/SS_CPLEX
for file in $DIR/*; do
 sbatch $file
done
