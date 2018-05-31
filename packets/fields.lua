local ffi = require('ffi')
require('string')

local fields = {
    incoming = {},
    outgoing = {},
}

--[[ Type functions. All these functions should have return a function that can ]]

local struct
local make_type
local copy_type = function(base)
    local new = make_type(base.cdef)

    for key, value in pairs(base) do
        new[key] = value
    end

    return new
end

do
    local make_cdef = function(arranged)
        local cdefs = {}
        local index = 0x00
        local unknown_count = 1
        for _, field in ipairs(arranged) do
            local diff = field.position - index
            if diff > 0 then
                cdefs[#cdefs + 1] = ('char _unknown%u[%u]'):format(unknown_count, diff)
                unknown_count = unknown_count + 1
            end
            index = index + diff

            local cdef
            if field.type.count then
                cdef = ('%s %s[%u]'):format(field.type.cdef, field.label, field.type.count)
            else
                cdef = ('%s %s'):format(field.type.cdef, field.label)
            end

            cdefs[#cdefs + 1] = cdef
            index = index + field.type.size
        end

        print(('struct {%s;}'):format(table.concat(cdefs, ';')))
        return ('struct {%s;}'):format(table.concat(cdefs, ';'))
    end

    local key_map = {
        [1] = 'position',
        [2] = 'type',
    }

    local type_mt = {
        __index = function(base, count)
            if type(count) ~= 'number' then
                return nil
            end

            local new = copy_type(base)
            new.count = count
            new.size = count * base.size

            return new
        end,
    }

    make_type = function(cdef)
        return setmetatable({
            cdef = cdef,
            size = ffi.sizeof(cdef),
        }, type_mt)
    end

    local keywords = {
        ['auto'] = true,
        ['break'] = true,
        ['case'] = true,
        ['char'] = true,
        ['complex'] = true,
        ['const'] = true,
        ['continue'] = true,
        ['default'] = true,
        ['do'] = true,
        ['double'] = true,
        ['else'] = true,
        ['enum'] = true,
        ['extern'] = true,
        ['float'] = true,
        ['for'] = true,
        ['goto'] = true,
        ['if'] = true,
        ['int'] = true,
        ['long'] = true,
        ['register'] = true,
        ['return'] = true,
        ['short'] = true,
        ['signed'] = true,
        ['sizeof'] = true,
        ['static'] = true,
        ['struct'] = true,
        ['switch'] = true,
        ['typedef'] = true,
        ['union'] = true,
        ['unsigned'] = true,
        ['void'] = true,
        ['volatile'] = true,
        ['while'] = true,
    }

    struct = function(fields)
        local arranged = {}
        for label, data in pairs(fields) do
            data.keyword = keywords[label] ~= nil
            local full = {
                label = data.keyword and ('_%s'):format(label) or label,
            }

            for key, value in pairs(data) do
                full[key_map[key] or key] = value
            end

            arranged[#arranged + 1] = full
        end

        table.sort(arranged, function(field1, field2)
            return field1.position < field2.position
        end)

        local new = copy_type({cdef = make_cdef(arranged)})
        new.fields = fields

        return new
    end
end

local uint8 = make_type('uint8_t')
local uint16 = make_type('uint16_t')
local uint32 = make_type('uint32_t')
local uint64 = make_type('uint64_t')
local int8 = make_type('int8_t')
local int16 = make_type('int16_t')
local int32 = make_type('int32_t')
local int64 = make_type('int64_t')
local float = make_type('float')
local double = make_type('double')
local bool = make_type('bool')

local string
do
    string_types = {}

    string = function(length)
        if not string_types[length] then
            local new = copy_type({cdef = 'char'})[length]

            new.tolua = function(raw)
                local index = raw:find('\0')
                return index and raw:sub(0, index - 1) or raw
            end

            new.toc = function(str)
                return #str >= length and str:sub(0, length) or str .. ('\0'):rep(length - #str)
            end

            string_types[length] = new
        end

        return string_types[length]
    end
end

local tag = function(base, tag)
    local new = copy_type(base)
    new.tag = tag
    return new
end
local entity = tag(uint32, 'entity')
local entity_index = tag(uint16, 'entity_index')
local zone = tag(uint16, 'zone')
local weather = tag(uint8, 'weather')
local status = tag(uint8, 'status')
local job = tag(uint8, 'job')
local race = tag(uint8, 'race')
local model = tag(uint16, 'model')
local percent_char = tag(uint8, 'percent')
local time = tag(uint32, 'time')
local bag = tag(uint8, 'bag')
local slot = tag(uint8, 'slot')

local pc_name = string(16)

local vitals = struct {
    str = {0x00, int16},
    dex = {0x02, int16},
    vit = {0x04, int16},
    agi = {0x06, int16},
    int = {0x08, int16},
    mnd = {0x0A, int16},
    chr = {0x0C, int16},
}

-- Zone update
fields.incoming[0x00A] = struct {
    player_id           = {0x04, entity},
    player_index        = {0x08, entity_index},
    heading             = {0x0B, uint8},
    x                   = {0x0C, float},
    y                   = {0x10, float},
    z                   = {0x14, float},
    run_count           = {0x18, uint16},
    target_index        = {0x1A, entity_index},
    movement_speed      = {0x1C, uint8},
    animation_speed     = {0x1D, uint8},
    hp_percent          = {0x1E, percent_char},
    status              = {0x1F, status},
    zone                = {0x30, zone},
    timestamp_1         = {0x38, time},
    timestamp_2         = {0x3C, time},
    _dupe_zone          = {0x42, zone},
    face                = {0x44, uint8},
    race                = {0x45, race},
    head                = {0x46, model},
    body                = {0x48, model},
    hands               = {0x4A, model},
    legs                = {0x4C, model},
    feet                = {0x4E, model},
    main                = {0x50, model},
    sub                 = {0x52, model},
    ranged              = {0x54, model},
    day_music           = {0x56, uint16},
    night_music         = {0x58, uint16},
    solo_combat_music   = {0x5A, uint16},
    party_combat_music  = {0x5C, uint16},
    menu_zone           = {0x62, uint16},
    menu_id             = {0x64, uint16},
    weather             = {0x68, weather},
    player_name         = {0x84, pc_name},
    abyssea_timestamp   = {0xA0, time},
    zone_model          = {0xAA, uint16},
    main_job            = {0xB4, job},
    sub_job             = {0xB7, job},
    job_levels          = {0xBC, job[0x10], lookup='jobs'},
    vitals              = {0xCC, vitals},
    vitals_bonus        = {0xDA, vitals},
    max_hp              = {0xE8, uint32},
    max_mp              = {0xEC, uint32},
}

-- Equipment
fields.incoming[0x050] = struct {
    inventory_index     = {0x04, uint8},
    slot_id             = {0x05, slot},
    bag_id              = {0x06, bag},
}

return fields
