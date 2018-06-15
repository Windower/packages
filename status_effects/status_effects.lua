local enum   = require('enumerable')
local res    = require('resources')
local shared = require('shared')

local fetch_status_effects = shared.get('status_effects_service', 'status_effects')

local indexer = function(data, resource_name, index)
    return data[resource_name][index]
end

local iterator = function(data, resource_name, index)
    return {next(data[resource_name], index)}
end

local player_indexer = function(result, index)
    local data = {}
    for k, v in pairs(result) do
        if v.id == index then
            data[#data + 1] = v
        end
    end
    return data 
end

local party_indexer = function(result, index)
    local data = {}
    for k, v in pairs(result) do
        if v == index then
            data[#data + 1] = v
        end
    end
    return data 
end

local indexers = {
    party = function(result, index) 
        if result[index] then
            return setmetatable({},  {                
                    __index = function(mts, k)
                        if type(k) == "string" then                    
                            status = res.buffs:first(function(v) return v.english == k end)
                            if status then
                                return party_indexer(result[index], status.id)
                            end
                        elseif type(k) == "number" then
                            status = res.buffs[k]
                            if status then
                                return party_indexer(result[index], status.id)
                            end
                        end
                    end,
                    __len = function(t)
                        return #result[index]
                    end,
                    __pairs = function(_)
                        return function(_,k) 
                            return next(result[index], k) 
                        end
                    end,
                })
        end
        return
    end,
    player = function(result, index)
        if type(index) == "string" then                    
            status = res.buffs:first(function(v) return v.english == index end)
            if status then
                return player_indexer(result, status.id)
            end
        elseif type(index) == "number" then
            status = res.buffs[index]
            if status then
                return player_indexer(result, status.id)
            end
        end
        return
    end,
}

local constructors = setmetatable({}, {
        __index = function(mts, resource_name)
            local _, result = fetch_status_effects(function(data, resource_name)
                    return data[resource_name]
                end, resource_name)

            local meta = {}

            meta.__index = function(t, index)
                if(indexers[resource_name]) then
                    r = indexers[resource_name](result, index)
                    if r then return r end
                end
                local success, data = fetch_status_effects(indexer, resource_name, index)

                if not success then
                    error(data)
                end

                return data
            end

            meta.__pairs = function(t)
                return function(t, index)
                    local success, data = fetch_status_effects(iterator, resource_name, index)

                    if not success then
                        error(data)
                    end

                    return unpack(data)
                end, t, nil
            end

            local constructor = enum.init_type(meta)
            mts[resource_name] = constructor
            return constructor
        end,
    })

return setmetatable({}, {
        __index = function(_, resource_name)
            return constructors[resource_name]()
        end
    })