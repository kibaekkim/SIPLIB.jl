#=
Source:
  A. Papavasiliou and S. Oren. (2013) Multiarea Stochastic Unit Commitment for High Wind
  Penetration in a Transmission Constrained Network. Operations Research 61(3):578-592
=#
cd(dirname(Base.source_path()))
using StructJuMP

type UnitCommitmentModel

    # Sets
    IMPORT # import points
    G      # generators
    Gf     # fast generators
    Gs     # slow generators
    L      # transmission lines
    LOAD   # loads
    N      # buses
    RE     # renewable generators
    T      # time periods
    T0     # 0..|T|
    WIND   # wind farms

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
    D    # netload in bus n, time t, scenarion j
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

    π # probability

    UnitCommitmentModel() = new()
end

function suc_wecc(nScenarios::Integer, Season::AbstractString)::JuMP.Model
    # get model data
    uc = weccdata(nScenarios, Season)

    model = StructuredModel(num_scenarios=nScenarios)

    @variable(model, w[g=uc.Gs,t=uc.T0], Bin)
    @variable(model, 0 <= z[g=uc.Gs,t=uc.T] <= 1)

    @objective(model, Min,
        sum(uc.K[g]*w[g,t] + uc.S[g]*z[g,t] for g in uc.Gs for t in uc.T)
    )

    # Unit commitment for slow generators
    @constraint(model, [g=uc.Gs,t=Int(uc.UT[g]):length(uc.T)], sum(z[g,q] for q=Int(t-uc.UT[g]+1):t) <= w[g,t])
    @constraint(model, [g=uc.Gs,t=1:Int(length(uc.T)-uc.DT[g])], sum(z[g,q] for q=(t+1):Int(t+uc.DT[g])) <= w[g,t])
    @constraint(model, [g=uc.Gs,t=uc.T], z[g,t] >= w[g,t] - w[g,t-1])

    for j in 1:nScenarios
        sb = StructuredModel(parent=model, id = j, prob = uc.π[j])

        @variable(sb, u[g=uc.Gf,t=uc.T0], Bin)
        @variable(sb, 0 <= v[g=uc.Gf,t=uc.T] <= 1)
        @variable(sb, -360 <= θ[n=uc.N,t=uc.T] <= 360)
        @variable(sb, -uc.TC[l] <= e[l=uc.L,t=uc.T] <= uc.TC[l])
        @variable(sb, p[g=uc.G,t=uc.T0] >= 0)
        @variable(sb, 0 <= loadshed[i=uc.LOAD,t=uc.T] <= uc.load[i,t]) # load shedding
        @variable(sb, 0 <= ispill[i=uc.IMPORT,t=uc.T] <= uc.Igen[i,t]) # import spillage
        @variable(sb, 0 <= rspill[i=uc.RE,t=uc.T] <= uc.Rgen[i,t])     # renewable spillage
        @variable(sb, 0 <= wspill[i=uc.WIND,t=uc.T] <= uc.Wgen[i,t,j])   # wind spillage

        @objective(sb, Min,
              sum(uc.K[g]*u[g,t] + uc.S[g]*v[g,t] for g in uc.Gf for t in uc.T)
            + sum(uc.C[g]*p[g,t] for g in uc.G for t in uc.T)
            + sum(uc.Cl * loadshed[i,t] for i in uc.LOAD for t in uc.T)
            + sum(uc.Ci * ispill[i,t] for i in uc.IMPORT for t in uc.T)
            + sum(uc.Cr * rspill[i,t] for i in uc.RE for t in uc.T)
            + sum(uc.Cw * wspill[i,t] for i in uc.WIND for t in uc.T)
        )

        # Unit commitment for fast generators
        @constraint(sb, [g=uc.Gf,t=Int(uc.UT[g]):length(uc.T)], sum(v[g,q] for q=Int(t-uc.UT[g]+1):t) <= u[g,t])
        @constraint(sb, [g=uc.Gf,t=1:Int(length(uc.T)-uc.DT[g])], sum(v[g,q] for q=(t+1):Int(t+uc.DT[g])) <= u[g,t])
        @constraint(sb, [g=uc.Gf,t=uc.T], v[g,t] >= u[g,t] - u[g,t-1])

        # Flow balance
        @constraint(sb, [n=uc.N,t=uc.T],
            sum(e[l,t] for l in uc.L if uc.tbus[l] == n)
            + sum(p[g,t] for g in uc.G if uc.gen2bus[g] == n)
            + sum(loadshed[i,t] for i in uc.LOAD if uc.load2bus[i] == n)
            + sum(uc.Wgen[i,t,j] for i in uc.WIND if uc.wind2bus[i] == n)
            == uc.D[n,t]
            + sum(e[l,t] for l in uc.L if uc.fbus[l] == n)
            + sum(ispill[i,t] for i in uc.IMPORT if uc.import2bus[i] == n)
            + sum(rspill[i,t] for i in uc.RE if uc.re2bus[i] == n)
            + sum(wspill[i,t] for i in uc.WIND if uc.wind2bus[i] == n)
        )

        # Power flow equation
        @constraint(sb, [l=uc.L,t=uc.T], e[l,t] == uc.B[l] * (θ[uc.fbus[l],t] - θ[uc.tbus[l],t]))

        # Max generation capacity
        @constraint(sb, [g=uc.Gs,t=uc.T0], p[g,t] <= uc.Pmax[g] * w[g,t])
        @constraint(sb, [g=uc.Gf,t=uc.T0], p[g,t] <= uc.Pmax[g] * u[g,t])

        # # Min generation capacity
        @constraint(sb, [g=uc.Gs,t=uc.T0], p[g,t] >= uc.Pmin[g] * w[g,t])
        @constraint(sb, [g=uc.Gf,t=uc.T0], p[g,t] >= uc.Pmin[g] * u[g,t])

        # Ramping capacity
        @constraint(sb, [g=uc.G,t=uc.T], p[g,t] - p[g,t-1] <= uc.Rmax[g])
        @constraint(sb, [g=uc.G,t=uc.T], p[g,t] - p[g,t-1] >= -uc.Rmin[g])
    end

    return model
