local enumerable = require('enumerable')
local res = require('resources')
local shared = require('shared')

local fetch = shared.get('items_service', 'equipment')

local iterate = function(data, index)
    return next(data, index)
end

local equip_meta = {
    __index = function(t, index)
        if type(index) == 'string' then
            local lc_slot = index:lower()
            index = (res.slots:first(function(v, k, t)
                return v.english:lower() == lc_slot
            end) or {}).id or index
        end
        
        return fetch:read(index)
    end,

    __newindex = function()
        error('The equipment structure is read-only.')
    end,

    __pairs = function(t)
        return function(t, index)
            return fetch:call(iterate, index)
        end, t, nil
    end,
}

return enumerable.init_type(equip_meta)()
