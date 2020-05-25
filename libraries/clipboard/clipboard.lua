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
