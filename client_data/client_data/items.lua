local bit = require('bit')
local files = require('client_data.files')
local ffi = require('ffi')
local structs = require('structs')
local unicode = require('unicode')

local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_string = ffi.string
local ffi_typeof = ffi.typeof
local to_utf16 = unicode.to_utf16
local from_shift_jis = unicode.from_shift_jis

local size_type = ffi.typeof('unsigned long[1]')
local raw_data_ptr = ffi.typeof('uint8_t*')
local int32_ptr = ffi.typeof('int32_t*')
local invalid_handle = ffi.cast('void*', -1)

local int8 = structs.int8
local int16 = structs.int16
local int32 = structs.int32
local int64 = structs.int64
local uint8 = structs.uint8
local uint16 = structs.uint16
local uint32 = structs.uint32
local uint64 = structs.uint64
local float = structs.float
local double = structs.double
local bool = structs.bool

local string = structs.string

local struct = structs.struct
local bit = structs.bit

ffi.cdef[[
typedef struct _OVERLAPPED OVERLAPPED;

void* CreateFileW(wchar_t const*, unsigned long, unsigned long, void*, unsigned long, unsigned long, void*);
unsigned long SetFilePointer(void*, long, long*, unsigned long);
int ReadFile(void*, void*, unsigned long, unsigned long*, OVERLAPPED*);
int CloseHandle(void*);
unsigned long GetLastError();
]]

local c = ffi.C

local file_handles = setmetatable({}, {
    __index = function(t, dat_id)
        local path = files[dat_id]
        if not path then
            error('unknown dat id [dat id: ' .. tostring(dat_id) .. ']')
        end

        local handle = c.CreateFileW(to_utf16(path), --[[GENERIC_READ]] 0x80000000, --[[FILE_SHARE_READ]] 0x1, nil,
        --[[OPEN_EXISTING]] 3, --[[FILE_ATTRIBUTE_NORMAL]] 128, nil)
        if handle == nil or handle == invalid_handle then
            error('error opening file "' .. path .. '" [error code: ' .. c.GetLastError() .. '; dat id: ' .. dat_id .. ']')
        end
        handle = ffi_gc(handle, c.CloseHandle)

        rawset(t, dat_id, handle)
        return handle
    end
})

local decrypt = function(data, size)
    local blocks = ffi_cast(int32_ptr, data)
    for i = 0, size / 4 - 1 do
        local b = blocks[i]
        blocks[i] = bor(rshift(band(b, 0xE0E0E0E0), 5), lshift(band(b, 0x1F1F1F1F), 3))
    end
end

local string_table = struct({
    count           = {0x00, uint32},
    entries         = {0x04, struct({
        offset      = {0x00, uint32},
        type        = {0x04, uint32},
    })[5]},
})

local item_struct
do
    local icon_descriptor = {0x280, uint8[0x980]}
    item_struct = function(fields)
        fields.icon = icon_descriptor
        return struct(fields)
    end
end

local general_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    element         = {0x0E, uint16},
    storage         = {0x10, uint16},
    _item_ref_id    = {0x12, uint16},
    _unknown1       = {0x14, uint16},
    attachment_id   = {0x16, uint16},
    strings         = {0x18, string_table},
})

local usable_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    activation_time = {0x0E, uint16},
    _item_ref_id    = {0x10, uint16},
    _unknown2       = {0x12, uint8},
    action_type     = {0x13, uint8},
    action_id       = {0x14, uint16},
    aoe_range       = {0x16, uint8},
    aoe             = {0x17, bool},
    aoe_targets     = {0x18, uint8},
    strings         = {0x1C, string_table},
})

local automaton_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    automaton_slot  = {0x0E, uint16},
    charge          = {0x10, struct({
        fire        = {0x00, bit(uint32, 4), offset = 0x00},
        ice         = {0x00, bit(uint32, 4), offset = 0x04},
        wind        = {0x00, bit(uint32, 4), offset = 0x08},
        earth       = {0x00, bit(uint32, 4), offset = 0x0C},
        lightning   = {0x00, bit(uint32, 4), offset = 0x10},
        water       = {0x00, bit(uint32, 4), offset = 0x14},
        light       = {0x00, bit(uint32, 4), offset = 0x18},
        dark        = {0x00, bit(uint32, 4), offset = 0x1C},
    })},
    _unknown3       = {0x14, uint32},
    strings         = {0x18, string_table},
})

