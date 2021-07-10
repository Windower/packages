local math = require('math')
local ffi = require('ffi')

local packet = require('packet')
local server = require('shared.server')
local struct = require('struct')

local item_type = struct.struct({
    item_id = {struct.uint16},
    raw     = {struct.uint8},
})

local data = server.new(struct.struct({
    index           = {struct.uint16},
    id              = {struct.uint32},
    name            = {struct.string(0x10)},
    owner_index     = {struct.uint16},
    owner_id        = {struct.uint32},
    target_id       = {struct.uint32},
    hp_percent      = {struct.uint8},
    mp_percent      = {struct.uint8},
    tp              = {struct.uint32},
    active          = {struct.bool},
    automaton       = {struct.struct({
        active              = {struct.bool},
        head                = {item_type},
        frame               = {item_type},
        attachments         = {item_type[12]},
        available_heads     = {struct.bitfield(4)},
        available_frames    = {struct.bitfield(4)},
        available_attach    = {struct.bitfield(32)},
        name                = {struct.string(0x10)},
        hp                  = {struct.uint16},
        hp_max              = {struct.uint16},
        mp                  = {struct.uint16},
        mp_max              = {struct.uint16},
        melee               = {struct.uint16},
        melee_max           = {struct.uint16},
        ranged              = {struct.uint16},
        ranged_max          = {struct.uint16},
        magic               = {struct.uint16},
        magic_max           = {struct.uint16},
        str                 = {struct.uint16},
        str_modifier        = {struct.uint16},
        dex                 = {struct.uint16},
        dex_modifier        = {struct.uint16},
        vit                 = {struct.uint16},
        vit_modifier        = {struct.uint16},
        agi                 = {struct.uint16},
        agi_modifier        = {struct.uint16},
        int                 = {struct.uint16},
        int_modifier        = {struct.uint16},
        mnd                 = {struct.uint16},
        mnd_modifier        = {struct.uint16},
        chr                 = {struct.uint16},
        chr_modifier        = {struct.uint16},
    })}
}))

packet.incoming:register_init({
    [{0x037}] = function(p) -- While this packet is mostly player data, it does occassionally update the pet index when no other pet related packet is sent. For example, when moving into zones where the pet is supressed, such as cities and towns, this packet will set the pet index to 0.
        data.index = p.pet_index
        if p.pet_index and p.pet_index ~= 0 then
            data.active = true
        else
            data.active = false
        end
    end,
    [{0x067}] = function(p)
        if p.type == 4 then
            data.index = p.pet_index
            data.id = p.pet_id
            data.owner_index = p.owner_index
            data.hp_percent = p.hp_percent
            data.mp_percent = p.mp_percent
            data.tp = p.pet_tp
            if p.pet_index and p.pet_index ~= 0 then
                data.active = true
            else
                data.active = false
            end
        end
    end,
    [{0x068}] = function(p)
        if p.type == 4 then
            data.owner_index = p.owner_index
            data.owner_id = p.owner_id
            data.index = p.pet_index
            data.hp_percent = p.hp_percent
            data.mp_percent = p.mp_percent
            data.tp = p.pet_tp
            data.target_id = p.target_id
            data.name = p.pet_name
            if p.pet_index and p.pet_index ~= 0 then
                data.active = true
            else
                data.active = false
            end
        end
    end,
    [{0x044,0x12}] = function(p)

        data.automaton.head.raw         = p.automaton_head
        data.automaton.head.item_id     = p.automaton_head + 0x2000
        data.automaton.frame.raw        = p.automaton_frame
        data.automaton.frame.item_id    = p.automaton_frame + 0x2000
        for i=0, 11 do
            data.automaton.attachments[i].raw = p.attachments[i]
            data.automaton.attachments[i].item_id = p.attachments[i] + 0x2100
        end
        ffi.copy(data.automaton._available_heads, p._available_heads, 4)
        ffi.copy(data.automaton._available_frames, p._available_frames, 4)
        ffi.copy(data.automaton._available_attach, p._available_attach, 32)
        data.automaton.name             = p.pet_name
        data.automaton.hp               = p.hp
        data.automaton.hp_max           = p.hp_max
        data.automaton.mp               = p.mp
        data.automaton.mp_max           = p.mp_max
        data.automaton.melee            = p.melee
        data.automaton.melee_max        = p.melee_max
        data.automaton.ranged           = p.ranged
        data.automaton.ranged_max       = p.ranged_max
        data.automaton.magic            = p.magic
        data.automaton.magic_max        = p.magic_max
        data.automaton.str              = p.str
        data.automaton.str_modifier     = p.str_modifier
        data.automaton.dex              = p.dex
        data.automaton.dex_modifier     = p.dex_modifier
        data.automaton.vit              = p.vit
        data.automaton.vit_modifier     = p.vit_modifier
        data.automaton.agi              = p.agi
        data.automaton.agi_modifier     = p.agi_modifier
        data.automaton.int              = p.int
        data.automaton.int_modifier     = p.int_modifier
        data.automaton.mnd              = p.mnd
        data.automaton.mnd_modifier     = p.mnd_modifier
        data.automaton.chr              = p.chr
        data.automaton.chr_modifier     = p.chr_modifier

        local active = data.active and (data.name == data.automaton.name)

        data.automaton.active = active

        if p.hp_max ~= 0 and active then
            data.hp_percent = math.floor(100 * p.hp / p.hp_max)
        end
        if p.mp_max ~= 0 and active then
            data.mp_percent = math.floor(100 * p.mp / p.mp_max)
        end
    end
})
