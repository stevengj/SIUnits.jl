using SIUnits
using SIUnits.ShortUnits
using Base.Test

# Basic arithmetic things
@test 1V + 2V == 3V
@test (1//2)V - 1V == (-1//2)V
@test_throws 1//2V - 1V
@test_throws 1V + 2s + 2kg

OneNewton = 1*(kg*m/s^2)
@test OneNewton*(1s)^2 == 1kg*m
@test OneNewton*s^2 == 1*kg*m

@test OneNewton/(kg*m) == 1Hertz^2

@test OneNewton^2 == 1kg^2*m^2/s^4

@test s == sqrt(1s^2)
@test sqrt(2)*m == sqrt(2m^2)

@test_throws sqrt(1s)

@test 1/s == 1Hz

@test 1Hz*1s == 1
@test 1s/(1s) == 1

# Issue #2

immutable note{T<:Real}
    pitch::quantity(T,Hz)     #has dimensions of inverse time
    duration::quantity(T,s) #has dimensions of time
    sustained::Bool
end

note{Float64}(1.0Hz,1.0s,true)

@test_throws immutable foo{T}
    bar::quantity(T,2s)
end

# Ranges (#4)
r1 = 1Hz:5Hz
@test length(r1) == 5

@test collect(1Hz:5Hz) == collect(1:5)Hz # Tests the iteration protocol

# Others

@test mod(2µm,4µm) == 2µm

# Issue #9
a = [1m 2N]
b = [1m 2N 3V]
@test a[1:2] == b[1:2]

# Issue #10
a = 1m
b = 2m
@test sqrt(a*b) == (a*b)^(1/2) == (a*b)^(1//2) == sqrt(2)*m

# Issue #11
au=[1m 2m 3m]
bu=[2N 3N 4N]
@test au*bu' == bu*au'
@test (au*bu')[1] == dot(vec(au),vec(bu))