local armor_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    level           = {0x0E, uint16},
    equipment_slots = {0x10, uint16},
    races           = {0x12, uint16},
    jobs            = {0x14, uint32},
    superior_level  = {0x18, uint16},
    shield_type     = {0x1A, uint16},
    max_charges     = {0x1C, uint8},
    cast_time       = {0x1D, uint8},
    use_delay       = {0x1E, uint16},
    reuse_delay     = {0x20, uint32},
    _item_ref_id    = {0x24, uint16},
    item_level      = {0x26, uint8},
    _augmentable    = {0x27, bool},
    aoe_modifier    = {0x28, uint8},
    aoe_range       = {0x29, uint8},
    aoe             = {0x2A, bool},
    aoe_targets     = {0x2B, uint8},
    strings         = {0x2C, string_table},
})

local weapon_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    level           = {0x0E, uint16},
    equipment_slots = {0x10, uint16},
    races           = {0x12, uint16},
    jobs            = {0x14, uint32},
    superior_level  = {0x18, uint16},
    damage          = {0x1C, uint16},
    delay           = {0x1E, uint16},
    dps             = {0x20, uint16},
    skill           = {0x22, uint8},
    animation       = {0x24, uint32},
    max_charges     = {0x28, uint8},
    cast_time       = {0x29, uint8},
    use_delay       = {0x2A, uint16},
    reuse_delay     = {0x2C, uint32},
    _item_ref_id    = {0x30, uint16},
    item_level      = {0x32, uint8},
    _augmentable    = {0x33, bool},
    aoe_modifier    = {0x34, uint8},
    aoe_range       = {0x35, uint8},
    aoe             = {0x36, bool},
    targets         = {0x37, uint8},
    strings         = {0x38, string_table},
})

local maze_tabula_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    _unknown4       = {0x0E, uint16},
    tabula_layout   = {0x14, int8[25]},
    strings         = {0x54, string_table},
})

local maze_voucher_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    _unknown4       = {0x0E, uint16},
    _unknown5       = {0x14, uint8[15]},
    strings         = {0x54, string_table},
})

local maze_rune_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    _unknown4       = {0x0E, uint16},
    element         = {0x14, int8},
    shape           = {0x15, uint8},
    strings         = {0x54, string_table},
})

local basic_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    _unknown4       = {0x0E, uint16},
    strings         = {0x54, string_table},
})

local instinct_item = item_struct({
    id              = {0x00, uint16},
    _unknown6       = {0x04, uint32},
    _unknown7       = {0x08, uint16},
    instinct_id     = {0x0A, uint16},
    _unknown8       = {0x0E, uint16},
    _unknown9       = {0x12, uint16},
    faculty_points  = {0x18, uint32},
    strings         = {0x28, string_table},
})

local monipulator_item = item_struct({
    id              = {0x00, uint16},
    monipulator_id  = {0x04, uint16},
    name            = {0x06, string(32)},
    family          = {0x26, uint16},
    species         = {0x28, uint16},
    sort_value      = {0x2A, uint16},
    _unknown10      = {0x2C, uint16},
    size            = {0x2E, uint16},
    abilities       = {0x30, struct({
        id          = {0x00, uint16},
        level       = {0x02, uint8},
        _unknown    = {0x03, uint8},
    })[16]},
    strings         = {0x70, string_table},
})

local gil_item = item_struct({
    id              = {0x00, uint16},
    flags           = {0x04, uint16},
    stack_size      = {0x06, int8},
    _unknown11      = {0x07, uint8},
    type            = {0x08, uint16},
    ah_sort_value   = {0x0A, uint16},
    valid_targets   = {0x0C, uint16},
    strings         = {0x10, string_table},
})

