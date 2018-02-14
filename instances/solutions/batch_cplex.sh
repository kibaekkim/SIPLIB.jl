#!/bin/bash

for f in ../MPS/*.mps
do
	echo $f	
	julia cplex.jl $f
done
