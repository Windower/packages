local enumerable = {}

enumerable.enumerate = function(t)
    return function(t, k)
        local key, value = next(t, k)
        return value, key
    end, t, nil
end

enumerable.count = function(t, ...)
    local count = 0

    if select('#', ...) == 0 or type(...) == 'table' then
        for _ in pairs(t) do
            count = count + 1
        end
    else
        for _, el in pairs(t) do
            if (...)(el) == true then
                count = count + 1
            end
        end
    end

    return count
end

enumerable.any = function(t, ...)
    if select('#', ...) == 0 then
        for _ in pairs(t) do
            return true
        end

        return false
    end

    for _, v in pairs(t) do
        if (...)(v) == true then
            return true
        end
    end

    return false
end

enumerable.all = function(t, fn)
    for _, v in pairs(t) do
        if fn(v) == false then
            return false
        end
    end

    return true
end

enumerable.contains = function(t, search)
    for _, el in pairs(t) do
        if el == search then
            return true
        end
    end

    return false
end

enumerable.to_table = function(t)
    local arr = {}
    local key = 0
    for _, el in pairs(t) do
        key = key + 1
        arr[key] = el
    end

    return arr
end

enumerable.aggregate = function(t, fn, ...)
    local initialized = select('#', ...) > 0
    local res = ...

    for key, el in pairs(t) do
        if not initialized then
            res = el
            initialized = true
        else
            res = fn(res, el, key, t)
        end
    end

    return res
end

local redirect = {
    add = {
        copy = function(constructor, add, t)
            local res = constructor()
            for _, el in pairs(t) do
                add(res, el)
            end

            return res
        end,
        select = function(constructor, add, t, fn)
            local res = constructor()

            for key, el in pairs(t) do
                add(res, fn(el, key, t))
            end

            return res
        end,
        where = function(constructor, add, t, fn)
            local res = constructor()

            for key, el in pairs(t) do
                if fn(el, key, t) then
                    add(res, el)
                end
            end

            return res
        end,
    },
    remove = {
        clear = function(constructor, remove, t)
            for key in pairs(t) do
                remove(t, key)
            end

            return t
        end,
    },
}

local build_index = function(constructor, proxies)
    local index = {}

    for name, fn in pairs(enumerable) do
        index[name] = fn
    end

    if constructor ~= nil then
        for proxy_name, proxy in pairs(proxies) do
            for name, fn in pairs(redirect[proxy_name]) do
                index[name] = function(...)
                    return fn(constructor, proxy, ...)
                end
            end
        end
    end

    return index
end

return function(meta)
    local index = build_index(meta.__create, {
        add = meta.__add_element,
        remove = meta.__remove_key,
    })

    -- __index
    local original = meta.__index
    local index_type = type(original)
    if index_type == 'nil' then
        meta.__index = index
    elseif index_type == 'table' then
        meta.__index = function(t, k)
            return original[k] or index[k]
        end
    elseif index_type == 'function' then
        meta.__index = function(t, k)
            return original(t, k) or index[k]
        end
    else
        error(('Unknown indexing index_type: %s'):format(type))
    end

    -- __len
    if meta.__len == nil then
        meta.__len = type(meta.__index) == 'table' and meta.__index.count or meta.__index(nil, 'count')
    end
end

--[[
Copyright © 2016, Windower
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
    * Neither the name of Windower nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL Windower BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]

