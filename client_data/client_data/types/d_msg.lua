local ffi = require('ffi')
local structs = require('structs')
local unicode = require('unicode')

local ffi_cast = ffi.cast
local ffi_string = ffi.string
local unicode_from_shift_jis = unicode.from_shift_jis

local byte_ptr = ffi.typeof('uint8_t*')
local int_ptr = ffi.typeof('uint32_t*')

local header_type = structs.struct({
    format          = {0x00, structs.string(0x08)},
    type            = {0x08, structs.uint16},
    encrypted       = {0x0A, structs.bool},
    version1        = {0x0C, structs.uint32},
    version2        = {0x10, structs.uint32},
    file_size       = {0x14, structs.uint32},
    header_size     = {0x18, structs.uint32},
    table_size      = {0x1C, structs.uint32},
    entry_size      = {0x20, structs.uint32}, -- Maybe not set in memory? Is zero, at least for weather strings
    data_size       = {0x24, structs.uint32},
    count           = {0x28, structs.uint32},
})

local offset_from_table = function(id, table, entry_size)
    return table[2 * id]
end

local offset_from_entry_size = function(id, table, entry_size)
    return id * entry_size
end

local build_index = function(ptr, header, lookup)
    local table = ffi_cast(int_ptr, ptr + header.header_size)
    local data = ptr + header.header_size + header.table_size

    if header.type == 0x10 then
        return function(_, id)
            return (unicode_from_shift_jis(ffi_string(data + table[2 * id])))
        end
    end

    local entry_size = header.entry_size
    local get_offset = entry_size ~= 0 and offset_from_entry_size or offset_from_table

    return function(_, id)
        local entry = data + get_offset(id, table, entry_size)
        local entry_table = ffi_cast(int_ptr, entry + 4)

        local res = {}
        for index = 0, ffi_cast(int_ptr, entry)[0] - 1 do
            local type = entry_table[2 * index + 1]
            local item_ptr = entry + entry_table[2 * index]
            if type == 0 then
                res[index + 1] = (unicode_from_shift_jis(ffi_string(item_ptr + 0x1C)))
            elseif type == 1 then
                res[index + 1] = ffi_cast(int_ptr, item_ptr)[0]
            end
        end

        for name, index in pairs(lookup) do
            res[name] = res[index]
        end

        return res
    end
end

return {
    new = function(ptr, lookup)
        ptr = ffi_cast(byte_ptr, ptr)
        lookup = lookup or {}

        local header = structs.from_ptr(header_type, ptr)
        local size = header.count

        return setmetatable({}, {
            __index = build_index(ptr, header, lookup),
            __pairs = function(t)
                return function(t, k)
                    k = k + 1
                    if k >= size then
                        return nil, nil
                    end

                    return k, t[k]
                end, t, -1
            end,
            __ipairs = pairs,
            __len = function(t)
                return size
            end,
            __newindex = error,
            __metatable = false,
        })
    end,
}
