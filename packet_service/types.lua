local math = require('math')
local struct = require('struct')

local bit_get
local bit_set
do
    local floor = math.floor

    bit_get = function(cdata, bit, length)
        local first = floor(bit / 8)
        local last = floor((bit + length - 1) / 8)

        local acc = 0
        local step = 0
        for i = first, last do
            acc = acc + 0x100 ^ step * cdata[i]
            step = step + 1
        end

        return floor(acc / 2 ^ (bit % 8)) % 2 ^ length
    end

    bit_set = function(cdata, bit, length, value)
        local first = floor(bit / 8)
        local last = floor((bit + length - 1) / 8)

        local low_mask = 2 ^ (bit % 8)
        local high_mask = 2 ^ ((bit + length - 1) % 8)

        local shifted = value * low_mask

        local step = 0
        for i = first, last do
            local current = cdata[i]
            local prefix = i == first and current % low_mask or 0
            local suffix = i == last and floor(current / high_mask) * high_mask or 0
            cdata[i] = prefix + floor(shifted / 0x100 ^ step) % 0x100 + suffix
            step = step + 1
        end
    end
end

local tag = struct.tag
local string = struct.string
local data = struct.data
local packed_string = struct.packed_string

local int8 = struct.int8
local int16 = struct.int16
local int32 = struct.int32
local int64 = struct.int64
local uint8 = struct.uint8
local uint16 = struct.uint16
local uint32 = struct.uint32
local uint64 = struct.uint64
local float = struct.float
local double = struct.double
local bool = struct.bool

local bit = struct.bit
local boolbit = struct.boolbit
local bitfield = struct.bitfield

local time = struct.time

local struct = function(info, fields)
    info, fields = fields and info or {}, fields or info

    for _, field in pairs(fields) do
        local ftype = field[2]
        if ftype and ftype.count == '*' then
            info.size = 0x100
        end
    end

    return struct.struct(info, fields)
end

local multiple
do
    local update = function(base, update)
        for key, value in pairs(update) do
            base[key] = value
        end
        return base
    end

    multiple = function(ftype)
        local types = {}
        local base_info = {
            cache = { ftype.key },
        }
        local base_fields = ftype.base.fields
        for index, definitions in pairs(ftype.lookups) do
            types[index] = struct(update({}, base_info), update(update({}, base_fields), definitions.fields))
        end

        base_info.empty = true
        base_info.key = ftype.key
        ftype.info = { cache = base_info.cache }
        ftype.base = struct(base_info, base_fields)
        ftype.lookups = nil

        ftype.types = types

        return ftype
    end
end

local entity = tag(uint32, 'entity')
local entity_index = tag(uint16, 'entity_index')
local zone = tag(uint16, 'zones')
local weather = tag(uint8, 'weather')
local state = tag(uint8, 'statuses')
local job = tag(uint8, 'jobs')
local race = tag(uint8, 'races')
local percent = tag(uint8, 'percent')
local bag = tag(uint8, 'bags')
local slot = tag(uint8, 'slots')
local item = tag(uint16, 'items')
local item_status = tag(uint8, 'item_status')
local flags = tag(uint32, 'flags')
local title = tag(uint16, 'titles')
local nation = tag(uint8, 'nation') -- 0 sandy, 1 bastok, 2 windy
local status_effect = tag(uint8, 'buffs')
local skill = tag(uint8, 'skills')
local indi = tag(uint8, 'indi')
local ip = tag(uint32, 'ip')
local chat = tag(uint8, 'chat')
local ability_recast = tag(uint8, 'ability_recasts')
local action_message = tag(uint16, 'action_messages')
local roe_quest = tag(bit(uint32, 12), 'roe_quest')

local pc_name = string(0x10)
local fourcc = string(0x04)

local ls_name = packed_string(0x0F, '`abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')
-- local item_inscription = packed_string(0x0C, '\x000123456798ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{')

local stats = struct({
    str                 = {0x00, int16},
    dex                 = {0x02, int16},
    vit                 = {0x04, int16},
    agi                 = {0x06, int16},
    int                 = {0x08, int16},
    mnd                 = {0x0A, int16},
    chr                 = {0x0C, int16},
})

local model = struct({
    head_model_id       = {0x00, uint16},
    body_model_id       = {0x02, uint16},
    hands_model_id      = {0x04, uint16},
    legs_model_id       = {0x06, uint16},
    feet_model_id       = {0x08, uint16},
    main_model_id       = {0x0A, uint16},
    sub_model_id        = {0x0C, uint16},
    range_model_id      = {0x0E, uint16},
})

local resistances = struct({
    fire                = {0x0, uint16},
    wind                = {0x2, uint16},
    lightning           = {0x4, uint16},
    light               = {0x6, uint16},
    ice                 = {0x8, uint16},
    earth               = {0xA, uint16},
    water               = {0xC, uint16},
    dark                = {0xE, uint16},
})

local combat_skill = struct({
    level               = {0x00, bit(uint16, 15), offset=0},
    capped              = {0x00, boolbit(uint16), offset=15},
})

local crafting_skill = struct({
    level               = {0x00, bit(uint16, 5), offset=0},
    rank_id             = {0x00, bit(uint16, 10), offset=5},
    capped              = {0x00, boolbit(uint16), offset=15},
})

local party_status_effects = struct({
    id                  = {0x00, entity},
    index               = {0x04, entity_index},
    status_effect_mask  = {0x08, data(8)},
    status_effects      = {0x10, status_effect[0x20]},
})

local rmap_region_info = struct({
    influence_ranking   = {0x00, uint8},
    influence_ranking_no_beastmen   = {0x01, uint8},
    beastmen_ranking    = {0x02, bit(uint8,2), offset=0},
    windurst_ranking    = {0x02, bit(uint8,2), offset=2},
    bastok_ranking      = {0x02, bit(uint8,2), offset=4},
    sandoria_ranking    = {0x02, bit(uint8,2), offset=6},
    ownership           = {0x03, uint8}, -- 0: Neutral, 1: San'doria, 2: Bastok, 3: Windurst, 0xFF: Jeuno
})

local bmap_region_info = struct({
-- Beastman Status
    -- 0 = Training
    -- 1 = Advancing
    -- 2 = Attacking
    -- 3 = Retreating
    -- 4 = Defending
    -- 5 = Preparing
    status              = {0x00, bit(uint32, 3), offset=0},
    number_of_forces    = {0x00, bit(uint32, 8), offset=3},
    level               = {0x00, bit(uint32, 4), offset=11},
    number_of_mirrors   = {0x00, bit(uint32, 4), offset=15},
    number_of_prisoners = {0x00, bit(uint32, 4), offset=19},
    -- No clear purpose for the remaining 9 bits
})

local roe_quest_entry = struct({
    roe_quest_id        = {0x00, roe_quest},
    roe_quest_progress  = {0x00, bit(uint32, 20), offset=12},
})

local guild_entry = struct({
    item                = {0x00, item},
    current_stock       = {0x02, uint8},
    max_stock           = {0x03, uint8},
    price               = {0x04, uint32},
})

local unity = struct({
    -- 0=None, 1=Pieuje, 2=Ayame, 3=Invincible Shield, 4=Apururu, 5=Maat, 6=Aldo, 7=Jakoh Wahcondalo, 8=Naja Salaheem, 9=Flavira
    id                  = {0x00, bit(uint32, 5), offset=0},
    points              = {0x00, bit(uint32, 16), offset=10},
})

local alliance_member = struct({
    player_id           = {0x00, entity},
    player_index        = {0x04, entity_index},
    flags               = {0x06, uint16},
    zone_id             = {0x08, zone},
    -- 0x0A~0x0B: Always 0?
})

local check_item = struct({
    item                = {0x00, item},
    slot_id             = {0x02, slot},
    extdata             = {0x04, data(0x18)},
})

local shop_item = struct({
    price               = {0x00, uint32},
    item_id             = {0x04, item},
    shop_slot           = {0x06, uint16},
    craft_skill         = {0x08, skill}, -- Zero on normal shops, has values that correlate to res\skills.
    craft_rank          = {0x0A, uint16}, -- Correlates to Rank able to purchase product from GuildNPC
})

local merit_entry = struct({
    merit_id            = {0x00, uint16},
    next_cost           = {0x02, uint8},
    value               = {0x03, uint8},
})

local job_point_entry = struct({
    job_point_id        = {0x00, uint16},
    _known1             = {0x02, bit(uint16,10), offset=0},
    value               = {0x02, bit(uint16, 6), offset=10},
})

local job_point_info = struct({
    capacity_points     = {0x00, uint16},
    job_points          = {0x02, uint16},
    job_points_spent    = {0x04, uint16},
})

local blacklist_entry = struct({
    player_id           = {0x00, entity},
    player_name         = {0x04, pc_name},
})

local equipset_build = struct({
    active              = {0x00, boolbit(uint8), offset=0},
    bag_id              = {0x00, bit(bag, 6), offset=2},
    bag_index           = {0x01, uint8},
    item_id             = {0x02, item},
})

local equipset_entry = struct({size = 4}, {
    bag_index           = {0x00, uint8},
    slot_id             = {0x01, slot},
    bag_id              = {0x02, bag},
})

local ability_recast = struct({
    duration            = {0x00, uint16},
    _known1             = {0x02, uint8, const=0},
    recast              = {0x03, ability_recast},
})

local lockstyle_entry = struct({size = 8}, {
    bag_index           = {0x00, uint8},
    slot_id             = {0x01, slot},
    bag_id              = {0x02, bag},
    item_id             = {0x04, item},
})

local types = {
    incoming = {},
    outgoing = {},
}

types.incoming[0x009] = struct({
    target_id           = {0x00, entity},
    target_index        = {0x04, entity_index},
    message_id          = {0x06, uint16},
})

-- Zone update
types.incoming[0x00A] = struct({
    player_id           = {0x00, entity},
    player_index        = {0x04, entity_index},
    heading             = {0x07, uint8},
    x                   = {0x08, float},
    z                   = {0x0C, float},
    y                   = {0x10, float},
    run_count           = {0x14, uint16},
    target_index        = {0x16, entity_index},
    movement_speed      = {0x18, uint8},
    animation_speed     = {0x19, uint8},
    hp_percent          = {0x1A, percent},
    state_id            = {0x1B, state},
    zone_id             = {0x2C, zone},
    timestamp_1         = {0x34, time()},
    timestamp_2         = {0x38, time()},
    _dupe_zone          = {0x3E, zone},
    face_model_id       = {0x40, uint8},
    race_id             = {0x41, race},
    model               = {0x42, model},
    day_music           = {0x52, uint16},
    night_music         = {0x54, uint16},
    solo_combat_music   = {0x56, uint16},
    party_combat_music  = {0x58, uint16},
    mount_music         = {0x5A, uint16},
    menu_zone           = {0x5E, uint16},
    menu_id             = {0x60, uint16},
    weather_id          = {0x64, weather},
    flags               = {0x7C, struct({size = 0x04}, {
        mog_house           = {0x01, boolbit(uint8), offset=1},
    })},
    player_name         = {0x80, pc_name},
    abyssea_timestamp   = {0x9C, time()},
    zone_model          = {0xA6, uint16},
    main_job_id         = {0xB0, job},
    sub_job_id          = {0xB3, job},
    job_levels          = {0xB8, uint8[0x10], key_lookup='jobs'},
    stats_base          = {0xC8, stats},
    stats_bonus         = {0xD6, stats},
    hp_max              = {0xE4, uint32},
    mp_max              = {0xE8, uint32},
})

-- Zone Response
types.incoming[0x00B] = struct({cache = {'type'}}, {
    type                = {0x00, uint8},
    ip                  = {0x04, ip},
    port                = {0x08, uint16},
})

-- PC Update
    -- The flags in this byte are complicated and may not strictly be flags.
    -- Byte 0x20: -- Mentor is somewhere in this byte
    -- 01 = None
    -- 02 = Deletes everyone
    -- 04 = Deletes everyone
    -- 08 = None
    -- 16 = None
    -- 32 = None
    -- 64 = None
    -- 128 = None


    -- Byte 0x21:
    -- 01 = None
    -- 02 = None
    -- 04 = None
    -- 08 = LFG
    -- 16 = Anon
    -- 32 = Turns your name orange
    -- 64 = Away
    -- 128 = None

    -- Byte 0x22:
    -- 01 = POL Icon, can target?
    -- 02 = no notable effect
    -- 04 = DCing
    -- 08 = Untargettable
    -- 16 = No linkshell
    -- 32 = No Linkshell again
    -- 64 = No linkshell again
    -- 128 = No linkshell again

    -- Byte 0x23:
    -- 01 = Trial Account
    -- 02 = Trial Account
    -- 04 = GM Mode
    -- 08 = None
    -- 16 = None
    -- 32 = Invisible models
    -- 64 = None
    -- 128 = Bazaar

    -- Byte 0x36
    -- 0x20 = Ballista
types.incoming[0x00D] = struct({
    player_id           = {0x00, entity},
    player_index        = {0x04, entity_index},
    update_position     = {0x06, boolbit(uint8), offset=0}, -- Position, Rotation, Target, Speed
    update_status       = {0x06, boolbit(uint8), offset=1}, -- Not used for 0x00D
    update_vitals       = {0x06, boolbit(uint8), offset=2}, -- HP%, Status, Flags, LS color, "Face Flags"
    update_name         = {0x06, boolbit(uint8), offset=3}, -- Name
    update_model        = {0x06, boolbit(uint8), offset=4}, -- Race, Face, Gear models
    despawn             = {0x06, boolbit(uint8), offset=5}, -- Only set if player runs out of range or zones
    heading             = {0x07, uint8},
    x                   = {0x08, float},
    z                   = {0x0C, float},
    y                   = {0x10, float},
    run_count           = {0x14, bit(uint16, 13), offset=0},
    target_index        = {0x16, bit(entity_index, 15), offset=1},
    movement_speed      = {0x18, uint8}, -- 32 represents 100%
    animation_speed     = {0x19, uint8}, -- 32 represents 100%
    hp_percent          = {0x1A, percent},
    state_id            = {0x1B, state},
    flags               = {0x1C, flags},
    linkshell_red       = {0x20, uint8},
    linkshell_green     = {0x21, uint8},
    linkshell_blue      = {0x22, uint8},
    indi_bubble         = {0x3E, uint8},
    face_flags          = {0x3F, uint8}, -- 0, 3, 4 or 8
    face_model_id       = {0x44, uint8},
    race_id             = {0x45, race},
    model               = {0x46, model},
    name                = {0x56, string(0x10)},
})

-- NPC Update
-- There are two different types of these packets. One is for regular NPCs, the other occurs for certain NPCs (often nameless) and differs greatly in structure.
-- The common fields seem to be the ID, Index, mask and _unknown3.
-- The second one seems to have an int counter at 0x38 that increases by varying amounts every time byte 0x1F changes.
-- Currently I don't know how to algorithmically distinguish when the packets are different.

-- Mask values (from antiquity):
-- 0x01: "Basic"
-- 0x02: Status
-- 0x04: HP
-- 0x08: Name
-- 0x10: "Bit 4"
-- 0x20: "Bit 5"
-- 0x40: "Bit 6"
-- 0x80: "Bit 7"

-- Status flags (from antiquity):
-- 0b00100000 = CFH Bit
-- 0b10000101 = "Normal_Status?"
types.incoming[0x00E] = struct({
    npc_id              = {0x00, entity},
    npc_index           = {0x04, entity_index},
    update_position     = {0x06, boolbit(uint8), offset=0}, -- Position, Rotation, Walk Count
    update_status       = {0x06, boolbit(uint8), offset=1}, -- Claimer ID
    update_vitals       = {0x06, boolbit(uint8), offset=2}, -- HP%, Status, Flags
    update_name         = {0x06, boolbit(uint8), offset=3}, -- Name
    update_model        = {0x06, boolbit(uint8), offset=4}, -- Race, Face, Gear models
    despawn             = {0x06, boolbit(uint8), offset=5}, -- Only set if player runs out of range or zones
    heading             = {0x07, uint8},
    x                   = {0x08, float},
    z                   = {0x0C, float},
    y                   = {0x10, float},
    run_count           = {0x14, bit(uint16, 13), offset=0},
    -- target index?
    hp_percent          = {0x1A, percent},
    state_id            = {0x1B, state},
    flags               = {0x1C, flags},
    claimer_id          = {0x28, entity},
    model_id            = {0x2E, uint16},
    name                = {0x30, string()},
})

-- Incoming Chat
types.incoming[0x017] = struct({
    chat                = {0x00, chat},
    gm                  = {0x01, boolbit(uint8), offset=0},
    formatted           = {0x01, boolbit(uint8), offset=3},
    zone                = {0x02, zone},
    name                = {0x04, pc_name},
    message             = {0x14, string()},
})

