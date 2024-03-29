local fn = require('expression')
local ffi = require('ffi')
local table = require('table')
local unicode = require('core.unicode')

local C = ffi.C

local ffi_cdef = ffi.cdef
local ffi_load = ffi.load
local table_concat = table.concat

ffi.cdef[[
    void SetLastError(uint32_t);
    uint32_t GetLastError();
    uint32_t FormatMessageW(uint32_t, void const*, uint32_t, uint32_t, wchar_t*, uint32_t);
]]

local buffer_size = 0x100
local buffer_t = ffi.typeof('wchar_t[?]')

local modules = {}

local null = {}
local error_t = {
    error = {},
    print = {},
    ignore = {},
}
local error_type_error = error_t.error
local error_type_print = error_t.print
local error_type_ignore = error_t.ignore

local get_check_fn = function(definition)
    local success_value = definition.success
    if success_value ~= nil then
        local success_type = type(success_value)
        if success_type == 'function' then
            return fn.neg(success_value)
        elseif success_type == 'table' then
            return fn.not_one_of(unpack(success_value))
        else
            return fn.is_not(success_value)
        end
    end

    local failure_value = definition.failure
    if failure_value ~= nil then
        local failure_type = type(failure_value)
        if failure_type == 'function' then
            return failure_value
        elseif failure_type == 'table' then
            return fn.one_of(unpack(failure_value))
        else
            return fn.is(failure_value)
        end
    end

    error()
end

local get_error_fn = function(definition)
    local error_type = definition.error_type
    if error_type == error_type_error then
        return error
    end

    if error_type == error_type_print then
        return print
    end

    if type(error_type) == 'function' then
        return error_type
    end

    return nil
end

local wrap_fn = function(definition, module)
    local name = definition.name
    if definition.error_type == error_type_ignore then
        return function(...)
            return module[name](...)
        end
    end

    local check_fn = get_check_fn(definition)
    local error_fn = get_error_fn(definition)

    local ignore_codes = definition.ignore_codes or {}
    local ignore_codes_length = #ignore_codes
    return function(...)
        C.SetLastError(0)

        local result = module[name](...)
        if check_fn(result == nil and null or result) then
            local code = C.GetLastError()
            for i = 1, ignore_codes_length do
                if code == ignore_codes[i] then
                    return result
                end
            end

            local buffer = buffer_t(buffer_size)
            local message_length = C.FormatMessageW(0x00001200, nil, code, 0, buffer, buffer_size)
            error_fn('[Error] Win32: ' .. unicode.from_utf16(buffer, message_length - 2) .. ' (' .. tostring(code) .. ')')
        end

        return result
    end
end

ffi.cdef[[
    typedef uint16_t WORD;
    typedef uint32_t DWORD;
    typedef int32_t INT;
    typedef uint32_t UINT;
    typedef int32_t LONG;
    typedef uint32_t ULONG;
    typedef void* HANDLE;
    typedef void* HMODULE;
    typedef void* HWND;
    typedef wchar_t WCHAR;
    typedef int32_t* LONG_PTR;
    typedef uint32_t* ULONG_PTR;
    typedef bool BOOL;
    typedef char* PSTR;
    typedef char* LPSTR;
    typedef wchar_t* PWSTR;
    typedef wchar_t* LPWSTR;
    typedef char const* PCSTR;
    typedef char const* LPCSTR;
    typedef wchar_t const* PCWSTR;
    typedef wchar_t const* LPCWSTR;
    typedef void* PVOID;
    typedef void* LPVOID;
    typedef void const* PCVOID;
    typedef void const* LPCVOID;
    typedef DWORD* PDWORD;
    typedef DWORD* LPDWORD;

    static uint32_t const MAX_PATH = 260;
    static uint32_t const INVALID_FILE_ATTRIBUTES = (DWORD)-1;
    static uint32_t const INVALID_FILE_SIZE = (DWORD)0xFFFFFFFF;
]]

return {
    null = null,
    error_type = error_t,
    def = function(definition)
        definition.cdef = definition.cdef or definition.returns .. ' ' .. definition.name .. '(' .. table_concat(definition.parameters, ', ') .. ');'
        definition.error_type = definition.error_type or (definition.success ~= nil or definition.failure ~= nil) and error_type_error or error_type_ignore
        definition.ignore_codes = definition.ignore_codes or {0}

        ffi_cdef(definition.cdef)

        local module_name = definition.module
        local module = modules[module_name]
        if module_name ~= nil and module == nil then
            module = ffi_load(module_name)
            modules[module_name] = module
        end

        return wrap_fn(definition, module or C)
    end,
    values = setmetatable({
        MAX_PATH = C.MAX_PATH,
        INVALID_FILE_ATTRIBUTES = C.INVALID_FILE_ATTRIBUTES,
        INVALID_FILE_SIZE = C.INVALID_FILE_SIZE,
        INVALID_HANDLE_VALUE = ffi.cast('void*', -1),
    }, {
        __index = function(t, k)
            local value = C[k]
            rawset(t, k, value)
            return value
        end,
    }),
}

--[[
Copyright © 2020, Windower Dev Team
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
