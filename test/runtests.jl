using SIPLIB
using Test

include("../instances/AIRLIFT/AIRLIFT_model.jl")
include("../instances/CARGO/CARGO_model.jl")
include("../instances/CHEM/CHEM_model.jl")
include("../instances/DCAP/DCAP_model.jl")
include("../instances/MPTSPs/MPTSPs_model.jl")
include("../instances/PHONE/PHONE_model.jl")
include("../instances/SDCP/SDCP_model.jl")
include("../instances/SIZES/SIZES_model.jl")
include("../instances/SMKP/SMKP_model.jl")
include("../instances/SSLP/SSLP_model.jl")
include("../instances/SUC/SUC_model.jl")

SIPLIB.write_smps(AIRLIFT(5), "AIRLIFT_5", mktempdir())
SIPLIB.write_smps(CARGO(5), "CARGO_5", mktempdir())
SIPLIB.write_smps(CHEM(5), "CHEM_5", mktempdir())
SIPLIB.write_smps(DCAP(2,2,3,5), "DCAP_2_2_3_10", mktempdir())
SIPLIB.write_smps(MPTSPs("D0",5,5), "MPTSPs_D0_5_5", mktempdir())
SIPLIB.write_smps(PHONE(5), "PHONE_5", mktempdir())
SIPLIB.write_smps(SDCP(5,10,"FallWD",5), "SDCP_5_10_FallWD_5", mktempdir())
SIPLIB.write_smps(SIZES(5), "SIZES_5", mktempdir())
SIPLIB.write_smps(SMKP(5,5), "SMKP_5_5", mktempdir())
SIPLIB.write_smps(SSLP(5,25,5), "SSLP_5_25_5", mktempdir())
SIPLIB.write_smps(SUC("FallWD",5), "SUC_FallWD_5", mktempdir())

