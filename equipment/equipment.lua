local shared = require('shared')
local enumerable = require('enumerable')
local res = require('resources')

local fetch = shared.get('items_service', 'equipment')

local indexer = function(data, index)
    return data[index]
end

local iterator = function(data, index)
    return {next(data, index)}
end

local equip_meta = {
    __index = function(t, index)
        
        if type(index) == 'string' then
            index = (res.slots:first(function(v, k, t)
                local lc_slot = index:lower()
                return v.english:lower() == lc_slot
            end) or {}).id or index
        end
        
        local success, data = fetch(indexer, index)

        if not success then
            error(data)
        end

        return data
    end,

    __newindex = function()
        error('The equipment structure is read-only.')
    end,

    __pairs = function(t)
        return function(t, index)
            local success, data = fetch(iterator, index)

            if not success then
                error(data)
            end

            return unpack(data)
        end, t, nil
    end,
}

return enumerable(equip_meta)()
