#=
Source:
  A. Papavasiliou and S. Oren. (2013) Multiarea Stochastic Unit Commitment for High Wind
  Penetration in a Transmission Constrained Network. Operations Research 61(3):578-592
=#
using StructJuMP

include("./SUC_data.jl")

function SUC(Season::AbstractString, nS::Integer, seed::Int=1)::JuMP.Model

    # read & generate instance data
    data = SUCData(Season, nS)

    # copy (for convenience)
    G, Gf, Gs, L, N, T, T0, LOAD, IMPORT, WIND, RE = data.G, data.Gf, data.Gs, data.L, data.N, data.T, data.T0, data.LOAD, data.IMPORT, data.WIND, data.RE
    C, Cl, Ci, Cr, Cw, K, S = data.C, data.Cl, data.Ci, data.Cr, data.Cw, data.K, data.S
    B, Pmax, Pmin, Rmax, Rmin, TC, DT, UT = data.B, data.Pmax, data.Pmin, data.Rmax, data.Rmin, data.TC, data.DT, data.UT
    D, Igen, Rgen, Wgen, load = data.D, data.Igen, data.Rgen, data.Wgen, data.load
    gen2bus, import2bus, load2bus, re2bus = data.gen2bus, data.import2bus, data.load2bus, data.re2bus
    wind2bus, fbus, tbus = data.wind2bus, data.fbus, data.tbus
    Pr = data.Pr

    # construct JuMP.Model
    model = StructuredModel(num_scenarios=nS)

    ## 1st stage
    @variable(model, w[g=Gs,t=T0], Bin)
    @variable(model, 0 <= z[g=Gs,t=T] <= 1)

    @objective(model, Min,
        sum(K[g]*w[g,t] + S[g]*z[g,t] for g in Gs for t in T)
    )
    # Unit commitment for slow generators
    @constraint(model, [g=Gs,t=Int(UT[g]):length(T)], sum(z[g,q] for q=Int(t-UT[g]+1):t) <= w[g,t])
    @constraint(model, [g=Gs,t=1:Int(length(T)-DT[g])], sum(z[g,q] for q=(t+1):Int(t+DT[g])) <= w[g,t])
    @constraint(model, [g=Gs,t=T], z[g,t] >= w[g,t] - w[g,t-1])

    ## 2nd stage
    for j in 1:nS
        sb = StructuredModel(parent=model, id = j, prob = Pr[j])

        @variable(sb, u[g=Gf,t=T0], Bin)
        @variable(sb, 0 <= v[g=Gf,t=T] <= 1)
        @variable(sb, -360 <= theta[n=N,t=T] <= 360)
        @variable(sb, -TC[l] <= e[l=L,t=T] <= TC[l])
        @variable(sb, p[g=G,t=T0] >= 0)
        @variable(sb, 0 <= loadshed[i=LOAD,t=T] <= load[i,t]) # load shedding
        @variable(sb, 0 <= ispill[i=IMPORT,t=T] <= Igen[i,t]) # import spillage
        @variable(sb, 0 <= rspill[i=RE,t=T] <= Rgen[i,t])     # renewable spillage
        @variable(sb, 0 <= wspill[i=WIND,t=T] <= Wgen[i,t,j])   # wind spillage

        @objective(sb, Min,
              sum(K[g]*u[g,t] + S[g]*v[g,t] for g in Gf for t in T)
            + sum(C[g]*p[g,t] for g in G for t in T)
            + sum(Cl*loadshed[i,t] for i in LOAD for t in T)
            + sum(Ci*ispill[i,t] for i in IMPORT for t in T)
            + sum(Cr*rspill[i,t] for i in RE for t in T)
            + sum(Cw*wspill[i,t] for i in WIND for t in T)
        )

        # Unit commitment for fast generators
        @constraint(sb, [g=Gf,t=Int(UT[g]):length(T)], sum(v[g,q] for q=Int(t-UT[g]+1):t) <= u[g,t])
        @constraint(sb, [g=Gf,t=1:Int(length(T)-DT[g])], sum(v[g,q] for q=(t+1):Int(t+DT[g])) <= u[g,t])
        @constraint(sb, [g=Gf,t=T], v[g,t] >= u[g,t] - u[g,t-1])

        # Flow balance
        @constraint(sb, [n=N,t=T],
            sum(e[l,t] for l in L if tbus[l] == n)
            + sum(p[g,t] for g in G if gen2bus[g] == n)
            + sum(loadshed[i,t] for i in LOAD if load2bus[i] == n)
            + sum(Wgen[i,t,j] for i in WIND if wind2bus[i] == n)
            ==
            D[n,t] + sum(e[l,t] for l in L if fbus[l] == n)
            + sum(ispill[i,t] for i in IMPORT if import2bus[i] == n)
            + sum(rspill[i,t] for i in RE if re2bus[i] == n)
            + sum(wspill[i,t] for i in WIND if wind2bus[i] == n)
        )

        # Power flow equation
        @constraint(sb, [l=L,t=T], e[l,t] == B[l] * (theta[fbus[l],t] - theta[tbus[l],t]))

        # Max generation capacity
        @constraint(sb, [g=Gs,t=T0], p[g,t] <= Pmax[g] * w[g,t])
        @constraint(sb, [g=Gf,t=T0], p[g,t] <= Pmax[g] * u[g,t])

        # # Min generation capacity
        @constraint(sb, [g=Gs,t=T0], p[g,t] >= Pmin[g] * w[g,t])
        @constraint(sb, [g=Gf,t=T0], p[g,t] >= Pmin[g] * u[g,t])

        # Ramping capacity
        @constraint(sb, [g=G,t=T], p[g,t] - p[g,t-1] <= Rmax[g])
        @constraint(sb, [g=G,t=T], p[g,t] - p[g,t-1] >= -Rmin[g])
    end

    return model
end
