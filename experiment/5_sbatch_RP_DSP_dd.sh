export DIR=$PWD/sbatch_scripts/EF_DSP_dd

for file in $DIR/*; do
 sbatch $file
done
