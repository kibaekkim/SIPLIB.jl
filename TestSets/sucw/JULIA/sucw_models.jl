#=
Source:
  A. Papavasiliou and S. Oren. (2013) Multiarea Stochastic Unit Commitment for High Wind
  Penetration in a Transmission Constrained Network. Operations Research 61(3):578-592
=#
include("./sucw_types.jl")
include("./sucw_functions.jl")
using StructJuMP, JuMP

function sucw(Season::AbstractString, nScenarios::Integer)::JuMP.Model
    # get model data
    uc = weccdata(Season, nScenarios)

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
