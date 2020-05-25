require('core.event') -- Required for the serializer
local channel = require('core.channel')
local serializer = require('core.serializer')
local struct = require('struct')

local channel_get = channel.get
local serializer_deserialize = serializer.deserialize
local struct_name = struct.name
local struct_metatype = struct.metatype
local struct_from_ptr = struct.from_ptr

local prepared = {}

local prepare_struct
local prepare_array

local configure_ftype = function(ftype)
    local count = ftype.count
    local fields = ftype.fields

    if count then
        prepare_array(ftype)
    elseif fields then
        prepare_struct(ftype)
    end

    local name = ftype.name
    if not name or prepared[name] then
        return
    end

    if count or fields then
        struct_name(ftype, name)
        struct_metatype(ftype)
    end

    prepared[name] = true
end

prepare_struct = function(struct)
    for _, field in pairs(struct.fields) do
        local ftype = field.type
        if ftype then
            configure_ftype(ftype)
        end
    end
end

prepare_array = function(array)
    local ftype = array.base
    if ftype then
        configure_ftype(ftype)
    end
end

return {
    new = function(package_name, data_name)
        data_name = data_name or 'data'

        local data_client = channel_get(package_name, package_name .. '_' .. data_name)
        local data = data_client:read()

        local ftype = serializer_deserialize(data.ftype)
        configure_ftype(ftype)

        return struct_from_ptr(ftype, data.address), ftype
    end,
    configure = function(ftype)
        configure_ftype(ftype)
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
