local packets = require('packets')
local shared = require('shared')
local linkshell = shared.new('linkshell')

linkshell.env = {
    next = next,
}
  
linkshell.data = {
    [1] = { lsmes = { }, color = { }, },
    [2] = { lsmes = { }, },
}

local handle_0CC = function(p)
    local data = linkshell.data[p.ls_index + 1]
    data.name = p.linkshell_name
    data.lsmes.timestamp = p.timestamp
    data.lsmes.author = p.player_name
    data.lsmes.text = p.message
    data.lsmes.permissions = p.permissions
end
packets.incoming:register_init({
    [{0x0CC, 0}] = handle_0CC,
    [{0x0CC, 1}] = handle_0CC,
    [{0x037}] = function(p)
        local data = linkshell.data[1]
        data.color.red = p.linkshell1_red
        data.color.green = p.linkshell1_green
        data.color.blue = p.linkshell1_blue
    end,
    [{0x0E0}]    = function(p)
        local data = linkshell.data[p.linkshell_number]
        data.bag_index = p.bag_index
    end,
})

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
