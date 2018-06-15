local structs = require('structs')

local struct = structs.struct

local multiple = function(info)
    info.multiple = true
    return info
end

local tag = structs.tag
local string = structs.string
local data = structs.data
local encoded = structs.encoded

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

local bit = structs.bit
local boolbit = structs.boolbit

local time = structs.time

local entity = tag(uint32, 'entity')
local entity_index = tag(uint16, 'entity_index')
local zone = tag(uint16, 'zone')
local weather = tag(uint8, 'weather')
local state = tag(uint8, 'state')
local job = tag(uint8, 'job')
local race = tag(uint8, 'race')
local percent = tag(uint8, 'percent')
local bag = tag(uint8, 'bag')
local slot = tag(uint8, 'slot')
local item = tag(uint16, 'item')
local item_status = tag(uint8, 'item_status')
local flags = tag(uint32, 'flags')
local title = tag(uint16, 'title')
local nation = tag(uint8, 'nation') -- 0 sandy, 1 bastok, 2 windy
local status_effect = tag(uint8, 'status_effect')
local indi = tag(uint8, 'indi')
local ip = tag(uint32, 'ip')

local pc_name = string(0x10)

local ls_name = encoded(0x10, 6, '\x00abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
local item_inscription = encoded(0x0C, 6, '\x000123456798ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{')
local ls_name_extdata = encoded(0x0C, 6, '`abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')

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
    face                = {0x00, uint8},
    race                = {0x01, uint8},
    head                = {0x02, uint16},
    body                = {0x04, uint16},
    hands               = {0x06, uint16},
    legs                = {0x08, uint16},
    feet                = {0x0A, uint16},
    main                = {0x0C, uint16},
    sub                 = {0x0E, uint16},
    range               = {0x10, uint16},
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

local unity = struct({
    -- 0=None, 1=Pieuje, 2=Ayame, 3=Invincible Shield, 4=Apururu, 5=Maat, 6=Aldo, 7=Jakoh Wahcondalo, 8=Naja Salaheem, 9=Flavira
    id                  = {0x00, bit(uint32, 5), offset=0},
    points              = {0x00, bit(uint32, 16), offset=10},
})

local job_point_info = struct({
    capacity_points     = {0x00, uint16},
    job_points          = {0x02, uint16},
    job_points_spent    = {0x04, uint16},
})

local types = {
    incoming = {},
    outgoing = {},
}

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
    state               = {0x1B, state},
    zone                = {0x2C, zone},
    timestamp_1         = {0x34, time},
    timestamp_2         = {0x38, time},
    _dupe_zone          = {0x3E, zone},
    model               = {0x40, model},
    day_music           = {0x52, uint16},
    night_music         = {0x54, uint16},
    solo_combat_music   = {0x56, uint16},
    party_combat_music  = {0x58, uint16},
    menu_zone           = {0x5E, uint16},
    menu_id             = {0x60, uint16},
    weather             = {0x64, weather},
    player_name         = {0x80, pc_name},
    abyssea_timestamp   = {0x9C, time},
    zone_model          = {0xA6, uint16},
    main_job_id         = {0xB0, job},
    sub_job_id          = {0xB3, job},
    job_levels          = {0xB8, uint8[0x10], lookup='jobs'},
    stats_base          = {0xC8, stats},
    stats_bonus         = {0xD6, stats},
    max_hp              = {0xE4, uint32},
    max_mp              = {0xE8, uint32},
})

-- Zone Response
types.incoming[0x00B] = struct({
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
    state               = {0x1B, state},
    flags               = {0x1C, flags},
    linkshell_red       = {0x20, uint8},
    linkshell_green     = {0x21, uint8},
    linkshell_blue      = {0x22, uint8},
    face_flags          = {0x3F, uint8}, -- 0, 3, 4 or 8
    model               = {0x44, model},
    name                = {0x56, string()},
})

