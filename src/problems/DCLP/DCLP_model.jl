include("./DCLP_data.jl")

function DCLP(M::Int, PenetPercent::Any, Season::String, nS::Int, seed::Int=1)::JuMP.Model

    ## read data
    data = DCLPData(PenetPercent, Season, nS)

    # copy
    G, L, N, T, T0 = data.G, data.L, data.N, data.T, data.T0
    LOAD, IMPORT, WIND, RE = data.LOAD, data.IMPORT, data.WIND, data.RE
    C, Cl, Ci, Cr, Cw = data.C, data.Cl, data.Ci, data.Cr, data.Cw
    B, Pmax, Rmax, Rmin, TC = data.B, data.Pmax, data.Rmax, data.Rmin, data.TC
    Igen, Rgen, Wgen, load = data.Igen, data.Rgen, data.Wgen, data.load
    gen2bus, import2bus, load2bus = data.gen2bus, data.import2bus, data.load2bus
    re2bus, wind2bus, fbus, tbus = data.re2bus, data.wind2bus, data.fbus, data.tbus
    Pr = data.Pr

    # construct JuMP.Model
    model = StructuredModel(num_scenarios=nS)

    ## 1st stage
    @variable(model, d[n=N] >= 0, Int)
    @objective(model, Min, 0)
    @constraint(model, sum(d[n] for n in N) <= M)

    ## 2nd stage
    for s in 1:nS
        sb = StructuredModel(parent=model, id = s, prob = Pr[s])

        @variable(sb, u[n=N,t=T] >= 0)  # dispatchable load served at bus n at time t
        @variable(sb, 0 <= p[g=G,t=T0] <= Pmax[g]) # power generation from generator g
        @variable(sb, -TC[l] <= f[l=L,t=T] <= TC[l])    # power flow
        @variable(sb, -360 <= theta[n=N,t=T] <= 360)
        @variable(sb, 0 <= loadshed[i=LOAD,t=T] <= load[i,t]) # load shedding
        @variable(sb, 0 <= ispill[i=IMPORT,t=T] <= Igen[i,t]) # import spillage
        @variable(sb, 0 <= rspill[i=RE,t=T] <= Rgen[i,t])     # renewable spillage
        @variable(sb, 0 <= wspill[i=WIND,t=T] <= Wgen[i,t,s])   # wind spillage
        #@variable(sb, wspill[i=WIND,t=T] >= 0)   # wind spillage

        @objective(sb, Min,
            sum(C[g]*p[g,t] for g in G for t in T)
            + sum(Cl*loadshed[i,t] for i in LOAD for t in T)
            + sum(Ci*ispill[i,t] for i in IMPORT for t in T)
            + sum(Cr*rspill[i,t] for i in RE for t in T)
            + sum(Cw*wspill[i,t] for i in WIND for t in T)
        )

        # Flow balance
        @constraint(sb, [n=N,t=T],
            sum(f[l,t] for l in L if tbus[l] == n)
            - sum(f[l,t] for l in L if fbus[l] == n)
            + sum(p[g,t] for g in G if gen2bus[g] == n)
            + sum(Igen[i,t] - ispill[i,t] for i in IMPORT if import2bus[i] == n)
            + sum(Wgen[i,t,s] - wspill[i,t] for i in WIND if wind2bus[i] == n)
            + sum(Rgen[i,t] - rspill[i,t] for i in RE if re2bus[i] == n)
            - u[n,t]
            ==
            sum(load[i,t] - loadshed[i,t] for i in LOAD if load2bus[i] == n)
        )

        # Power flow equation
        @constraint(sb, [l=L,t=T], f[l,t] == B[l] * (theta[fbus[l],t] - theta[tbus[l],t]))

        # Ramping capacity
        @constraint(sb, [g=G,t=T], p[g,t] - p[g,t-1] <= Rmax[g])
        @constraint(sb, [g=G,t=T], p[g,t] - p[g,t-1] >= -Rmin[g])
    end

    return model
end
