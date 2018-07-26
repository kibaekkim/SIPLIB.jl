#!/bin/bash
#SBATCH -J SIPLIB_DCAP
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1
#SBATCH --ntasks-per-node=36
#SBATCH -t 00:05:00

export prob=DCAP
export de_param=/home/choy/Siplib/experiment/DSP/parameters/de_3h.txt
export dd_param=/home/choy/Siplib/experiment/DSP/parameters/dd_3h.txt
export num_cores_only=/home/choy/Siplib/experiment/DSP/parameters/num_cores_only.txt

for filename in ../SMPS/$prob/*.cor; do
 /home/choy/DSP/build/bin/runDsp --param "$num_cores_only" --algo de --smps "${filename%.*}" --soln "../logs/$prob/$(basename ${filename%.*})_cplex" > "../logs/$prob/$(basename ${filename%.*})_cplex.log.txt";
# /home/choy/DSP/build/bin/runDsp --param $dd_param --algo dd --smps "${filename%.*}" --soln "../logs/$prob/$(basename ${filename%.*})_cplex" > "../logs/$prob/$(basename ${filename%.*})_dsp.log.txt";
done
