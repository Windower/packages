local command = require('command')
local account = require('account')
local ffi = require('ffi')

ffi.cdef[[
  bool SetWindowTextW(void* hWnd, wchar_t const* title);
  void* GetActiveWindow();
  ]]
  
local user32 = ffi.load('user32')

local wide = function(str)
  local ctor = ffi.typeof('wchar_t[?]')
  local wstr = ctor(#str + 1)
  for i = 1, #str do
    wstr[i - 1] = str:byte(i)
  end
  return wstr
end

local set_window_title = function(title)
  local hwnd = user32.GetActiveWindow() 
  assert(hwnd, 'Could not obtain the current window handle.')
  assert(type(title) == 'string', 'The window title must be a string.')
  assert(user32.SetWindowTextW(hwnd, wide(title)), 'Critical error occurred renaming the window.')
end

do 
  if account.logged_in then
    set_window_title(account.name)
  end

  account.login:register(function() set_window_title(account.name) end)
  account.logout:register(function() set_window_title('Final Fantasy XI') end)
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
