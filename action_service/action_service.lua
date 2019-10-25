local event = require('core.event')
local ffi = require("ffi")
local packets = require('packets')
local shared = require('core.shared')

service = shared.new('service')

service.data = {
    filter_action   = event.new(),
    pre_action      = event.new(),
    mid_action      = event.new(),
    post_action     = event.new(),
}

service.env = {}

local filter_action_event = service.data.filter_action
local pre_action_event = service.data.pre_action
local mid_action_event = service.data.mid_action
local post_action_event = service.data.post_action

-- Constants
ffi.cdef[[
struct outgoing_category_constants {
    static const int MAGIC_CAST = 3;
    static const int WEAPON_SKILL = 7;
    static const int JOB_ABILITY = 9;
    static const int RANGED_ATTACK = 16;
};

struct incoming_category_constants {
    static const int RANGED_ATTACK = 2;
    static const int WEAPON_SKILL = 3;
    static const int MAGIC_CAST = 4;
    static const int ITEM_USE = 5;
    static const int JOB_ABILITY = 6;
    static const int PET_WEAPON_SKILL = 13;
    static const int JOB_ABILITY_2 = 14;
    static const int JOB_ABILITY_3 = 15;
};]]
local cat_out = ffi.new("struct outgoing_category_constants")
local cat_in = ffi.new("struct incoming_category_constants")

local blocked = false
service.env.block = function()
    blocked = true
end

local handle_outgoing_action = function(p, info)
    if not (info.injected or info.blocked) and
            (p.action_category == cat_out.MAGIC_CAST or
            p.action_category == cat_out.WEAPON_SKILL or
            p.action_category == cat_out.JOB_ABILITY or
            p.action_category == cat_out.RANGED_ATTACK) then

        local packet = p
        packets.block()

        blocked = false

        filter_action_event:trigger(packet)

        if blocked then
            return
        end

        coroutine.schedule(function()
            pre_action_event:trigger(packet)

            packets.outgoing[0x01A]:inject(packet)

            if  p.action_category == cat_out.MAGIC_CAST or
                p.action_category == cat_out.RANGED_ATTACK then

                mid_action_event:trigger(packet)
            end
        end)
    end
end

local handle_incoming_action = function(p)
    if  (p.category >= cat_in.RANGED_ATTACK and p.category <= cat_in.JOB_ABILITY) or
        (p.category >= cat_in.PET_WEAPON_SKILL and p.category <= cat_in.JOB_ABILITY_3) then

        local packet = p

        coroutine.schedule(function()
            post_action_event:trigger(packet)
        end)
    end
end

packets.outgoing[0x01A]:register(handle_outgoing_action)
packets.incoming[0x028]:register(handle_incoming_action)

--[[
Copyright © 2019, Windower Dev Team
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
