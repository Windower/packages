-- sharing_lib
-- Requirements:
--   type(shared.data) has to be constant.

local shared = require('shared')

local default_env = {pairs=pairs,ipairs=ipairs,print=print,next=next,type=type,rawget=rawget,unpack=unpack}

local function make_shared(name,data,env)
    -- Users currently cannot alter env
    local userdata = shared.new(name)
    
    -- REVISIT: The below exception is currently not handled
    -- Can it even happen?
    if not userdata then return false end
    
    local const_type = type(data)
    userdata.data = data or {}
    userdata.env = env or default_env
    
    local sharing_metamethods = {}

    function sharing_metamethods.__index(t,k)
        if sharing_metamethods[k] then return sharing_metamethods[k] end
        return userdata.data[k]
    end
    
    function sharing_metamethods.__newindex(t,k,v)
        userdata.data[k] = v
    end
    
    function sharing_metamethods:type()
        return const_type
    end
    
    function sharing_metamethods:len()
        local i = 0
        while userdata.data[i+1] do
            i = i + 1
        end
        return i
    end
    
    function sharing_metamethods:value()
        return userdata.data
    end
    
    function sharing_metamethods:assign(v)
        userdata.data = v
    end

    return setmetatable({},sharing_metamethods)
end

local function share_container()
    local list = make_shared('list')
    local shared_objects = {}
    
    local meta = {}
    
    meta.__newindex=function(t,k,v)
        k = tostring(k)
        
        if not shared_objects[k] then
            shared_objects[k] = make_shared(k,v)
            list[list:len()+1] = k
        elseif shared_objects[k]:type() == type(v) then
            shared_objects[k]:assign(v)
        else
            -- REVISIT: Currently it is ignored if the user tries to change the base data type
        end
    end
    
    meta.__index=function(t,k)
        k=tostring(k)
        if not shared_objects[k] then return end

        if shared_objects[k]:type() == 'table' then
            return shared_objects[k]
        else
            return shared_objects[k]:value()
        end
    end
    
    return setmetatable({},meta)
end

return share_container