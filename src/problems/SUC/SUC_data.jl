mutable struct SUCData

    # Sets
    G      # generators
    Gf     # fast generators
    Gs     # slow generators
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
    K  # commitment cost
    S  # startup cost

    # Capacity parameters
    B  # line susceptance
    Pmax # max generation capacity
    Pmin # min generation capacity
    Rmax # max ramping capacity
    Rmin # min ramping capacity
    TC   # transmission line capacity
    DT   # minimum downtime of generator g
    UT   # minimum uptime of generator g

    # Supply/demand parameters
    D    # netload in bus n, time t, scenario j
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

    SUCData() = new()
end

function SUCData(Season::AbstractString, nScenarios::Integer)::SUCData

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

    data = SUCData()

    # ---------------
    # Read data files
    # ---------------

    # BUSES
    data.N = readdlm("$DATA_DIR/Buses.txt");                     # list of buses
    data.gen2bus = readDict("$DATA_DIR/BusGenerators.txt");      # bus to generators
    data.import2bus = readDict("$DATA_DIR/BusImportPoints.txt"); # bus to import points
    data.load2bus = readDict("$DATA_DIR/BusLoads.txt");          # bus to loads
    data.re2bus = readDict("$DATA_DIR/BusREGenerators.txt");     # bus to RE generators
    data.wind2bus = readDict("$DATA_DIR/BusWindGenerators.txt"); # bus t wind generators

    # Generators
    data.G = readdlm("$DATA_DIR/Generators.txt");         # list of generators
    fastgen = readDict("$DATA_DIR/FastGenerators.txt")  # fast generators
    data.Gs = AbstractString[]
    data.Gf = AbstractString[]
    for g in data.G
        if fastgen[g] == "y"
            push!(data.Gf,g)
        else
            push!(data.Gs,g)
        end
    end
    data.Pmax = readDict("$DATA_DIR/MaxRunCapacity.txt"); # max generation capacity
    data.Pmin = readDict("$DATA_DIR/MinRunCapacity.txt"); # min generation capacity
    data.Rmin = readDict("$DATA_DIR/RampDown.txt");       # ramp down limit
    data.Rmax = readDict("$DATA_DIR/RampUp.txt");         # ramp up limit
    data.C = readDict("$DATA_DIR/FuelPrice.txt");         # generation cost
    data.K = readDict("$DATA_DIR/C0.txt");                # operating cost
    data.S = readDict("$DATA_DIR/SUC.txt");               # start-up cost
    data.UT = readDict("$DATA_DIR/UT.txt");               # minimum uptime
    data.DT = readDict("$DATA_DIR/DT.txt");               # minimum downtime
    # @show length(data.G)
    # @show length(data.Gs)
    # @show length(data.Gf)

    # Calculated Netdemand load
    data.LOAD = readdlm("$DATA_DIR/Loads.txt"); # list of loads
    tmp = readdlm("$DATA_DIR/Demand$Season.txt")
    data.load = create2DDict(tmp);
    # @show length(data.LOAD)

    # IMPORTS
    data.IMPORT = readdlm("$DATA_DIR/ImportPoints.txt");
    tmp = readdlm("$DATA_DIR/ImportProduction$Season.txt")
    data.Igen = create2DDict(tmp);
    # @show length(data.IMPORT)

    # Non-wind renewable production
    data.RE = readdlm("$DATA_DIR/REGenerators.txt");
    tmp = readdlm("$DATA_DIR/REProduction$Season.txt")
    data.Rgen = create2DDict(tmp);
    # @show length(data.RE)

    # Network
    data.L = readdlm("$DATA_DIR/Lines.txt"); # list of lines
    data.fbus = readDict("$DATA_DIR/FromBus.txt");
    data.tbus = readDict("$DATA_DIR/ToBus.txt");
    data.TC = readDict("$DATA_DIR/TC.txt"); # line capacity
    data.B = readDict("$DATA_DIR/Susceptance.txt");

    # WINDS
    data.WIND = readdlm("$DATA_DIR/WindGenerators.txt"); # list of wind generators
    dWindProductionSamples = readdlm("$WIND_DIR/WindProductionSamples.txt");
    # @show length(data.WIND)

    # ADDITIONAL PARAMETERS
    penetration = 0.1
    nPeriods = 24
    data.Pr = ones(nScenarios) / nScenarios # equal probabilities
    data.Cl = 5000 # value of lost load ($/MWh)
    data.Ci = 0 # import spillage penalty
    data.Cr = 0 # renewable spillage penalty
    data.Cw = 0 # wind spillage penalty

    # ADDITIONAL SETS
    data.T0 = 0:nPeriods;
    data.T = 1:nPeriods;

    # Wind production scenarios
    # TODO: not really generic
    reshapedWind = reshape(dWindProductionSamples[2:24001,2:6], nPeriods, 1000, length(data.WIND));
    data.Wgen = Dict();
    for w in 1:length(data.WIND)
        for t in data.T
            for s in 1:nScenarios
                # This calculates the production level scaled by a given penetration.
                data.Wgen[data.WIND[w],t,s] = reshapedWind[t,s,w] * penetration / 0.15;
            end
        end
    end

    data.D = Dict();
    for n = data.N
        for t = data.T
            nd = 0.0;
            for j in data.LOAD
                if data.load2bus[j] == n
                    nd += data.load[j,t];
                end
            end
            for j in data.IMPORT
                if data.import2bus[j] == n
                    nd -= data.Igen[j,t];
                end
            end
            for j in data.RE
                if data.re2bus[j] == n
                    nd -= data.Rgen[j,t];
                end
            end
            data.D[n,t] = nd
        end
    end

    return data
end
