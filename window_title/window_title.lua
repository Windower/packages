local account = require('account')
local ffi = require('ffi')
local table = require('table')
local string = require('string')

local user32 = ffi.load('user32')
local kernel32 = ffi.load('kernel32')

ffi.cdef[[
    bool SetWindowTextW(void* hwnd, wchar_t const* title);
    typedef int (__stdcall *WNDENUMPROC)(void* hwnd, intptr_t l);
    bool EnumThreadWindows(uint32_t thread, WNDENUMPROC fn, intptr_t l);
    int GetClassNameW(void* hwnd, wchar_t const* name, int max_length);
    uint32_t GetCurrentThreadId();
]]

local game_window = false

--[[
    Temporary until we provide a common mechanism for wchar_t support
]]
local wstr_ctor = ffi.typeof('wchar_t[?]')
local wide = function(str)
    local wstr = wstr_ctor(#str + 1)
    for i = 1, #str do
        wstr[i - 1] = str:byte(i)
    end
    return wstr
end

local narrow = function(wchar, length)
    local str_tab = {}
    for i = 1, length do
        str_tab[i] = string.char(wchar[i - 1])
    end
    return table.concat(str_tab)
end

--[[
    Alternatively expose the game's window in core
]]
local max_class_name = 0x10

local enum_tw_cb = function(hwnd, l)
    local wide_name = wstr_ctor(max_class_name)
    local result_count = user32.GetClassNameW(hwnd, wide_name, max_class_name)
    
    assert(result_count > 0, 'Error obtaining class name for window handle.')

    if narrow(wide_name, result_count) == 'FFXiClass' then
        game_window = hwnd
        return false
    end

    return true
end

local set_window_title = function(title)
    assert(game_window, 'An error occurred finding the FFXI window.')
    assert(type(title) == 'string', 'The window title must be a string.')
    assert(user32.SetWindowTextW(game_window, wide(title)), 'Critical error occurred changing the window title.')
end

user32.EnumThreadWindows(kernel32.GetCurrentThreadId(), enum_tw_cb, 0)
set_window_title(account.logged_in and account.name or 'Final Fantasy XI')
account.login:register(function() set_window_title(account.name) end)
account.logout:register(function() set_window_title('Final Fantasy XI') end)

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
