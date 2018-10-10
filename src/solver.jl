function LP(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; level::Int=3, output::Bool=false, timelimit::Float64=Inf, genericnames::Bool=true, splice::Bool=false)

    m = deepcopy(model)
    lprelaxModel!(m, level)
    efrp = getExtensiveFormModel(m, genericnames, splice)

    if !output
        MathProgBase.setparameters!(solver,Silent=true)
    end
    if timelimit != Inf
        MathProgBase.setparameters!(solver,TimeLimit=timelimit)
    end

    setsolver(efrp, solver)
    print("Solving Level $level LP-relaxed recourse problem (RP-LP$level) in the extensive form ... ")
    st = time()
    status = solve(efrp, suppress_warnings=true)
    rp_time = time() - st
    println("$status")
    RPLP = efrp.objVal
    gap = getobjgap(efrp)
    efrp = Model()
    println("RP-LP$level = $(round(RPLP,3)) (gap: $(round(gap,3))%, elapsed time: $(round(rp_time,2))s)")

    if !output
        MathProgBase.setparameters!(solver,Silent=false)
    end
    if timelimit != Inf
        MathProgBase.setparameters!(solver,TimeLimit=Inf)
    end

    return RPLP
end

function EV(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; for_eev::Bool=false, output::Bool=false, timelimit::Float64=Inf, splice::Bool=false, genericnames::Bool=true)
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

    # trial counter
    tc = 1

    # save the number of scenarios
    nS = model.ext[:Stochastic].num_scen

    # Step 1: get expected value problem and save the first-stage solution
    mdata_all = getStructModelData(model, genericnames, false)
    m1 = mdata_all[1]
    m2 = mdata_all[2]
    avg_mat = m2.mat
    avg_rhs = m2.rhs
    avg_obj = m2.obj
    avg_clbd = m2.clbd
    avg_cubd = m2.cubd
    for s in 2:nS
        avg_mat += mdata_all[s+1].mat
        avg_rhs += mdata_all[s+1].rhs
        avg_obj += mdata_all[s+1].obj
        avg_clbd += mdata_all[s+1].clbd
        avg_cubd += mdata_all[s+1].cubd
    end
    avg_mat = avg_mat/nS
    avg_obj = avg_obj/nS
    avg_rhs = avg_rhs/nS
    avg_clbd = avg_clbd/nS
    avg_cubd = avg_cubd/nS

    mdata_all_evp = ModelData[]
    push!(mdata_all_evp, m1)
    push!(mdata_all_evp, ModelData(avg_mat,avg_rhs,m2.sense,avg_obj,m2.objsense,avg_clbd,avg_cubd,m2.ctype,m2.cname))
    evp, x = getExtensiveFormModel(mdata_all_evp, return_x=true)

    if !output
        MathProgBase.setparameters!(solver, Silent=true)
    end
    if timelimit != Inf
        MathProgBase.setparameters!(solver, TimeLimit=timelimit)
    end

    setsolver(evp, solver)
    print("  Solving the expected value problem (EV) ... ")
    st = time()
    status = solve(evp, suppress_warnings=true)

    if status == :Infeasible
        println("EV is infeasible. Trying again with the rounded RHS ...")
    else
        ev_sol = getvalue(x)
        ev_gap = getobjgap(evp)
        ev_time = time() - st
        println("$status (gap: $(round(ev_gap,3))%, elapsed time: $(round(ev_time,2))s)")
        if for_eev
            return (status, ev_sol, ev_gap)
        else
            return evp.objVal
        end
    end

    # solve EV with rounded RHS
    mdata_all_evp = ModelData[]
    push!(mdata_all_evp, m1)
    push!(mdata_all_evp, ModelData(avg_mat,round.(avg_rhs),m2.sense,avg_obj,m2.objsense,avg_clbd,avg_cubd,m2.ctype,m2.cname))
    evp, x = getExtensiveFormModel(mdata_all_evp, return_x=true)

    setsolver(evp, solver)
    print("  Solving the expected value problem with the rounded RHS ... ")
    st = time()
    status = solve(evp, suppress_warnings=true)

    if status == :Infeasible
        println("EV is again infeasible.")
        return (status, [], 0.0)
    else
        ev_sol = getvalue(x)
        ev_gap = getobjgap(evp)
        ev_time = time() - st
        println("$status (gap: $(round(ev_gap,3))%, elapsed time: $(round(ev_time,2))s)")
        if for_eev
            return (status, ev_sol, ev_gap)
        else
            return evp.objVal
        end
    end
end

