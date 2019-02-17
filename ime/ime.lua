local scanner = require('scanner')
local ffi = require('ffi')

local language_check
language_check = ffi.gc(ffi.cast('uint8_t*', scanner.scan('&83EC08A1????????5333DB56')) + 0x2F, function()
    language_check[0] = 0x74
end)

local ime_class
ime_class = ffi.gc(ffi.cast('uint8_t**', scanner.scan('8B0D*????????81EC0401000053568B'))[0], function()
    ime_class[0xF0EC] = 1
    ime_class[0xF10C] = 1
end)

if language_check == nil or language_check[0] ~= 0x74 then
    error('Invalid language_check signature')
end

if ime_class == nil then
    error('Invalid ime_class signature')
end

local coroutine_sleep_frame = coroutine.sleep_frame

coroutine.schedule(function()
    while true do
        language_check[0] = 0xEB
        ime_class[0xF0EC] = 0
        ime_class[0xF10C] = 0
        coroutine_sleep_frame()
    end
end)

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
