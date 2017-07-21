#=
This reads MPS file and solves the model using CPLEX. 
Required are Cplex software and Julia packages (CPLEX.jl and JuMP.jl).

One can easily switch CPLEX to other solvers such as GUROBI.

This script is from a JuMP example.

Kibaek Kim
=#

using CPLEX, JuMP, MathProgBase

# command-line arguments
mpsfile = ARGS[1] # mps file to read
ofile   = ARGS[2] # output file to write

# set parameters for CPLEX
mod = Model(solver=CplexSolver(CPX_PARAM_TILIM=3600,CPX_PARAM_EPAGAP=0.0))
m_internal = MathProgBase.LinearQuadraticModel(CplexSolver())

MathProgBase.loadproblem!(m_internal, mpsfile)

# grab MathProgBase data
c = MathProgBase.getobj(m_internal)
A = MathProgBase.getconstrmatrix(m_internal)
m, n = size(A)
xlb = MathProgBase.getvarLB(m_internal)
xub = MathProgBase.getvarUB(m_internal)
l = MathProgBase.getconstrLB(m_internal)
u = MathProgBase.getconstrUB(m_internal)
vtypes = MathProgBase.getvartype(m_internal)

# populate JuMP model with data from internal model
@variable(mod, x[1:n])
for i in 1:n
    setlowerbound(x[i], xlb[i])
    setupperbound(x[i], xub[i])
    # change vartype to integer when appropriate
    if vtypes[i] == :Bin || vtypes[i] == :Int
        setcategory(x[i], vtypes[i])
    end
end
At = A' # transpose to get useful row-wise sparse representation
for i in 1:At.n
    @constraint( mod, l[i] <= sum( At.nzval[idx]*x[At.rowval[idx]] for idx = At.colptr[i]:(At.colptr[i+1]-1) ) <= u[i] )
end
@objective(mod, Min, sum( c[i]*x[i] for i=1:n ))

status = solve(mod)
# @show status
# @show getobjectivevalue(mod)
# @show getobjectivebound(mod)
# @show getsolvetime(mod)

# write simple soultion file in the form of
# (instance, primal objective, dual objective, solution time)
fp = open(ofile, "w")
@printf(fp, "%s,%e,%e,%e\n", mpsfile, getobjectivevalue(mod), getobjectivebound(mod), getsolvetime(mod))
close(fp)
