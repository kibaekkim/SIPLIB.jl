NAME          AIRLIFT_1000_SS467
ROWS
 N  OBJ
 L  CON1
 L  CON2
 L  CON3
 L  CON4
 L  CON5
 L  CON6
 E  CON7
 E  CON8
COLUMNS
    MARKER    'MARKER'                'INTORG'
    x[1,1]    OBJ       7200.000000   CON1      24.000000   
    x[1,1]    CON3      -24.000000    CON7      50.000000   
    x[1,2]    OBJ       6000.000000   CON1      14.000000   
    x[1,2]    CON4      -14.000000    CON8      75.000000   
    x[2,1]    OBJ       7200.000000   CON2      49.000000   
    x[2,1]    CON5      -49.000000    CON7      20.000000   
    x[2,2]    OBJ       4000.000000   CON2      29.000000   
    x[2,2]    CON6      -29.000000    CON8      20.000000   
    chi[1,1,2]  OBJ       -500.000000   CON3      29.000000   
    chi[1,1,2]  CON7      -60.416667    CON8      75.000000   
    chi[1,2,1]  OBJ       -1142.857143  CON4      19.000000   
    chi[1,2,1]  CON7      50.000000     CON8      -101.785714 
    chi[2,1,2]  OBJ       471.428571    CON5      56.000000   
    chi[2,1,2]  CON7      -22.857143    CON8      20.000000   
    chi[2,2,1]  OBJ       534.482759    CON6      36.000000   
    chi[2,2,1]  CON7      20.000000     CON8      -24.827586  
    MARKER    'MARKER'                 'INTEND'
    yplus[1]  OBJ       500.000000    CON7      1.000000    
    yplus[2]  OBJ       250.000000    CON8      1.000000    
    yminus[1]  CON7      -1.000000   
    yminus[2]  CON8      -1.000000   
RHS
    RHS       CON1      720.000000    CON2      720.000000  
    RHS       CON3      -0.000000     CON4      -0.000000   
    RHS       CON5      -0.000000     CON6      -0.000000   
    RHS       CON7      1043.533335   CON8      1134.128963 
BOUNDS
 LI BOUND     x[1,1]    0.000000    
 LI BOUND     x[1,2]    0.000000    
 LI BOUND     x[2,1]    0.000000    
 LI BOUND     x[2,2]    0.000000    
 LI BOUND     chi[1,1,2]  0.000000    
 LI BOUND     chi[1,2,1]  0.000000    
 LI BOUND     chi[2,1,2]  0.000000    
 LI BOUND     chi[2,2,1]  0.000000    
ENDATA
