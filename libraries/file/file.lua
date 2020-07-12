local bit = require('bit')
local ffi = require('ffi')
local math = require('math')
local string = require('string')
local table = require('table')
local unicode = require('core.unicode')
local win32 = require('win32')

local paths = {}

local file = {}

local file_fns = {}

local file_mt = {
    __index = file_fns,
    __tostring = function(f)
        return 'file: ' .. f.path
    end,
}

ffi.cdef[[
    typedef struct _FILETIME {
        uint32_t dwLowDateTime;
        uint32_t dwHighDateTime;
    } FILETIME;
    typedef struct _FILETIME* PFILETIME;
    typedef struct _FILETIME* LPFILETIME;

    typedef struct _SECURITY_ATTRIBUTES {
        DWORD nLength;
        LPVOID lpSecurityDescriptor;
        BOOL bInheritHandle;
    } SECURITY_ATTRIBUTES;
    typedef struct _SECURITY_ATTRIBUTES* PSECURITY_ATTRIBUTES;
    typedef struct _SECURITY_ATTRIBUTES* LPSECURITY_ATTRIBUTES;

    typedef struct _OVERLAPPED {
        ULONG_PTR Internal;
        ULONG_PTR InternalHigh;
        union {
            struct {
                DWORD Offset;
                DWORD OffsetHigh;
            } DUMMYSTRUCTNAME;
            PVOID Pointer;
        } DUMMYUNIONNAME;
        HANDLE hEvent;
    } OVERLAPPED;
    typedef struct _OVERLAPPED* LPOVERLAPPED;

    typedef struct _BY_HANDLE_FILE_INFORMATION {
        DWORD dwFileAttributes;
        FILETIME ftCreationTime;
        FILETIME ftLastAccessTime;
        FILETIME ftLastWriteTime;
        DWORD dwVolumeSerialNumber;
        DWORD nFileSizeHigh;
        DWORD nFileSizeLow;
        DWORD nNumberOfLinks;
        DWORD nFileIndexHigh;
        DWORD nFileIndexLow;
    } BY_HANDLE_FILE_INFORMATION;
    typedef struct _BY_HANDLE_FILE_INFORMATION* PBY_HANDLE_FILE_INFORMATION;
    typedef struct _BY_HANDLE_FILE_INFORMATION* LPBY_HANDLE_FILE_INFORMATION;

    typedef struct _WIN32_FIND_DATAW {
        DWORD dwFileAttributes;
        FILETIME ftCreationTime;
        FILETIME ftLastAccessTime;
        FILETIME ftLastWriteTime;
        DWORD nFileSizeHigh;
        DWORD nFileSizeLow;
        DWORD dwReserved0;
        DWORD dwReserved1;
        WCHAR cFileName[MAX_PATH];
        WCHAR cAlternateFileName[14];
        DWORD dwFileType;
        DWORD dwCreatorType;
        WORD wFinderFlags;
    } WIN32_FIND_DATAW;
    typedef struct _WIN32_FIND_DATAW* PWIN32_FIND_DATAW;
    typedef struct _WIN32_FIND_DATAW* LPWIN32_FIND_DATAW;
]]

ffi.metatype('FILETIME', {
    __index = function(t, k)
        if k == 'time' then
            return t.dwHighDateTime * 429.4967296 + t.dwLowDateTime / 10000000 - 11644473600
        end
    end,
})

local create_file = win32.def({
    name = 'CreateFileW',
    returns = 'HANDLE',
    parameters = {
        'LPCWSTR',
        'DWORD',
        'DWORD',
        'LPSECURITY_ATTRIBUTES',
        'DWORD',
        'DWORD',
        'HANDLE',
    },
    failure = win32.values.INVALID_HANDLE_VALUE,
})

local close_handle = win32.def({
    name = 'CloseHandle',
    returns = 'BOOL',
    parameters = {
        'HANDLE'
    },
    failure = false,
})

