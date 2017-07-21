#!/bin/bash

for f in *.txt
do
	if [ "$f" == "param.txt" ]
	then
		continue
	fi
	cat $f
done
