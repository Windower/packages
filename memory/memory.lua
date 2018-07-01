local ffi = require('ffi')
local scanner = require('scanner')
local string = require('string')
local types = require('memory:types')

local scan_results = {}
local fixed_types = {}

local modules = {'FFXiMain.dll', 'polcore.dll', 'polcoreEU.dll'}
local byte_ptr = ffi.typeof('char*')
local void_ptr_ptr = ffi.typeof('void**')

local meta_array
local meta_struct

local do_get_magic
do_get_magic = function(instance, type)
    if instance == nil then
        return nil
    end

    if type.ptr == true then
        return do_get_magic(instance[0], type.base)
    elseif type.count ~= nil and type.cdef ~= 'char' then
        return setmetatable({ cdata = instance, type = type.base }, meta_array)
    elseif type.fields ~= nil then
        return setmetatable({ cdata = instance, type = type }, meta_struct)
    else
        local tolua = type.tolua
        local data = type.signature ~= nil and instance[0] or instance
        return tolua and tolua(data) or data
    end
end

local do_set_magic = function(root_instance, index, value, type)
    local toc = type.toc
    if toc ~= nil then
        toc(root_instance, index, value)
    else
        root_instance[index] = value
    end
end

meta_array = {
    __index = function(data, index)
        local instance = data.cdata[index]
        return do_get_magic(instance, data.type)
    end,
    __newindex = function(data, index, value)
        do_set_magic(data.cdata, index, value, data.type)
    end,
}

do
    local get_struct_field = function(fields, name)
        for _, field in ipairs(fields) do
            if field.label == name then
                return field
            end
        end

        error('Nested memory definition for \'' .. name .. '\' not found.')
    end

    meta_struct = {
        __index = function(data, name)
            local instance = data.cdata[name]
            local field = get_struct_field(data.type.fields, name)
            return do_get_magic(instance, field.type)
        end,
        __newindex = function(data, name, value)
            local field = get_struct_field(data.type.fields, name)
            do_set_magic(data.cdata, name, value, field.type)
        end,
    }
end

local get_instance = function(type, ptr)
    return ffi.cast(type.ctype, ptr)
end

local setup_name = function(name)
    local type = types[name]
    assert(type ~= nil, 'Memory definition for \'' .. name .. '\' not found.')

    local ptr = scan_results[name]
    if ptr == nil then
        for _, module in ipairs(modules) do
            ptr = scanner.scan(type.signature, module)
            if ptr ~= nil then
                break
            end
        end
        assert(ptr ~= nil, 'Signature ' .. type.signature .. ' not found.')

        for _, offset in ipairs(type.static_offsets) do
            ptr = ffi.cast(void_ptr_ptr, (ffi.cast(byte_ptr, ptr) + offset))[0]
        end

        scan_results[name] = ptr
    end

    return type, ptr
end

return setmetatable({}, {
    __index = function(_, name)
        do
            local cached = fixed_types[name]
            if cached ~= nil then
                return do_get_magic(cached, types[name])
            end
        end

        local type, ptr = setup_name(name)

        if next(type.offsets) == nil then
            local res = get_instance(type, ptr)
            fixed_types[name] = res
            return do_get_magic(res, type)
        end

        for _, offset in ipairs(type.offsets) do
            ptr = ffi.cast(byte_ptr, ptr)[offset]
        end

        return do_get_magic(get_instance(type, ptr), type)
    end,
    __newindex = function(_, name, value)
        if value.signature then
            types[name] = value
            return
        end

        do
            local cached = fixed_types[name]
            if cached ~= nil then
                return do_set_magic(cached, 0, value, types[name])
            end
        end

        local type, ptr = setup_name(name)

        do_set_magic(get_instance(type, ptr), 0, value, type)
    end,
})

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
