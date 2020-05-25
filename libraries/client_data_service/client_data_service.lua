local bit = require('bit')
local ffi = require('ffi')
local io = require('io')
local channel = require('core.channel')
local string = require('string')
local windower = require('core.windower')

id_map = channel.new('id_map')

local rom_map
local id_count

do
    local rom = 1
    local vtable
    do
        local f = assert(io.open(windower.client_path .. '\\VTABLE.DAT', 'rb'))
        vtable = f:read('*a')
        f:close()
    end

    id_count = #vtable
    rom_map = ffi.new('uint8_t[' .. id_count .. ']')

    while vtable ~= nil do
        for id = 1, id_count do
            local temp = vtable:byte(id)
            if temp == rom then
                rom_map[id - 1] = temp
            end
        end

        rom = rom + 1
        vtable = nil
        local f = io.open(windower.client_path .. '\\ROM' .. rom .. '\\VTABLE' .. rom .. '.DAT', 'rb')
        if f then
            vtable = f:read('*a')
            f:close()
        end
    end
end

do
    local band = bit.band
    local bor = bit.bor
    local lshift = bit.lshift
    local rshift = bit.rshift
    local io_open = io.open
    local string_byte = string.byte

    id_map.data = setmetatable({}, {
        __index = function(_, id)
            if type(id) ~= 'number' or id < 0 or id >= id_count then
                return nil
            end

            local rom = rom_map[id]
            local dir
            local dat

            do
                local ftable
                if rom == 1 then
                    ftable = windower.client_path .. '\\FTABLE.DAT'
                elseif rom > 1 then
                    ftable = windower.client_path .. '\\ROM' .. rom .. '\\FTABLE' .. rom .. '.DAT'
                else
                    return nil
                end
                local f = assert(io_open(ftable, 'rb'))
                f:seek('set', id * 2)
                local packed = f:read(2)
                f:close()
                dir = bor(lshift(string_byte(packed, 2), 1), rshift(string_byte(packed, 1), 7))
                dat = band(string_byte(packed, 1), 0x7F)
            end

            if rom == 1 then
                return windower.client_path .. '\\ROM\\' .. dir .. '\\' .. dat .. '.DAT'
            else
                return windower.client_path .. '\\ROM' .. rom .. '\\' .. dir .. '\\' .. dat .. '.DAT'
            end
        end,
        __newindex = error,
        __metatable = false,
    })
end
