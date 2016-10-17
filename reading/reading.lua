-- reading_lib
local shared = require('shared')
require('os')


local function make_weak_metamethods()
    local ts={__mode='kv'}
    local cache = {__mode='kv'}
    local meta = {}
    function meta.__index(_,k)
        if cache[k] and ts[k] and os.clock() - ts[k] < 1 then
            return cache[k]
        end
        if cache[k] then
            -- REVISIT
            -- Not explicitly necessary, perhaps
            -- Will this interfere with __newindex?
            cache[k] = nil
        end
        if ts[k] then
            -- REVISIT
            -- Not explicitly necessary, perhaps
            -- Will this interfere with __newindex?
            ts[k] = nil
        end
    end
    function meta.__newindex(_,k,v)
        cache[k]=v
        ts[k]=os.clock()
    end
    return meta
end

local function make_reading_metamethods(name,userdata,userdata_type)
    local meta = {}
    local cache = setmetatable({},make_weak_metamethods())
    
    function meta.__index(t,k)
        if meta[k] then return meta[k] end
        
        -- Cached result prevents multiple fetches in a short period of time
        if cache[k] then
            return cache[k]
        end
        
        local function ind(t,k)
            return t[k]
        end

        local ok,result = userdata:fetch(ind,k)
        
        if ok and result then
            cache[k]=result
            return result
        end
    end

    function meta:len()
        local len
        if userdata_type == 'table' then
            len = function(t)
                local counter = 0
                for i in ipairs(t) do
                    counter = i
                end
                return counter
            end
        elseif userdata_type == 'string' then
            len = function(t)
                local i = 0
                while t[i+1] do
                    i = i+1
                end
                return i
            end
        else
            -- REVISIT : Can this be hit?
        end
        local ok,result = userdata:fetch(len)
        return ok and result
    end

    function meta:keys()
        if userdata_type ~= 'table' then
            -- REVISIT : Can this be hit?
            return
        end
        local function keys(t)
            local keys = {}
            for i in pairs(t) do
                keys[#keys+1]=i
            end
            return keys
        end
        local ok,result = userdata:fetch(keys)
        return ok and result
    end

    function meta:with(key,val,limit)
        if userdata_type ~= 'table' then
            -- REVISIT : Can this even be hit?
            print(':with(key,val,limit) only works for tables')
            return
        end
        if not key then
            return
        end
        
        local function with(data,key,val,limit)
            limit = limit and limit < 300 or 300 -- REVISIT: Need the real value for this at some point
            local results = {}
            for i,v in pairs(data) do
                if rawget(v,key) and (not val or rawget(v,key) == val) then
                    results[#results+1]=v
                end
                if limit and #results == limit then break end
            end
            
            if #results > 0 then
                return results
            end
            
            return {false}
        end
        
        -- REVISIT
        -- Need a way to return variable arguments
        local ok,results = userdata:fetch(with,key,val,limit)
        if ok then return unpack(results) end
    end
    
    function meta:type()
        return userdata_type
    end
    
    function meta:value()
        if userdata_type == 'table' then
            error('reading_lib: :value() only works for non-table values',-2)
        else
            -- REVISIT
            -- How should this check the cache?
            local ok,data = userdata:fetch(function(t) return t end)
            return ok and data
        end
    end
    
    return meta
end

local function read_container(addon_name)
    if type(addon_name) ~= 'string' then return end
    
    local meta,shared_objects = {},{}
    
    function meta.__index(t,k)
        k = tostring(k) -- Shared object names are stored in strings
        
        if shared_objects[k] then
            -- Shared object reference has already been acquired by this addon
            if shared_objects[k]:type() == 'table' then
                return shared_objects[k]
            else
                return shared_objects[k]:value()
            end
        else
            -- Acquire shared object reference, if it exists
            local ok,result = shared.get(addon_name,k)
            if ok then
                local _,shared_data_type = result:fetch(function(t) return type(t) end)
                shared_objects[k]=setmetatable({},make_reading_metamethods(k,result,shared_data_type))

                if shared_data_type == 'table' then
                    return shared_objects[k]
                else
                    return shared_objects[k]:value()
                end
            end
            return ok
        end
    end

    local events_exist,events = shared.get(addon_name,'new_event')
    
    
    function meta.new_event(t,k)
        if events_exist then -- Events will not exist if the other side is not using the sharing lib
            k = tostring(k)
            if events[k] then
                return events[k]
            else
                return {register=function() end,unregister=function() end}
            end
        end
    end
    
    function meta.__newindex(t,k)
        -- No more assignment allowed.
    end
    
    return setmetatable({},meta)
end

-- Need to make function that returns the list of shared values from an addon.

return read_container