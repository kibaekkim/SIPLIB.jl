export DIR=$PWD/sbatch_scripts/EF_DSP_de

for file in $DIR/*; do
 sbatch $file
done