-- Job Info
types.incoming[0x01B] = struct({
    race_id             = {0x00, race},
    main_job_id         = {0x04, job},
    -- 0x05~0x06 were 0x0101 for me
    sub_job_id          = {0x07, job},
    sub_job_unlocked    = {0x08, boolbit(uint32)},
    sub_jobs_unlocked   = {0x08, bit(uint32, 0x16), offset=1}, -- flags field
    job_levels_pre_toau = {0x0C, uint8[0x10], key_lookup='jobs'},
    stats_base          = {0x1C, stats}, -- Altering these stat values has no impact on your equipment menu.
    hp_max              = {0x38, uint32},
    mp_max              = {0x3C, uint32},
    job_levels          = {0x44, uint8[0x18], key_lookup='jobs'},
    monster_level       = {0x5B, uint8},
    encumbrance_flags   = {0x5C, uint32}, -- [legs, hands, body, head, ammo, range, sub, main,] [back, right_ring, left_ring, right_ear, left_ear, waist, neck, feet] [HP, CHR, MND, INT, AGI, VIT, DEX, STR,] [X X X X X X X MP]
})

-- Inventory Count
-- It is unclear why there are two representations of the size for this.
-- I have manipulated my inventory size on a mule after the item update packets have
-- all arrived and still did not see any change in the second set of sizes, so they
-- may not be max size/used size chars as I initially assumed. Adding them as shorts
-- for now.
-- There appears to be space for another 8 bags.
types.incoming[0x01C] = struct({
    size                = {0x00, uint8[13], key_lookup='bags'},
    -- These "dupe" sizes are set to 0 if the inventory disabled.
    -- storage: The accumulated storage from all items (uncapped) -1
    -- wardrobe 3/4: This is not set to 0 despite being disabled for whatever reason
    other_size          = {0x10, uint16[13], key_lookup='bags'},
})

-- Finish Inventory
types.incoming[0x01D] = struct({
    _known1             = {0x00, uint8, const=0x01},
})

-- Modify Inventory
types.incoming[0x01E] = struct({cache = {'bag_id', 'bag_index'}}, {
    count               = {0x00, uint32},
    bag_id              = {0x04, bag},
    bag_index           = {0x05, uint8},
    status              = {0x06, item_status},
})

-- Item Assign
types.incoming[0x01F] = struct({cache = {'bag_id', 'bag_index'}}, {
    count               = {0x00, uint32},
    item_id             = {0x04, item},
    bag_id              = {0x06, bag},
    bag_index           = {0x07, uint8},
    status              = {0x08, item_status},
})

-- Item Updates
types.incoming[0x020] = struct({cache = {'bag_id', 'bag_index'}}, {
    count               = {0x00, uint32},
    bazaar              = {0x04, uint32},
    item_id             = {0x08, item},
    bag_id              = {0x0A, bag},
    bag_index           = {0x0B, uint8},
    status              = {0x0C, item_status},
    extdata             = {0x0D, data(24)},
})

-- Trade request received
types.incoming[0x021] = struct({
    player_id           = {0x00, entity},
    player_index        = {0x04, entity_index},
})

-- Trade request sent
types.incoming[0x022] = struct({
    player_id           = {0x00, entity},
-- phase enum:
--  0 == 'Trade started'
--  1 == 'Trade canceled'
--  2 == 'Trade accepted by other party'
--  9 == 'Trade successful'
    phase               = {0x04, uint32},
    player_index        = {0x08, entity_index},
})

-- Trade item, other party
types.incoming[0x023] = struct({
    count               = {0x00, uint32},
    trade_count         = {0x04, uint16}, -- Seems to increment every time packet 0x023 comes in, i.e. every trade action performed by the other party
    item_id             = {0x06, item}, -- If the item is removed, gil is used with a count of zero
    _known1             = {0x08, uint8, const=0x05},
    trade_slot          = {0x09, uint8}, -- Gil itself is in slot 0, whereas the other slots start at 1 and count up horizontally
    extdata             = {0x0A, data(24)},
})

-- Trade item, self
types.incoming[0x025] = struct({
    count               = {0x00, uint32},
    item_id             = {0x04, item}, -- If the item is removed, gil is used with a count of zero
    trade_slot          = {0x06, uint8}, -- Gil itself is in slot 0, whereas the other slots start at 1 and count up horizontally
    bag_index           = {0x07, uint8},
})

-- Count to 80
-- Sent after Item Update chunks for active inventory (sometimes) when zoning.
-- #BYRTH# come back to this at some point because I think this is missing something.
types.incoming[0x026] = struct({
    _known1             = {0x00, uint8, const=0x00},
    bag_index           = {0x01, uint8},
    _known2             = {0x02, data(22), const=0x00},
})

-- String Message
types.incoming[0x027] = struct({
    player_id           = {0x00, entity}, -- 0x0112413A in Omen, 0x010B7083 in Legion, Layer Reserve ID for Ambuscade queue, 0x01046062 for Chocobo circuit
    player_index        = {0x04, entity_index}, -- 0x013A in Omen, 0x0083 in Legion , Layer Reserve Index for Ambuscade queue, 0x0062 for Chocobo circuit
    message_id          = {0x06, bit(uint16, 15), offset=0},
    type                = {0x08, uint32}, -- 0x04 for Fishing/Salvage, 0x05 for Omen/Legion/Ambuscade queue/Chocobo Circuit
    param_1             = {0x0C, uint32}, -- Parameter 0 on the display messages dat files
    param_2             = {0x10, uint32}, -- Parameter 1 on the display messages dat files
    param_3             = {0x14, uint32}, -- Parameter 2 on the display messages dat files
    param_4             = {0x18, uint32}, -- Parameter 3 on the display messages dat files
    name                = {0x1C, pc_name},
    name_other          = {0x3C, pc_name},
})

types.incoming[0x028] = struct({
    size                = {0x00, uint8},
    _payload            = {0x01, uint8[0xFF]},
    actor               = {
        get = function(p) return bit_get(p._payload,  0, 32) end,
        set = function(p, value) bit_set(p._payload,  0, 32, value) end,
    },
    target_count        = {
        get = function(p) return bit_get(p._payload, 32, 10) end,
        set = function(p, value) bit_set(p._payload, 32, 10, value) end,
    },
    category            = {
        get = function(p) return bit_get(p._payload, 42,  4) end,
        set = function(p, value) bit_set(p._payload, 42,  4, value) end,
    },
    param               = {
        get = function(p) return bit_get(p._payload, 46, 16) end,
        set = function(p, value) bit_set(p._payload, 46, 16, value) end,
    },
    recast              = {
        get = function(p) return bit_get(p._payload, 78, 32) end,
        set = function(p, value) bit_set(p._payload, 78, 32, value) end,
    },
    targets             = {
        get = function(p)
            local payload = p._payload
            local current = 110

            local get = function(length)
                local value = bit_get(payload, current, length)
                current = current + length
                return value
            end

            local skip = function(length)
                current = current + length
            end

            local targets = {}
            for i = 1, p.target_count do
                local id = get(32)
                local action_count = get(4)
                local actions = {}

                for j = 1, action_count do
                    local reaction = get(5)
                    local animation = get(11)
                    local effect = get(5)
                    local stagger = get(6)
                    local param = get(17)
                    local message = get(10)

                    skip(31) -- Message Modifier? If you get a complete (Resist!) this is set to 2 otherwise a regular Resist is 0.

                    local has_add_effect = get(1) == 1
                    local add_effect
                    if has_add_effect then
                        add_effect = {
                            animation = get(6),
                            effect = get(4),
                            param = get(17),
                            message = get(10),
                        }
                    end

                    local has_spike_effect = get(1) == 1
                    local spike_effect
                    if has_spike_effect then
                        spike_effect = {
                            animation = get(6),
                            effect = get(4),
                            param = get(14),
                            message = get(10),
                        }
                    end

                    actions[j] = {
                        reaction = reaction,
                        animation = animation,
                        effect = effect,
                        stagger = stagger,
                        param = param,
                        message = message,
                        has_add_effect = has_add_effect,
                        add_effect = add_effect,
                        has_spike_effect = has_spike_effect,
                        spike_effect = spike_effect,
                    }
                end

                targets[i] = {
                    id = id,
                    action_count = action_count,
                    actions = actions,
                }
            end
            return targets
        end,
        set = function(p)
            error('todo...')
        end,
    },
})

-- Action Message
types.incoming[0x029] = struct({
    actor_id            = {0x00, entity},
    target_id           = {0x04, entity},
    param_1             = {0x08, uint32},
    param_2             = {0x0C, uint32},
    actor_index         = {0x10, entity_index},
    target_index        = {0x12, entity_index},
    message_id          = {0x14, action_message},
})

--[[ 0x2A can be triggered by knealing in the right areas while in the possession of a VWNM KI:
    Field1 will be lights level:
    0 = 'Tier 1', -- faintly/feebly depending on whether it's outside of inside Abyssea
    1 = 'Tier 2', -- softly
    2 = 'Tier 3', -- solidly. Highest Tier in Abyssea
    3 = 'Tier 4', --- strongly
    4 = 'Tier 5', -- very strongly.  Unused currently
    5 = 'Tier 6', --- furiously.  Unused currently
    - But if there are no mobs left in area, or no mobs nearby, field1 will be the KeyItem#
    1253 = 'Clear Abyssite'
    1254 = 'Colorful Abyssite'
    1564 = 'Clear Demilune Abyssite'
    etc.

    Field2 will be direction:
    0 = 'East'
    1 = 'Southeast'
    2 = 'South'
    3 = 'Southwest'
    4 = 'West'
    5 = 'Northwest'
    6 = 'North'
    7 = 'Northeast'

    Field3 will be distance. When there are no mobs, this value is set to 300000

    Field4 will be KI# of the abyssite used. Ex:
    1253 = 'Clear Abyssite'
    1254 = 'Colorful Abyssite'
    1564 = 'Clear Demilune Abyssite'
    etc.
]]

--[[  0x2A can also be triggered by buying/disposing of a VWNM KI from an NPC:
      Index/ID field will be those of the NPC
      Field1 will be 1000 (gil) when acquiring in Jueno, 300 (cruor) when acquiring in Abyssea
      Field2 will be the KI# acquired
      Fields are used slighly different when dropping the KI using the NPC.
]]

--[[  0x2A can also be triggered by spending cruor by buying non-vwnm related items, or even activating/using Flux
      Field1 will be the amount of cruor spent
]]


--[[ 0x2A can also be triggered by zoning into Abyssea:
     Field1 will be set to your remaining time. 5 at first, then whatever new value when acquiring visiting status.
     0x2A will likely be triggered as well when extending your time limit. Needs verification.
]]


--[[ 0x2A can be triggered sometimes when zoning into non-Abyssea:
     Not sure what it means.
]]

-- Resting Message
types.incoming[0x02A] = struct({
    player_id           = {0x00, entity},
    param_1             = {0x04, uint32},
    param_2             = {0x08, uint32},
    param_3             = {0x0C, uint32},
    param_4             = {0x10, uint32},
    player_index        = {0x14, entity_index},
    message_id          = {0x16, bit(uint16,15), offset=0}, -- The high bit is occasionally set, though the reason for it is unclear.
    -- 0x18   Possibly flags, 0x06000000 and 0x02000000 observed
})

-- Kill Message
-- Updates EXP gained, RoE messages, Limit Points, and Capacity Points
types.incoming[0x02D] = struct({
    player_id           = {0x00, entity},
    target_id           = {0x04, entity}, -- Player ID in the case of RoE log updates
    player_index        = {0x08, entity_index},
    target_index        = {0x0A, entity_index}, -- Player Index in the case of RoE log updates
    param_1             = {0x0C, uint32},
    param_2             = {0x10, uint32},
    message_id          = {0x14, uint16},
})

-- Mog House Menu
types.incoming[0x02E] = struct({}) -- Seems to contain no fields. Just needs to be sent to client to open.

-- Digging Animation
types.incoming[0x02F] = struct({
    player_id           = {0x00, entity},
    player_index        = {0x04, entity_index},
    animation           = {0x06, uint8}, -- Changing it to anything other than 1 eliminates the animation
    -- Packet is likely padded with junk. Setting it has no effect on anything notable.
})

-- Synth Animation
-- #BYRTH# investigate why these fields are named what they are.
types.incoming[0x030] = struct({
    player_id           = {0x00, entity},
    player_index        = {0x04, entity_index},
    effect              = {0x06, uint16}, -- 10 00 is water, 11 00 is wind, 12 00 is fire, 13 00 is earth, 14 00 is lightning, 15 00 is ice, 16 00 is light, 17 00 is dark
    param               = {0x08, uint8}, -- 00 is NQ, 01 is break, 02 is HQ
    animation           = {0x09, uint8}, -- Always C2 for me.
    -- Packet is likely padded with junk
})

-- #BYRTH# needs more investigation
-- Synth List / Synth Recipe
--[[ This packet is used for list of recipes, but also for details of a specific recipe.

   If you ask the guild NPC that provides regular Image Suppor for recipes,
   s/he will give you a list of recipes, fields are as follows:
   Field1-2: NPC ID
   Field3: NPC Index
   Field4-6: Unknown
   Field7-22: Item ID of recipe
   Field23: Unknown
   Field24: Usually Item ID of the recipe on next page


   If you ask a guild NPC for a specific recipe, fields are as follows:
   field1: item to make (item id)
   field2,3,4: sub-crafts needed. Note that main craft will not be listed.
      1 = woodworking
      2 = smithing
      3 = goldsmithing
      4 = clothcraft
      5 = leatherworking
      6 = bonecraft
      7 = Alchemy
      8 = Cooking
   field5: crystal (item id)
   field6: KeyItem needed, if any (in Big Endian)
   field7-14: material required (item id)
   field15-22: qty for each material above.
   field23-24: Unknown
 ]]
--fields.incoming[0x031] = L{
--    {ctype='unsigned short[24]',    label='Field'},                             -- 04
--}

-- NPC Interaction Type 1
-- #BYRTH# other_zone_id should be a short, but it is only a char. Why?
types.incoming[0x032] = struct({
    npc                 = {0x00, entity},
    npc_index           = {0x04, entity_index},
    zone_id             = {0x06, zone},
    menu_id             = {0x08, uint16}, -- Seems to select between menus within a zone
    _known1             = {0x0A, uint16, const=0x00},
    other_zone_id       = {0x0C, uint8},
    _known2             = {0x0D, data(3)},
})

-- String NPC Interaction
types.incoming[0x033] = struct({
    npc                 = {0x00, entity},
    npc_index           = {0x04, entity_index},
    zone_id             = {0x06, zone},
    menu_id             = {0x08, uint16}, -- Seems to select between menus within a zone
    -- 0x0A is an unknown short with observed values 00 00 or 08 00
    name_1              = {0x0C, pc_name},
    name_2              = {0x1C, pc_name},
    name_3              = {0x2C, pc_name},
    name_4              = {0x3C, pc_name},
    params              = {0x4C, data(0x20)}, -- The way this information is interpreted varies by menu.
})

-- NPC Interaction Type 2
types.incoming[0x034] = struct({
    npc                 = {0x00, entity},
    params              = {0x04, data(0x20)},
    npc_index           = {0x24, entity_index},
    zone_id             = {0x26, zone},
    menu_id             = {0x28, uint16},
    -- 0x2A is usually 8 for pre-WotG menus, but often not for newer menus
    other_zone_id       = {0x2C, zone},
    _known1             = {0x2E, data(2), const=0},
})

--- When messages are fishing related, the player is the Actor.
--- For some areas, the most significant bit of the message ID is set sometimes.
-- NPC Chat
types.incoming[0x036] = struct({
    actor               = {0x00, entity},
    actor_index         = {0x04, entity_index},
    message_id          = {0x06, bit(uint16, 15), offset=0},
})

-- Player update
-- Buff IDs go can over 0xFF, but in the packet each buff only takes up one byte.
-- To address that there's a 8 byte bitmask starting at 0x4C where each 2 bits
-- represent how much to add to the value in the respective byte.