-- Job Info
types.incoming[0x01B] = struct({
    main_job_id         = {0x04, job},
    -- 09: Flags or main job level?
    -- 0A: Flags or sub job level?
    sub_job_id          = {0x07, job},
    sub_job_unlocked    = {0x08, boolbit(uint32)},
    sub_jobs_unlocked   = {0x08, boolbit(uint32, 0x16), offset=1},
    job_levels_pre_toau = {0x0C, uint8[0x10], lookup='jobs'},
    stats_base          = {0x1C, stats}, -- Altering these stat values has no impact on your equipment menu.
    hp_max              = {0x38, uint32},
    mp_max              = {0x3C, uint32},
    job_levels          = {0x40, uint8[0x18], lookup='jobs'},
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
    size                = {0x00, uint8[13], lookup='bags'},
    -- These "dupe" sizes are set to 0 if the inventory disabled.
    -- storage: The accumulated storage from all items (uncapped) -1
    -- wardrobe 3/4: This is not set to 0 despite being disabled for whatever reason
    other_size          = {0x10, uint16[13], lookup='bags'},
})

-- Finish Inventory
types.incoming[0x01D] = struct({
    flag                = {0x00, uint8, const=0x01},
})

-- Modify Inventory
types.incoming[0x01E] = struct({
    count               = {0x00, uint32},
    bag                 = {0x04, bag},
    bag_index           = {0x05, uint8},
    status              = {0x06, item_status},
})

-- Item Assign
types.incoming[0x01F] = struct({
    count               = {0x00, uint32},
    item_id             = {0x04, item},
    bag                 = {0x06, bag},
    bag_index           = {0x07, uint8},
    status              = {0x08, item_status},
})

-- Item Updates
types.incoming[0x020] = struct({
    count               = {0x00, uint32},
    bazaar              = {0x04, uint32},
    item_id             = {0x08, item},
    bag                 = {0x0A, bag},
    bag_index           = {0x0B, uint8},
    status              = {0x0C, item_status},
    extdata             = {0x0D, data(24)},
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
    state               = {0x2C, state},
    linkshell_red       = {0x2D, uint8},
    linkshell_green     = {0x2E, uint8},
    linkshell_blue      = {0x2F, uint8},
    pet_index           = {0x30, bit(uint32, 16), offset=3}, -- From 0x08 of byte 0x34 to 0x04 of byte 0x36
    ballista_stuff      = {0x30, bit(uint32, 9), offset=21}, -- The first few bits seem to determine the icon, but the icon appears to be tied to the type of fight, so it's more than just an icon.
    time_offset_maybe   = {0x38, uint32}, -- For me, this is the number of seconds in 66 hours
    timestamp           = {0x3C, uint32}, -- This is 32 years off of JST at the time the packet is sent.
    status_effect_mask  = {0x48, data(8)},
    indi_status_effect  = {0x54, indi},
})

-- Equipment
types.incoming[0x050] = struct({
    bag_index           = {0x00, uint8},
    slot_id             = {0x01, slot},
    bag_id              = {0x02, bag},
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
    title               = {0x40, title},
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
    combat_skills       = {0x7C, combat_skill[0x30], lookup='skills', lookup_index=0x00},
    crafting_skills     = {0xDC, crafting_skill[0x0A], lookup='skills', lookup_index=0x30},
})

-- Set Update
-- This packet likely varies based on jobs, but currently I only have it worked out for Monstrosity.
-- It also appears in three chunks, so it's double-varying.
-- Packet was expanded in the March 2014 update and now includes a fourth packet, which contains CP values.
types.incoming[0x063] = multiple({
    base = struct({
        type            = {0x00, uint16},
    }),
    lookups = {'type'},
    [0x02] = struct({
        flags           = {0x02, data(7)}, -- The 3rd bit of the last byte is the flag that indicates whether or not you are xp capped (blue levels)
    }),
    [0x03] = struct({
        flags1          = {0x02, data(2)}, -- Consistently D8 for me
        flags2          = {0x04, data(2)}, -- Vary when I change species
        flags3          = {0x06, data(2)}, -- Consistent across species
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
        job_points      = {0x08, job_point_info[0x18], lookup='jobs'}
    }),
    [0x09] = struct({
        status_effects  = {0x04, uint16[0x20]},
        durations       = {0x44, time[0x20]},
    }),
})

types.incoming[0x076] = struct({
    party_members       = {0x00, party_status_effects[5]},
})

-- LS Message
types.incoming[0x0CC] = struct({
    flags               = {0x00, flags},
    message             = {0x04, string(0x80)},
    timestamp           = {0x84, time},
    player_name         = {0x88, pc_name},
    permissions         = {0x94, data(4)},
    linkshell_name      = {0x98, ls_name},
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

return types
