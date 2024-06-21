local command = require('core.command')
local packet = require('packet')
local resources = require('resources')
local status_effects = require('status_effects')
local string = require('string.ext')

local buffs = resources.buffs
local string_match = string.match
local string_normalize = string.normalize

local cancel = function(...)
    for _, arg in ipairs({...}) do
        local arg_norm = string_normalize(arg)

        for _, status in ipairs(status_effects.array) do
            if status.duration == 0 then
                break
            end

            local id = status.id

            if string_match(string_normalize(buffs[id].enl), arg_norm) then
                packet.outgoing[0x0F1]:inject({buff = id})
                break
            end
        end
    end
end

command.arg.register('buff', '<buff:string>')
command.new('cancel'):register(cancel, '{buff}*')

--[[
Copyright © 2022, Aliquis https://github.com/4liquis
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are
permitted provided that the following conditions are met:

    *   Redistributions of source code must retain the above copyright notice, this
        list of conditions and the following disclaimer.

    *   Redistributions in binary form must reproduce the above copyright notice,
        this list of conditions and the following disclaimer in the documentation
        and/or other materials provided with the distribution.

    *   Neither the name of the "Cancel" nor the names of its contributors may be
        used to endorse or promote products derived from this software without
        specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL ALIQUIS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
