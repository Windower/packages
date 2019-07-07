local ffi = require('ffi')
local scanner = require('scanner')
local types = require('memory:types')

local scan_results = {}
local fixed_types = {}

local modules = {'FFXiMain.dll', 'polcore.dll', 'polcoreEU.dll'}
local byte_ptr = ffi.typeof('char*')
local void_ptr_ptr = ffi.typeof('void**')

local ffi_cast = ffi.cast
local scanner_scan = scanner.scan

local get_instance = function(ftype, ptr)
    return ffi_cast(ftype.name .. '*', ptr)[0]
end

local setup_name = function(name)
    local ftype = types[name]

    local ptr = scan_results[name]
    if ptr == nil then
        for _, module in ipairs(modules) do
            ptr = scanner_scan(ftype.signature, module)
            if ptr ~= nil then
                break
            end
        end

        for _, offset in ipairs(ftype.static_offsets) do
            ptr = ffi_cast(void_ptr_ptr, ffi_cast(byte_ptr, ptr) + offset)[0]
        end

        scan_results[name] = ptr
    end

    return ftype, ptr
end

return setmetatable({}, {
    __index = function(_, name)
        do
            local cached = fixed_types[name]
            if cached ~= nil then
                return cached
            end
        end

        local ftype, ptr = setup_name(name)

        local offsets = ftype.offsets
        if next(offsets) == nil then
            local res = get_instance(ftype, ptr)
            fixed_types[name] = res
            return res
        end

        for _, offset in ipairs(offsets) do
            ptr = ffi_cast(byte_ptr, ptr)[offset]
        end

        return get_instance(ftype, ptr)
    end,
    __newindex = function(_, name, value)
        types[name] = value
    end,
    __pairs = function(memory)
        return function(t, k)
            local key = next(t, k)
            return key, key and memory[key]
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
