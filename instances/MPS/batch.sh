#!/bin/bash

FILES=../SMPS/*.cor

for f in $FILES
do
	fname="${f##*/}"
	smps="${f%.*}"
	mps="${fname%.*}"
	echo "Writing ${mps}.mps file."
	julia writeMps.jl $smps ${mps}.mps
done
