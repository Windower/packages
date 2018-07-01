local packets = require('packets')
local shared = require('shared')

local linkshell = shared.new('linkshell')

-- Does this file need this?
local linkshell.env = {
    next = next,
}
  
local linkshell.data = {
    [1] = { message = { }, color = { }, },
    [2] = { message = { }, },
}

local handle_color = function(p)
local data = linkshell[1]
    data.color.red = p.linkshell_red
    data.color.green = p.linkshell_green
    data.color.blue = p.linkshell_blue
end

packets.incoming[0x0CC]:register(function(p)
    local ls_number = bit.band(p.flags, 0x40) == 0x40 and 2 or 1
    local data = linkshell[ls_number]
    data.name = p.linkshell_name
    data.message.timestamp = p.timestamp
    data.message.author = p.player_name
    data.message.text = p.message
    data.message.permissions = p.permissions
end)

packets.incoming[0x0E0]:register(function(p)
    local data = linkshell[p.linkshell_number]
    data.bag_index = p.bag_index
end)

packets.incoming[0x00D]:register(handle_color)
packets.incoming[0x037]:register(handle_color)
packets.incoming[0x0C9]:register(handle_color)

handler_color(packets.incoming[0x00D].last)
handler_color(packets.incoming[0x037].last)
handler_color(packets.incoming[0x0C9].last)

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