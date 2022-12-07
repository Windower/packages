local command = require('core.command')
local packet = require('packet')
local resources = require('resources')
local status_effects = require('status_effects')
local string = require('string.ext')
local table = require('table')

local string_match = string.match
local string_normalize = string.normalize
local table_insert = table.insert

local cancel_buff = function (buff)
    buff = string_normalize(buff)

    for _, v in ipairs(status_effects.array) do
        if v.duration == 0 then
            break
        end

        v = resources.buffs[v.id]
        if string_match(string_normalize(v.en), buff) or string_match(string_normalize(v.enl), buff) then
            packet.outgoing[0x0f1]:inject{buff = v.id}
            return
        end
    end
end

command.new('cancel'):register(cancel_buff, '<buff:string>')
