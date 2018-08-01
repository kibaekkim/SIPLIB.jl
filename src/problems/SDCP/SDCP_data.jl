mutable struct SDCPData

    # Sets
    S      # scenarios
    G      # generators
    L      # transmission lines
    N      # buses
    T      # time periods
    T0     # 0..|T|
    LOAD   # loads
    IMPORT # import points
    WIND   # wind farms
    RE     # renewable generators

    # Cost parameters
    C  # generation cost
    Cl # loadsheding cost
    Ci # import spillage cost
    Cr # renewable spillage cost
    Cw # wind spillage cost

    # Capacity parameters
    B  # line susceptance
    Pmax # max generation capacity
    Rdown # ramping down limit
    Rup # ramping up limit
    TC   # transmission line capacity

    # Supply/demand parameters
    Igen # generation from import points
    Rgen # generation from renewable
    Wgen # wind generation
    load # load at load i at time t

    # Mapping parameters
    gen2bus    # map generator to bus
    import2bus # map import point to bus
    load2bus   # map load to bus
    re2bus     # map renewable generator to bus
    wind2bus   # map wind farm to bus
    fbus       # bus from which line l flows
    tbus       # bus to which line l flows

    Pr # probability

    SDCPData() = new()
end


function SDCPData(PenetPercent::Any, Season::String, nScenarios::Int)::SDCPData

    # read file and create dictionary
    function readDict(f)
        d = readdlm(f);
        return Dict(zip(d[:,1], d[:,2]));
    end

    # read file and create dictionary in reverse column indices
    function readRDict(f)
        d = readdlm(f);
        return Dict(zip(d[:,2], d[:,1]));
    end

    # create a dictionary for 2-dimensional data
    function create2DDict(d)
        dd = Dict();
        for j in 2:size(d,2)
            for t = 1:24
                dd[d[1,j],t] = d[t+1,j]
            end
        end
        return dd;
    end

    # Set paths
    DATA_DIR = "$(dirname(@__FILE__))/DATA";
    WIND_DIR = "$DATA_DIR/WIND/$Season";

    data = SDCPData()

    # ---------------
    # Read data files
    # ---------------

    # BUSES
    data.N = readdlm("$DATA_DIR/Buses.txt");                     # list of buses (ZC_data.jl: BUSES)
    data.gen2bus = readDict("$DATA_DIR/BusGenerators.txt");      # bus to generators
    data.import2bus = readDict("$DATA_DIR/BusImportPoints.txt"); # bus to import points (ZC_data.jl: dBusImportPoints)
    data.load2bus = readDict("$DATA_DIR/BusLoads.txt");          # bus to loads (ZC_data.jl: dBusLoads)
    data.re2bus = readDict("$DATA_DIR/BusREGenerators.txt");     # bus to RE generators (ZC_data.jl: dBusREGenerators)
    data.wind2bus = readDict("$DATA_DIR/BusWindGenerators.txt"); # bus t wind generators (ZC_data.jl: dBusWindGenerators)

    # Generators
    data.G = readdlm("$DATA_DIR/Generators.txt");         # list of generators (ZC_data.jl: GENERATORS)
    data.Pmax = readDict("$DATA_DIR/MaxRunCapacity.txt"); # max generation capacity
    data.Rdown = readDict("$DATA_DIR/RampDown.txt");       # ramp down limit
    data.Rup = readDict("$DATA_DIR/RampUp.txt");         # ramp up limit
    data.C = readDict("$DATA_DIR/FuelPrice.txt");         # generation cost (ZC_data.jl: gen_cost)

    # Calculated Netdemand load
    data.LOAD = readdlm("$DATA_DIR/Loads.txt"); # list of loads (ZC_data.jl: LOADS)
    tmp = readdlm("$DATA_DIR/Demand$Season.txt")
    data.load = create2DDict(tmp);  # (ZC_data.jl: dictDemand)
    # @show length(data.LOAD)

    # IMPORTS
    data.IMPORT = readdlm("$DATA_DIR/ImportPoints.txt");    # (ZC_data.jl: IMPORTS)
    tmp = readdlm("$DATA_DIR/ImportProduction$Season.txt")
    data.Igen = create2DDict(tmp); # (ZC_data.jl: dictImportProduction)

    # Non-wind renewable production
    data.RE = readdlm("$DATA_DIR/REGenerators.txt");    # (ZC_data.jl: REGENERATORS)
    tmp = readdlm("$DATA_DIR/REProduction$Season.txt")
    data.Rgen = create2DDict(tmp);  # (ZC_data.jl: dictREProduction)
    # @show length(data.RE)

    # Network
    data.L = readdlm("$DATA_DIR/Lines.txt"); # list of lines (ZC_data.jl: LINES)
    data.fbus = readDict("$DATA_DIR/FromBus.txt"); # (ZC_data.jl: frombus)
    data.tbus = readDict("$DATA_DIR/ToBus.txt");    # (ZC_data.jl: tobus)
    data.TC = readDict("$DATA_DIR/TC.txt"); # (ZC_data.jl: flowmax)
    data.B = readDict("$DATA_DIR/Susceptance.txt"); # (ZC_data.jl: susceptance)

    # WINDS
    data.WIND = readdlm("$DATA_DIR/WindGenerators.txt"); # list of wind generators (ZC_data.jl: WINDS)
    dWindProductionSamples = readdlm("$WIND_DIR/WindProductionSamples.txt");
    # @show length(data.WIND)

    # ADDITIONAL PARAMETERS
    nPeriods = 24
    data.Pr = ones(nScenarios) / nScenarios # equal probabilities
    data.Cl = 1000 # value of lost load ($/MWh) (ZC_data.jl: voll)
    data.Ci = 1000 # import spillage penalty
    data.Cr = 2000 # renewable spillage penalty
    data.Cw = 100  # wind spillage penalty

    # ADDITIONAL SETS
    data.S = 1:nScenarios
    data.T0 = 0:nPeriods;
    data.T = 1:nPeriods; # (ZC_data.jl: PERIODS)

    # Wind production scenarios
    # TODO: not really generic
    reshapedWind = reshape(dWindProductionSamples[2:24001,2:6], nPeriods, 1000, length(data.WIND));
    data.Wgen = Dict();
    for w in 1:length(data.WIND)
        for t in data.T
            for s in 1:nScenarios
                # This calculates the production level scaled by a given penetration.
                data.Wgen[data.WIND[w],t,s] = reshapedWind[t,s,w] * (PenetPercent * 0.01) / 0.15;
            end
        end
    end

    return data
end

#=
data = SDCPData(5, "FallWD", 10)

count = 0
for n in data.N
    for l in data.L
        if data.tbus[l] == n
            count += 1
        end
    end
    for l in data.L
        if data.fbus[l] == n
            count += 1
        end
    end
    for g in data.G
        if data.gen2bus[g] == n
            count += 1
        end
    end
    for i in data.IMPORT
        if data.import2bus[i] == n
            count += 1
        end
    end
    for i in data.LOAD
        if data.load2bus[i] == n
            count += 1
        end
    end
    for i in data.WIND
        if data.wind2bus[i] == n
            count += 1
        end
    end
    for i in data.RE
        if data.re2bus[i] == n
            count += 1
        end
    end
    count += 1
end
count = 24*count
=#
