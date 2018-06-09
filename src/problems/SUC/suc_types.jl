struct SUCData

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
