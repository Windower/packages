local memory = require('memory')

local key_fns = {
    alliance = function() return memory.party.members[0].alliance_info end
}

return setmetatable({}, {
    __index = function(_, key)
        if type(key) ~= 'number' then
            local fn = key_fns[key]
            return fn and fn()
        elseif key < 1 or key > 18 then
            return nil
        end

        local member = memory.party.members[key - 1]
        return member.active and member or nil
    end,
})