local item_info_map = {
    {first = 0x0000, last = 0x0FFF, base = 0x0000, en = 0x0049, ja = 0x0004, type = general_item},
    {first = 0x1000, last = 0x1FFF, base = 0x1000, en = 0x004A, ja = 0x0005, type = usable_item},
    {first = 0x2000, last = 0x21FF, base = 0x2000, en = 0x004D, ja = 0x0008, type = automaton_item},
    {first = 0x2200, last = 0x27FF, base = 0x2200, en = 0xD977, ja = 0xD8FF, type = general_item},
    {first = 0x2800, last = 0x3FFF, base = 0x2800, en = 0x004C, ja = 0x0007, type = armor_item},
    {first = 0x4000, last = 0x59FF, base = 0x4000, en = 0x004B, ja = 0x0006, type = weapon_item},
    {first = 0x5A00, last = 0x6FFF, base = 0x5A00, en = 0xD974, ja = 0xD8FC, type = armor_item},
    {first = 0x7000, last = 0x703F, base = 0x7000, en = 0xD973, ja = 0xD8FB, type = maze_tabula_item},
    {first = 0x7040, last = 0x707F, base = 0x7000, en = 0xD973, ja = 0xD8FB, type = maze_voucher_item},
    {first = 0x7080, last = 0x727F, base = 0x7000, en = 0xD973, ja = 0xD8FB, type = maze_rune_item},
    {first = 0x7280, last = 0x73FF, base = 0x7000, en = 0xD973, ja = 0xD8FB, type = basic_item},
    {first = 0x7400, last = 0x77FF, base = 0x7400, en = 0xD976, ja = 0xD8FE, type = instinct_item},
    {first = 0xF000, last = 0xF1FF, base = 0xF000, en = 0xD975, ja = 0xD8FD, type = monipulator_item},
    {first = 0xFFFF, last = 0xFFFF, base = 0xFFFF, en = 0x005B, ja = 0x0009, type = gil_item},
}

lookup_info = function(item_id)
    for i = 1, #item_info_map do
        local e = item_info_map[i]
        if item_id >= e.first and item_id <= e.last then
            return e
        end
    end
    return nil
end

local data_block_size = 0x30000
local data_block = ffi.typeof('uint8_t[' .. data_block_size .. ']')
local data_blocks = setmetatable({}, {
    __index = function(t, id)
        local dat_id = rshift(id, 10)
        local block_number = band(id, 0x3FF)

        local file_handle = file_handles[dat_id]
        local file_offset = block_number * data_block_size
        if c.SetFilePointer(file_handle, file_offset, nil, --[[FILE_BEGIN]] 0) == 0xFFFFFFFF then
            error('error seeking to offset [error code: ' .. c.GetLastError() .. '; dat id: ' .. dat_id .. ']')
        end

        local block = data_block()
        if c.ReadFile(file_handle, block, data_block_size, size_type(), nil) == 0 then
            error('error reading from file [error code: ' .. c.GetLastError() .. '; dat id: ' .. dat_id .. ']')
        end

        decrypt(block, data_block_size)

        rawset(t, id, block)
        return block
    end,
    __mode = 'v'
})

local item_cache = setmetatable({}, {__mode = 'v'})
local block_map = setmetatable({}, {__mode = 'v'})
local last_block

get_item = function(id, language)
    local key = id .. ':' .. language
    local item = item_cache[key]
    if item == nil then
        local dat_info = lookup_info(id)
        if dat_info == nil then
            return nil
        end

        local ctype_ptr = dat_info.ctype_ptr
        if ctype_ptr == nil then
            ctype_ptr = ffi_typeof(dat_info.type.name .. '*')
            dat_info.ctype_ptr = ctype_ptr
        end

        local block_id = bor(lshift(dat_info[language], 10), rshift(id - dat_info.base, 6))
        local block = data_blocks[block_id]
        item = ffi_cast(ctype_ptr, block)[band(id - dat_info.base, 0x3F)]

        item_cache[key] = item
        block_map[item] = block
        last_block = block
    end
    return item
end

local string_entry = function(item, i)
    if item.strings.count >= 0x40 or i >= item.strings.count then
        return nil
    end

    local offset = item.strings.entries[i].offset
    if offset >= 0x270 then
        return nil
    end

    local base_ptr = ffi_cast(raw_data_ptr, item) + ffi.offsetof(item, 'strings')
    local type = item.strings.entries[i].type
    if type == 0 then
        return (from_shift_jis(ffi_string(base_ptr + offset + 0x1C)))
    elseif type == 1 then
        return ffi_cast(uint32_ptr, base_ptr + offset)[0]
    end

    return nil
end

return {get_item = get_item, string_entry = string_entry}