local get_file_attributes = win32.def({
    name = 'GetFileAttributesW',
    returns = 'DWORD',
    parameters = {
        'LPCWSTR',
    },
})

local get_file_size = win32.def({
    name = 'GetFileSize',
    returns = 'DWORD',
    parameters = {
        'HANDLE',
        'LPDWORD',
    },
    failure = win32.values.INVALID_FILE_SIZE,
})

local get_file_information_by_handle = win32.def({
    name = 'GetFileInformationByHandle',
    returns = 'BOOL',
    parameters = {
        'HANDLE',
        'LPBY_HANDLE_FILE_INFORMATION',
    },
    failure = false,
})

local read_file = win32.def({
    name = 'ReadFile',
    returns = 'BOOL',
    parameters = {
        'HANDLE',
        'LPVOID',
        'DWORD',
        'LPDWORD',
        'LPOVERLAPPED',
    },
    failure = false,
})

local write_file = win32.def({
    name = 'WriteFile',
    returns = 'BOOL',
    parameters = {
        'HANDLE',
        'LPCVOID',
        'DWORD',
        'LPDWORD',
        'LPOVERLAPPED',
    },
    failure = false,
})

local create_directory = win32.def({
    name = 'CreateDirectoryW',
    returns = 'BOOL',
    parameters = {
        'LPCWSTR',
        'LPSECURITY_ATTRIBUTES',
    },
    failure = false,
})

local find_first_file = win32.def({
    name = 'FindFirstFileW',
    returns = 'HANDLE',
    parameters = {
        'LPCWSTR',
        'LPWIN32_FIND_DATAW',
    },
    failure = 'INVALID_HANDLE_VALUE',
    ignore_codes = {2},
})

local find_next_file = win32.def({
    name = 'FindNextFileW',
    returns = 'BOOL',
    parameters = {
        'HANDLE',
        'LPWIN32_FIND_DATAW',
    },
    failure = false,
    ignore_codes = {18},
})

local find_close = win32.def({
    name = 'FindClose',
    returns = 'BOOL',
    parameters = {
        'HANDLE',
    },
    failure = false,
})

do
    local setmetatable = setmetatable
    local unicode_to_utf16 = unicode.to_utf16

    file.new = function(path)
        local obj = {
            path = path,
        }

        paths[obj] = unicode_to_utf16(path)
        return setmetatable(obj, file_mt)
    end
end

do
    local bit_band = bit.band

    local invalid_attributes = win32.values.INVALID_FILE_ATTRIBUTES

    file_fns.exists = function(f)
        local attr = get_file_attributes(paths[f])
        return attr ~= invalid_attributes and bit_band(attr, 0x10) == 0
    end
end

do
    local ffi_new = ffi.new

    file_fns.info = function(f)
        local handle = create_file(paths[f], 0x00000001, 0x00000003, nil, 3, 0x00000080, nil)

        local info = ffi_new('BY_HANDLE_FILE_INFORMATION')
        get_file_information_by_handle(handle, info)
        close_handle(handle)
        return info
    end
end

do
    local bit_band = bit.band
    local ffi_cast = ffi.cast
    local ffi_copy = ffi.copy
    local unicode_from_utf16 = unicode.from_utf16
    local unicode_to_utf16 = unicode.to_utf16

    local result_type = ffi.typeof('WIN32_FIND_DATAW')
    local result_size = ffi.sizeof(result_type)
    local find_result = result_type()
    local invalid_handle = win32.values.INVALID_HANDLE_VALUE

    file_fns.enumerate = function(f, pattern)
        local handle = find_first_file(unicode_to_utf16(f.path .. '\\' .. (pattern or '*')), find_result)
        if handle == invalid_handle then
            return {}
        end

        local results = {}
        local results_count = 0
        repeat
            local name = unicode_from_utf16(ffi_cast('WCHAR*', find_result.cFileName))
            if bit_band(find_result.dwFileAttributes, 0x00000010) == 0 or name ~= '.' and name ~= '..' then
                local result = result_type()
                ffi_copy(result, find_result, result_size)
                results_count = results_count + 1
                results[results_count] = result
            end
        until not find_next_file(handle, find_result)

        find_close(handle)

        return results
    end
