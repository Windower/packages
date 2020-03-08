require('core.event') -- Required for the serializer
local ffi = require('ffi')
local channel = require('core.channel')
local serializer = require('core.serializer')
local struct = require('struct')
local windower = require('core.windower')

ffi.cdef[[
    void* HeapAlloc(void*, uint32_t, size_t);
    bool HeapFree(void*, uint32_t, void*);
    void* HeapCreate(uint32_t, size_t, size_t);
    bool HeapDestroy(void*);
]]

local C = ffi.C
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local channel_new = channel.new
local serializer_serialize = serializer.serialize
local struct_name = struct.name

local destroyed = false
local heap = ffi_gc(C.HeapCreate(0, 0, 0), function(heap)
    destroyed = true
    C.HeapDestroy(heap)
end)

local ptr_cache = setmetatable({}, {
    __mode = 'k'
})

local destroy = function(cdata)
    if destroyed then
        return
    end

    C.HeapFree(heap, 0, ptr_cache[cdata])
end

local attach_gc = function(cdata, ptr)
    ptr_cache[cdata] = tonumber(ffi_cast('intptr_t', ptr))
    return ffi_gc(cdata, destroy)
end

local new_ptr = function(ftype)
    struct_name(ftype)
    return ffi_cast(ftype.name .. '*', C.HeapAlloc(heap, 8, ftype.size))
end

local servers = {}
local service_name = windower.package_path:gsub('(.+\\)', '')

return {
    new = function(name, ftype)
        name, ftype = ftype and name or 'data', ftype or name

        local server = channel_new(service_name .. '_' .. name)
        servers[name] = server

        local ptr = new_ptr(ftype)
        server.data = {
            address = tonumber(ffi_cast('intptr_t', ptr)),
            ftype = serializer_serialize(ftype, true),
        }

        return attach_gc(ptr[0], ptr)
    end,
    new_ptr = function(ftype)
        local ptr = new_ptr(ftype)
        return attach_gc(ptr, ptr)
    end,
}

--[[
Copyright © 2018, Windower Dev Team
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Windower Dev Team nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE WINDOWER DEV TEAM BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
