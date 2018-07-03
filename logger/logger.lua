local string = require('string')
local windower = require('windower')
local files = require('files')
local os = require('os')
local chat = require('chat')
local account = require('account')

local log_file = nil
local log_date = nil

local get_log = function()
    local dir = windower.user_path .. '\\' .. account.name .. '\\'
    os.execute('mkdir "' .. dir .. '" >nul 2>nul')

    log_date = os.date('*t')
    local file_timestamp = string.format('%.4u.%.2u.%.2u.log', log_date.year, log_date.month, log_date.day)
    
    log_file = files.create(dir .. file_timestamp)
end

account.login:register(get_log)

account.logout:register(function ()
    log_file = nil
    log_timestamp = nil
end)

chat.text_added:register(function(obj)
    if account.logged_in then
        local date = os.date('*t')
        if log_date == nil or date.day ~= log_date.day then
            get_log()
        end

        if log_file ~= nil then
            log_file:append(obj.text, true)
        end
    end
end)

--[[
Copyright © 2018, GenericHero
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of GenericHero nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL GenericHero BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]]
