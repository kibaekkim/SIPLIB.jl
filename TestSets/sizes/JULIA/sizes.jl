using JuMP, StructJuMP

type SIZESModel

    # Sets
    N   # set of sleeve lengths
    S   # set of scenarios

    # Parameters
    L   # sleeve lengths
    D   # demand for each length of sleeve
    P   # unit production cost
    r   # unit cutting cost
    s   # setup cost
    rc  # resource (sleeve) capacity
    pc  # production capacity
    π   # probability distribution of scenario s



    SIZESModel() = new()
end

function sizesdata(nScenarios::Integer)

end

function sizes(nScenarios::Integer)

end

cd(dirname(Base.source_path()))
DATA_PATH = "../DATA/oneperioddata.csv"
data_array = readdlm(DATA_PATH, ',')
L = data_array[8:17, 1]
D = data_array[8:17, 3]
P = data_array[8:17, 2]
r = data_array[4,1]
s = data_array[6,1]
c = data_array[2,1]
