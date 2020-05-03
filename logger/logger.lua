local account = require('account')
local chat = require('core.chat')
local ffi = require('ffi')
local file = require('file')
local os = require('os')
local string = require('string.ext')
local unicode = require('core.unicode')
local windower = require('core.windower')

ffi.cdef[[
    bool CreateDirectoryW(wchar_t*, void*);
    int GetLastError();
]]

local C = ffi.C

local log_file = nil
local log_day = nil

local base_path = windower.user_path .. '\\'
C.CreateDirectoryW(unicode.to_utf16(base_path .. '..'), nil)
C.CreateDirectoryW(unicode.to_utf16(base_path), nil)

local update_log = function()
    local dir = base_path .. account.name
    C.CreateDirectoryW(unicode.to_utf16(dir), nil)

    local date = os.date('*t')
    local file_timestamp = string.format('%.4u-%.2u-%.2u.log', date.year, date.month, date.day)

    log_file = file.new(dir .. '\\' .. file_timestamp)
    log_day = date.day
end

chat.text_added:register(function(obj)
    if log_day ~= os.date('%d') then
        update_log()
    end

    log_file:log(obj.text:trim())
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
