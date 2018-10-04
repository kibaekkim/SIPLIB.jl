#!/bin/bash
#SBATCH -J SIPLIB_SIZES_3
#SBATCH -p bdwall
#SBATCH -A NEXTGENOPT
#SBATCH -N 1
#SBATCH --ntasks-per-node=36
#SBATCH -t 01:20:00

export prob=SIZES
export de_param=/home/choy/Siplib/experiment/DSP/parameters/de_3h.txt
export dd_param=/home/choy/Siplib/experiment/DSP/parameters/dd_3h.txt
export num_cores_only=/home/choy/Siplib/experiment/DSP/parameters/num_cores_only.txt

/home/choy/DSP/build/bin/runDsp --param "$num_cores_only" --algo de --smps "${filename%.*}" --soln "../logs/$prob/$(basename ${filename%.*})_cplex" > "../logs/$prob/$(basename ${filename%.*})_cplex.log.txt";
