local bit = require('bit')
local ffi = require('ffi')
local io = require('io')
local shared = require('shared')
local string = require('string')
local windower = require('windower')

id_map = shared.new('id_map')

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
                local f = assert(io.open(ftable, 'rb'))
                f:seek('set', id * 2)
                local packed = f:read(2)
                f:close()
                dir = bor(lshift(packed:byte(2), 1), rshift(packed:byte(1), 7))
                dat = band(packed:byte(1), 0x7F)
            end

            if rom == 1 then
                return windower.client_path .. '\\ROM\\' .. dir .. '\\' .. dat .. '.DAT'
            else
                return windower.client_path .. '\\ROM' .. rom .. '\\' .. dir .. '\\' .. dat .. '.DAT'
            end
        end,
        __newindex = function() end,
        __metatable = false,
    })
end
