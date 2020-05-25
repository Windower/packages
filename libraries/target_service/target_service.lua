local command = require('core.command')
local channel = require('core.channel')

do
    local handling = nil
    local channels = setmetatable({}, {
        __mode = 'v',
        __index = function(t, package)
            local st_channel = channel.get(package, '__sub_target_channel')
            rawset(t, package, st_channel)
            return st_channel
        end,
    })

    local search_handler = function(source, command_string)
        if source:match('^sub_target') then
            local package, counter, target_id =
                command_string:match('^/aim \u{FFFD}select_sub_target\u{FFFD} "(%w+)" (%d+) (%d+)$')
            if package and target_id then
                local tag = package .. ':' .. counter
                if handling == tag then
                    handling = nil
                    local package_channel = channels[package]
                    if package_channel then
                        package_channel:pcall(function(_, ...)
                            report_result(...)
                        end, tonumber(counter), tonumber(target_id))
                    end
                else
                    handling = tag
                end
                return
            end
        end
        command.input('/:' .. command_string:sub(2), source)
    end
    command.core.register('aim', search_handler, true)
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
