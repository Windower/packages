local bit = require('bit')
local ffi = require('ffi')
local scanner = require('core.scanner')

ffi.cdef[[
    bool VirtualProtect(void*, uint32_t, uint32_t, uint32_t*);
]]

local C = ffi.C

local signatures = {
    '&74558BCEE8????????84C0744A',
    '&746F8BCEE8????????84C07464807E0C02',
    '&0F82EE00000068????????B9????????C6461800',
    '&727368????????B9????????C6461800',
    '&8BCEE8????????84C0742C8A460C84C0757A',
    '&8BCEE8????????84C0742C8A460C84C0752C',
    '&8BCEE8????????84C00F845A020000',
    '&8BCEE8????????84C00F84DA010000',
}

local ptrs = {}
for i = 1, #signatures do
    ptrs[i] = ffi.cast('uint8_t*', assert(scanner.scan(signatures[i]), 'Signature not found: ' .. signatures[i]))
end

local patches = {
    {0xEB},
    {0xEB},
    {0x90, 0x90, 0x90, 0x90, 0x90, 0x90},
    {0x90, 0x90},
    {[6] = 0xCC, [7] = 0xCC},
    {[6] = 0xCC, [7] = 0xCC},
}

local adjust = function(list, index)
    local offset = ptrs[index] - ptrs[index - 2] - 5
    list[1] = 0xE9
    for i = 2, 5 do
        list[i] = bit.band(bit.rshift(offset, (i - 2) * 0x08), 0xFF)
    end
end

adjust(patches[5], 7)
adjust(patches[6], 8)

for i = 1, #patches do
    assert(C.VirtualProtect(ptrs[i], #patches[i], 0x40, ffi.new('int[1]')), 'VirtualProtect failed')
end

local originals = {}

for i = 1, #patches do
    local original = {}
    local ptr = ptrs[i]
    for j = 1, #patches[i] do
        original[j] = ptr[j - 1]
    end
    originals[i] = original
end

local apply = function(ptr, patch)
    for i = 1, #patch do
        ptr[i - 1] = patch[i]
    end
end

for i = 1, #patches do
    apply(ptrs[i], patches[i])
end

--TODO replace with unload event
gc_global = ffi.new('int*')

ffi.gc(gc_global, function()
    for i = 1, #originals do
        apply(ptrs[i], originals[i])
    end
end)

--[[
Copyright © 2019, Windower Dev Team
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
