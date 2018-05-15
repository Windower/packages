local shared = require('shared')
local enumerable = require('enumerable')
local res = require('resources')

local fetch = shared.get('items_service', 'items')

local indexer = function(data, bag, index)
    if type(index) == 'number' then
        return data.bags[bag].contents[index]
    end

    return data.bags[bag][index]
end

local bag_iterator = function(data, index)
    local k, v = next(data.bags, index)
    return {k, (v or {}).contents}
end

local iterator = function(data, bag, index)
    return {next(data.bags[bag].contents, index)}
end

local constructors = setmetatable({}, {
    __index = function(mts, bag)
        
        local success, data = fetch(function(data, bag)
            return data.bags[bag] ~= nil
        end, bag)

        if not success then
            error(data)
        elseif not data then
            error("Unknown bag: " .. bag )
        end

        local meta = {
            __index = function(t, index)
                local success, data = fetch(indexer, bag, index)
    
                if not success then
                    error(data)
                end
    
                return data
            end,

            __pairs = function(t)
                return function(t, index)
                    local success, data = fetch(iterator, bag, index)

                    if not success then
                        error(data)
                    end

                    return unpack(data)
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
                local success, data = fetch(function(data) return data.gil end)
                if not success then
                    error(data)
                end
                return data
            end

            bag = (res.bags:first(function(v, k, t)
                return v.command == lc_bag or v.english:lower() == lc_bag
            end) or {}).id or bag
        end
        return constructors[bag]()
    end,

    __pairs = function(t)
        return function(t, index)
            local success, data = fetch(bag_iterator, index)

            if not success then
                error(data)
            end
            return unpack(data)
        end, t, nil
    end,
})
