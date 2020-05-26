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

--[[
Copyright © 2019, Windower Dev Team
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Windower Dev Team nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE WINDOWER DEV TEAM BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
