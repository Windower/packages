local ffi = require('ffi')
local scanner = require('core.scanner')
local types = require('memory:types')

local modules = {'FFXiMain.dll', 'polcore.dll', 'polcoreEU.dll'}
local byte_ptr = ffi.typeof('char*')
local void_ptr_ptr = ffi.typeof('void**')

local rawset = rawset
local next = next
local ffi_cast = ffi.cast
local scanner_scan = scanner.scan

local get_instance = function(ftype, ptr)
    return ffi_cast(ftype.name .. '*', ptr)[0]
end

local get_scan_ptr = function(ftype)
    for i = 1, #modules do
        local ptr = scanner_scan(ftype.signature, modules[i])
        if ptr ~= nil then
            return ptr
        end
    end
end

local setup_name = function(name)
    local ftype = types[name]

    local ptr = get_scan_ptr(ftype)

    local offsets = ftype.offsets
    for i = 1, #offsets do
        ptr = ffi_cast(void_ptr_ptr, ffi_cast(byte_ptr, ptr) + offsets[i])[0]
    end

    return ftype, ptr
end

return setmetatable({}, {
    __index = function(t, k)
        local ftype, ptr = setup_name(k)

        local cdata = get_instance(ftype, ptr)
        rawset(t, k, cdata)
        return cdata
    end,
    __newindex = function(_, k, value)
        types[k] = value
    end,
    __pairs = function(t)
        return function(t, k)
            local key = next(t, k)
            return key, key and t[key]
        end, types, nil
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
