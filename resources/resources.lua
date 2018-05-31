local shared = require('shared')
local enumerable = require('enumerable')

local fetch = shared.get('resources_service', 'resources')

local indexer = function(data, resource_name, index)
    return data[resource_name][index]
end

local iterator = function(data, resource_name, index)
    return {next(data[resource_name], index)}
end

local constructors = setmetatable({}, {
    __index = function(mts, resource_name)
        local success, data = assert(fetch(function(data, resource_name)
            return data[resource_name] ~= nil
        end, resource_name))

        assert(data, 'Resource "' .. resource_name .. '" not found.')

        local meta = {}

        meta.__index = function(t, index)
            local success, data = assert(fetch(indexer, resource_name, index))
            if data == nil then
                return nil
            end

            -- TODO: proper language detection...
            data.name = data.english
            return data
        end

        meta.__pairs = function(t)
            return function(t, index)
                local success, data = assert(fetch(iterator, resource_name, index))

                return unpack(data)
            end, t, nil
        end

        meta.__add_element = function(t, el)
            rawset(t, el.id, el)
        end

        local constructor = enumerable.init_type(meta)
        mts[resource_name] = constructor
        return constructor
    end,
})

return setmetatable({}, {
    __index = function(_, resource_name)
        return constructors[resource_name]()
    end
})
