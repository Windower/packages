local bit = require('bit')
local chat = require('core.chat')
local list = require('list');
local os = require('os')
local settings = require('settings')
local string = require('string')
local table = require('table')

local defaults = {
    format = '[%H:%M:%S]',
    color = 0xCF,
}

local timestamp_format

do
    local band = bit.band
    local bor = bit.bor
    local rshift = bit.rshift
    local string_char = string.char

    settings.settings_change:register(function(options)
        -- TODO: Export color reading code to a lib?
        local color = options.color
        if color < 1 or color > 0x1FF then
            error('Invalid color specified for the timestamp. Color must be between 1 and 511.')
        end

        if color == 0x101 then
            color = 1
        end

        local codepoint
        if color < 0x100 then
            codepoint = 0xF700 + color
        else
            codepoint = 0xF500 + color
        end

        local color_string = string_char(bor(0xE0, rshift(codepoint, 12)), bor(0x80, band(rshift(codepoint, 6), 0x3F)), bor(0x80, band(codepoint, 0x3F)))
        timestamp_format = color_string .. options.format .. '\u{F601} '
    end)
end

settings.load(defaults, true)

do
    local os_date = os.date
    local os_time = os.time
    local string_gmatch = string.gmatch
    local table_concat = table.concat

    chat.text_added:register(function(obj)
        local format = timestamp_format

        -- This type adjustment prevents the game from indenting newlines before the timestamp is added
        if obj.type == 150 then
            obj.type = 151
        end

        if obj.indented then
            obj.indented = false
            format = format .. '\u{3000}'
        end

        local time = os_date(format, os_time())
        local lines = list()
        for line in string_gmatch(obj.text, '[^\r\n\x07]+') do
            lines:add(line)
        end

        obj.text = table_concat(lines:select(function(line) return time .. line end):to_list(), '\n')
    end)
end

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
