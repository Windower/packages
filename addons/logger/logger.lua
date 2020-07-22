local account = require('account')
local chat = require('core.chat')
local ffi = require('ffi')
local file = require('file')
local queue = require('queue')
local os = require('os')
local string = require('string.ext')
local win32 = require('win32')
local windower = require('core.windower')

local log_file

local update_log = function()
    if not account.logged_in then
        log_file = nil
        return
    end

    local date = os.date('*t')
    local timestamp = string.format('%.4u-%.2u-%.2u.log', date.year, date.month, date.day)

    log_file = file.new(windower.user_path .. '\\' .. account.name .. '\\' .. timestamp)
    log_file:create_directories()
end

local lines = queue() -- TODO Remove when the thing is implemented

chat.text_added:register(function(obj)
    lines:add(os.date('%X | ') .. obj.text:trim())

    if account.logged_in then
        while lines:any() do
            log_file:log(lines:pop())
        end
    end
end)

account.login:register(function()
    update_log()
end)
account.logout:register(update_log)

local start
do -- TODO os.time: Remove all of this
    local get_system_time_as_file_time = win32.def({
        name = 'GetSystemTimeAsFileTime',
        returns = 'void',
        parameters = {
            'FILETIME*',
        },
    })

    local file_time_to_local_file_time = win32.def({
        name = 'FileTimeToLocalFileTime',
        returns = 'BOOL',
        parameters = {
            'FILETIME const*',
            'FILETIME*',
        },
    })

    local utc_time = ffi.new('FILETIME')
    local local_time = ffi.new('FILETIME')

    get_system_time_as_file_time(utc_time)
    file_time_to_local_file_time(utc_time, local_time)

    local now = local_time.dwHighDateTime * 429.4967296 + local_time.dwLowDateTime / 10000000 - 11644473600
    start = now - os.clock()
end

coroutine.schedule(function()
    while true do
        coroutine.sleep(24 * 60 * 60 - (start + os.clock()) % (24 * 60 * 60))
        update_log()
    end
end)

update_log()

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
