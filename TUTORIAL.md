# Prerequisites

- You have `Julia >= 0.6.2` and know basic syntax. 
- You have installed three packages: `StructJuMP`, `Distributions`, `PyPlot`
- You know how to model with `JuMP`.
- You have a two-stage stochastic programming problem (e.g., `DCAP`) that you want to add to `Siplib.jl`. You know everything about the problem, e.g., formulation, data generation procedure.
- Your `Siplib.jl` package is located in `/DIR/Siplib`.

# Tutorial: How to add a new problem
Follow the steps to add a new problem. We will use `DCAP` as an example. The full information on `DCAP` can be found from Appendix A.1 in the paper.

Be very careful whenever you make a new component that is named after the problem name (e.g., folder, script, function). 

You must be consistent with the predefined manner.

## Step 1. Modify the file: `/DIR/Siplib/src/problem_info.csv`

`problem_info.csv` file contains parameter information for each problem. Open the file and add a new comma-delimited line at the bottom, e.g.,
```Spreadsheet
DCAP, 4, "[R,N,T,S], All integers."
```
- DCAP: Name of the problem.
- 4: Number of parameters that define the problem (e.g., `DCAP` has 4 parameters: |R|, |N|, |T|, |S|).
- "[R,N,T,S], All integers.": Simple note on the parameters (if not needed, just let it "")

Later, SMPS files will be generated using the syntax like the following (minimal input arguments example):

```julia
	julia> generateSMPS(:DCAP, [3,3,3,10])
```


## Step 2. Create a new folder `DCAP` under: `/DIR/Siplib/src/problem/`

The folder name must be the same as the problem name.

## Step 3. Create `DCAP_model.jl` file into: `/DIR/Siplib/src/problem/DCAP`

The file name must be `(problem_name)_model.jl`

## Step 4. Implement a modeling function on `DCAP_model.jl`: ``function DCAP(nR::Int, nN::Int, nT::Int, nS::Int, seed::Int=1)::JuMP.Model``
- This function returns a `JuMP.Model`-type object.
- The function name must be same as the problem name.
- Be consistent with the order of the input arguments we have used. 
- Note that the argument `seed::Int=1` for the random seed must be added at the end and set to be 1 as a default. It can be changed by user when generating SMPS files, e.g., 

```julia
	julia> generateSMPS(:DCAP, [3,3,3,10], seed=2)
```

The full definition of the function ``DCAP()`` is:

```julia

function DCAP(nR::Int, nN::Int, nT::Int, nS::Int, seed::Int=1)::JuMP.Model

    # set random seed (default=1)
    srand(seed)

    # generate & store instance data
    ## sets
    R = 1:nR
    N = 1:nN
    T = 1:nT
    S = 1:nS

    ## parameters
    a = rand(nR, nT) * 5 + 5
    b = rand(nR, nT) * 40 + 10
    c = rand(nR, nN, nT, nS) * 5 + 5
    c0 = rand(nN, nT, nS) * 500 + 500
    d = rand(nN, nT, nS) + 0.5
    Pr = ones(nS)/nS

    # construct JuMP.Model
    model = StructuredModel(num_scenarios = nS)

    ## 1st stage
    @variable(model, x[i=R,t=T] >= 0)
    @variable(model, u[i=R,t=T], Bin)
    @objective(model, Min, sum(a[i,t]*x[i,t] + b[i,t]*u[i,t] for i in R for t in T))
    @constraint(model, [i=R,t=T], x[i,t] - u[i,t] <= 0)

    ## 2nd stage
    for s in S
        sb = StructuredModel(parent=model, id = s, prob = Pr[s])
        @variable(sb, y[i=R, j=N, t=T], Bin)
        @variable(sb, z[j=N,t=T] >= 0)
        @objective(sb, Min, sum(c[i,j,t,s]*y[i,j,t] for i in R for j in N for t in T) + sum(c0[j,t,s]*z[j,t] for j in N for t in T))
        @constraint(sb, [i=R, t=T], -sum(x[i,tau] for tau in 1:t) + sum(d[j,t,s]*y[i,j,t] for j in N) <= 0)
        @constraint(sb, [j=N, t=T], sum(y[i,j,t] for i in R) + z[j,t] == 1)
    end

    return model
end
```

## Step 5. Check if everything is well done
- Open a terminal and change working directory to `DIR/Siplib/src/`
```Shell
user@LINUX:~$ cd DIR/Siplib/src/
```
- Run `Julia` in that directory
```Shell
user@LINUX:~/DIR/Siplib/src/$ julia
```
- Include ``Siplib.jl``
```julia
julia> include("Siplib.jl")
```
- Execute `using Siplib`
```julia
julia> using Siplib
```
- Execute `generateSMPS(:DCAP, [3,3,3,10])` to generate DCAP_3_3_3_10 instance.
```julia
julia> generateSMPS(:DCAP, [3,3,3,10])
```
- Check out the directory `DIR/Siplib/instance` if SMPS files are stored.
### Note 1. The function `generateSMPS()` has two necessary arguments (`problem::Symbol`, `params_arr::Any`) and five optional positional/keyword arguments (see the table below).
### Note 2. All the optional argurments have default values. Users can specify them with another values (see the table below).
### Note 3. The positional argument must be placed at the proper position. The keyword arguments can be placed anywhere after the positional arguments. 
Optional argument | Argument type | Meaning |Acceptable value | Example
--- | --- | --- | --- | ---
`DIR_NAME::String` | `positional` |Set the path in which SMPS files are stored |`String` (default:`"DIR/Siplib/instance"`)|`generateSMPS(:DCAP,[3,3,3,10],"another/path")`
`seed::Int` | ` keyword` |Set random seed for pseudo random generator|`Int` (default:`1`)|`generateSMPS(:DCAP,[3,3,3,10],"another/path",seed=2)`
`lprelax::Bool`|` keyword`|Set the level of LP-relaxation (0: no relax, 1: 1st stage only, 2: 2nd stage only, 3: fully relax)|`0, 1, 2, 3` (defalut:`0`)|`generateSMPS(:DCAP,[3,3,3,10],"another/path",lprelax=2)`
`genericnames::Bool`|`keyword`|Set if we maintain original variable names (for human readability)|`true, false` (default:`true`)|`generateSMPS(:DCAP,[3,3,3,10],"another/path",genericnames=false)`
`splice::Bool`|`keyword`|Set if we splice the data in the model object after writing SMPS (for memory efficiency)|`true, false` (default:`true`)|`generateSMPS(:DCAP,[3,3,3,10],"another/path",splice=false)`