end

function weccdata(nScenarios::Integer, Season::AbstractString)::UnitCommitmentModel

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
    DATA_DIR = "./WECC_DATA";
    WIND_DIR = "$DATA_DIR/WIND/$Season";

    uc = UnitCommitmentModel()

    # ---------------
    # Read data files
    # ---------------

    # BUSES
    uc.N = readdlm("$DATA_DIR/Buses.txt");                     # list of buses
    uc.gen2bus = readDict("$DATA_DIR/BusGenerators.txt");      # bus to generators
    uc.import2bus = readDict("$DATA_DIR/BusImportPoints.txt"); # bus to import points
    uc.load2bus = readDict("$DATA_DIR/BusLoads.txt");          # bus to loads
    uc.re2bus = readDict("$DATA_DIR/BusREGenerators.txt");     # bus to RE generators
    uc.wind2bus = readDict("$DATA_DIR/BusWindGenerators.txt"); # bus t wind generators

    # Generators
    uc.G = readdlm("$DATA_DIR/Generators.txt");         # list of generators
    fastgen = readDict("$DATA_DIR/FastGenerators.txt")  # fast generators
    uc.Gs = AbstractString[]
    uc.Gf = AbstractString[]
    for g in uc.G
        if fastgen[g] == "y"
            push!(uc.Gf,g)
        else
            push!(uc.Gs,g)
        end
    end
    uc.Pmax = readDict("$DATA_DIR/MaxRunCapacity.txt"); # max generation capacity
    uc.Pmin = readDict("$DATA_DIR/MinRunCapacity.txt"); # min generation capacity
    uc.Rmin = readDict("$DATA_DIR/RampDown.txt");       # ramp down limit
    uc.Rmax = readDict("$DATA_DIR/RampUp.txt");         # ramp up limit
    uc.C = readDict("$DATA_DIR/FuelPrice.txt");         # generation cost
    uc.K = readDict("$DATA_DIR/C0.txt");                # operating cost
    uc.S = readDict("$DATA_DIR/SUC.txt");               # start-up cost
    uc.UT = readDict("$DATA_DIR/UT.txt");               # minimum uptime
    uc.DT = readDict("$DATA_DIR/DT.txt");               # minimum downtime
    # @show length(uc.G)
    # @show length(uc.Gs)
    # @show length(uc.Gf)

    # Calculated Netdemand load
    uc.LOAD = readdlm("$DATA_DIR/Loads.txt"); # list of loads
    tmp = readdlm("$DATA_DIR/Demand$Season.txt")
    uc.load = create2DDict(tmp);
    # @show length(uc.LOAD)

    # IMPORTS
    uc.IMPORT = readdlm("$DATA_DIR/ImportPoints.txt");
    tmp = readdlm("$DATA_DIR/ImportProduction$Season.txt")
    uc.Igen = create2DDict(tmp);
    # @show length(uc.IMPORT)

    # Non-wind renewable production
    uc.RE = readdlm("$DATA_DIR/REGenerators.txt");
    tmp = readdlm("$DATA_DIR/REProduction$Season.txt")
    uc.Rgen = create2DDict(tmp);
    # @show length(uc.RE)

    # Network
    uc.L = readdlm("$DATA_DIR/Lines.txt"); # list of lines
    uc.fbus = readDict("$DATA_DIR/FromBus.txt");
    uc.tbus = readDict("$DATA_DIR/ToBus.txt");
    uc.TC = readDict("$DATA_DIR/TC.txt"); # line capacity
    uc.B = readDict("$DATA_DIR/Susceptance.txt");

    # WINDS
    uc.WIND = readdlm("$DATA_DIR/WindGenerators.txt"); # list of wind generators
    dWindProductionSamples = readdlm("$WIND_DIR/WindProductionSamples.txt");
    # @show length(uc.WIND)

    # ADDITIONAL PARAMETERS
    penetration = 0.1
    nPeriods = 24
    uc.π = ones(nScenarios) / nScenarios # equal probabilities
    uc.Cl = 5000 # value of lost load ($/MWh)
    uc.Ci = 0 # import spillage penalty
    uc.Cr = 0 # renewable spillage penalty
    uc.Cw = 0 # wind spillage penalty

    # ADDITIONAL SETS
    uc.T0 = 0:nPeriods;
    uc.T = 1:nPeriods;

    # Wind production scenarios
    # TODO: not really generic
    reshapedWind = reshape(dWindProductionSamples[2:24001,2:6], nPeriods, 1000, length(uc.WIND));
    uc.Wgen = Dict();
    for w in 1:length(uc.WIND)
        for t in uc.T
            for s in 1:nScenarios
                # This calculates the production level scaled by a given penetration.
                uc.Wgen[uc.WIND[w],t,s] = reshapedWind[t,s,w] * penetration / 0.15;
            end
        end
    end

    uc.D = Dict();
    for n = uc.N
        for t = uc.T
            nd = 0.0;
            for j in uc.LOAD
                if uc.load2bus[j] == n
                    nd += uc.load[j,t];
                end
            end
            for j in uc.IMPORT
                if uc.import2bus[j] == n
                    nd -= uc.Igen[j,t];
                end
            end
            for j in uc.RE
                if uc.re2bus[j] == n
                    nd -= uc.Rgen[j,t];
                end
            end
            uc.D[n,t] = nd
        end
    end

    return uc
end

# include("../../../src/SmpsWriter.jl")
# using SmpsWriter

# @time begin
#     model = suc_wecc(3, "FallWD")
# end

# # Write SMPS files
# @time writeSmps(model, "../../SMPS/suc_3")
