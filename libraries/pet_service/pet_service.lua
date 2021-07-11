local math = require('math')
local ffi = require('ffi')

local packet = require('packet')
local server = require('shared.server')
local struct = require('struct')

local item_type = struct.struct({
    item_id = {struct.int32},
    raw     = {struct.int32},
})

local data = server.new(struct.struct({
    index           = {struct.int32},
    id              = {struct.int32},
    name            = {struct.string(0x10)},
    owner_index     = {struct.int32},
    owner_id        = {struct.int32},
    target_id       = {struct.int32},
    hp_percent      = {struct.int32},
    mp_percent      = {struct.int32},
    tp              = {struct.int32},
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
        hp                  = {struct.int32},
        hp_max              = {struct.int32},
        mp                  = {struct.int32},
        mp_max              = {struct.int32},
        melee               = {struct.int32},
        melee_max           = {struct.int32},
        ranged              = {struct.int32},
        ranged_max          = {struct.int32},
        magic               = {struct.int32},
        magic_max           = {struct.int32},
        str                 = {struct.int32},
        str_modifier        = {struct.int32},
        dex                 = {struct.int32},
        dex_modifier        = {struct.int32},
        vit                 = {struct.int32},
        vit_modifier        = {struct.int32},
        agi                 = {struct.int32},
        agi_modifier        = {struct.int32},
        int                 = {struct.int32},
        int_modifier        = {struct.int32},
        mnd                 = {struct.int32},
        mnd_modifier        = {struct.int32},
        chr                 = {struct.int32},
        chr_modifier        = {struct.int32},
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

--[[
Copyright © 2020, Windower Dev Team
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
