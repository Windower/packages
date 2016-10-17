-- sharing_lib
-- Requirements:
--   type(shared.data) has to be constant.
--   objects and new_event cannot be first level keys.

local shared = require('shared')
local event = require('event')

local default_env = {pairs=pairs,ipairs=ipairs,print=print,next=next,type=type,rawget=rawget,unpack=unpack}

local function make_shared(name,data,env)
    -- Users currently cannot alter env
    local userdata = shared.new(name)
    local shared_event = event.new()
    local event_running = true
    local event_waiting = false
    
    local const_type = type(data)
    userdata.data = data or {}
    userdata.env = env or default_env
    
    local function call_event()
        if event_running then
            shared_event:trigger(userdata.data)
        else
            event_waiting = true
        end
    end
    
    local sharing_metamethods = {}

    function sharing_metamethods.__index(t,k)
        if sharing_metamethods[k] then return sharing_metamethods[k] end
        return userdata.data[k]
    end
    
    function sharing_metamethods.__newindex(t,k,v)
        if userdata.data[k] ~= v then
            userdata.data[k] = v
            call_event()
        end
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
    
    function sharing_metamethods:notify_changed(bool)
        if bool and not event_running and event_waiting then
            -- The event was paused and is being unpaused and the service wanted to call it while it was paused
            shared_event:trigger(userdata.data)
            event_waiting = false
        end
        event_running = bool
    end
    
    function sharing_metamethods:value()
        return userdata.data
    end
    
    function sharing_metamethods:assign(v)
        if userdata.data ~= v then
            userdata.data = v
            call_event()
        end
    end

    return setmetatable({},sharing_metamethods),shared_event
end

local function share_container()
    local objects = make_shared('objects')
    local shared_events = make_shared('new_event')
    local shared_objects = {}
    
    local meta = {}
    
    meta.__newindex=function(t,k,v)
        k = tostring(k)
        
        if not shared_objects[k] then
            shared_objects[k],shared_events[k] = make_shared(k,v)
            objects[objects:len()+1] = k
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