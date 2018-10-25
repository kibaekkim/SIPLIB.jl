export DIR=$PWD/sbatch_scripts/LP2_DSP_de
for file in $DIR/*; do
 sbatch $file
done
