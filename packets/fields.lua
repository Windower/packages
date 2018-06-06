local structs = require('structs')

local struct = structs.struct

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

local pc_name = string(0x10)

local ls_name = encoded(0x10, 6, '\x00abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ')
local item_inscription = encoded(0x0C, 6, '\x000123456798ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz{')
local ls_name_extdata = encoded(0x0C, 6, '`abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00')

local stats = struct {
    str                 = {0x00, int16},
    dex                 = {0x02, int16},
    vit                 = {0x04, int16},
    agi                 = {0x06, int16},
    int                 = {0x08, int16},
    mnd                 = {0x0A, int16},
    chr                 = {0x0C, int16},
}

local model = struct {
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
}

local resistances = struct {
    fire                = {0x34, uint16},
    wind                = {0x36, uint16},
    lightning           = {0x38, uint16},
    light               = {0x3A, uint16},
    ice                 = {0x3C, uint16},
    earth               = {0x3E, uint16},
    water               = {0x40, uint16},
    dark                = {0x42, uint16},
}

local combat_skill = struct {
    level               = {0x00, bit(uint16, 15), offset=0},
    capped              = {0x00, boolbit(uint16), offset=15},
}

local crafting_skill = struct {
    level               = {0x00, bit(uint16, 5), offset=0},
    rank_id             = {0x00, bit(uint16, 10), offset=5},
    capped              = {0x00, boolbit(uint16), offset=15},
}

local party_status_effects   = struct {
    id                  = {0x00, entity},
    index               = {0x04, entity_index},
    status_effect_mask  = {0x08, data(8)},
    status_effects      = {0x10, status_effect[0x20]},
}

local unity = struct {
    -- 0=None, 1=Pieuje, 2=Ayame, 3=Invincible Shield, 4=Apururu, 5=Maat, 6=Aldo, 7=Jakoh Wahcondalo, 8=Naja Salaheem, 9=Flavira
    id                  = {0x00, bit(uint32, 5), offset=0},
    points              = {0x00, bit(uint32, 16), offset=10},
}

local fields = {
    incoming = {},
    outgoing = {},
}

-- Zone update
fields.incoming[0x00A] = struct {
    player_id           = {0x04, entity},
    player_index        = {0x08, entity_index},
    heading             = {0x0B, uint8},
    x                   = {0x0C, float},
    z                   = {0x10, float},
    y                   = {0x14, float},
    run_count           = {0x18, uint16},
    target_index        = {0x1A, entity_index},
    movement_speed      = {0x1C, uint8},
    animation_speed     = {0x1D, uint8},
    hp_percent          = {0x1E, percent},
    state               = {0x1F, state},
    zone                = {0x30, zone},
    timestamp_1         = {0x38, time},
    timestamp_2         = {0x3C, time},
    _dupe_zone          = {0x42, zone},
    model               = {0x44, model},
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
    main_job_id         = {0xB4, job},
    sub_job_id          = {0xB7, job},
    job_levels          = {0xBC, uint8[0x10], lookup='jobs'},
    stats_base          = {0xCC, stats},
    stats_bonus         = {0xDA, stats},
    max_hp              = {0xE8, uint32},
    max_mp              = {0xEC, uint32},
}

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
fields.incoming[0x00D] = struct {
    player_id           = {0x04, entity},
    player_index        = {0x08, entity_index},
    update_position     = {0x0A, boolbit(uint8), offset=0}, -- Position, Rotation, Target, Speed
    update_status       = {0x0A, boolbit(uint8), offset=1}, -- Not used for 0x00D
    update_vitals       = {0x0A, boolbit(uint8), offset=2}, -- HP%, Status, Flags, LS color, "Face Flags"
    update_name         = {0x0A, boolbit(uint8), offset=3}, -- Name
    update_model        = {0x0A, boolbit(uint8), offset=4}, -- Race, Face, Gear models
    despawn             = {0x0A, boolbit(uint8), offset=5}, -- Only set if player runs out of range or zones
    heading             = {0x0B, uint8},
    x                   = {0x0C, float},
    z                   = {0x10, float},
    y                   = {0x14, float},
    run_count           = {0x18, bit(uint16, 13), offset=0},
    target_index        = {0x1A, bit(entity_index, 15), offset=1},
    movement_speed      = {0x1C, uint8}, -- 32 represents 100%
    animation_speed     = {0x1D, uint8}, -- 32 represents 100%
    hp_percent          = {0x1E, percent},
    state               = {0x1F, state},
    flags               = {0x20, flags},
    linkshell_red       = {0x24, uint8},
    linkshell_green     = {0x25, uint8},
    linkshell_blue      = {0x26, uint8},
    face_flags          = {0x43, uint8}, -- 0, 3, 4 or 8
    model               = {0x48, model},
    name                = {0x5A, string()},
}

