# Test sets (c_: completed, w_: work in progress)

This folder contains test sets and their solutions.

You will find below 4-5 folders inside of each test set folder.

0) DATA folder: This exists only in case where data is required to construct model. If it does not exists, the model is constructed only by randomly generated parameters. This random generation is done by Julia package (Distribution.jl) or built-in random number generator (rand()).

1) JULIA folder: This contains the julia source code (.jl) that models the SIP as a 'JuMP.Model'-type object.

2) MPS folder: This contains MPS-type files.

3) SMPS folder: This contains SMPS-type files.

4) solutions folder: This contains solutions for benchmarking.