end

do
    local bit_band = bit.band
    local math_min = math.min
    local string_byte = string.byte
    local string_find = string.find
    local string_sub = string.sub
    local table_concat = table.concat
    local unicode_to_utf16 = unicode.to_utf16

    local invalid_attributes = win32.values.INVALID_FILE_ATTRIBUTES

    local get_prefix_index = function(path)
        local byte1, byte2, byte3 = string_byte(path, 1, 3)
        if byte2 == 58 and (byte1 >= 65 and byte1 <= 90 or byte1 >=97 and byte1 <= 122) and (byte3 == 92 or byte3 == 47) then
            return 4
        end

        local byte4, _, byte6 = string_byte(path, 4, 6)
        if byte1 == 92 and byte2 == 92 and byte3 == 63 and byte4 == 92 and byte6 == 92 then
            return 7
        end

        return 1
    end

    local segment_path = function(path)
        local segments = {}
        local segments_count = 0

        local index = get_prefix_index(path)
        if index > 1 then
            segments_count = segments_count + 1
            segments[segments_count] = string_sub(path, 1, index - 2)
        end

        while true do
            local next_slash = string_find(path, '/', index)
            local next_backslash = string_find(path, '\\', index)
            if next_slash == nil and next_backslash == nil then
                break
            end

            local next_index = next_slash == nil and next_backslash or next_backslash == nil and next_slash or math_min(next_slash, next_backslash)
            if next_index ~= index then
                segments_count = segments_count + 1
                segments[segments_count] = string_sub(path, index, next_index - 1)
                index = next_index
            end

            index = index + 1
        end

        return segments, segments_count
    end

    file_fns.create_directories = function(f)
        local segments, segments_count = segment_path(f.path)

        local stack = {}
        local stack_count = 0
        for i = segments_count, 1, -1 do
            local path = unicode_to_utf16(table_concat(segments, '\\', 1, i))
            local attributes = get_file_attributes(path)
            if attributes == invalid_attributes then
                stack_count = stack_count + 1
                stack[stack_count] = path
            elseif bit_band(attributes, 0x00000010) then
                break
            end
        end

        for i = stack_count, 1, -1 do
            create_directory(stack[i], nil)
        end
    end
end

do
    local ffi_new = ffi.new
    local ffi_string = ffi.string
    local ffi_typeof = ffi.typeof

    local buffer_type = ffi_typeof('char[?]')
    local read_ptr = ffi_new('int[1]')

    file_fns.read = function(f)
        local handle = create_file(paths[f], 0x00000001, 0x00000003, nil, 3, 0x00000080, nil)
        local size = get_file_size(handle, nil)
        local buffer = buffer_type(size)

        read_file(handle, buffer, size, read_ptr, nil)
        close_handle(handle)
        return ffi_string(buffer, size)
    end
end

do
    local ffi_copy = ffi.copy
    local ffi_new = ffi.new
    local ffi_typeof = ffi.typeof

    local buffer_type = ffi_typeof('char[?]')
    local written_ptr = ffi_new('int[1]')

    file_fns.write = function(f, str)
        local handle = create_file(paths[f], 0x40000000, 0x00000000, nil, 2, 0x00000080, nil)
        local size = #str
        local buffer = buffer_type(size)

        ffi_copy(buffer, str, size)
        write_file(handle, buffer, size, written_ptr, nil)
        close_handle(handle)
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
            local value = ffi_gc(create_file(paths[k], 0x00000004, 0x00000001, nil, 4, 0x80000000, nil), close_handle)
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
        write_file(handle, buffer, size, read_ptr, nil)
    end
end

file_fns.load = function(f, ...)
    return loadfile(f.path)(...)
end

file_fns.load_env = function(f, env, ...)
    return setfenv(loadfile(f.path), env)(...)
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
