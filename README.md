# SIPLIB.jl

A Julia package for generating, modifying, and maintaining Stochastic Integer Programming Test Problem Library (SIPLIB) as algebraic equations.
This package allows users to write stochasitc program in algebraic form and create SMPS files.

## Instances

This package also contains most of the existing SIPLIB instances in https://www2.isye.gatech.edu/~sahmed/siplib/:

- DCAP (two-stage mixed-binary problem)
- ~EXPUTIL~ (single-stage nonlinear 0-1 problem)
- MPTSP (two-stage 0-1 problem)
- ~PROBPORT~ (chance constrained problem)
- ~SEMI~ (to be added; two-stage integer problem)
- SMKP (two-stage stochastic multiple knapsack)
- SIZES (two-stage mixed-ingeter problem)
- SSLP (two-stage mixed-integer problem)
- ~VACCINE~ (chanced constrained problem)

In addition, we have instances of:

- AIRLIFT
- CARGO
- CHEM
- PHONE
- SDCP
- SUC

## Example

This shows how to generate SMPS files from `farmer` instance.

```julia
using SIPLIB
using StructJuMP

NS = 3;                        # number of scenarios
probability = [1/3, 1/3, 1/3]; # probability

# FIRST-STAGE MODEL
CROPS = 1:3; # set of crops (wheat, corn and sugar beets, resp.)
Cost = [150 230 260]; # cost of planting crops
Budget = 500; # budget capacity

# SECOND-STAGE MODELS
PURCH = 1:2; # set of crops to purchase (wheat and corn, resp.)
SELL  = 1:4; # set of crops to sell (wheat, corn, sugar beets under 6K and those over 6K)
Purchase = [238 210;
            238 210;
            238 210];   # purchase price
Sell = [170 150 36 10;
        170 150 36 10;
        170 150 36 10]; # selling price
Yield = [3.0 3.6 24.0;
         2.5 3.0 20.0;
         2.0 2.4 16.0];
Minreq = [200 240 0;
          200 240 0;
          200 240 0]; # minimum crop requirement

# CREATE STOCHASTIC MODEL
m = StructuredModel(num_scenarios=NS);

# first-stage variables
@variable(m, x[i=CROPS] >= 0)

# first-stage objective
@objective(m, Min, sum(Cost[i] * x[i] for i=CROPS))

# first-stage constraint
@constraint(m, const_budget, sum(x[i] for i=CROPS) <= Budget)

# SECOND-STAGE MODELS
for s in 1:NS
    # stochastic block
    sb = StructuredModel(parent=m, id = s, prob = probability[s]);
    @variable(sb, y[j=PURCH] >= 0)
    @variable(sb, w[k=SELL] >= 0)
    @objective(sb, Min, sum(Purchase[s,j] * y[j] for j=PURCH) - sum(Sell[s,k] * w[k] for k=SELL))
    @constraint(sb, const_minreq[j=PURCH], Yield[s,j] * x[j] + y[j] - w[j] >= Minreq[s,j])
    @constraint(sb, const_minreq_beets, Yield[s,3] * x[3] - w[3] - w[4] >= Minreq[s,3])
    @constraint(sb, const_aux, w[3] <= 6000)
end

SIPLIB.write_smps(m, "farmer")
```

## Acknowledgement

This material is based upon work supported by the U.S. Department of Energy, Office of Science, under contract number DE-AC02-06CH11357.
