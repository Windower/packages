local ffi = require('ffi')
local scanner = require('scanner')
local string = require('string')
local types = require('memory:types')

local scan_results = {}
local fixed_types = {}

local modules = {'FFXiMain.dll', 'polcore.dll', 'polcoreEU.dll'}
local byte_ptr = ffi.typeof('char*')
local void_ptr_ptr = ffi.typeof('void**')

local get_instance = function(ftype, ptr)
    return ffi.cast(ftype.name .. '*', ptr)
end

local setup_name = function(name)
    local ftype = types[name]
    assert(ftype ~= nil, 'Memory definition for \'' .. name .. '\' not found.')

    local ptr = scan_results[name]
    if ptr == nil then
        for _, module in ipairs(modules) do
            ptr = scanner.scan(ftype.signature, module)
            if ptr ~= nil then
                break
            end
        end
        assert(ptr ~= nil, 'Signature ' .. ftype.signature .. ' not found.')

        for _, offset in ipairs(ftype.static_offsets) do
            ptr = ffi.cast(void_ptr_ptr, ffi.cast(byte_ptr, ptr) + offset)[0]
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
                return cached[0]
            end
        end

        local ftype, ptr = setup_name(name)

        if next(ftype.offsets) == nil then
            local res = get_instance(ftype, ptr)
            fixed_types[name] = res
            return res[0]
        end

        for _, offset in ipairs(ftype.offsets) do
            ptr = ffi.cast(byte_ptr, ptr)[offset]
        end

        return get_instance(ftype, ptr)[0]
    end,
    __newindex = function(_, name, value)
        types[name] = value
    end,
    __pairs = function(_)
        return function(t, k)
            return (next(t, k))
        end, types, nil
    end
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