-- Job Info
fields.incoming[0x01B] = struct {
    main_job_id         = {0x08, job},
    -- 09: Flags or main job level?
    -- 0A: Flags or sub job level?
    sub_job_id          = {0x0B, job},
    sub_job_unlocked    = {0x0C, boolbit(uint32)},
    sub_jobs_unlocked   = {0x0C, boolbit(uint32, 0x16), offset=1},
    job_levels_pre_toau = {0x10, uint8[0x10], lookup='jobs'},
    stats_base          = {0x20, stats}, -- Altering these stat values has no impact on your equipment menu.
    hp_max              = {0x3C, uint32},
    mp_max              = {0x40, uint32},
    job_levels          = {0x44, uint8[0x18], lookup='jobs'},
    monster_level       = {0x5F, uint8},
    encumbrance_flags   = {0x60, uint32}, -- [legs, hands, body, head, ammo, range, sub, main,] [back, right_ring, left_ring, right_ear, left_ear, waist, neck, feet] [HP, CHR, MND, INT, AGI, VIT, DEX, STR,] [X X X X X X X MP]
}

-- Inventory Count
-- It is unclear why there are two representations of the size for this.
-- I have manipulated my inventory size on a mule after the item update packets have
-- all arrived and still did not see any change in the second set of sizes, so they
-- may not be max size/used size chars as I initially assumed. Adding them as shorts
-- for now.
-- There appears to be space for another 8 bags.
fields.incoming[0x01C] = struct {
    size                = {0x04, uint8[13], lookup='bags'},
    -- These "dupe" sizes are set to 0 if the inventory disabled.
    -- storage: The accumulated storage from all items (uncapped) -1
    -- wardrobe 3/4: This is not set to 0 despite being disabled for whatever reason
    other_size          = {0x14, uint16[13], lookup='bags'},
}

-- Finish Inventory
fields.incoming[0x01D] = struct {
    flag                = {0x04, uint8, const=0x01},
}

-- Modify Inventory
fields.incoming[0x01E] = struct {
    count               = {0x04, uint32},
    bag                 = {0x08, bag},
    bag_index           = {0x09, uint8},
    status              = {0x0A, item_status},
}

-- Item Assign
fields.incoming[0x01F] = struct {
    count               = {0x04, uint32},
    item_id             = {0x08, item},
    bag                 = {0x0A, bag},
    bag_index           = {0x0B, uint8},
    status              = {0x0C, item_status},
}