--[[Flags 0x28: The structure here looks similar to byte 0x33 of 0x00D, but left shifted by 1 bit
    -- 0x0001 -- Despawns your character
    -- 0x0002 -- Also despawns your character, and may trigger an outgoing packet to the server (which triggers an incoming 0x037 packet)
    -- 0x0004 -- No obvious effect
    -- 0x0008 -- No obvious effect
    -- 0x0010 -- LFG flag
    -- 0x0020 -- /anon flag - blue name
    -- 0x0040 -- orange name?
    -- 0x0080 -- Away flag
    -- 0x0100 -- No obvious effect
    -- 0x0200 -- No obvious effect
    -- 0x0400 -- No obvious effect
    -- 0x0800 -- No obvious effect
    -- 0x1000 -- No obvious effect
    -- 0x2000 -- No obvious effect
    -- 0x4000 -- No obvious effect
    -- 0x8000 -- No obvious effect

    Flags 0x2B:
    -- 0x01 -- POL Icon :: Actually a flag, overrides everything else but does not affect name color
    -- 0x02 -- No obvious effect
    -- 0x04 -- Disconnection icon :: Actually a flag, overrides everything but POL Icon
    -- 0x08 -- No linkshell
    -- 0x0A -- No obvious effect

    -- 0x10 -- No linkshell
    -- 0x20 -- Trial account icon
    -- 0x40 -- Trial account icon
    -- 0x60 -- POL Icon (lets you walk through NPCs/PCs)
    -- 0x80 -- GM mode
    -- 0xA0 -- GM mode
    -- 0xC0 -- GM mode
    -- 0xE0 -- SGM mode
    -- No statuses differentiate based on 0x10
    -- Bit 0x20 + 0x40 makes 0x60, which is different.
    -- Bit 0x80 overpowers those bits
    -- Bit 0x80 combines with 0x04 and 0x02 to make SGM.
    -- These are basically flags, but they can be combined to mean different things sometimes.

    Flags 0x2D:
    -- 0x10 -- No obvious effect
    -- 0x20 -- Event mode? Can't activate the targeting cursor but can still spin the camera
    -- 0x40 -- No obvious effect
    -- 0x80 -- Invisible model

    Flags 0x2F:
    -- 0x02 -- No obvious effect
    -- 0x04 -- No obvious effect
    -- 0x08 -- No obvious effect
    -- 0x10 -- No obvious effect
    -- 0x20 -- Bazaar icon
    -- 0x40 -- Event status again? Can't activate the targeting cursor but can move the camera.
    -- 0x80 -- No obvious effects

    Flags 0x34:
    -- 0x01 -- No obvious effect
    -- 0x02 -- No obvious effect
    -- 0x04 -- Autoinvite icon

    Flags 0x36:
    -- 0x08 -- Terror flag
    -- 0x10 -- No obvious effect

    Ballista stuff:
    -- 0x0020 -- No obvious effect
    -- 0x0040 -- San d'Oria ballista flag
    -- 0x0060 -- Bastok ballista flag
    -- 0x0080 -- Windurst Ballista flag
    -- 0x0100 -- Participation icon?
    -- 0x0200 -- Has some effect
    -- 0x0400 -- I don't know anything about ballista
    -- 0x0800 -- and I still don't D:<
    -- 0x1000 -- and I still don't D:<

    Flags 0x37: Probably tried into ballista stuff too
    -- 0x0020 -- No obvious effect
    -- 0x0040 -- Individually, this bit has no effect. When combined with 0x20, it prevents you from returning to a walking animation after you stop (sliding along the ground while bound)
    -- 0x0080 -- No obvious effect
    -- 0x0100 -- No obvious effect
    -- 0x0200 -- Trial Account emblem
    -- 0x0400 -- No obvious effect
    -- 0x0800 -- Question mark icon
    -- 0x1000 -- Mentor icon

    Flags 0x5C:
    -- 0x00000001 -- Seems to indicate wardrobe 3
    -- 0x00000002 -- Seems to indicate wardrobe 4
]]
types.incoming[0x037] = struct({
    status_effects      = {0x00, status_effect[0x20]},
    player_id           = {0x20, entity},
    hp_percent          = {0x26, percent},
    movement_speed_half = {0x28, bit(uint16, 12), offset=0},
    yalms_per_step      = {0x2A, bit(uint16, 9), offset=0}, -- Determines how quickly your animation walks
    state_id            = {0x2C, state},
    linkshell1_red      = {0x2D, uint8},
    linkshell1_green    = {0x2E, uint8},
    linkshell1_blue     = {0x2F, uint8},
    pet_index           = {0x30, bit(uint32, 16), offset=3}, -- From 0x08 of byte 0x34 to 0x04 of byte 0x36
    ballista_stuff      = {0x30, bit(uint32, 9), offset=21}, -- The first few bits seem to determine the icon, but the icon appears to be tied to the type of fight, so it's more than just an icon.
    time_offset_maybe   = {0x38, uint32}, -- For me, this is the number of seconds in 66 hours
    timestamp           = {0x3C, time()}, -- This is 32 years off of JST at the time the packet is sent.
    fish_hook_delay     = {0x46, uint8}, -- number of seconds between casting and hooking a fish, only set when state_id changes to 56
    status_effect_mask  = {0x48, data(8)},
    indi_status_effect  = {0x54, indi},
})

-- Entity Animation
-- Most frequently used for spawning ("deru") and despawning ("kesu")
-- Another example: "sp00" for Selh'teus making his spear of light appear
types.incoming[0x038] = struct({
    npc_id              = {0x00, entity},
    other_npc_id        = {0x04, entity},
    fourcc              = {0x08, fourcc},
    npc_index           = {0x0C, entity_index},
    other_npc_index     = {0x0E, entity_index},
})

-- Env. Animation
-- Animations without entities will have zeroes for ID and Index
-- Example without IDs: Runic Gate/Runic Portal
-- Example with IDs: Diabolos floor tiles
types.incoming[0x039] = struct({
    npc_id              = {0x00, entity},
    other_npc_id        = {0x04, entity},
    fourcc              = {0x08, fourcc},
    npc_index           = {0x0C, entity_index},
    other_npc_index     = {0x0E, entity_index},
})

-- Independent Animation
-- This is sometimes sent along with an Action Message packet, to provide an animation for an action message.
types.incoming[0x03A] = struct({
    actor_id            = {0x00, entity},
    target_id           = {0x04, entity},
    actor_index         = {0x08, entity_index},
    target_index        = {0x0A, entity_index},
    animation_id        = {0x0C, uint16},
    animation_type      = {0x0E, uint8},
    -- Last byte seems to have no effect
})

-- Shop
types.incoming[0x03C] = struct({
   offset               = {0x00, uint16},
   items                = {0x04, shop_item['*']},
})

-- Price response
-- Sent after an outgoing price request for an NPC vendor (0x085)
types.incoming[0x03D] = struct({
    price               = {0x00, uint32},
    bag_index           = {0x04, uint8},
    bag_id              = {0x05, bag},
    _known1             = {0x08, uint32, const=0x01},
})

-- Open Buy/Sell
types.incoming[0x03E] = struct({
    _known1             = {0x00, uint8, const=0x04},
})


-- Shop Buy Response
types.incoming[0x03F] = struct({
    shop_slot           = {0x00, uint16},
    -- 0x02 uint16 : First byte always seems to be 1, second byte varies between 0 and 1? Unclear correlation to anything.
    count               = {0x04, uint32},
})

-- Blacklist
types.incoming[0x041] = struct({
    blacklist_entries   = {0x00, blacklist_entry[0x12]},
    _known1             = {0xF0, uint8, const=3},
    size                = {0xF1, uint8},
})

-- Blacklist (add/delete)
types.incoming[0x042] = struct({
    -- 0x00 uint32 : Looks like a player ID, but does not match the sender or the receiver.
    player_name         = {0x04, pc_name},
    type                = {0x14, bool}, -- 0 == add, 1 == remove
    -- 0x15 data[3] : values observed on adding but not deleting
})

-- Pet Stat
-- This packet varies and is indexed by job ID (byte 4)
-- Packet 0x044 is sent twice in sequence when stats could change. This can be caused by anything from
-- using a Maneuver on PUP to changing job. The two packets are the same length. The first
-- contains information about your main job. The second contains information about your
-- subjob and has the Subjob flag flipped.
types.incoming[0x044] = multiple({
    base = struct({
        job             = {0x00, job},
        subjob          = {0x01, bool},
        _padding1       = {0x02, data(2)},
    }),

    key = 'job',

    lookups = {

        --PUP
        [0x12] = struct({
            automaton_head  = {0x04, uint8}, -- Harlequinn 0x01, Valoredge 0x02, Sharpshot 0x03, Stormwaker 0x04, Soulsoother 0x05, Spiritreaver 0x06 (Item ID - 0x2000)
            automaton_frame = {0x05, uint8}, -- Harlequinn 0x20, Valoredge 0x21, Sharpshot 0x22, Stormwaker 0x23 (Item ID - 0x2000)
            attachments     = {0x06, uint8[0x0C]}, -- Attachment assignments are based off their position in the equipment list. 0 is an empty slot, otherwise Item ID - 0x2100, so Strobe is 0x01, etc.
            available_heads = {0x14, bitfield(4)}, -- Flags for the available heads. Position corresponds to Item ID shifted down by 0x2000. Harlequinn & 0x02, etc.
            available_frames= {0x18, bitfield(4)}, -- #BYRTH# Flags for the available frames. Position corresponds to the item ID shifted down by 0x2020. Harlequinn & 0x01, etc.
            available_attach= {0x34, bitfield(32)}, -- #BYRTH# This used to be broken out into 8 INTs. Need to confirm. Flags for the available attachments. Position corresponds to the item ID shifted down by 0x2100.
            pet_name        = {0x54, string(0x10)},
            hp              = {0x64, uint16},
            hp_max          = {0x66, uint16},
            mp              = {0x68, uint16},
            mp_max          = {0x6A, uint16},
            melee           = {0x6C, uint16},
            melee_max       = {0x6E, uint16},
            ranged          = {0x70, uint16},
            ranged_max      = {0x72, uint16},
            magic           = {0x74, uint16},
            magic_max       = {0x76, uint16},
            str             = {0x7C, uint16},
            str_modifier    = {0x7E, uint16},
            dex             = {0x80, uint16},
            dex_modifier    = {0x82, uint16},
            vit             = {0x84, uint16},
            vit_modifier    = {0x86, uint16},
            agi             = {0x88, uint16},
            agi_modifier    = {0x8A, uint16},
            int             = {0x8C, uint16},
            int_modifier    = {0x8E, uint16},
            mnd             = {0x90, uint16},
            mnd_modifier    = {0x92, uint16},
            chr             = {0x94, uint16},
            chr_modifier    = {0x96, uint16}
        }),

        --MON
        [0x17] = struct({
            species         = {0x04, uint16},
            instinct        = {0x08, item[12]}, -- Order is based off their position in the equipment list.
            -- Zeroing everything after byte 0x22 has no notable effect.
        }),

        -- For BLM, 0x29 to 0x43 appear to represent the black magic that you know
    },
})

-- Translate Response
types.incoming[0x047] = struct({
    autotranslate_code  = {0x00, data(4)},
    starting_language   = {0x02, uint8}, -- 0 == JP, 1 == EN
    ending_language     = {0x03, uint8}, -- 0 == JP, 1 == EN
    initial_phrase      = {0x04, string(64)},
    translated_phrase   = {0x44, string(64)} -- Will be 00'd if no match was found
})

-- Unknown 0x048 incoming :: Sent when loading linkshell information from the Linkshell Concierge
-- One per entry, 128 bytes long, mostly empty, does not contain name as far as I can see.
-- Likely contributes to that information.

-- Delivery Item
types.incoming[0x04B] = multiple({
    base = struct({
        type            = {0x00, uint8},
        _known1         = {0x01, uint8}, -- 0x01 for all types except 0x05, where it is 0xFF
        delivery_slot   = {0x02, uint8}, -- This goes left to right and then drops down a row and left to right again. Value is 00 through 07
        _known2         = {0x03, uint8}, -- 0xFF for all packets except 0x06, where it indicates whether the packet is the first of a pair.
        _known3         = {0x04, uint32, const=0xFFFFFFFF},
    }),

    key = 'type',

    lookups = {

        -- Seems to occur when refreshing the d-box after any change (or before changes).
        [0x01] = struct({
            packet_number   = {0x08, uint8},
            player_name     = {0x0A, pc_name}, -- This is used for sender (in inbox) and recipient (in outbox)
            -- 0x18: 46 32 00 00 and 42 32 00 00 observed - Possibly flags. Rare vs. Rare/Ex.?
            timestamp       = {0x24, time()},
            item_id         = {0x2C, item},
            -- 0x26: Fiendish Tome: Chapter 11 had it, but Oneiros Pebble was just 00 00. May well be junked, 38 38 observed.
            -- 0x28: Flags? 01/04 00 00 00 observed
            count           = {0x34, uint16},
            -- 0x2E: Unknown short
            -- 0x30: 28 bytes of all 0x00 observed, extdata? Doesn't seem to be the case, but same size
        }),

        -- Seems to occur when placing items into the d-box.
        [0x02] = struct({
            packet_number   = {0x08, uint8},
        }),

        -- Two occur per item that is actually sent (hitting "OK" to send).
        [0x03] = struct({
            packet_number   = {0x08, uint8},
        }),

        -- Two occur per sent item that is Canceled.
        [0x04] = struct({
            packet_number   = {0x08, uint8},
            player_name     = {0x0A, pc_name}, -- This is used for sender (in inbox) and recipient (in outbox)
            -- 0x18: 46 32 00 00 and 42 32 00 00 observed - Possibly flags. Rare vs. Rare/Ex.?
            timestamp       = {0x24, time()},
            item_id         = {0x2A, item},
            -- 0x26: Fiendish Tome: Chapter 11 had it, but Oneiros Pebble was just 00 00. May well be junked, 38 38 observed.
            -- 0x28: Flags? 01/04 00 00 00 observed
            count           = {0x34, uint16},
            -- 0x2E: Unknown short
            -- 0x30: 28 bytes of all 0x00 observed, extdata? Doesn't seem to be the case, but same size
        }),

        -- Seems to occur quasi-randomly. Can be seen following spells.
        [0x05] = struct({
            packet_number   = {0x08, uint8},
        }),

        -- 0x06 Occurs for new items.
        -- Two of these are sent sequentially. The first one doesn't seem to contain much/any
        -- information and the second one is very similar to a type 0x01 packet
        -- First packet's first 12 bytes:   06 01 00 01 FF FF FF FF 02 02 FF FF
        -- Second packet's first 12 bytes:  06 01 00 FF FF FF FF FF 01 02 FF FF
        [0x06] = struct({
            packet_number   = {0x08, uint8},
            player_name     = {0x0A, pc_name}, -- This is used for sender (in inbox) and recipient (in outbox)
            -- 0x18: 46 32 00 00 and 42 32 00 00 observed - Possibly flags. Rare vs. Rare/Ex.?
            timestamp       = {0x24, time()},
            item_id         = {0x2C, item},
            -- 0x26: Fiendish Tome: Chapter 11 had it, but Oneiros Pebble was just 00 00. May well be junked, 38 38 observed.
            -- 0x28: Flags? 01/04 00 00 00 observed
            count           = {0x34, uint16},
            -- 0x2E: Unknown short
            -- 0x30: 28 bytes of all 0x00 observed, extdata? Doesn't seem to be the case, but same size
        }),

        -- Occurs as the first packet when removing something from the send box.
        [0x07] = struct({
            packet_number   = {0x08, uint8},
        }),

        -- Occurs as the first packet when removing or dropping something from the delivery box.
        [0x08] = struct({
            packet_number   = {0x08, uint8},
            player_name     = {0x0A, pc_name}, -- This is used for sender (in inbox) and recipient (in outbox)
            -- 0x18: 46 32 00 00 and 42 32 00 00 observed - Possibly flags. Rare vs. Rare/Ex.?
            timestamp       = {0x24, time()},
            item_id         = {0x2C, item},
            -- 0x26: Fiendish Tome: Chapter 11 had it, but Oneiros Pebble was just 00 00. May well be junked, 38 38 observed.
            -- 0x28: Flags? 01/04 00 00 00 observed
            count           = {0x34, uint16},
            -- 0x2E: Unknown short
            -- 0x30: 28 bytes of all 0x00 observed, extdata? Doesn't seem to be the case, but same size
        }),

        -- Occurs when someone returns something from the delivery box.
        [0x09] = struct({
            packet_number   = {0x08, uint8},
        }),

        -- Occurs as the second packet when removing something from the delivery box or send box.
        [0x0A] = struct({
            packet_number   = {0x08, uint8},
            player_name     = {0x0A, pc_name}, -- This is used for sender (in inbox) and recipient (in outbox)
            -- 0x18: 46 32 00 00 and 42 32 00 00 observed - Possibly flags. Rare vs. Rare/Ex.?
            timestamp       = {0x24, time()},
            item_id         = {0x2C, item},
            -- 0x26: Fiendish Tome: Chapter 11 had it, but Oneiros Pebble was just 00 00. May well be junked, 38 38 observed.
            -- 0x28: Flags? 01/04 00 00 00 observed
            count           = {0x34, uint16},
            -- 0x2E: Unknown short
            -- 0x30: 28 bytes of all 0x00 observed, extdata? Doesn't seem to be the case, but same size
        }),

        -- Occurs as the second packet when dropping something from the delivery box.
        [0x0B] = struct({
            packet_number   = {0x08, uint8},
        }),

        -- Sent after entering a name and hitting "OK" in the outbox.
        [0x0C] = struct({
            packet_number   = {0x08, uint8},
        }),

        -- Sent after requesting the send box, causes the client to open the send box dialogue.
        [0x0D] = struct({
            success         = {0x08, uint8}, -- 01 grants request to open inbox/outbox. With FA you get "Please try again later"
        }),

        -- Sent after requesting the delivery box, causes the client to open the delivery box dialogue.
        [0x0E] = struct({
            success         = {0x08, uint8}, -- 01 grants request to open inbox/outbox. With FA you get "Please try again later"
        }),

        -- Sent after closing the delivery box or send box.
        [0x0F] = struct({
            packet_number   = {0x08, uint8},
        }),
    },
})

