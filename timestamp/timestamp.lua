local bit = require('bit')
local chat = require('chat')
local os = require('os')
local settings = require('settings')
local string = require('string')

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

local options = settings.load(defaults, true)

do
    local os_date = os.date
    local os_time = os.time
    local string_gsub = string.gsub
    local string_match = string.match
    local newline_pattern = '[^\n' .. string.char(0x07) ..']+'

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
        obj.text = time .. string_gsub(obj.text, '[\n\x07]', '\n' .. time .. '\u{3000}')
    end)
end
