local clipboard = require('clipboard')
local command = require('core.command')
local math = require('math')
local memory = require('memory')
local unicode = require('core.unicode')

local paste = command.new('paste')

local max_chat_size = 0x96

paste:register(function()
    local text = unicode.to_shift_jis(clipboard.get())
    if text == nil then
        return
    end

    local chat = memory.chat_input
    local original = chat.internal
    text = text:sub(1, math.max(max_chat_size - #original, 0))

    local modified = original:sub(1, chat.position_internal) .. text .. original:sub(chat.position_internal + 1)

    do -- Set internal value
        local buffer = modified
        if #buffer > max_chat_size then
            buffer = buffer:sub(1, max_chat_size)
        end

        chat.internal = buffer
        chat.length_internal = #buffer
        chat.position_internal = math.min(chat.position_internal + #text, max_chat_size)
    end

    do -- Set the stripped buffer
        local buffer = unicode.to_shift_jis(unicode.expand_autotranslate((unicode.from_shift_jis(modified)), '', ''))
        if #buffer > max_chat_size then
            buffer = buffer:sub(1, max_chat_size)
        end

        chat.stripped = buffer
        chat.length_stripped = #buffer
    end

    do -- Set the display buffer
        local buffer =
            unicode.to_shift_jis(unicode.expand_autotranslate((unicode.from_shift_jis(modified:sub(1, chat.position_internal))), '\u{F569}', '\u{F564}')) ..
            '\x7F\xFF' ..
            unicode.to_shift_jis(unicode.expand_autotranslate((unicode.from_shift_jis(modified:sub(chat.position_internal + 1))), '\u{F569}', '\u{F564}'))
        if #buffer > max_chat_size + 2 then
            buffer = buffer:sub(1, max_chat_size + 2)
        end

        chat.display = buffer
    end

    chat.update_history = true
end)

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