--[[enums['ah itype'] = {
    [0x02] = 'Open menu response',
    [0x03] = 'Unknown Logout',
    [0x04] = 'Sell item confirmation',
    [0x05] = 'Open sales status menu',
    [0x0A] = 'Open menu confirmation',
    [0x0B] = 'Sell item confirmation',
    [0x0D] = 'Sales item status',
    [0x0E] = 'Purchase item result',
}]]

-- Auction Interaction
-- All types in here are server responses to the equivalent type in 0x04E
-- The only exception is type 0x02, which is sent to initiate the AH menu
types.incoming[0x04C] = multiple({
    base = struct({
        type            = {0x00, uint8},
        sale_slot       = {0x01, int8}, -- 0xFF for types 0x02, 0x03, 0x04, and 0x05, which do not use a sale slot.
        packet_number   = {0x02, uint8}, -- 0xF6 if the action fails
        _known1         = {0x03, uint8}, -- 0x00 except for type 0x04, where it takes the value 0x04 and type 0x0D, where it is 0x00 for the first packet (packet_number == 0x02) and 0x01 for the second (packet_number == 0x01)
    }),

    key = 'type',

    lookups = {

        -- Open menu response
        [0x02] = struct({
            -- Two identical packets were sent to me
            -- 0x00: 0x35 observed
            -- 0x28~0x2F take values.
        }),

        -- Unknown Logout
        [0x03] = struct({
        }),

        -- Sell item confirmation
        [0x04] = struct({
            fee             = {0x08, uint32},
            bag_index       = {0x0C, uint8},
            _known2         = {0x0D, uint8, const=0x00},
            item_id         = {0x0E, item},
            stack           = {0x10, bool},
            -- 0x2A was 0x32 for me. The rest of the undefined bytes were 0x00.
        }),

        -- Open sales status menu
        [0x05] = struct({
            -- 0x00: 0x72 observed
            -- 0x02: 0x08 observed
            -- 0x2A: 0x32 observed
            -- 0x2C~0x33 are likely junk. Came through as "AuctionC"
            -- Rest of the bytes were 0x00 for me.
        }),

        --[[ sale_status = {
            [0x00] = Do not display the slot,
            [0x02] = Placing,
            [0x03] = On auction,
            [0x06] = Do not display the slot,
            [0x07] = Do not display the slot,
            [0x0A] = Sold,
            [0x0B] = Not sold,
            [0x0C] = Flashes unsold before refreshing,
            [0x0D] = Flashes sold before refreshing,
            [0x0E] = Flashes locked (grey) before refreshing,
            [0x0F] = Flashes locked (grey) before refreshing,
            [0x10] = Checking ? Just looks locked to me
            All unlisted combinations just grey out every slot.
        } ]]

        -- Open menu confirmation
        [0x0A] = struct({
            -- 12 junk bytes?
            sale_status     = {0x10, uint8}, -- see breakout above
            -- 0x11 is not a part of sale_status
            bag_index       = {0x12, uint8}, -- From when the item was put on auction
            _known3         = {0x13, uint8, const=0x00}, -- Might explain why bag_index is a short, or it might be the bag ID (always 00, inventory)
            player_name     = {0x14, pc_name},
            item_id         = {0x24, item},
            count           = {0x26, uint8},
            ah_category     = {0x27, uint8},
            price           = {0x28, uint32},
            auction_state   = {0x2E, uint32}, -- Always 04 00 00 00 after the auction has been accepted by the server
            auction_id      = {0x30, uint32}, -- Server seems to increment this counter 1 per auction
            auction_start   = {0x34, time()}, -- UTC time
        }),

        -- Sell item confirmation - Sent twice. On action completion, the second seems to contain updated information
        [0x0B] = struct({
            -- 0x28~0x2F: are only populated in the second packet (after the auction is confirmed accepted)
            -- 12 junk bytes?
            sale_status     = {0x10, uint8}, -- see above
            bag_index       = {0x12, uint8}, -- From when the item was put on auction
            _known3         = {0x13, uint8, const=0x00}, -- Might explain why bag_index is a short, or it might be the bag ID (always 00, inventory)
            player_name     = {0x14, pc_name},
            item_id         = {0x24, item},
            count           = {0x26, uint8},
            ah_category     = {0x27, uint8},
            price           = {0x28, uint32},
            auction_state   = {0x2C, uint32}, -- Always 04 00 00 00 after the auction has been accepted by the server
            auction_id      = {0x30, uint32}, -- Server seems to increment this counter 1 per auction
            auction_start   = {0x34, time()}, -- UTC time
        }),

        -- Remove item confirmation?
        [0x0C] = struct({
            -- 0x00~0x33 are only populated in the first packet (before the auction is confirmed canceled)
            -- 12 junk bytes?
            sale_status     = {0x10, uint8}, -- see above
            bag_index       = {0x12, uint8}, -- From when the item was put on auction
            _known3         = {0x13, uint8, const=0x00}, -- Might explain why bag_index is a short, or it might be the bag ID (always 00, inventory)
            player_name     = {0x14, pc_name},
            item_id         = {0x24, item},
            count           = {0x26, uint8},
            ah_category     = {0x27, uint8},
            price           = {0x28, uint32},
            auction_state   = {0x2C, uint32}, -- 04 00 00 00 in the first packet and 00 00 00 00 when confirmed canceled.
            auction_id      = {0x30, uint32}, -- present in the first packet and blanked in the second.
            auction_start   = {0x34, time()}, -- UTC time
        }),

        -- Sales item status - Sent twice. On action completion, the second seems to contain updated information
        [0x0D] = struct({
            -- 12 junk bytes?
            sale_status     = {0x10, uint8}, -- see above
            bag_index       = {0x12, uint8}, -- From when the item was put on auction
            _known3         = {0x13, uint8, const=0x00}, -- Might explain why bag_index is a short, or it might be the bag ID (always 00, inventory)
            player_name     = {0x14, pc_name},
            item_id         = {0x24, item},
            count           = {0x26, uint8},
            ah_category     = {0x27, uint8},
            price           = {0x28, uint32},
            auction_state   = {0x2C, uint32}, -- Always 04 00 00 00 after the auction has been accepted by the server
            auction_id      = {0x30, uint32}, -- Server seems to increment this counter 1 per auction
            auction_start   = {0x34, time()}, -- UTC time the auction started
        }),

        --[[ buy_status = {
            [0x01] = 'Success',
            [0x02] = 'Placing',
            [0xC5] = 'Failed',
        } ]]

        [0x0E] = struct({
            buy_status      = {0x01, uint8},
            price           = {0x04, uint32},
            item_id         = {0x08, item},
            count           = {0x0C, uint16},
            name            = {0x14, string(0x10)}, -- Character name (pending buy only)
            pending_item_id = {0x24, uint16}, -- Only filled out during pending packets
            pending_count   = {0x26, uint16}, -- Only filled out during pending packets
            pending_price   = {0x28, uint32}, -- Only filled out during pending packets
            timestamp       = {0x34, time()}, -- Only filled out during pending packets
        }),

        -- ??? : I have never seen this one.
        [0x10] = struct({
        }),
    },
})

-- Servmes Resp
-- Length of the packet may vary based on message length? Kind of hard to test.
-- The server message appears to generate some kind of feedback to the server based on the flags?
-- If you set the first byte to 0 in incoming chunk with eval and do /smes, the message will not display until you unload eval.
types.incoming[0x04D] = struct({
    _known1             = {0x00, uint8, const=0x01}, -- Message does not appear without this
    _known2             = {0x01, uint8, const=0x01}, -- Nonessential to message appearance
    _known3             = {0x02, uint8, const=0x01}, -- Message does not appear without this
    _known4             = {0x03, uint8, const=0x02}, -- Message does not appear without this
    timestamp           = {0x04, uint32}, -- UTC timestamp
    message_length      = {0x08, uint32}, -- Number of characters in the message
    other_message_length= {0x10, uint32}, -- Same as original message length
    message             = {0x14, string()}, -- Currently prefixed with 0x81, 0xA1 - A custom shift-jis character that translates to a square.
                                            -- This string may not contain a null terminating byte
})

-- Data Download 2
--   This packet's contents are nonessential. They are often leftovers from other outgoing
--   packets. It is common to see things like inventory size, equipment information, and
--   character ID in this packet. They do not appear to be meaningful and the client functions
--   normally even if they are blocked.
--   Tends to bookend model change packets (0x51), though blocking it, zeroing it, etc. seems to affect nothing.
--   It is always four bytes.
types.incoming[0x04F] = struct({})

-- Equipment
types.incoming[0x050] = struct({cache = {'slot_id'}}, {
    bag_index           = {0x00, uint8},
    slot_id             = {0x01, slot},
    bag_id              = {0x02, bag},
})

-- Model Change
types.incoming[0x051] = struct({
    face_model_id       = {0x00, uint8},
    race_id             = {0x01, race},
    model               = {0x02, model},
    -- 0x12: May varying meaningfully, but it's unclear
})

-- System message
-- This packet is used for system messages.
-- The most commonly encountered is the logout counter (id = 0x0007).
types.incoming[0x053] = struct({
    -- Packing in the first eight bytes of the packet might be somewhat variable
    param_1             = {0x00, uint32},
    param_2             = {0x04, uint32},
    message_id          = {0x08, uint16}, -- POLUtils referred to this resource as "System Messages (2)"
})

-- Key Item Log
-- FFing these packets between bytes 0x14 and 0x82 gives you access to all (or almost all) key items.
-- #BYRTH# examine this. I remember this not being entirely accurate
types.incoming[0x055] = struct({cache = {'type'}}, { -- #BYRTH# unadjusted for the base offset
    key_items_available = {0x00, data(0x40)}, -- The bit offset appears to correspond to type * 0x200 in the resources
    key_items_examined  = {0x40, data(0x40)},
    type                = {0x80, uint8}, -- Only goes from 0~6 at present, but has 3 bytes after it.
})

--[[enums.quest_mission_log = {
    [0x0030] = 'Completed Campaign Missions',
    [0x0038] = 'Completed Campaign Missions (2)',       -- Starts at index 256
    [0x0050] = 'Current San d\'Oria Quests',
    [0x0058] = 'Current Bastok Quests',
    [0x0060] = 'Current Windurst Quests',
    [0x0068] = 'Current Jeuno Quests',
    [0x0070] = 'Current Other Quests',
    [0x0078] = 'Current Outlands Quests',
    [0x0080] = 'Current TOAU Quests and Missions (TOAU, WOTG, Assault, Campaign)',
    [0x0088] = 'Current WOTG Quests',
    [0x0090] = 'Completed San d\'Oria Quests',
    [0x0098] = 'Completed Bastok Quests',
    [0x00A0] = 'Completed Windurst Quests',
    [0x00A8] = 'Completed Jeuno Quests',
    [0x00B0] = 'Completed Other Quests',
    [0x00B8] = 'Completed Outlands Quests',
    [0x00C0] = 'Completed TOAU Quests and Assaults',
    [0x00C8] = 'Completed WOTG Quests',
    [0x00D0] = 'Completed Missions (Nations, Zilart)',
    [0x00D8] = 'Completed Missions (TOAU, WOTG)',
    [0x00E0] = 'Current Abyssea Quests',
    [0x00E8] = 'Completed Abyssea Quests',
    [0x00F0] = 'Current Adoulin Quests',
    [0x00F8] = 'Completed Adoulin Quests',
    [0x0100] = 'Current Coalition Quests',
    [0x0108] = 'Completed Coalition Quests',
    [0xFFFF] = 'Current Missions',
}]]

-- There are 27 variations of this packet to populate different quest information.
-- Current quests, completed quests, and completed missions (where applicable) are represented by bit flags where the position
-- corresponds to the quest index in the respective DAT.
-- "Current Mission" fields refer to the mission ID, except COP, SOA, and ROV, which represent a mapping of some sort(?)
-- Additionally, COP, SOA, and ROV do not have a "completed" missions packet, they are instead updated with the current mission.
-- Quests will remain in your 'current' list after they are completed unless they are repeatable.

types.incoming[0x056] = multiple({ -- #BYRTH# unadjusted for the base offset
    base = struct({
        type            = {0x20, uint16},
    }),

    key = 'type',

    lookups = {

        [0x0080] = struct({
            current_toau_quests     = {0x00, data(16)},
            current_assault_mission = {0x10, uint32},
            current_toau_mission    = {0x14, uint32},
            current_wotg_mission    = {0x18, uint32},
            current_campaign_mission= {0x1C, uint32},
        }),

        [0x00C0] = struct({
            completed_toau_quests   = {0x00, data(16)},
            completed_assaults      = {0x10, data(16)},
        }),

        [0x00D0] = struct({
            completed_sandoria_missions = {0x00, data(8)},
            completed_bastok_missions   = {0x08, data(8)},
            completed_windurst_missions = {0x10, data(8)},
            completed_rotz_missions     = {0x18, data(8)},
        }),

        [0x00D8] = struct({
            completed_toau_missions = {0x00, data(8)},
            completed_wotg_missions = {0x08, data(8)},
        }),

        [0xFFFF] = struct({
            nation                  = {0x00, uint32},
            current_nation_mission  = {0x04, uint32},
            current_rotz_mission    = {0x08, uint32},
            current_cop_mission     = {0x0C, uint32}, -- doesn't correspond directly to .dat
            current_acp_mission     = {0x14, bit(uint16, 4), offset=0},
            current_mkd_mission     = {0x14, bit(uint16, 4), offset=4},
            current_asa_mission     = {0x14, bit(uint16, 4), offset=8},
            current_soa_mission     = {0x18, uint32},
            current_rov_mission     = {0x1C, uint32},
        }),
    },
})

-- Weather Change
types.incoming[0x057] = struct({
    vanadiel_time       = {0x00, time()}, -- Units of minutes.
    weather_id          = {0x04, weather},
})

-- Assist response
types.incoming[0x058] = struct({
    player_id           = {0x00, entity},
    target_id           = {0x04, entity},
    player_index        = {0x08, entity_index},
})

-- Emote
types.incoming[0x05A] = struct({
    player_id           = {0x00, entity},
    target_id           = {0x04, entity},
    player_index        = {0x08, entity_index},
    target_index        = {0x0A, entity_index},
    emote_id            = {0x0C, uint16},
    _known1             = {0x0E, uint16, const=0x0002},
    motion              = {0x12, boolbit(uint8), offset=1},
})

-- Spawn
types.incoming[0x05B] = struct({
    x                   = {0x00, float},
    z                   = {0x04, float},
    y                   = {0x08, float},
    entity_id           = {0x0C, entity},
    entity_index        = {0x10, entity_index},
    type                = {0x12, uint8}, -- 3 for regular Monsters, 0 for Treasure Caskets and NPCs, 0x0A for Self
    -- 0x13: Always 0 if Type is 3, otherwise a seemingly random non-zero number
})

-- Dialogue Information
types.incoming[0x05C] = struct({
    params              = {0x00, data(32)}, -- How information is packed in this region depends on the particular dialogue exchange.
})

-- Campaign/Besieged Map information

-- Bitpacked Campaign Info:
-- First Byte: Influence ranking including Beastmen
-- Second Byte: Influence ranking excluding Beastmen

-- Third Byte (bitpacked xxww bbss -- First two bits are for beastmen)
    -- 0 = Minimal
    -- 1 = Minor
    -- 2 = Major
    -- 3 = Dominant

-- Fourth Byte: Ownership (value)
    -- 0 = Neutral
    -- 1 = Sandy
    -- 2 = Bastok
    -- 3 = Windurst
    -- 4 = Beastmen
    -- 0xFF = Jeuno
