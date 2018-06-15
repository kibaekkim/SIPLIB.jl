function test_function(a::Int, b::Int ; c::Int=5)
    return a*b*c
end

test_function(3,5,c=10)


function test_function2(prob::Symbol, params...)

end

test_function2(1,2,3,4,5)

function test_function3(a::Int, b::Int, c::Int, seed::Float64=1.0)
    println(a)
    println(b)
    println(c)
    println(seed)
end

arr = [3,4,5]
test_function3(arr...,6.0)
