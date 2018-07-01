local memory = require('memory')
local player = require('player')

local key_fns = {
    t = function() return memory.target_array.targets[memory.target_array.sub_target_active and 1 or 0].entity end,
    st = function() return memory.target_array.sub_target_active and memory.target_array.targets[0].entity or nil end,
    me = function() return memory.entities[player.index] end,
}

return setmetatable({}, {
    __index = function(_, key)
        local fn = key_fns[key]
        return fn and fn() or nil
    end,
})