types.incoming[0x05E] = struct({
    -- First two bits have an unknown function, but might indicate beastman influence?
    windurst_ranking    = {0x00, bit(uint8, 2), offset=2},
    bastok_ranking      = {0x00, bit(uint8, 2), offset=4},
    sandoria_ranking    = {0x00, bit(uint8, 2), offset=6},
    alliance_indicator  = {0x01, bool}, -- Indicates whether the bottom two nations are allied.
    --0x02~0x15: All Zeros, and changed nothing when 0xFF'd. 4 bytes larger than we would expect if there was empty space left for the town regions
    ronfaure_info       = {0x16, rmap_region_info},
    zulkheim_info       = {0x1A, rmap_region_info},
    norvallen_info      = {0x1E, rmap_region_info},
    gustaberg_info      = {0x22, rmap_region_info},
    derfland_info       = {0x26, rmap_region_info},
    sarutabaruta_info   = {0x2A, rmap_region_info},
    kolshushu_info      = {0x2E, rmap_region_info},
    aragoneau_info      = {0x32, rmap_region_info},
    faurengandi_info    = {0x36, rmap_region_info},
    valdeaunia_info     = {0x3A, rmap_region_info},
    qufim_info          = {0x3E, rmap_region_info},
    li_telor_info       = {0x42, rmap_region_info},
    kuzotz_info         = {0x46, rmap_region_info},
    vollbow_info        = {0x4A, rmap_region_info},
    elshimo_lowlands_info   = {0x4E, rmap_region_info},
    elshimo_uploands_info   = {0x52, rmap_region_info},
    tu_lia_info         = {0x56, rmap_region_info}, -- Skips Dynamis
    movapolos_info      = {0x5A, rmap_region_info},
    tavnazian_archipelago_info  = {0x5E, rmap_region_info},
    -- 0x62~0x81: All Zeros, and changed nothing when 0xFF'd.
    sandoria_region_bar = {0x82, percent}, -- These indicate how full the current region's bar is (in percent).
    bastok_region_bar   = {0x83, percent},
    windurst_region_bar = {0x84, percent},
    sandoria_region_bar_no_beastmen = {0x85, percent}, -- Unsure of the purpose of the without beastman indicators
    bastok_region_bar_no_beastmen   = {0x86, percent},
    windurst_region_bar_no_beastmen = {0x87, percent},
    days_to_tally       = {0x88, uint8}, -- Number of days to the next conquest tally
    -- 0x089~0x08B All Zeros, and changed nothing when 0xFF'd.
    conquest_points     = {0x8C, int32},
    beastmen_region_bar = {0x90, uint8},
    -- 0x91~0x9C: Mostly zeros and noticed no change when 0xFF'd.

-- These bytes are for the overview summary on the map.
-- Candescence Owners:
    -- 0 = Whitegate
    -- 1 = MMJ
    -- 2 = Halvung
    -- 3 = Arrapago
    astral_candescence_owner    = {0x9C, bit(uint32,2), offset=0},
-- Orders:
    -- 0 = Defend Al Zahbi
    -- 1 = Intercept Enemy
    -- 2 = Invade Enemy Base
    -- 3 = Recover the Orb
    current_orders      = {0x9C, bit(uint32,2), offset=2},
    mamool_ja_level     = {0x9C, bit(uint32,4), offset=4},
    halvung_level       = {0x9C, bit(uint32,4), offset=8},
    arrapago_level      = {0x9C, bit(uint32,4), offset=12},
    mamool_ja_orders    = {0x9C, bit(uint32,3), offset=16}, -- #BYRTH# Why is this three bits when there are only 3 recorded states for orders?
    halvung_orders      = {0x9C, bit(uint32,3), offset=19},
    arrapago_orders     = {0x9C, bit(uint32,3), offset=22},

    -- This is for the stronghold information:
    mamool_ja_stronghold    = {0xA0, bmap_region_info},
    halvung_ja_stronghold   = {0xA4, bmap_region_info},
    arrapago_ja_stronghold  = {0xA8, bmap_region_info},

    imperial_standing   = {0xAC, int32},
})

-- Music Change
types.incoming[0x05F] = struct({
    music_type          = {0x00, uint16}, -- 01 = idle music, 06 = mog house music. 00, 02, and 03 are fight musics and some other stuff.
    song_id             = {0x02, uint16}, -- See the setBGM addon for more information
})

-- Char Stats
types.incoming[0x061] = struct({
    hp_max              = {0x00, uint32},
    mp_max              = {0x04, uint32},
    main_job_id         = {0x08, job},
    main_job_level      = {0x09, uint8},
    sub_job_id          = {0x0A, job},
    sub_job_level       = {0x0B, uint8},
    exp                 = {0x0C, uint16},
    exp_required        = {0x0E, uint16},
    stats_base          = {0x10, stats},
    stats_bonus         = {0x1E, stats},
    attack              = {0x2C, uint16},
    defense             = {0x2E, uint16},
    resistance          = {0x30, resistances},
    title_id            = {0x40, title},
    nation_rank         = {0x42, uint16},
    nation_rank_points  = {0x44, uint16}, -- Capped at 0xFFF
    home_point_zone_id  = {0x46, zone},
    nation_id           = {0x4C, nation},
    superior_level      = {0x4E, uint8},
    item_level_max      = {0x50, uint8},
    item_level_over_99  = {0x51, uint8},
    item_level_main     = {0x52, uint8},
    unity               = {0x54, unity},
})

-- Skills Update
types.incoming[0x062] = struct({
    combat_skills       = {0x7C, combat_skill[0x30], key_lookup='skills', lookup_index=0x00},
    crafting_skills     = {0xDC, crafting_skill[0x0A], key_lookup='skills', lookup_index=0x30},
})