-- Item Updates
fields.incoming[0x020] = struct {
    count               = {0x04, uint32},
    bazaar              = {0x08, uint32},
    item_id             = {0x0C, item},
    bag                 = {0x0E, bag},
    bag_index           = {0x0F, uint8},
    status              = {0x10, item_status},
    extdata             = {0x11, data(24)},
}

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
fields.incoming[0x037] = struct {
    status_effects      = {0x04, status_effect[0x20]},
    player_id           = {0x24, entity},
    hp_percent          = {0x2A, percent},
    movement_speed_half = {0x2C, bit(uint16, 12), offset=0},
    yalms_per_step      = {0x2E, bit(uint16, 9), offset=0}, -- Determines how quickly your animation walks
    state               = {0x30, state},
    linkshell_red       = {0x31, uint8},
    linkshell_green     = {0x32, uint8},
    linkshell_blue      = {0x33, uint8},
    pet_index           = {0x34, bit(uint32, 16), offset=3}, -- From 0x08 of byte 0x34 to 0x04 of byte 0x36
    ballista_stuff      = {0x34, bit(uint32, 9), offset=21}, -- The first few bits seem to determine the icon, but the icon appears to be tied to the type of fight, so it's more than just an icon.
    time_offset_maybe   = {0x3C, uint32}, -- For me, this is the number of seconds in 66 hours
    timestamp           = {0x40, uint32}, -- This is 32 years off of JST at the time the packet is sent.
    status_effect_mask  = {0x4C, data(8)},
    indi_status_effect  = {0x58, indi},
}

-- Equipment
fields.incoming[0x050] = struct {
    bag_index           = {0x04, uint8},
    slot_id             = {0x05, slot},
    bag_id              = {0x06, bag},
}

-- Char Stats
fields.incoming[0x061] = struct {
    hp_max              = {0x04, uint32},
    mp_max              = {0x08, uint32},
    main_job_id         = {0x0C, job},
    main_job_level      = {0x0D, uint8},
    sub_job_id          = {0x0E, job},
    sub_job_level       = {0x0F, uint8},
    exp                 = {0x10, uint16},
    exp_required        = {0x12, uint16},
    stats_base          = {0x14, stats},
    stats_bonus         = {0x22, stats},
    attack              = {0x30, uint16},
    defense             = {0x32, uint16},
    resistance          = {0x34, resistances},
    title               = {0x44, title},
    nation_rank         = {0x46, uint16},
    nation_rank_points  = {0x48, uint16}, -- Capped at 0xFFF
    home_point_zone_id  = {0x4A, zone},
    nation_id           = {0x50, nation},
    superior_level      = {0x52, uint8},
    item_level_max      = {0x54, uint8},
    item_level_over_99  = {0x55, uint8},
    item_level_main     = {0x56, uint8},
    unity               = {0x51, unity},
}

-- Skills Update
fields.incoming[0x062] = struct {
    combat_skills       = {0x80, combat_skill[0x30], lookup='skills', lookup_index=0x00},
    crafting_skills     = {0xE0, crafting_skill[0x0A], lookup='skills', lookup_index=0x30},
}

-- Party Status Effects
fields.incoming[0x076] = struct {
    party_members       = {0x04, party_status_effects[5]},
}

-- LS Message
fields.incoming[0x0CC] = struct {
    flags               = {0x04, flags},
    message             = {0x08, string(0x80)},
    timestamp           = {0x88, time},
    player_name         = {0x8C, pc_name},
    permissions         = {0x98, data(4)},
    linkshell_name      = {0x9C, ls_name},
}

-- Char Update
fields.incoming[0x0DF] = struct {
    id                  = {0x04, entity},
    hp                  = {0x08, uint32},
    mp                  = {0x0C, uint32},
    tp                  = {0x10, uint32},
    index               = {0x14, entity_index},
    hp_percent          = {0x16, percent},
    mp_percent          = {0x17, percent},
    main_job_id         = {0x20, job},
    main_job_level      = {0x21, uint8},
    sub_job_id          = {0x22, job},
    sub_job_level       = {0x23, uint8},
}

-- Char Info
fields.incoming[0x0E2] = struct {
    id                  = {0x04, entity},
    hp                  = {0x08, uint32},
    mp                  = {0x0C, uint32},
    tp                  = {0x10, uint32},
    index               = {0x18, entity_index},
    hp_percent          = {0x1D, percent},
    mp_percent          = {0x1E, percent},
    name                = {0x22, string()},
}

return fields
