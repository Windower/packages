local chat = require('chat')
local sets = require('sets')
local string = require('string')
local target = require('target')

local blacklist = sets({
    'Paintbrush of Souls', -- Requires correct timing, should not be skipped
    'Geomantic Reservoir', -- Causes dialogue freeze for some reason
})

local prompt = '\u{F800}'
local prompt_length = #prompt

do
    local string_sub = string.sub

    chat.text_added:register(function(obj)
        if (obj.type == 150 or obj.type == 151) and string_sub(obj.text, -prompt_length) == prompt then
            local current_target = target.t
            if not (current_target and blacklist:contains(current_target.name)) then
                obj.text = string_sub(obj.text, 1, -prompt_length - 1)
            end
        end
    end)
end