-- Set Update
-- This packet likely varies based on jobs, but currently I only have it worked out for Monstrosity.
-- It also appears in three chunks, so it's double-varying.
-- Packet was expanded in the March 2014 update and now includes a fourth packet, which contains CP values.
types.incoming[0x063] = multiple({
    base = struct({
        type            = {0x00, uint16},
        size            = {0x02, uint16},
    }),

    key = 'type',

    lookups = {

        [0x02] = struct({
            limit_points    = {0x04, uint16},
            merit_points    = {0x06, uint8},
            merit_switch    = {0x07, boolbit(uint8), offset=7},
            level_capped    = {0x07, boolbit(uint8), offset=6},
            merits_unlocked = {0x07, boolbit(uint8), offset=5}, -- Merits unlocked and/or limit points earnable? Needs confirmation from lower level characters.
            merit_points_max= {0x08, uint8},
        }),

        [0x03] = struct({
            flags1          = {0x04, data(2)}, -- Vary when I change species
            flags2          = {0x06, data(2)}, -- Consistent across species
            monstrosity_rank= {0x08, uint8}, -- 00 = Mon, 01 = NM, 02 = HM
            infamy          = {0x0E, uint16},
            instinct_flags  = {0x18, data(0x40)}, -- Bitpacked 2-bit values. 0 = no instincts from that species, 1 == first instinct, 2 == first and second instinct, 3 == first, second, and third instinct.
            monster_levels  = {0x58, data(0x80)}, -- Mapped onto the item ID for these creatures. (00 doesn't exist, 01 is rabbit, 02 is behemoth, etc.)
        }),

        [0x04] = struct({
            slime_level     = {0x82, uint8},
            spriggan_level  = {0x83, uint8},
            instinct_flags  = {0x84, data(0x0C)}, -- Contains job/race instincts from the 0x03 set. Has 8 unused bytes. This is a 1:1 mapping.
            variants_flags  = {0x90, data(0x20)}, -- Does not show normal monsters, only variants. Bit is 1 if the variant is owned. Length is an estimation including the possible padding.
        }),

        [0x05] = struct({
            job_points      = {0x08, job_point_info[0x18], key_lookup='jobs'}
        }),

        [0x09] = struct({
            status_effects  = {0x04, uint16[0x20]},
            durations       = {0x44, time(1510890320, 60)[0x20]},
        }),
    },
})

-- Repositioning
types.incoming[0x065] = struct({
    x                   = {0x00, float},
    z                   = {0x04, float},
    y                   = {0x08, float},
    entity_id           = {0x0C, entity},
    entity_index        = {0x10, entity_index},
    type                = {0x12, uint8}, -- 1 observed. May indicate repositoning type.
    -- 0x13: Unknown, but matches the same byte of a matching spawn packet
    -- 0x14~0x19: All zeros observed.
})

-- Pet Info
types.incoming[0x067] = struct({
-- The lower 6 bits of the Mask is the type of packet:
-- 2 occurs often even with no pet, contains player index, id and main job level
-- 3 identifies (potential) pets and who owns them
-- 4 gives status information about your pet
        type                = {0x00, bit(uint16, 6), offset=0},
        packet_length       = {0x00, bit(uint16, 10), offset=6}, -- Length of packet in bytes excluding the header and any padding after the pet name
        pet_index           = {0x02, entity_index},
        pet_id              = {0x04, entity},
        owner_index         = {0x08, entity_index},
        hp_percent          = {0x0A, percent},
        mp_percent          = {0x0B, percent},
        pet_tp              = {0x0C, uint32},
        --pet_name            = {0x10, pc_name},    -- Is variable-length and isn't always included
})

-- Pet Status
-- It is sent every time a pet performs an action, every time anything about its vitals changes (HP, MP, TP) and every time its target changes
types.incoming[0x068] = struct({
    type                = {0x00, bit(uint16, 6), offset=0}, -- Seems to always be 4
    packet_length       = {0x00, bit(uint16, 10), offset=6},
    owner_index         = {0x02, entity_index},
    owner_id            = {0x04, entity},
    pet_index           = {0x08, entity_index},
    hp_percent          = {0x0A, percent},
    mp_percent          = {0x0B, percent},
    pet_tp              = {0x0C, uint32},
    target_id           = {0x10, entity},
    pet_name            = {0x14, string()},
})

-- Self Synth Result
types.incoming[0x06F] = struct({
    result              = {0x00, uint8},
    quality             = {0x01, int8},
    count               = {0x02, uint8}, -- Even set for fail (set as the NQ amount in that case)
    -- 0x03: fields.lua implies this byte is junk
    item                = {0x04, item},
    lost_item           = {0x06, item[8]},
    skill               = {0x16, skill[4]},
    skillup             = {0x1A, uint8[4]}, -- divided by 10
    crystal             = {0x1E, item},
})

-- Others Synth Result
types.incoming[0x070] = struct({
    result              = {0x00, uint8},
    quality             = {0x01, int8},
    count               = {0x02, uint8}, -- Even set for fail (set as the NQ amount in that case)
    -- 0x03: fields.lua implies this byte is junk
    item                = {0x04, item},
    lost_item           = {0x06, item[8]},
    skill               = {0x16, skill[4]}, -- Not totally sure about this
    player_name         = {0x1A, pc_name},
})

-- Unity Start
-- Only observed being used for Unity fights.
types.incoming[0x075] = struct({
    fight_designation   = {0x00, uint32}, -- Anything other than 0 makes a timer. 0 deletes the timer.
    timestamp_offset    = {0x04, time()}, -- Number of seconds since 15:00:00 GMT 31/12/2002 (0x3C307D70)
    fight_duration      = {0x08, time()},
    --0x0C~0x17: This packet clearly needs position information, but it's unclear how these bytes carry it.
    battlefield_radius  = {0x18, uint32}, -- Yalms*1000, so a 50 yalm battlefield would have 50,000 for this field
    render_radius       = {0x1C, uint32}, -- Yalms*1000, so a fence that renders when you're 25 yalms away would have 25,000 for this field
})

types.incoming[0x076] = struct({
    party_members       = {0x00, party_status_effects[5]},
})

-- Proposal
types.incoming[0x078] = struct({
    player_id           = {0x00, entity},
    -- 0x04~0x07: Proposal ID?
    proposer_index      = {0x08, entity_index},
    proposer_name       = {0x0A, string(15)}, -- #BYRTH# Only 15 bytes?
    mode                = {0x19, uint8}, -- Not typical chat mode mapping. 1 = Party
    proposal            = {0x1A, string()}, -- Proposal text, complete with special characters
})

-- Proposal Update
types.incoming[0x079] = struct({
    -- 0x04~0x1B: Likely contains information about the current chat mode and vote count
    proposer_name       = {0x0A, pc_name}, -- Why is this different than the above?
})

-- Guild Buy Response
-- Sent when buying an item from a guild NPC
types.incoming[0x082] = struct({
    item                = {0x00, item}, -- This was labeled as 0x08 in fields.lua
    count               = {0x03, uint8},
})

-- Guild Inv List
types.incoming[0x083] = struct({
    items               = {0x00, guild_entry[30]},
    number_of_items     = {0xF0, uint8},
    order               = {0xF1, bit(uint8, 4), order=0},
    -- fields.lua implies that the upper 4 bits of 0xF1 may have a use.
})

-- Guild Sell Response
-- Sent when selling an item to a guild NPC
types.incoming[0x084] = struct({
    item                = {0x00, item}, -- This was labeled as 0x08 in fields.lua
    -- No obvious purpose
    count               = {0x03, uint8}, -- Number you bought. If 0, the transaction failed.
})

-- Guild Sale List
types.incoming[0x085] = struct({
    items               = {0x00, guild_entry[30]},
    number_of_items     = {0xF0, uint8},
    order               = {0xF1, bit(uint8, 4), order=0},
    -- fields.lua implies that the upper 4 bits of 0xF1 may have a use.
})

-- Guild Open
-- Sent to update guild status or open the guild menu.
types.incoming[0x086] = struct({
    guild_status        = {0x00, uint8}, -- 0x00 = Open guild menu, 0x01 = Guild is closed, 0x03 = nothing, so this is treated as an unsigned char
    -- 0x01~0x03: Does not seem to matter in any permutation of this packet
    guild_hours         = {0x04, data(3)}, -- Bitpacked: First 1 indicates the opening hour. First 0 after that indicates the closing hour. In the event that there are no 0s, 91022244 is used.
    close_guild         = {0x07, bit(uint8,1), offset=7}, -- Most significant bit (0x80) indicates whether the "close guild" message should be displayed.
})

-- Merits
types.incoming[0x08C] = struct({
    entry_count         = {0x00, uint8}, -- Number of merits entries in this packet (possibly a short, although it wouldn't make sense)
    -- Always 00 0F 01?
    merit_entries       = {0x04, merit_entry[1]}, -- #BYRTH# This is going to be a problem. There are an entry_count number of these
    _known1             = {0x04 + 1*4, uint32, const=0}, -- #BYRTH# This is going to be a problem. Should be entry_count*4
})

-- Job Points
types.incoming[0x08D] = struct({
    job_point_entries   = {0x00, job_point_entry[1]}, -- #BYRTH# This is going to be a problem. Should be *
})

-- Campaign Map Info
-- types.incoming[0x071]
-- Perhaps it's my lack of interest, but this (triple-ish) packet is nearly incomprehensible to me.
-- Does not appear to contain zone IDs. It's probably bitpacked or something.
-- Has a byte that seems to be either 02 or 03, but the packet is sent three times. There are two 02s.
-- The second 02 packet contains different information after the ~48th content byte.

-- Party Map Marker
-- This packet is ignored if your party member is within 50' of you.
types.incoming[0x0A0] = struct({
    player_id           = {0x00, entity},
    zone_id             = {0x04, zone},
    -- 0x06~0x07: Looks like junk
    x                   = {0x08, float},
    z                   = {0x0C, float},
    y                   = {0x10, float},
})

-- Player spells known
types.incoming[0x0AA] = struct({
    spells              = {0x00, bitfield(0x80)} -- 0 indexed bit field where nth bit indicates if that spell_id is known. I.E. bit 1 is Cure, bit 2 is Cure II, etc.
})

-- 0x0AC, and 0x0AE are bitfields where the lsb indicates whether you have index 0 of the related resource.

-- Help Desk submenu open
types.incoming[0x0B5] = struct({
    number_of_opens     = {0x14, uint32},
})

-- Alliance status update
types.incoming[0x0C8] = struct({
    -- 0x00: fields.lua implies this byte might be useful
    alliance_members    = {0x04, alliance_member[18]},
    -- 0xDC~0xF4: fields.lua claims it might always be 0, but the fact that it is another 18 bytes is suspicious
})

-- Check data
types.incoming[0x0C9] = multiple({
    base = struct({
        target_id       = {0x00, entity},
        target_index    = {0x04, entity_index},
        type            = {0x06, uint8}, -- fn=e+{0x0C9} ?
        count           = {0x07, uint8}, -- only known to be valid for type 0x03, but needs to be here to align the uint16s correctly
    }),

    key = 'type',

    lookups = {

        -- Metadata
        [0x01] = struct({
            icon_set_subtype= {0x0A, uint8},
            icon_set_id     = {0x0B, uint8},
            linkshell_red   = {0x0C, bit(uint16, 4), offset=0},
            linkshell_green = {0x0C, bit(uint16, 4), offset=4},
            linkshell_blue  = {0x0C, bit(uint16, 4), offset=8},
            main_job_id     = {0x0E, job},
            sub_job_id      = {0x0F, job},
            linkshell_name  = {0x10, ls_name},
            main_job_level  = {0x20, uint8},
            sub_job_level   = {0x21, uint8},
            -- 0x1A~0x46: At least the first two bytes and the last twelve bytes are junk, possibly more.
        }),

        -- Equipment listing
        [0x03] = struct({
            equipment       = {0x08, check_item[8]}, -- #BYRTH# There are `count` copies of this struct, not necessarily 8
        }),
    },
})

-- Bazaar Message
types.incoming[0x0CA] = struct({
    bazaar_message      = {0x00, string(0x7C)},
    player_name         = {0x7C, pc_name},
    player_title_id     = {0x8C, uint16},
    -- 0x8E~0x8F: 00 00 observed.
})

-- LS Message
types.incoming[0x0CC] = struct({cache = {'linkshell_index'}}, {
    linkshell_index         = {0x00, bit(uint32, 1), offset=14},
    message                 = {0x04, string(0x80)},
    timestamp               = {0x84, time()},
    player_name             = {0x88, pc_name},
    permissions             = {0x94, data(4)},
    linkshell_name          = {0x98, ls_name},
})

-- Found Item
types.incoming[0x0D2] = struct({cache = {'pool_index'}}, {
    -- 0x00~0x03: Could be characters starting the line - FD 02 02 18 observed; Arcon: Only ever observed 0x00000001 for this
    dropper_id          = {0x04, entity},
    gil                 = {0x08, uint32},
    item_id             = {0x0C, item},
    dropper_index       = {0x0E, entity_index},
    pool_index          = {0x10, uint8}, -- This is the internal index in memory, not the one it appears in in the menu
    is_old              = {0x11, bool}, -- This is true if it was already in the pool, but appeared in the pool before you joined a party
    _known1             = {0x12, uint8, const=0},
    -- 0x17: Seemingly random, both 00 and FF observed, as well as many values in between
    timestamp           = {0x14, time()},
    -- 28 bytes of 0s?
})

-- Item lot/drop
types.incoming[0x0D3] = struct({cache = {'pool_index'}}, {
    highest_lotter_id   = {0x00, entity},
    lotter_id           = {0x04, entity},
    highest_lotter_index= {0x08, entity_index},
    highest_lot         = {0x0A, uint16},
    lotter_index        = {0x0C, bit(uint16, 15), offset=0}, -- Not a normal index somehow
    --_known1             = {0x0C, bit(uint16, 1 ), offset=15, const=1}, -- Always seems set
    lot                 = {0x0E, uint16}, -- 0xFFFF if passing
    pool_index          = {0x10, uint8},
    drop                = {0x11, uint8}, -- 0 if no drop, 1 if dropped to player, 3 if floored
    highest_lotter_name = {0x12, pc_name},
    lotter_name         = {0x22, pc_name},
    -- 0x32~0x37: Thought to be junk
})

-- Party Invite: Provides information about the inviter
types.incoming[0x0DC] = struct({
    player_id           = {0x00, entity},
    flags               = {0x04, uint32}, -- This may also contain the type of invite (alliance vs. party)
    player_name         = {0x08, pc_name},
})

-- Party member update
types.incoming[0x0DD] = struct({
    player_id           = {0x00, entity},
    hp                  = {0x04, uint32},
    mp                  = {0x08, uint32},
    tp                  = {0x0C, uint32},
    flags               = {0x10, uint16},
    player_index        = {0x14, entity_index},
    hp_percent          = {0x19, percent},
    mp_percent          = {0x1A, percent},
    zone_id             = {0x1C, zone},
    main_job_id         = {0x1E, job},
    main_job_level      = {0x1F, uint8},
    sub_job_id          = {0x20, job},
    sub_job_level       = {0x21, uint8},
    player_name         = {0x22, pc_name},
})

-- Unnamed 0xDE packet
-- 8 bytes long, sent in response to opening/closing mog house. Occasionally sent when zoning.
-- Injecting it with different values has no obvious effect.
types.incoming[0x0DE] = struct({
    type                = {0x00, uint8} -- Was always 0x4 for opening/closing mog house
})

-- Char Update
types.incoming[0x0DF] = struct({
    id                  = {0x00, entity},
    hp                  = {0x04, uint32},
    mp                  = {0x08, uint32},
    tp                  = {0x0C, uint32},
    index               = {0x10, entity_index},
    hp_percent          = {0x12, percent},
    mp_percent          = {0x13, percent},
    main_job_id         = {0x1C, job},
    main_job_level      = {0x1D, uint8},
    sub_job_id          = {0x1E, job},
    sub_job_level       = {0x1F, uint8},
})

-- Linkshell Equip
types.incoming[0x0E0] = struct({cache = {'linkshell_number'}}, {
    linkshell_number    = {0x00, uint8},
    bag_index           = {0x01, slot},
})

-- Party Member List
types.incoming[0x0E1] = struct({
    party_id            = {0x00, string(2)}, -- For whatever reason, this is always valid ASCII in my captured packets.
    -- 0x02~0x03  Likely contains information about the current chat mode and vote count
})

-- Char Info
types.incoming[0x0E2] = struct({
    id                  = {0x00, entity},
    hp                  = {0x04, uint32},
    mp                  = {0x08, uint32},
    tp                  = {0x0C, uint32},
    index               = {0x14, entity_index},
    hp_percent          = {0x19, percent},
    mp_percent          = {0x1A, percent},
    name                = {0x1E, string()},
})

-- Toggle Heal
types.incoming[0x0E8] = struct({
    reason              = {0x00, uint8}, -- 02 if caused by movement
    -- 0x000000 observed
})

-- Widescan Mob
types.incoming[0x0F4] = struct({
    index               = {0x00, entity_index},
    level               = {0x02, uint8},
    type                = {0x03, uint8}, -- 0: Other, 1: Friendly, 2: Enemy
    x_offset            = {0x04, uint16}, -- Offset on the map
    y_offset            = {0x06, uint16},
    name                = {0x08, pc_name}, -- Slugged, may not extend all the way to 27. Up to 25 has been observed. This will be used if Type == 0
})

-- Widescan Track
types.incoming[0x0F5] = struct({
    x                   = {0x00, float},
    z                   = {0x04, float},
    y                   = {0x08, float},
    level               = {0x0C, uint8},
    index               = {0x0E, entity_index},
    status              = {0x10, uint32}, -- 1: Update, 2: Reset (zone), 3: Reset (new scan)
})

-- Widescan Mark
types.incoming[0x0F6] = struct({
    type                = {0x00, uint32}, -- 1: Start, 2: End
})

--[[enums['reraise'] = {
    [0x01] = 'Raise dialogue',
    [0x02] = 'Tractor dialogue',
}]]

-- Reraise Activation
types.incoming[0x0F9] = struct({
    player_id           = {0x00, entity},
    player_index        = {0x04, entity_index},
    category            = {0x08, uint8},
})

-- Furniture Interaction
types.incoming[0x0FA] = struct({
    item                = {0x00, item},
    _known1             = {0x02, data(6), const=0},
    bag_index           = {0x08, uint8}, -- Safe slot for the furniture being interacted with? How does safe2 work?
})

-- Bazaar item listing
types.incoming[0x105] = struct({
    price               = {0x00, uint32},
    count               = {0x04, uint32},
    item_id             = {0x0A, item},
    bag_index           = {0x0C, uint8}, -- This is the seller's inventory index of the item
})

-- Bazaar Seller Info Packet
-- Information on the purchase sent to the buyer when they attempt to buy
-- something from a bazaar (whether or not they are successful)
types.incoming[0x106] = struct({
    type                = {0x00, bool},
    player_name         = {0x04, pc_name},
})

-- Bazaar closed
-- Sent when the bazaar closes while you're browsing it
-- This includes you buying the last item which leads to the message:
-- "Player's bazaar was closed midway through your transaction"
types.incoming[0x107] = struct({
    player_name         = {0x00, pc_name},
})

-- Bazaar visitor
-- Sent when someone opens your bazaar
types.incoming[0x108] = struct({
    player_id           = {0x00, entity},
    type                = {0x04, bool},
    _known1             = {0x05, data(4), const=0},
    player_index        = {0x0A, entity_index},
    player_name         = {0x0C, pc_name},
})

-- Bazaar Purchase Info Packet
-- Information on the purchase sent to the buyer when the purchase is successful.
types.incoming[0x109] = struct({
    buying_player_id    = {0x00, entity},
    count               = {0x04, uint32},
    buying_player_index = {0x08, entity_index},
    selling_player_index= {0x0A, entity_index},
    buying_player_name  = {0x0C, pc_name},
    -- 0x1C~0x1F: Was 05 00 02 00 for me
})

-- Bazaar Buyer Info Packet
-- Information on the purchase sent to the seller when a sale is successful.
types.incoming[0x10A] = struct({
    count               = {0x00, uint32},
    item_id             = {0x04, item},
    buying_player_name  = {0x06, pc_name},
})

-- Bazaar Open Packet
-- Packet sent when you open your bazaar.
types.incoming[0x10B] = struct({
    -- 0x00~0x03: Was 00 00 00 00 for me
})

-- Sparks update packet
types.incoming[0x110] = struct({
    sparks_total        = {0x00, uint32},
    -- 0x02~0x03: Sparks are currently capped at 50,000
    shared_unity        = {0x04, uint8}, -- Unity (Shared) designator (0=A, 1=B, 2=C, etc.)
    person_unity        = {0x05, uint8}, -- The game does not distinguish these
    _known1             = {0x06, data(6), const=0xFFFFFFFFFFFF},
})

-- Eminence Update
types.incoming[0x111] = struct({
    roe_quests              = {0x00, roe_quest_entry[30]},
    -- 0x78~0xFB: All 0s observed. Likely reserved in case they decide to expand allowed objectives.
    limited_time_roe_quest  = {0xFC, roe_quest_entry},
})

-- RoE Quest Log
types.incoming[0x112] = struct({
    -- Bitpacked quest completion flags. The position of the bit is the quest ID.
    -- Data regarding available quests and repeatability is handled client side or
    -- somewhere else
    roe_quest_bitfield  = {0x00, data(0x80)},
    order               = {0x80, uint32}, -- 0,1,2,3
})

--Currency Info (Currencies I)
types.incoming[0x113] = struct({
    conquest_points         = {0x00, int32[3], key_lookup='nations', lookup_index=0x00},
    beastmens_seals         = {0x0C, uint16},
    kindred_seals           = {0x0E, uint16},
    kindred_crests          = {0x10, uint16},
    high_kindred_crests     = {0x12, uint16},
    sacred_kindred_crests   = {0x14, uint16},
    ancient_beastcoins      = {0x16, uint16},
    valor_points            = {0x18, uint16},
    scylds                  = {0x1A, uint16},
    guild_points            = {0x1C, int32[0x09], key_lookup='skills', lookup_index=0x30},
    cinders                 = {0x40, int32},
    fewell                  = {0x44, uint8[0x08], key_lookup='elements', lookup_index=0x00},
    ballista_points         = {0x4C, int32},
    fellow_points           = {0x50, int32},
    chocobucks              = {0x54, uint16[3], key_lookup='nations', lookup_index=0x00},
    daily_tally             = {0x5A, uint16},
    research_marks          = {0x5C, uint32},
    wizened_tunnel_worms    = {0x60, uint8},
    wizened_morion_worms    = {0x61, uint8},
    wizened_phantom_worms   = {0x62, uint8},
    moblin_marbles          = {0x64, int32},
    infamy                  = {0x68, uint16},
    prestige                = {0x6A, uint16},
    legion_points           = {0x6C, int32},
    sparks_of_eminence      = {0x70, int32},
    shining_stars           = {0x74, int32},
    imperial_standing       = {0x78, int32},
    assault_points          = {0x7C, int32[5]},
    nyzul_tokens            = {0x90, int32},
    zeni                    = {0x94, int32},
    jettons                 = {0x98, int32},
    therion_ichor           = {0x9C, int32},
    allied_notes            = {0xA0, int32},
    aman_vouchers_stored    = {0xA4, int16},
    login_points            = {0xA6, int16},
    cruor                   = {0xA8, int32},
    resistance_credits      = {0xAC, int32},
    dominion_notes          = {0xB0, int32},
    battle_trophies         = {0xB4, int8[5]},
    cave_conservation_points= {0xB9, int8},
    imperial_army_id_tags   = {0xBA, int8},
    op_credits              = {0xBB, int8},
    traverser_stones        = {0xBC, int32},
    voidstones              = {0xC0, int32},
    kupofrieds_corundums    = {0xC4, int32},
    moblin_pheromone_sacks  = {0xC8, uint8}, -- May actually be uint16
    rems_tale_chapter_1     = {0xCA, uint8},
    rems_tale_chapter_2     = {0xCB, uint8},
    rems_tale_chapter_3     = {0xCC, uint8},
    rems_tale_chapter_4     = {0xCD, uint8},
    rems_tale_chapter_5     = {0xCE, uint8},
    rems_tale_chapter_6     = {0xCF, uint8},
    rems_tale_chapter_7     = {0xD0, uint8},
    rems_tale_chapter_8     = {0xD1, uint8},
    rems_tale_chapter_9     = {0xD2, uint8},
    rems_tale_chapter_10    = {0xD3, uint8},
    -- bloodshed_plans         = {0xD4, bit(uint64, 9), offset=0},
    -- umbrage_plans           = {0xD4, bit(uint64, 9), offset=9},
    -- ritualistic_plans       = {0xD4, bit(uint64, 9), offset=18},
    -- tutelary_plans          = {0xD4, bit(uint64, 9), offset=27},
    -- primacy_plans           = {0xD4, bit(uint64, 9), offset=36}, -- Upper two bytes here aren't used.
    reclamation_marks       = {0xDC, int32},
    unity_accolades         = {0xE0, int32},
    fire_crystals           = {0xE4, uint16},
    ice_crystals            = {0xE6, uint16},
    wind_crystals           = {0xE8, uint16},
    earth_crystals          = {0xEA, uint16},
    lightning_crystals      = {0xEC, uint16},
    water_crystals          = {0xEE, uint16},
    light_crystals          = {0xF0, uint16},
    dark_crystals           = {0xF2, uint16},
    deeds                   = {0xF4, int32},
    -- Packet structure current as of 2019-07-08 update.
})

-- Fishing Minigame Parameters
types.incoming[0x115] = struct({
    fish_hp             = {0x00, uint16}, -- max fish hp
    arrow_time          = {0x02, uint16}, -- a higher value means you have more time to correctly pick the arrow direction
    auto_regen          = {0x04, uint16}, -- bellow 128 will auto-drain fish hp, above 128 will auto-regen fish hp, 128 is neutral
    movement            = {0x06, uint16}, -- a lower value means the fishing rod will stay in the center longer (no arrow)
    damage              = {0x08, uint16}, -- amount of damage done when correctly picking the arrow direction
    healing             = {0x0a, uint16}, -- amount of healing given when incorrectly picking the arrow direction
    time_limit          = {0x0c, uint16}, -- amount of time you have to reel in the fish
    danger_music        = {0x0e, boolbit(uint8), offset=0}, -- if true the more intense fishing music is used
    critical_bite       = {0x0e, boolbit(uint8), offset=1}, -- if true the light bulb graphic will appear over the players head
    gold_arrows         = {0x10, uint32}, -- percentage chance of getting a gold arrow, used in the outgoing 0x110 packet when attempting to catch
})

-- Equipset Build Response
types.incoming[0x116] = struct({
    equipment           = {0x00, equipset_build[0x10], key_lookup='slots'}, -- Ordered according to equipment slot ID
})

-- Equipset
types.incoming[0x117] = struct({
    count               = {0x00, uint8},
    equipment           = {0x04, equipset_entry[0x10]}, -- #BYRTH# This is problematic. Should be indexed by `count`
    old_equipment       = {0x44, equipset_entry[0x10]}, -- This is my memory
})

-- Currency Info (Currencies2)
types.incoming[0x118] = struct({
    bayld                   = {0x00, int32},
    kinetic_units           = {0x04, uint16},
    coalition_imprimaturs   = {0x06, uint8},
    mystical_canteens       = {0x07, uint8},
    obsidian_fragments      = {0x08, int32},
    lebondopt_wings         = {0x0C, uint16},
    pulchridopt_wings       = {0x0E, uint16},
    mweya_plasm             = {0x10, int32},
    ghastly_stones          = {0x14, uint8},
    ghastly_stones_1        = {0x15, uint8},
    ghastly_stones_2        = {0x16, uint8},
    verdigris_stones        = {0x17, uint8},
    verdigris_stones_1      = {0x18, uint8},
    verdigris_stones_2      = {0x19, uint8},
    wailing_stones          = {0x1A, uint8},
    wailing_stones_1        = {0x1B, uint8},
    wailing_stones_2        = {0x1C, uint8},
    snowslit_stones         = {0x1D, uint8},
    snowslit_stones_1       = {0x1E, uint8},
    snowslit_stones_2       = {0x1F, uint8},
    snowtip_stones          = {0x20, uint8},
    snowtip_stones_1        = {0x21, uint8},
    snowtip_stones_2        = {0x22, uint8},
    snowdim_stones          = {0x23, uint8},
    snowdim_stones_1        = {0x24, uint8},
    snowdim_stones_2        = {0x25, uint8},
    snoworb_stones          = {0x26, uint8},
    snoworb_stones_1        = {0x27, uint8},
    snoworb_stones_2        = {0x28, uint8},
    leafslit_stones         = {0x29, uint8},
    leafslit_stones_1       = {0x2A, uint8},
    leafslit_stones_2       = {0x2B, uint8},
    leaftip_stones          = {0x2C, uint8},
    leaftip_stones_1        = {0x2D, uint8},
    leaftip_stones_2        = {0x2E, uint8},
    leafdim_stones          = {0x2F, uint8},
    leafdim_stones_1        = {0x30, uint8},
    leafdim_stones_2        = {0x31, uint8},
    leaforb_stones          = {0x32, uint8},
    leaforb_stones_1        = {0x33, uint8},
    leaforb_stones_2        = {0x34, uint8},
    duskslit_stones         = {0x35, uint8},
    duskslit_stones_1       = {0x36, uint8},
    duskslit_stones_2       = {0x37, uint8},
    dusktip_stones          = {0x38, uint8},
    dusktip_stones_1        = {0x39, uint8},
    dusktip_stones_2        = {0x3A, uint8},
    duskdim_stones          = {0x3B, uint8},
    duskdim_stones_1        = {0x3C, uint8},
    duskdim_stones_2        = {0x3D, uint8},
    duskorb_stones          = {0x3E, uint8},
    duskorb_stones_1        = {0x3F, uint8},
    duskorb_stones_2        = {0x40, uint8},
    pellucid_stone          = {0x41, uint8},
    fern_stone              = {0x42, uint8},
    taupe_stone             = {0x43, uint8},
    mellidopt_wings         = {0x44, uint16},
    escha_beads             = {0x46, uint16},
    escha_silt              = {0x48, int32},
    potpourri               = {0x4C, int32},
    hallmarks               = {0x50, int32},
    total_hallmarks         = {0x54, int32},
    gallantry               = {0x58, int32},
    crafter_points          = {0x5C, int32},
    fire_crystals_set       = {0x60, uint8},
    ice_crystals_set        = {0x61, uint8},
    wind_crystals_set       = {0x62, uint8},
    earth_crystals_set      = {0x63, uint8},
    lightning_crystals_set  = {0x64, uint8},
    water_crystals_set      = {0x65, uint8},
    light_crystals_set      = {0x66, uint8},
    dark_crystals_set       = {0x67, uint8},
    MCSSR01s_set            = {0x68, uint8},
    MCSSR02s_set            = {0x69, uint8},
    MCSSR03s_set            = {0x6A, uint8},
    liquefaction_spheres_set = {0x6B, uint8},
    induration_spheres_set  = {0x6C, uint8},
    detonation_spheres_set  = {0x6D, uint8},
    scission_spheres_set    = {0x6E, uint8},
    impaction_spheres_set   = {0x6F, uint8},
    reverberation_spheres_set = {0x70, uint8},
    transfixion_spheres_set = {0x71, uint8},
    compression_spheres_set = {0x72, uint8},
    fusion_spheres_set      = {0x73, uint8},
    distortion_spheres_set  = {0x74, uint8},
    fragmentation_spheres_set = {0x75, uint8},
    gravitation_spheres_set = {0x76, uint8},
    light_spheres_set       = {0x77, uint8},
    darkness_spheres_set    = {0x78, uint8},
    -- unknown padding 0x79 for 3 bytes
    silver_aman_vouchers    = {0x7C, int32},
    -- Packet structure current as of 2019-07-08 update.
})

-- Ability timers
types.incoming[0x119] = struct({
    recasts             = {0x00, ability_recast[0x1F]},
})

-- Party Request
types.incoming[0x11D] = struct({
    player_name         = {0x08, pc_name},
})

-- Zone In 1
-- Likely triggers specific incoming packets.
-- Does not trigger any packets when randomly injected.
types.outgoing[0x00C] = struct({
    _known1             = {0x00, data(8), const=0},
})

-- Client Leave
-- Last packet sent when zoning. Disconnects from the zone server.
types.outgoing[0x00D] = struct({
    _known1             = {0x00, uint32, const=0},
})

-- Zone In 2
-- Likely triggers specific incoming packets.
-- Does not trigger any packets when randomly injected.
types.outgoing[0x00F] = struct({
    _known1             = {0x00, data(32), const=0},
})

-- Zone In 3
-- Likely triggers specific incoming packets.
-- Does not trigger any packets when randomly injected.
types.outgoing[0x011] = struct({
    _known1             = {0x00, uint32, const=0x02000000},
})

-- Standard Client
types.outgoing[0x015] = struct({
    x                   = {0x00, float},
    z                   = {0x04, float},
    y                   = {0x08, float},
    run_count           = {0x0E, uint16}, -- Counter that indicates how long you've been running?
    heading             = {0x10, uint8},
    _flags1             = {0x11, uint8}, -- Bit 0x04 indicates that maintenance mode is activated
    target_index        = {0x12, entity_index},
    timestamp           = {0x14, time()}, -- Milliseconds
})

-- Update Request
types.outgoing[0x016] = struct({
    target_index        = {0x00, entity_index},
})

-- NPC Race Error
types.outgoing[0x017] = struct({
    target_index        = {0x00, entity_index},
    target_id           = {0x04, entity},
    reported_npc_type   = {0x0E, uint8},
})

--[[enums['action'] = {
    [0x00] = 'NPC Interaction',
    [0x02] = 'Engage monster',
    [0x03] = 'Magic cast',
    [0x04] = 'Disengage',
    [0x05] = 'Call for Help',
    [0x07] = 'Weaponskill usage',
    [0x09] = 'Job ability usage',
    [0x0C] = 'Assist',
    [0x0D] = 'Reraise dialogue',
    [0x0E] = 'Cast Fishing Rod',
    [0x0F] = 'Switch target',
    [0x10] = 'Ranged attack',
    [0x12] = 'Dismount Chocobo',
    [0x13] = 'Tractor Dialogue',
    [0x14] = 'Zoning/Appear', -- I think, the resource for this is ambiguous.
    [0x19] = 'Monsterskill',
    [0x1A] = 'Mount',
}]]

-- Action
types.outgoing[0x01A] = struct({
    target_id           = {0x00, entity},
    target_index        = {0x04, entity_index},
    action_category     = {0x06, uint16}, -- Why is this a short?
    param               = {0x08, uint16},
    _known1             = {0x0A, uint16, const=0},
    x_offset            = {0x0C, float}, -- non-zero values only observed for geo spells cast using a repositioned subtarget
    z_offset            = {0x10, float},
    y_offset            = {0x14, float},
})

-- /volunteer
types.outgoing[0x01E] = struct({
    target_name         = {0x00, string()}, -- null terminated string. Length of name to the nearest 4 bytes.
})

-- Drop Item
types.outgoing[0x028] = struct({
    count               = {0x00, uint32},
    bag_id              = {0x04, bag},
    bag_index           = {0x05, uint8},
})

-- Move Item
types.outgoing[0x029] = struct({
    count               = {0x00, uint32},
    current_bag_id      = {0x04, bag},
    target_bag_id       = {0x05, bag},
    current_bag_index   = {0x06, uint8},
    target_bag_index    = {0x07, uint8}, -- This byte is normally 0x52 (max index + 1) when moving items between bags, but setting it specifically works. It takes other values when manually sorting.
})

-- Translate
-- German and French translations appear to no longer be supported.
types.outgoing[0x02B] = struct({
    current_language    = {0x00, uint8}, -- 0 == JP, 1 == EN
    target_language     = {0x01, uint8}, -- 0 == JP, 1 == EN
    _known1             = {0x02, uint16, const=0},
    phrase              = {0x04, string(64)}, -- Quotation marks are removed. Phrase is truncated at 64 characters.
})

-- Trade request
types.outgoing[0x032] = struct({
    target_id           = {0x00, entity},
    target_index        = {0x04, entity_index},
})

--[[enums[0x033] = {
    [0] = 'Accept trade',
    [1] = 'Cancel trade',
    [2] = 'Confirm trade',
}]]

-- Trade confirm
-- Sent when accepting, confirming or canceling a trade
types.outgoing[0x033] = struct({
    type                = {0x00, uint32}, -- #BYRTH# Why is this 4 bytes?
    trade_count         = {0x04, uint32}, -- Necessary to set if you are receiving items, comes from incoming packet 0x023
})

-- Trade offer
types.outgoing[0x034] = struct({
    count               = {0x00, uint32},
    item_id             = {0x04, item},
    bag_index           = {0x06, uint8},
    trade_slot          = {0x07, uint8},
})

-- Menu Item
types.outgoing[0x036] = struct({
-- Item order is Gil -> top row left-to-right -> bottom row left-to-right, but
-- they slide up and fill empty slots
    target_id           = {0x00, entity},
    item_counts         = {0x04, uint32[9]},
    bag_indices         = {0x2C, uint8[9]}, -- Gil has a bag_index of 0
    target_index        = {0x36, entity_index},
    number_of_items     = {0x38, uint8},
})

-- Use Item
types.outgoing[0x037] = struct({
    player_id           = {0x00, entity},
    -- 0x04~0x07: 00 00 00 00 observed
    player_index        = {0x08, entity_index},
    bag_index           = {0x0A, uint8},
    -- 0x0B: takes values, but the meaning is unclear
    bag_id              = {0x0C, bag},
})

-- Sort Item
types.outgoing[0x03A] = struct({
    bag_id              = {0x00, bag},
})

-- Blacklist (add/delete)
types.outgoing[0x03D] = struct({
    -- 0x00~0x03: Looks like a player ID, but does not match the sender or the receiver. Perhaps the blacklister is nominally an NPC.
    player_name         = {0x04, pc_name},
    add_or_remove       = {0x14, bool}, -- 0 = add, 1 = remove
    -- 0x15~0x17: Values observed on adding but not deleting.
})

-- Lot item
types.outgoing[0x041] = struct({
    pool_index          = {0x00, uint8},
})

-- Pass item
types.outgoing[0x042] = struct({
    pool_index          = {0x00, uint8},
})

-- Servmes
-- First 4 bytes resemble the first 4 bytes of the incoming servmessage packet
types.outgoing[0x04B] = struct({
    -- 0x00: Always 1?
    -- 0x01: Can be 1 or 0
    -- 0x02: Always 1?
    -- 0x03: Always 2?
    -- 0x04~0x0F: Always 0?
    -- 0x10~0x13: EC 00 00 00 observed. May be junk.
})

-- Delivery Box
types.outgoing[0x04D] = struct({
    -- Removing an item from the d-box sends type 0x08
    -- It then responds to the server's 0x4B (id=0x08) with a 0x0A type packet.
    -- Their assignment is the same, as far as I can see.
    type                = {0x00, uint8},

    -- 0x01: 01 observed
    delivery_slot       = {0x02, uint8},
    -- 0x03~0x07: FF FF FF FF FF observed
    -- 0x08~0x1F: 00s observed
})

--[[enums['ah otype'] = {
    [0x04] = 'Sell item request',
    [0x05] = 'Check sales',
    [0x0A] = 'Open AH menu',
    [0x0B] = 'Sell item confirmation',
    [0x0C] = 'Stop sale',
    [0x0D] = 'Sale status confirmation',
    [0x0E] = 'Place bid',
    [0x10] = 'Item sold',
} ]]

types.outgoing[0x04E] = multiple({
    base = struct({
        type            = {0x00, uint8},
        sale_slot       = {0x01, uint8}, -- 0xFF for packet type 0x0A
        _padding1       = {0x02, data(2)},
    }),

    key = 'type',

    lookups = {

        -- Sent when putting an item up for auction (request)
        [0x04] = struct({
            price           = {0x04, uint32},
            bag_index       = {0x08, uint8}, -- This was a short in fields.lua
            item_id         = {0x0A, item},
            stack           = {0x0C, bool},
        }),

        -- Sent when checking your sale status
        [0x05] = struct({
            -- Labeled junk in fields.lua
        }),

        -- Sent when initially opening the AH menu
        [0x0A] = struct({
        }),

        -- Sent when putting an item up for auction (confirmation)
        [0x0B] = struct({
            price           = {0x04, uint32},
            bag_index       = {0x08, uint8}, -- This was a short in fields.lua
            stack           = {0x0C, bool},
        }),

        -- Sent when stopping an item from sale
        [0x0C] = struct({
        }),

        -- Sent after receiving the sale status list for each item
        [0x0D] = struct({
        }),

        -- Sent when bidding on an item
        [0x0E] = struct({
            price           = {0x04, uint32},
            item_id         = {0x08, item},
            stack           = {0x0C, bool},
        }),

        -- ???
        [0x0D] = struct({
        }),

        -- Sent when taking a sold item from the list
        [0x10] = struct({
        }),
    },
})

-- Equip
types.outgoing[0x050] = struct({cache = {'slot_id'}}, {
    bag_index           = {0x00, uint8},
    slot_id             = {0x01, slot},
    bag_id              = {0x02, bag},
})

types.outgoing[0x051] = struct({
    count               = {0x00, uint8},
    -- Same as _unknown1 is outgoing 0x052
    equipment           = {0x04, equipset_entry[0x10]},
    -- There is also a bunch of junk at the end of the packet.
})

-- Equipset Build
types.outgoing[0x052] = struct({
    -- First 8 bytes are for the newly changed item
    slot_id             = {0x00, slot},
    new_equipment       = {0x04, equipset_build},

    -- The next 16 are the entire current equipset, excluding the newly changed item
    previous_equipment  = {0x08, equipset_build[0x10], key_lookup='slots'},
})

-- lockstyleset
types.outgoing[0x053] = struct({
    -- First 4 bytes are a header for the set
    count               = {0x00, uint8},
    type                = {0x01, uint8}, -- 0 = "Stop locking style", 1 = "Continue locking style", 3 = "Lock style in this way". Might be flags?
    _known1             = {0x02, uint16, const=0},
    lockstyle_equipment = {0x04, lockstyle_entry[0x10], key_lookup='slots'},
})

-- End Synth
-- This packet is sent after receiving a result when synthesizing.
types.outgoing[0x059] = struct({
    -- 0x00~0x03: Often 00 00 00 00, but 01 00 00 00 observed.
    -- 0x04~0x0B: Often 00 00 00 00, likely junk from a non-zero'd buffer.
})

-- Conquest
types.outgoing[0x05A] = struct({ })

-- Dialogue options
types.outgoing[0x05B] = struct({
    target_id           = {0x00, entity},
    option_index        = {0x04, uint16},
    option_index_2      = {0x06, uint16},
    target_index        = {0x08, entity_index},
    not_exiting         = {0x0A, bool}, -- 1 if you are not exiting a menu with a multi-packet exchange
    zone_id             = {0x0C, zone},
    menu_id             = {0x0E, uint16},
})

-- Warp Request
types.outgoing[0x05C] = struct({
    x                   = {0x00, float},
    z                   = {0x04, float},
    y                   = {0x08, float},
    target_id           = {0x0C, entity},
    option_index        = {0x10, uint32},
    zone_id             = {0x14, zone},
    menu_id             = {0x16, uint16},
    target_index        = {0x18, entity_index},
    -- 0x1A~0x1B: Not zone ID
    heading             = {0x1B, uint8},
})

-- Outgoing emote
types.outgoing[0x05D] = struct({
    target_id           = {0x00, entity},
    target_index        = {0x04, entity_index},
    emote_id            = {0x06, uint8},
    motion              = {0x07, boolbit(uint8), offset=1},
    _known1             = {0x08, uint32, const=0},
})

-- Zone request
-- Sent when crossing a zone line.
types.outgoing[0x05E] = struct({
    zone_line           = {0x00, fourcc}, -- This seems to be a fourCC consisting of the following chars:
                                          -- 'z' (apparently constant)
                                          -- Region-specific char ('6' for Jeuno, '3' for Qufim, etc.)
                                          -- Zone-specific char ('u' for Port Jeuno, 't' for Lower Jeuno, 's' for Upper Jeuno, etc.)
                                          -- Zone line identifier ('4' for Port Jeuno > Qufim Island, '2' for Port Jeuno > Lower Jeuno, etc.)
    _known1             = {0x04, data(14), const=0},
    _known2             = {0x12, uint8, const=4}, -- Seemed to never vary for me
    type                = {0x13, uint8}, -- 03 for leaving the MH, 00 otherwise
})

-- Equipment Screen (0x02 length) -- Also observed when zoning
types.outgoing[0x061] = struct({ })

-- Digging Finished
-- This packet alone is responsible for generating the digging result, meaning that anyone that can inject
-- this packet is capable of digging with 0 delay.
types.outgoing[0x063] = struct({
    player_id           = {0x00, entity},
    player_index        = {0x08, entity_index},
    digging_action      = {0x0A, uint8}, -- Changing it to anything other than 0x11 causes the packet to fail
    -- Last byte is likely junk. Has no effect on anything notable.
})

--"New" Key Item examination packet
types.outgoing[0x064] = struct({
    player_id           = {0x00, entity},
    flags               = {0x04, data(0x40)}, -- These correspond to a particular section of the 0x55 incoming packet
    which_half          = {0x44, uint32}, -- This field somehow denotes which half-0x55-packet the flags corresponds to
})

-- Party invite
types.outgoing[0x06E] = struct({
    target_id           = {0x00, entity}, -- This is so weird. The client only knows IDs from searching for people or running into them. So if neither has happened, the manual invite will fail, as the ID cannot be retrieved.
    target_index        = {0x04, entity_index}, -- 00 if target not in zone
    alliance            = {0x06, uint8}, -- 05 for alliance, 00 for party or if invalid alliance target (the client somehow knows..)
    _known1             = {0x07, uint8, const=0x41},
})

-- Party leaving
types.outgoing[0x06F] = struct({
    alliance            = {0x00, uint8}, -- 05 for alliance, 00 for party
})

-- Party breakup
types.outgoing[0x070] = struct({
    alliance            = {0x00, uint8}, -- 02 for alliance, 00 for party
})

-- Kick
types.outgoing[0x071] = struct({
    kick_type           = {0x06, uint8}, -- 0 for party, 1 for linkshell, 2 for alliance (maybe)
    target_name         = {0x08, pc_name},
})

-- Party invite response
types.outgoing[0x074] = struct({
    join                = {0x00, bool},
})

--[[ -- Unnamed 0x76
-- Observed when zoning (sometimes). Probably triggers some information to be sent (perhaps about linkshells?)
types.outgoing[0x076] = struct({
    flags               = {0x00, uint8}, -- Only 01 observed
    -- 0x01~0x03: Only 00 00 00 observed.
})]]

-- Change Permissions
types.outgoing[0x077] = struct({
    target_name         = {0x00, pc_name}, -- Name of the person to give leader to
    party_type          = {0x10, uint8}, -- 0 = party, 1 = linkshell, 2 = alliance
    permissions         = {0x11, uint16}, -- 01 for alliance leader, 00 for party leader, 03 for linkshell "to sack", 02 for linkshell "to pearl"
})

-- Party list request (4 byte packet)
types.outgoing[0x078] = struct({ })

-- Guild NPC Buy
-- Sent when buying an item from a guild NPC
types.outgoing[0x082] = struct({
    item_id             = {0x00, item},
    _known1             = {0x02, uint8, const=0},
    count               = {0x03, uint8}, -- Number you are buying
})

-- NPC Buy Item
-- Sent when buying an item from a generic NPC vendor
types.outgoing[0x083] = struct({
    count               = {0x00, uint32},
    -- 0x04~0x05: Redirection Index? When buying from a guild helper, this was the index of the real guild NPC.
    shop_slot           = {0x06, uint8}, -- The same index sent in incoming packet 0x03C
    -- 0x07~0x0B: Always 0?
})

-- NPC Sell price query
-- Sent when trying to sell an item to an NPC
-- Clicking on the item the first time will determine the price
-- Also sent automatically when finalizing a sale, immediately preceeding packet 0x085
types.outgoing[0x084] = struct({
    count               = {0x00, uint32},
    item                = {0x04, item},
    bag_index           = {0x06, uint8},
    -- 0x07: Always 0? Likely padding
})

-- NPC Sell confirm
-- Sent when confirming a sell of an item to an NPC
types.outgoing[0x085] = struct({
    _known1             = {0x00, uint32, const=1}, -- Always 1? Possibly a type
})

-- Synth
types.outgoing[0x096] = struct({
    hash                = {0x00, uint16}, -- #BYRTH# Check the craft addon
    crystal_id          = {0x02, item},
    crystal_bag_index   = {0x04, uint8},
    ingredient_count    = {0x05, uint8},
    ingredients         = {0x06, item[0x08]},
    ingredients_bag_indices = {0x16, uint8[0x08]},
})

-- /nominate or /proposal
types.outgoing[0x0A0] = struct({
    type                = {0x00, uint8}, -- Not typical mapping. 0=Open poll (say), 1 = Open poll (party), 3 = conclude poll
    -- Just padding if the poll is being concluded.
    proposal            = {0x01, string()}, -- Proposal exactly as written. Space delimited with quotes and all. Null terminated.
})

-- /vote
types.outgoing[0x0A1] = struct({
    voting_option       = {0x00, uint8}, -- Voting option
    player_name         = {0x01, pc_name}, -- Character name. Null terminated.
})

-- /random
types.outgoing[0x0A2] = struct({
    -- 0x00~0x03: No clear purpose
})

-- Guild Buy Item
-- Sent when buying an item from a guild NPC
types.outgoing[0x0AA] = struct({
    item_id             = {0x00, item},
    _known1             = {0x02, uint8, const=0},
    count               = {0x03, uint8}, -- Number you are buying
})

-- Get Guild Inv List
-- It's unclear how the server figures out which guild you're asking about, but this triggers 0x83 Incoming.
types.outgoing[0x0AB] = struct({ })

-- Guild Sell Item
-- Sent when selling an item to a guild NPC
types.outgoing[0x0AC] = struct({
    item_id             = {0x00, item},
    count               = {0x03, uint8}, -- Number you are selling
})

-- Get Guild Sale List
-- It's unclear how the server figures out which guild you're asking about, but this triggers 0x85 Incoming.
types.outgoing[0x0AD] = struct({ })

-- Speech
types.outgoing[0x0B5] = struct({
    mode                = {0x00, chat},
    gm                  = {0x01, bool},
    message             = {0x02, string()},
})

-- Tell
types.outgoing[0x0B6] = struct({
    _known1             = {0x00, uint8, const=0}, -- Varying this does nothing.
    target_name         = {0x01, string(15)},
    message             = {0x10, string()},
})

-- Merit Point Increase
types.outgoing[0x0BE] = struct({
    _known1             = {0x00, uint8, const=3}, -- No idea what it is, but it's always 0x03 for me
    increasing          = {0x01, bool}, -- 1 when you're increasing a merit point. 0 when you're decreasing it.
    merit_point_id      = {0x02, uint16}, -- No known mapping, but unique to each merit point. Could be an int.
    _known2             = {0x04, uint32, const=0},
})

-- Job Point Increase
types.outgoing[0x0BF] = struct({
    type                = {0x00, bit(uint16, 5), offset=0},
    job_id              = {0x00, bit(uint16, 11), offset=5},
    _known1             = {0x00, uint16, const=0}, -- No values seen so far
})

-- Job Point Menu
-- This packet has no content bytes
types.outgoing[0x0C0] = struct({ })

-- /makelinkshell
types.outgoing[0x0C3] = struct({
    linkshell_number    = {0x05, uint8},
})

-- Equip Linkshell
types.outgoing[0x0C4] = struct({
    -- 0x00~0x01: 0x00 0x0F for me
    bag_index           = {0x02, uint8}, -- bag_index that holds the linkshell
    linkshell_number    = {0x03, uint8},
    -- 0x04~0x13: Probably going to be used in the future system somehow. Currently "dummy"..string.char(0,0,0).."%s %s "..string.char(0,1)
})

-- Open Mog
types.outgoing[0x0CB] = struct({
    type                = {0x00, uint8}, -- 1 = open mog, 2 = close mog
})

-- Party Marker Request
types.outgoing[0x0D2] = struct({
    zone_id             = {0x00, zone},
})

-- Open Help Submenu
types.outgoing[0x0D4] = struct({
    number_of_opens     = {0x00, uint32}, -- Number of times you've opened the submenu.
})

-- Check
types.outgoing[0x0DD] = struct({
    target_id           = {0x00, entity},
    target_index        = {0x04, entity_index},
    check_type          = {0x08, uint8}, -- 00 = Normal /check, 01 = /checkname, 02 = /checkparam
})

-- Search Comment
types.outgoing[0x0E0] = struct({
    line_1              = {0x00, string(0x28)}, -- Spaces (0x20) fill out any empty characters.
    line_2              = {0x28, string(0x28)}, -- Spaces (0x20) fill out any empty characters.
    line_3              = {0x50, string(0x28)}, -- Spaces (0x20) fill out any empty characters.
    -- 0x78~0x7B: 20 20 20 00 observed.
    -- 0x7C~0x93: Likely contains information about the flags.
})

-- Get LS Message
types.outgoing[0x0E1] = struct({
    _known1             = {0x00, data(136), const=0}, -- analogous to the set ls message, but with no content
})

-- Set LS Message
types.outgoing[0x0E2] = struct({
    _known1             = {0x00, uint32, const=0x00000040},
    -- 0x04~0x07: Usually 0, but sometimes contains some junk
    message             = {0x08, string(128)},
})

-- Logout
types.outgoing[0x0E7] = struct({
    -- 0x00~0x01: Observed to be 00 00
    logout_type         = {0x02, uint8}, -- /logout = 01, /pol == 02 (removed), /shutdown = 03
    -- 0x03: Observed to be 00
})

-- Sit
types.outgoing[0x0EA] = struct({
    movement            = {0x00, uint8},
})

-- Cancel
types.outgoing[0x0F1] = struct({
    buff                = {0x00, uint8},
})

-- Declare Subregion
types.outgoing[0x0F2] = struct({
    _known1             = {0x00, uint8, const=1},
    _known2             = {0x01, uint8, const=0},
    subregion_index     = {0x02, uint16},
})

-- Unknown packet 0xF2
types.outgoing[0x0F2] = struct({
    _known1             = {0x00, uint8, const=1},
    _known2             = {0x01, uint8, const=0},
    synergy_index       = {0x02, entity_index}, -- Has always been the index of a synergy enthusiast or furnace for me
})

-- Widescan
types.outgoing[0x0F4] = struct({
    getting_widescan    = {0x00, bool}, -- 1 when requesting widescan information. No other values observed.
})

-- Widescan Track
types.outgoing[0x0F5] = struct({
    target_index        = {0x00, entity_index}, -- Setting an index of 0 stops tracking
})

-- Widescan Cancel
types.outgoing[0x0F6] = struct({
    _known1             = {0x00, uint32, const=0},
})

-- Place/Move Furniture
types.outgoing[0x0FA] = struct({
    item_id             = {0x00, item}, -- 00 00 just gives the general update
    bag_id              = {0x02, bag},
    grid_x              = {0x03, uint8}, -- 0 to 0x12
    grid_z              = {0x04, uint8}, -- 0 to ?
    grid_y              = {0x05, uint8}, -- 0 to 0x17
    _known1             = {0x06, uint16, const=0},
})

-- Remove Furniture
types.outgoing[0x0FB] = struct({
    item_id             = {0x00, item},
    bag_id              = {0x02, bag},
})

-- Plant Flowerpot
types.outgoing[0x0FC] = struct({
    flowerpot_item_id   = {0x00, item},
    seed_item_id        = {0x02, item},
    flowerpot_bag_index = {0x04, uint8},
    seed_bag_index      = {0x05, uint8},
    -- 0x06~0x07: 00 00 observed
})

-- Examine Flowerpot
types.outgoing[0x0FD] = struct({
    flowerpot_item_id   = {0x00, item},
    flowerpot_bag_index = {0x02, uint8},
})

-- Uproot Flowerpot
types.outgoing[0x0FE] = struct({
    flowerpot_item_id   = {0x00, item},
    flowerpot_bag_index = {0x02, uint8},
    -- 0x03: Value of 1 observed.
})

-- Job Change
types.outgoing[0x100] = struct({
    main_job_id         = {0x00, job},
    sub_job_id          = {0x01, job},
})

-- Untraditional Equip
-- Currently only commented for changing instincts in Monstrosity. Refer to the doku wiki for information on Autos/BLUs. #BYRTH#
-- https://gist.github.com/nitrous24/baf9980df69b3dc7d3cf
types.outgoing[0x102] = struct({
    -- 0x00~0x01: 00 00 for Monipulators
    -- 0x02~0x03: Varies by Monster family for the species change packet. Monipulators that share the same tnl seem to have the same value. 00 00 for instinct changing.
    main_job_id         = {0x04, job}, -- 00x17 for Monipulators
    sub_job_id          = {0x05, job}, -- 00x00 for Monipulators
    flag                = {0x06, uint16}, -- 04 00 for Monipulators changing instincts. 01 00 for changing Monipulators. Possibly the type byte.
    species             = {0x08, uint16}, -- True both for species change and instinct change packets
    -- 0x0A~0x0B: 00 00 for Monipulators
    instincts           = {0x0C, item[0x0C]},
    name_1              = {0x24, uint8}, -- Indicates your monster's first name
    name_2              = {0x25, uint8}, -- Indicates your moster's middle name
    -- 0x25~*: All 00s for Monipulators
})

-- Open Bazaar
-- Sent when you open someone's bazaar from the /check window
types.outgoing[0x105] = struct({
    target_id           = {0x00, entity},
    target_index        = {0x04, entity_index},
})

-- Bid Bazaar
-- Sent when you bid on an item in someone's bazaar
types.outgoing[0x106] = struct({
    bag_index           = {0x00, uint8}, -- The seller's inventory index of the wanted item
    count               = {0x04, uint32},
})

-- Close own Bazaar
-- Sent when you close your bazaar window
types.outgoing[0x109] = struct({ })

-- Bazaar price set
-- Sent when you set the price of an item in your bazaar
types.outgoing[0x10A] = struct({
    bag_index           = {0x00, uint8}, -- The seller's inventory index of the wanted item
    price               = {0x04, uint32},
})

-- Open own Bazaar
-- Sent when you attempt to open your bazaar to set prices
types.outgoing[0x10B] = struct({
    _known1             = {0x00, uint32, const=0},
})

-- Start RoE Quest
types.outgoing[0x10C] = struct({
    roe_quest_id        = {0x00, roe_quest},
})

-- Cancel RoE Quest
types.outgoing[0x10D] = struct({
    roe_quest_id        = {0x00, roe_quest},
})

-- Accept RoE Quest reward that was denied due to a full inventory
types.outgoing[0x10E] = struct({
    roe_quest_id        = {0x00, roe_quest},
})

-- Currency Menu
types.outgoing[0x10F] = struct({ })

-- Fishing Minigame Action
types.outgoing[0x110] = struct({
    player_id           = {0x00, entity},
    fish_hp             = {0x04, uint32}, -- catch = remaining fish hp %, release = 200, release before hook = 201, time out = 300, time warning = seconds remaining, otherwise zero
    player_index        = {0x08, entity_index},
    action_type         = {0x0A, uint8}, -- hook fish = 2, catch/release/time out = 3, put away rod = 4, time warning = 5
    gold_arrows         = {0x0C, uint32}, -- when catching this will match gold_arrows from the incoming 0x115 packet, otherwise zero
})

-- Lockstyle
types.outgoing[0x111] = struct({
    lock                = {0x00, bool}, -- 0 = unlock, 1 = lock
})

-- ROE quest log request
types.outgoing[0x112] = struct({ })

-- Homepoint Map Trigger :: 4 bytes, sent when entering a specific zone's homepoint list to cause maps to appear.
types.outgoing[0x114] = struct({ })

-- Currency 2 Menu
types.outgoing[0x115] = struct({ })

-- Open Unity Menu :: Two of these are sent whenever I open my unity menu. The first one has a bool of 0 and the second of 1.
types.outgoing[0x116] = struct({
    is_second_packet    = {0x00, bool},
})

-- Unity Ranking Results  :: Sent when I open my Unity Ranking Results menu. Triggers a Sparks Update packet and may trigger ranking packets that I could not record.
types.outgoing[0x117] = struct({ })

-- Open Chat status
types.outgoing[0x118] = struct({
    chat_status         = {0x00, bool}, -- 0 for Inactive and 1 for Active
})

return types

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
