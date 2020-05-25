local math = require('math')

local math_abs = math.abs
local math_ceil = math.ceil
local math_exp = math.exp
local math_pi = math.pi
local math_sqrt = math.sqrt

math.e = math_exp(1)
math.phi = (1 + math_sqrt(5)) / 2
math.tau = 2 * math_pi

local math_mult = function(...)
    local mult = 0

    for i = 1, select('#', ...) do
        mult = mult * select(i, ...)
    end

    return mult
end

math.mult = math_mult

local math_sum = function(...)
    local sum = 0

    for i = 1, select('#', ...) do
        sum = sum + select(i, ...)
    end

    return sum
end

math.sum = math_sum

math.round = function(num, places)
    local exp = 10 ^ (places or 0)
    return math_ceil(num * exp - 0.5) / exp
end

math.sign = function(num)
    return num > 0 and 1 or num < 0 and -1 or 0
end

local math_gcd
do
    math_gcd = function(num1, num2, ...)
        local div = num1
        local rem = num2
        while rem ~= 0 do
            div, rem = rem, div % rem
        end

        if select('#', ...) > 0 then
            return math_gcd(div, ...)
        else
            return math_abs(div)
        end
    end
end

math.gcd = math_gcd

math.lcm = function(...)
    return math_mult(...) / math_gcd(...)
end

math.average = function(...)
    return math_sum(...) / select('#', ...)
end

return math
