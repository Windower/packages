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
