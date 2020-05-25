local math = require('math')
local memory = require('memory')
local settings = require('settings')
local windower = require('core.windower')

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
            auto = true,
            value = 16 / 9,
        },
        gamma = {
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
        },
        language_filter = {
            enabled = false,
        },
    },
}

local options = settings.load(defaults)

local window_aspect_ratio = (4 / 3) / (windower.settings.client_size.width / windower.settings.client_size.height)

local math_ceil = math.ceil

coroutine.schedule(function()
    while true do
        do -- graphics
            local graphics = memory.graphics
            local gamma = graphics.gamma
            local render = graphics.render

            local graphics_options = options.graphics
            local aspect_ratio_options = graphics_options.aspect_ratio
            local gamma_options = graphics_options.gamma

            gamma.red = gamma_options.red
            gamma.green = gamma_options.green
            gamma.blue = gamma_options.blue

            render.aspect_ratio = aspect_ratio_options.auto and window_aspect_ratio or ((4 / 3) / aspect_ratio_options.value)
            render.framerate_divisor = graphics_options.framerate == 'unlimited' and 0 or math_ceil(60 / graphics_options.framerate)

            graphics.clipping_plane_entity = graphics_options.clipping_plane
            graphics.clipping_plane_map = graphics_options.clipping_plane
        end

        do -- system
            local auto_disconnect = memory.auto_disconnect
            local language_filter = memory.language_filter

            local system_options = options.system
            local auto_disconnect_options = system_options.auto_disconnect
            local language_filter_options = system_options.language_filter

            auto_disconnect.enabled = auto_disconnect_options.enabled
            auto_disconnect.timeout_time = auto_disconnect_options.time

            language_filter.disabled = not language_filter_options.enabled
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
