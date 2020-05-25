local bit = require('bit')
local ffi = require('ffi')
local unicode = require('core.unicode')

ffi.cdef[[
    bool CloseHandle(void*);
    void* CreateFileW(wchar_t const*, uint32_t, uint32_t, void*, uint32_t, uint32_t, void*);
    uint32_t GetFileAttributesW(wchar_t const*);
    uint32_t GetFileSize(void*, void*);
    bool ReadFile(void*, uint8_t*, uint32_t, uint32_t*, void*);
    bool WriteFile(void*, uint8_t*, uint32_t, uint32_t*, void*);
]]

local C = ffi.C

local paths = {}

local file = {}

local file_fns = {}

local file_mt = {
    __index = file_fns,
}

do
    local setmetatable = setmetatable
    local unicode_to_utf16 = unicode.to_utf16

    file.new = function(path)
        local obj = {}
        paths[obj] = unicode_to_utf16(path)
        return setmetatable(obj, file_mt)
    end
end

do
    local bit_band = bit.band

    file_fns.exists = function(f)
        local attr = C.GetFileAttributesW(paths[f])
        return attr ~= 0xFFFFFFFF and bit_band(attr, 0x10) == 0
    end
end

do
    local ffi_new = ffi.new
    local ffi_string = ffi.string
    local ffi_typeof = ffi.typeof

    local buffer_type = ffi_typeof('char[?]')
    local read_ptr = ffi_new('int[1]')

    file_fns.read = function(f)
        local handle = C.CreateFileW(paths[f], 0x00000001, 0x00000003, nil, 3, 0x00000080, nil)
        local size = C.GetFileSize(handle, nil)
        local buffer = buffer_type(size)

        C.ReadFile(handle, buffer, size, read_ptr, nil)
        C.CloseHandle(handle)
        return ffi_string(buffer, size)
    end
end

do
    local ffi_copy = ffi.copy
    local ffi_new = ffi.new
    local ffi_typeof = ffi.typeof

    local buffer_type = ffi_typeof('char[?]')
    local read_ptr = ffi_new('int[1]')

    file_fns.write = function(f, str)
        local handle = C.CreateFileW(paths[f], 0x40000000, 0x00000000, nil, 2, 0x00000080, nil)
        local size = #str
        local buffer = buffer_type(size)

        ffi_copy(buffer, str, size)
        C.WriteFile(handle, buffer, size, read_ptr, nil)
        C.CloseHandle(handle)
    end
end

do
    local ffi_copy = ffi.copy
    local ffi_gc = ffi.gc
    local ffi_new = ffi.new
    local ffi_typeof = ffi.typeof

    local buffer_type = ffi_typeof('char[?]')
    local read_ptr = ffi_new('int[1]')

    local logs = setmetatable({}, {
        __index = function(t, k)
            local value = ffi_gc(C.CreateFileW(paths[k], 0x00000004, 0x00000001, nil, 4, 0x80000000, nil), C.CloseHandle)
            t[k] = value
            return value
        end,
    })

    file_fns.log = function(f, str)
        local line = str .. '\n'
        local handle = logs[f]
        local size = #line
        local buffer = buffer_type(size)

        ffi_copy(buffer, line, size)
        C.WriteFile(handle, buffer, size, read_ptr, nil)
    end
end

return file

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
