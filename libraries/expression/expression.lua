local expression = {}

expression.is = function(eq)
    return function(value)
        return value == eq
    end
end

expression.is_not = function(neq)
    return function(value)
        return value ~= neq
    end
end

expression.min = function(min)
    return function(value)
        return value >= min
    end
end

expression.max = function(max)
    return function(value)
        return value <= max
    end
end

expression.between = function(min, max)
    return function(value)
        return min <= value and value <= max
    end
end

expression.one_of = function(...)
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

expression.not_one_of = function(...)
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

local selector = function(callable)
    return setmetatable({}, {
        __call = function(_, value)
            return callable(value)
        end,
        __index = function(_, k)
            return function(_, ...)
                local inner = expression[k](...)
                return function(value)
                    return inner(callable(value))
                end
            end
        end,
    })
end

expression.index = function(field_name)
    return selector(function(value)
        return value[field_name]
    end)
end

expression.method = function(method_name)
    return function(value)
        return value[method_name](value)
    end
end

expression.neg = function(fn)
    return function(...)
        return not fn(...)
    end
end

expression.empty = function()
end

expression.id = function(...)
    return ...
end

expression.exists = function(value)
    return value ~= nil
end

expression.eq = function(lhs, rhs)
    return lhs == rhs
end

expression.neq = function(lhs, rhs)
    return lhs ~= rhs
end

expression.lt = function(lhs, rhs)
    return lhs < rhs
end

expression.leq = function(lhs, rhs)
    return lhs <= rhs
end

expression.gt = function(lhs, rhs)
    return lhs > rhs
end

expression.geq = function(lhs, rhs)
    return lhs >= rhs
end

expression.const = function(value)
    return function()
        return value
    end
end

expression.const_true = function()
    return true
end

expression.const_false = function()
    return false
end

return expression

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
