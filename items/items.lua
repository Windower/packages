local enumerable = require('enumerable')
local res = require('resources')
local shared = require('shared')

local fetch = shared.get('items_service', 'items')

local indexer = function(data, bag, index)
    if type(index) == 'number' then
        return data.bags[bag].contents[index]
    end

    return data.bags[bag][index]
end

local iterate = function(data, bag, index)
    return next(data.bags[bag].contents, index)
end

local iterate_bag = function(data, bag)
    local k, v = next(data.bags, bag)
    return k, (v or {}).contents
end

local constructors = setmetatable({}, {
    __index = function(mts, bag)
        fetch:call(function(data, bag)
            return data.bags[bag] ~= nil
        end, bag)

        assert(data, 'Unknown bag: ' .. bag)

        local meta = {
            __index = function(_, index)
                return fetch:read(bag, index)
            end,

            __pairs = function(t)
                return function(t, index)
                    return fetch:call(iterate, bag, index)
                end, t, nil
            end,
        }

        local constructor = enumerable(meta)
        mts[bag] = constructor
        return constructor
    end,
})

return setmetatable({}, {
    __index = function(_, bag)
        if type(bag) == 'string' then
            local lc_bag = bag:lower()
            
            if lc_bag == 'gil' then
                return fetch:read('gil')
            end

            bag = (res.bags:first(function(v, k, t)
                return v.command == lc_bag or v.english:lower() == lc_bag
            end) or {}).id or bag
        end
        return constructors[bag]()
    end,

    __pairs = function(t)
        return function(t, index)
            return fetch:call(iterate_bag, index)
        end, t, nil
    end,
})
