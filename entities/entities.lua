local memory = require('memory')

local entities = {}

function entities.get_by_id(id)
    for k=0, 0x900, 1 do
        entity = memory.entities[k]
        if entity.cdata ~= nil and entity.id == id then
            return entity
        end
    end
end

function entities.get_by_name(name)
    for k=0, 0x900, 1 do
        entity = memory.entities[k]
        if entity.cdata ~= nil and entity.name == name then
            return entity
        end
    end
end

function entities.get_by_index(index)
    for k=0, 0x900, 1 do
        entity = memory.entities[k]
        if entity.cdata ~= nil and entity.index == index then
            return entity
        end
    end
end

return entities
