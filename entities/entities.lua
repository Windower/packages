local memory = require('memory')
local bit = require('bit')

local entities = {}

local array_size = 0x900

local mob_begin = 0x000
local player_begin = 0x400
local ally_begin = 0x700

entities.get_by_id = function(id)
    if bit.band(id, 0xFF000000) ~= 0 then
        local sub_mask = bit.band(id, 0x7FF)
        local index = sub_mask + (bit.band(id, 0x800) ~= 0 and ally_begin or 0)
        if index < 0 or index > array_size then
            return nil
        end

        local entity = memory.entities[index]
        if not entity or entity.id ~= id then
            return nil
        end

        return entity
    end

    for i = player_begin, ally_begin - 1 do
        local entity = memory.entities[i]
        if entity and entity.id == id then
            return entity
        end
    end
end

entities.get_by_name = function(name)
    for i = 0, array_size do
        local entity = memory.entities[i]
        if entity and entity.name == name then
            return entity
        end
    end
end

return setmetatable(entities, {
    __index = function(_, key)
        if type(key) ~= 'number' or key < 0 or key > array_size then
            return nil
        end

        return memory.entities[key]
    end,
})
