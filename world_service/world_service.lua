local event = require('event')
local packets = require('packets')
local resources = require('resources')
local server = require('shared.server')
local structs = require('structs')

local data = server.new(structs.struct({
    zone                = {structs.int32, lookup=resources.zones},
    weather             = {structs.int32, lookup=resources.weather},
    music               = {structs.struct({
        day                 = {structs.int32},
        night               = {structs.int32},
        solo_combat         = {structs.int32},
        party_combat        = {structs.int32},
    })},
    zone_change         = {data=event.new()},
    weather_change      = {data=event.new()},
}))

data.zone = -1
data.weather = -1

local music = data.music

local zone_change_event = data.zone_change
local weather_change_event = data.weather_change

packets.incoming:register_init({
    [{0x00A}] = function(p)
        data.zone = p.zone
        data.weather = p.weather
        music.day = p.day_music
        music.night = p.night_music
        music.solo_combat = p.solo_combat_music
        music.party_combat = p.party_combat_music

        zone_change_event:trigger()
        weather_change_event:trigger()
    end,
    [{0x057}] = function(p)
        data.weather = p.weather

        weather_change_event:trigger()
    end,
    [{0x00B}] = function(p)
        data.zone = -1
        data.weather = -1
        music.day = 0
        music.night = 0
        music.solo_combat = 0
        music.party_combat = 0
    end,
})

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
