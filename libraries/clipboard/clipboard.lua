local ffi = require('ffi')
local windower = require('core.windower')

ffi.cdef[[
    bool OpenClipboard(void* hWndNewOwner);
    bool CloseClipboard();
    bool EmptyClipboard();
    void* GlobalAlloc(uint32_t uFlags, size_t dwBytes);
    void* GlobalLock(void* hMem);
    bool GlobalUnlock(void* hMem);
    void* GetClipboardData(uint32_t uFormat);
    void* SetClipboardData(uint32_t uFormat, void* hMem);
]]

local C = ffi.C

local hwnd = windower.client_hwnd

local get
local set
local clear

do
    local ffi_cast = ffi.cast
    local ffi_copy = ffi.copy
    local ffi_string = ffi.string
    local char_ptr = ffi.typeof('char*')

    get = function()
        C.OpenClipboard(hwnd)

        local hmem = C.GetClipboardData(1)
        if hmem == nil then
            return nil
        end

        local ptr = C.GlobalLock(hmem)
        if ptr == nil then
            return nil
        end

        local str = ffi_string(ffi_cast(char_ptr, ptr))
        C.GlobalUnlock(hmem)

        C.CloseClipboard()

        return str
    end

    set = function(str)
        C.OpenClipboard(hwnd)

        local length = #str + 1
        local hmem = C.GlobalAlloc(2, length)

        local buffer = ffi_cast(char_ptr, C.GlobalLock(hmem))
        ffi_copy(buffer, str, length)
        buffer[length - 1] = 0

        C.GlobalUnlock(hmem)

        C.EmptyClipboard()
        C.SetClipboardData(1, hmem)

        C.CloseClipboard()
    end

    clear = function()
        C.OpenClipboard(hwnd)
        C.EmptyClipboard()
        C.CloseClipboard()
    end
end

return {
    get = get,
    set = set,
    clear = clear,
}

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
