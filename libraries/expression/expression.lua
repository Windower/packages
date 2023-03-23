local expression = {}

local expression_empty
local expression_id
local expression_exists
local expression_is
local expression_is_not
local expression_min
local expression_max
local expression_between
local expression_one_of
local expression_not_one_of
local expression_eq
local expression_neq
local expression_lt
local expression_leq
local expression_gt
local expression_geq
local expression_add
local expression_sub
local expression_mul
local expression_div
local expression_pow
local expression_append
local expression_prepend
local expression_index
local expression_lookup
local expression_method
local expression_chain
local expression_neg
local expression_const
local expression_const_true
local expression_const_false

-- general

expression_empty = function()
end

expression_id = function(...)
    return ...
end

-- predicates

expression_exists = function(value)
    return value ~= nil
end

expression_is = function(eq)
    return function(value)
        return value == eq
    end
end

expression_is_not = function(neq)
    return function(value)
        return value ~= neq
    end
end

expression_min = function(min)
    return function(value)
        return value >= min
    end
end

expression_max = function(max)
    return function(value)
        return value <= max
    end
end

expression_between = function(min, max)
    return function(value)
        return min <= value and value <= max
    end
end

expression_one_of = function(...)
    local length = select('#', ...)
    local args = {...}
    return function(value)
        for i = 1, length do
            if args[i] == value then
                return true
            end
        end

        return false
    end
end

expression_not_one_of = function(...)
    local length = select('#', ...)
    local args = {...}
    return function(value)
        for i = 1, length do
            if args[i] == value then
                return false
            end
        end

        return true
    end
end

-- comparisons

expression_eq = function(lhs, rhs)
    return lhs == rhs
end

expression_neq = function(lhs, rhs)
    return lhs ~= rhs
end

expression_lt = function(lhs, rhs)
    return lhs < rhs
end

expression_leq = function(lhs, rhs)
    return lhs <= rhs
end

expression_gt = function(lhs, rhs)
    return lhs > rhs
end

expression_geq = function(lhs, rhs)
    return lhs >= rhs
end

-- operators

expression_add = function(base)
    return function(value)
        return base + value
    end
end

expression_sub = function(base)
    return function(value)
        return base - value
    end
end

expression_mul = function(base)
    return function(value)
        return base * value
    end
end

expression_div = function(base)
    return function(value)
        return base / value
    end
end

expression_pow = function(base)
    return function(value)
        return base ^ value
    end
end

expression_append = function(base)
    return function(value)
        return value .. base
    end
end

expression_prepend = function(base)
    return function(value)
        return base .. value
    end
end

-- accessors

local selector

local expression_mt = {
    __call = function(callable, value)
        return callable.fn(value)
    end,
    __index = function(callable, k)
        local fn = expression[k]
        return function(_, ...)
            local outer = fn(...)
            return selector(function(value)
                return outer(callable.fn(value))
            end)
        end
    end,
}

selector = function(fn)
    return setmetatable({fn = fn}, expression_mt)
end

expression_index = function(field_name)
    return selector(function(value)
        return value[field_name]
    end)
end

expression_lookup = function(lookup)
    return selector(function(value)
        return lookup[value]
    end)
end

expression_method = function(method_name)
    return selector(function(value)
        return value[method_name](value)
    end)
end

do
    local chain = function(...)
        if select('#', ...) == 0 then
            return expression_id
        end

        if select('#', ...) == 1 then
            return ...
        end

        local first, second = ...
        return expression_chain(function(...)
            return second(first(...))
        end, select(3, ...))
    end

    expression_chain = function(...)
        return selector(chain(...))
    end
end

expression_neg = function(fn)
    return selector(function(...)
        return not fn(...)
    end)
end

expression_const = function(value)
    return selector(function()
        return value
    end)
end

expression_const_true = selector(function()
    return true
end)

expression_const_false = selector(function()
    return false
end)

expression.empty = expression_empty
expression.id = expression_id
expression.exists = expression_exists
expression.is = expression_is
expression.is_not = expression_is_not
expression.min = expression_min
expression.max = expression_max
expression.between = expression_between
expression.one_of = expression_one_of
expression.not_one_of = expression_not_one_of
expression.eq = expression_eq
expression.neq = expression_neq
expression.lt = expression_lt
expression.leq = expression_leq
expression.gt = expression_gt
expression.geq = expression_geq
expression.add = expression_add
expression.sub = expression_sub
expression.mul = expression_mul
expression.div = expression_div
expression.pow = expression_pow
expression.append = expression_append
expression.prepend = expression_prepend
expression.index = expression_index
expression.lookup = expression_lookup
expression.method = expression_method
expression.chain = expression_chain
expression.neg = expression_neg
expression.const = expression_const
expression.const_true = expression_const_true
expression.const_false = expression_const_false

return expression

--[[
Copyright © 2021, Windower Dev Team
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
