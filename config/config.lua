local memory = require('memory')
local settings = require('settings')
local math = require('math')

local defaults = {
    gameplay = {
        auto_target = true,
        inventory = {
            sort = false,
            type = 1,
        },
    },
    graphics = {
        aspect_ratio = {
            auto = false,
            value = 1.778,
        },
        gamma_adjustment = {
            red = 1.5,
            green = 1.5,
            blue = 1.5,
        },
        framerate = 60,
        animation_framerate = 60,
        clipping_plane = 10,
    },
    audio = {
        volume = {
            effects = 1.0,
            music = 1.0,
        },
        footstep_effects = true,
    },
    system = {
        auto_disconnect = {
            enabled = false,
            time = 60,
        }
    },
}

local options = settings.load(defaults)

coroutine.schedule(function()
    while true do
        do -- misc2_graphics
            local struct = memory.misc2_graphics
            local options = options.graphics

            local aspect_ratio = options.aspect_ratio

            struct.render.aspect_ratio = (4 / 3) / (aspect_ratio.auto and (x / y) or aspect_ratio.value)
            struct.render.framerate_divisor = options.framerate == 'unlimited' and 0 or math.ceil(60 / options.framerate)
            struct.clipping_plane_entity = options.clipping_plane
            struct.clipping_plane_map = options.clipping_plane
        end

        do -- auto_disconnect
            local struct = memory.auto_disconnect
            local options = options.system
            
            local auto_disconnect = options.auto_disconnect

            struct.enabled = auto_disconnect.enabled
            struct.timeout_time = auto_disconnect.time
        end

        do -- gamma_adjustment
            local struct = memory.gamma_adjustment
            local options = options.graphics

            local gamma_adjustment = options.gamma_adjustment

            struct.red = gamma_adjustment.red
            struct.green = gamma_adjustment.green
            struct.blue = gamma_adjustment.blue
        end

        coroutine.sleep_frame()
    end
end)

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
