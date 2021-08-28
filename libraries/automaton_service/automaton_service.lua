local packet = require('packet')
local struct = require('struct')
local server = require('shared.server')


local data, ftype = server.new(struct.struct({
    name = {struct.string(0x10)};

    head_id = {struct.int32},
    frame_id = {struct.int32},
    attachments = {struct.struct({
        id = {struct.uint8},
        slot = {struct.uint8},
    })[0x0C]},

    skills = {struct.struct({
        melee = {struct.uint16},
        melee_max = {struct.uint16},
        ranged = {struct.uint16},
        ranged_max = {struct.uint16},
        magic = {struct.uint16},
        magic_max = {struct.uint16},
    })},

    stats = {struct.struct({
        str             = {struct.uint16},
        str_modifier    = {struct.uint16},
        dex             = {struct.uint16},
        dex_modifier    = {struct.uint16},
        vit             = {struct.uint16},
        vit_modifier    = {struct.uint16},
        agi             = {struct.uint16},
        agi_modifier    = {struct.uint16},
        int             = {struct.uint16},
        int_modifier    = {struct.uint16},
        mnd             = {struct.uint16},
        mnd_modifier    = {struct.uint16},
        chr             = {struct.uint16},
        chr_modifier    = {struct.uint16},
    })},

    available_heads = {struct.bitfield(4)},
    available_frames= {struct.bitfield(4)},
    available_attachments = {struct.bitfield(32)},
}))

packet.incoming:register_init({
    [{0x044, 0x12}] = function(p)
        data.name = p.pet_name
        data.head_id = p.automaton_head
        data.frame_id = p.automaton_frame

        data.skills.melee = p.melee
        data.skills.magic = p.magic
        data.skills.ranged = p.ranged
        data.skills.melee_max = p.melee_max
        data.skills.magic_max = p.magic_max
        data.skills.ranged_max = p.ranged_max

        for k, v in pairs(p.attachments) do
             data.attachments[k].id = v
             data.attachments[k].slot = k + 1
        end

        data.available_heads = p.available_heads
        data.available_frames = p.available_frames
        data.available_attachments = p.available_attach

        data.stats.chr = p.chr
        data.stats.str = p.str
        data.stats.agi = p.agi
        data.stats.mnd = p.mnd
        data.stats.vit = p.vit
        data.stats.dex = p.dex
        data.stats.chr_modifier = p.chr_modifier
        data.stats.str_modifier = p.str_modifier
        data.stats.agi_modifier = p.agi_modifier
        data.stats.mnd_modifier = p.mnd_modifier
        data.stats.vit_modifier = p.vit_modifier
        data.stats.dex_modifier = p.dex_modifier
    end,
})

--[[
Copyright © 2021, Windower Dev Team
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