# calculate Wait-and-See solution (needs any MIP solver, e.g., using CPLEX)
function WS(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; output::Bool=false, ss_timelimit::Float64=Inf, splice::Bool=false)
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

    println("Calculating the Wait-and-See solution (WS)")

    num_notoptimal = 0 # counts the number of single scenario model that is not solved to optimality
    sum = 0.0
    println("  Solving $(model.ext[:Stochastic].num_scen) single scenario problems")

    if !output
        MathProgBase.setparameters!(solver,Silent=true)
    end
    if ss_timelimit != Inf
        MathProgBase.setparameters!(solver,TimeLimit=ss_timelimit)
    end

    for s in 1:model.ext[:Stochastic].num_scen
#        tic()
        st = time()
        print("    Scenario $s ... ")
        ssm = getSingleScenarioModel(model, s, true, splice)
        setsolver(ssm, solver)
        status = solve(ssm, suppress_warnings=true)
        ssm_time = time() - st
        ssm_gap = getobjgap(ssm)
        println("$status (gap: $(round(ssm_gap,3))%, elapsed time: $(round(ssm_time,2))s)")
        if status != :Optimal
            num_notoptimal += 1
        end
        sum += ssm.objVal
        ssm = Model()   # free memory?
#        toc()
    end
    println("  Done")

    WS = sum/model.ext[:Stochastic].num_scen
    println("WS = $(round(WS,3)) (# of nonoptimal single scenario problems: $num_notoptimal)")

    if !output
        MathProgBase.setparameters!(solver,Silent=false)
    end
    if ss_timelimit != Inf
        MathProgBase.setparameters!(solver,TimeLimit=Inf)
    end

    return sum/model.ext[:Stochastic].num_scen
end

# (needs any MIP solver, e.g., using CPLEX)
function EEV(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; output::Bool=false, ev_timelimit::Float64=Inf, eev_timelimit::Float64=Inf, genericnames::Bool=true)
    # check if model is stochastic (or structured) model
    if in(:Stochastic, model.ext.keys) == false
        warn("Not a stochastic model.")
        return
    end

    println("Calculating the effect of using the expected value solution (EEV)")

    # save the number of scenarios
    nS = model.ext[:Stochastic].num_scen
    # Step 1: get expected value problem and save the first-stage solution
    status, ev_sol, ev_gap = EV(model, solver, for_eev=true, timelimit=ev_timelimit)
    if status == :Infeasible
#        println("EV is infeasible.")
        return
    end

    # Step 2: fix the first-stage variables and get EEV
    mdata_all = getStructModelData(model, genericnames, false)
    eev, x = getExtensiveFormModel(mdata_all,return_x=true)
    for j in 1:length(x)
        JuMP.fix(x[j],ev_sol[j])
    end

    setsolver(eev, solver)
    print("  Solving the recourse problem with fixed first-stage (EEV) ... ")
    st = time()
    status = solve(eev, suppress_warnings=true)
    eev_time = time() - st
    println("$status")

    EEV = eev.objVal
#    eev_gap = getobjgap(eev)
    eev = Model()
    println("EV gap: $(round(ev_gap,3))%")
    #println("EEV = $(round(EEV,3)) (gap: $(round(eev_gap,3))%, elapsed time: $(round(eev_time,2))s)")
    println("EEV = $(round(EEV,3)), elapsed time: $(round(eev_time,2))s)")
    if !output
        MathProgBase.setparameters!(solver,Silent=false)
    end
    if ev_timelimit != Inf
        MathProgBase.setparameters!(solver,TimeLimit=Inf)
    end

    return EEV
end

# (needs any MIP solver, e.g., using CPLEX)
function RP(model::JuMP.Model, solver::MathProgBase.AbstractMathProgSolver; output::Bool=false, timelimit::Float64=Inf, genericnames::Bool=true, splice::Bool=false, std::Bool=true)
    efrp = getExtensiveFormModel(model, genericnames, splice)

    if !output
        MathProgBase.setparameters!(solver,Silent=true)
    end
    if timelimit != Inf
        MathProgBase.setparameters!(solver,TimeLimit=timelimit)
    end

    setsolver(efrp, solver)
    print("Solving recourse problem in the extensive form (RP) ... ")
    st = time()
    status = solve(efrp, suppress_warnings=true)
    rp_time = time() - st
    println("$status")
    RP = efrp.objVal
    gap = getobjgap(efrp)
    efrp = Model()
    println("RP = $(round(RP,3)) (gap: $(round(gap,3))%, elapsed time: $(round(rp_time,2))s)")

    if !output
        MathProgBase.setparameters!(solver,Silent=false)
    end
    if timelimit != Inf
        MathProgBase.setparameters!(solver,TimeLimit=Inf)
    end

    if !std
        return RP
    else
        return (RP, )
    end
end

function STD()

end
