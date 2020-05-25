local bit = require('bit')
local files = require('client_data.files')
local ffi = require('ffi')
local string = require('string')
local types = require('client_data.types.items')
local unicode = require('core.unicode')
local windower = require('core.windower')

windower.client_language = 'en'

local band = bit.band
local bor = bit.bor
local lshift = bit.lshift
local rshift = bit.rshift
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_offsetof = ffi.offsetof
local ffi_string = ffi.string
local ffi_typeof = ffi.typeof
local string_byte = string.byte
local to_utf16 = unicode.to_utf16
local from_shift_jis = unicode.from_shift_jis

local size_type = ffi.typeof('unsigned long[1]')
local raw_data_ptr = ffi.typeof('uint8_t*')
local int32_ptr = ffi.typeof('int32_t*')
local invalid_handle = ffi.cast('void*', -1)

ffi.cdef[[
typedef struct _OVERLAPPED OVERLAPPED;

void* CreateFileW(wchar_t const*, unsigned long, unsigned long, void*, unsigned long, unsigned long, void*);
unsigned long SetFilePointer(void*, long, long*, unsigned long);
int ReadFile(void*, void*, unsigned long, unsigned long*, OVERLAPPED*);
int CloseHandle(void*);
unsigned long GetLastError();
]]

local c = ffi.C

local file_handles = setmetatable({}, {
    __index = function(t, dat_id)
        local path = files[dat_id]
        if not path then
            error('unknown dat id [dat id: ' .. tostring(dat_id) .. ']')
        end

        local handle = c.CreateFileW(to_utf16(path), --[[GENERIC_READ]] 0x80000000, --[[FILE_SHARE_READ]] 0x1, nil,
        --[[OPEN_EXISTING]] 3, --[[FILE_ATTRIBUTE_NORMAL]] 128, nil)
        if handle == nil or handle == invalid_handle then
            error('error opening file "' .. path .. '" [error code: ' .. c.GetLastError() .. '; dat id: ' .. dat_id .. ']')
        end
        handle = ffi_gc(handle, c.CloseHandle)

        rawset(t, dat_id, handle)
        return handle
    end
})

local decrypt = function(data, size)
    local blocks = ffi_cast(int32_ptr, data)
    for i = 0, size / 4 - 1 do
        local b = blocks[i]
        blocks[i] = bor(rshift(band(b, 0xE0E0E0E0), 5), lshift(band(b, 0x1F1F1F1F), 3))
    end
end

local lookup_info
do
    local item_type_map = types.type_map
    lookup_info = function(item_id)
        for i = 1, #item_type_map do
            local e = item_type_map[i]
            if item_id >= e.first and item_id <= e.last then
                return e
            end
        end
        return nil
    end
end

local data_block_size = 0x30000
local data_block = ffi.typeof('uint8_t[' .. data_block_size .. ']')
local data_blocks = setmetatable({}, {
    __index = function(t, id)
        local dat_id = rshift(id, 10)
        local block_number = band(id, 0x3FF)

        local file_handle = file_handles[dat_id]
        local file_offset = block_number * data_block_size
        if c.SetFilePointer(file_handle, file_offset, nil, --[[FILE_BEGIN]] 0) == 0xFFFFFFFF then
            error('error seeking to offset [error code: ' .. c.GetLastError() .. '; dat id: ' .. dat_id .. ']')
        end

        local block = data_block()
        if c.ReadFile(file_handle, block, data_block_size, size_type(), nil) == 0 then
            error('error reading from file [error code: ' .. c.GetLastError() .. '; dat id: ' .. dat_id .. ']')
        end

        decrypt(block, data_block_size)

        rawset(t, id, block)
        return block
    end,
    __mode = 'v',
})

local item_cache = setmetatable({}, {__mode = 'v'})

local language_ids = {en = 0, ja = 1}

local get_item = function(id, language)
    if id < 0 or id > 0xFFFF then
        return nil
    end

    local key = id + language_ids[language] * 0x10000
    local item = item_cache[key]
    if item == nil then
        local dat_info = lookup_info(id)
        if dat_info == nil then
            return nil
        end

        local ctype_ptr = dat_info.ctype_ptr
        if ctype_ptr == nil then
            ctype_ptr = ffi_typeof(dat_info.type.name .. '*')
            dat_info.ctype_ptr = ctype_ptr
        end

        local block_id = bor(lshift(dat_info[language], 10), rshift(id - dat_info.base, 6))
        local block = data_blocks[block_id]
        item = {ffi_cast(ctype_ptr, block)[band(id - dat_info.base, 0x3F)], block}

        item_cache[key] = item
    end
    return item
end

local string_entry = function(item, i)
    local strings = item._strings

    if strings.count >= 0x40 or i >= strings.count then
        return nil
    end

    local entry = strings.entries[i]
    local offset = entry.offset
    if offset >= 0x270 then
        return nil
    end

    local base_ptr = ffi_cast(raw_data_ptr, item) + ffi_offsetof(item, '__strings')
    local type = entry.type
    if type == 0 then
        return (from_shift_jis(ffi_string(base_ptr + offset + 0x1C)))
    elseif type == 1 then
        return ffi_cast(int32_ptr, base_ptr + offset)[0]
    end

    return nil
end

local some = {}

local definite = {}
local indefinite = {}
local numeric = {}
local none = {}

local wrap_log_string = function(item, log_string)
    return function(_, ...)
        if type(_) ~= 'table' then
            error('bad argument #1 to \'log_string\' (expected item; got ' .. type(_) .. ')')
        end

        return log_string(_, item, ...)
    end
end

local en_log_string = function(_, item, count, article)
    local article_type = string_entry(item, 1)
    if type(article_type) ~= 'number' then
        return nil
    end

    article = article == nil and indefinite or article

    if count == 1 then
        local singular
        if item.id == 0xFFFF then
            singular = 'gil'
        else
            singular = string_entry(item, 2)
        end

        if article == indefinite then
            if     article_type == 0 then return 'a ' .. singular
            elseif article_type == 1 then return 'an ' .. singular
            elseif article_type == 2 then return 'a pair of ' .. singular
            elseif article_type == 3 then return 'a suit of ' .. singular
            else return '<article: ' .. article_type .. '> ' .. singular
            end
        elseif article == definite then
            if     article_type == 0 or article_type == 1 then return 'the ' .. singular
            elseif article_type == 2 then return 'the pair of ' .. singular
            elseif article_type == 3 then return 'the suit of ' .. singular
            else return '<article: ' .. article_type .. '> ' .. singular
            end
        elseif article == none then
            if     article_type == 0 or article_type == 1 then return singular
            elseif article_type == 2 then return 'pair of ' .. singular
            elseif article_type == 3 then return 'suit of ' .. singular
            else return '<article: ' .. article_type .. '> ' .. singular
            end
        else
            if     article_type == 0 or article_type == 1 then return singular
            elseif article_type == 2 then return '1 pair of ' .. singular
            elseif article_type == 3 then return '1 suit of ' .. singular
            else return '1 <article: ' .. article_type .. '> ' .. singular
            end
        end
    else
        local plural
        if item.id == 0xFFFF then
            plural = 'gil'
        else
            plural = string_entry(item, 3)
        end

        if count == some then
            if article == definite then
                return 'the ' .. plural
            elseif article == none then
                return plural
            else
                return 'some ' .. plural
            end
        elseif type(count) == 'number' then
            if article == definite then
                return 'the ' .. count .. ' ' .. plural
            elseif article == none then
                return plural
            else
                return count .. ' ' .. plural
            end
        else
            error('bad argument #2 to \'log_string\' (expected number; got ' .. type(count) .. ')')
        end
    end
end

local ja_log_string = function(_, item, count, article)
    if count == 1 then
        if article == numeric then
            return '1' .. string_entry(item, 0)
        else
            return string_entry(item, 0)
        end
    elseif count == some then
        return string_entry(item, 0)
    elseif type(count) == 'number' then
        if article == none then
            return string_entry(item, 0)
        else
            return count .. string_entry(item, 0)
        end
    else
        error('bad argument #1 to \'log_string\' (expected number; got ' .. type(count) .. ')')
    end
end

local wrap_strings = function(item, log_string, description_index)
    return setmetatable({}, {
        __index = function(_, k)
            if k == 'name' then
                return string_entry(item, 0)
            elseif k == 'description' then
                return string_entry(item, description_index)
            elseif k == 'log_string' then
                return wrap_log_string(item, log_string)
            end
        end,
        __newindex = error,
        __pairs = function(t)
            return function(t, k)
                local v
                if k == nil then
                    k = 'name'
                    v = t.name
                elseif k == 'name' then
                    k = 'description'
                    v = t.description
                elseif k == 'description' then
                    k = 'log_string'
                    v = t.log_string
                elseif k == 'log_string' then
                    k = nil
                end
                return k, v
            end, t, nil
        end,
    })
end

local client_language = windower.client_language
local last_language = client_language

local client_log_string = ja_log_string
local client_description_index = 1
if client_language == 'en' then
    client_log_string = en_log_string
    client_description_index = 4
end

local wrap_item = function(item, language)
    local en, ja, client
    if language == 'en' then
        en = item
    else
        ja = item
    end
    if client_language == language then
        client = item
    end

    return setmetatable({}, {
        __index = function(t, k)
            if k == 'name' or k == 'description' or k == 'log_string' or k == 'full_name' then
                if client == nil then
                    last_language = client_language
                    client = get_item(item[1].id, client_language)
                    if client == nil then
                        return nil
                    end
                    if client_language == 'en' then
                        en = client
                    else
                        ja = client
                    end
                end
                local result
                if k == 'name' then
                    if item[1].id < 0xF000 or item[1].id > 0xF1FF then
                        result = string_entry(client[1], 0)
                    else
                        result = item[1].name
                    end
                elseif k == 'description' then
                    if item[1].id < 0xF000 or item[1].id > 0xF1FF then
                        result = string_entry(client[1], client_description_index)
                    else
                        result = string_entry(client[1], 0)
                    end
                elseif k == 'log_string' then
                    result = wrap_log_string(client[1], client_log_string)
                elseif k == 'full_name' then
                    if client_language == 'en' then
                        local name = string_entry(client[1], 2)
                        result = name:sub(1, 1):upper() .. name:sub(2)
                    else
                        result = string_entry(client[1], 0)
                    end
                else
                    error()
                end
                rawset(t, k, result)
                return result
            elseif k == 'en' then
                if en == nil then
                    last_language = 'en'
                    en = get_item(item[1].id, 'en')
                    if en == nil then
                        return nil
                    end
                end
                local result = wrap_strings(en[1], en_log_string, 4)
                rawset(t, k, result)
                return result
            elseif k == 'ja' then
                if ja == nil then
                    last_language = 'ja'
                    ja = get_item(item[1].id, 'ja')
                    if en == nil then
                        return nil
                    end
                end
                local result = wrap_strings(ja[1], ja_log_string, 1)
                rawset(t, k, result)
                return result
            end
            return item[1][k]
        end,
        __newindex = error,
        __pairs = function(wrapper)
            local next, t, start = pairs(item[1])
            return function(t, k)
                local v
                if k == nil then
                    k = 'name'
                    v = wrapper.name
                elseif k == 'name' then
                    k = 'description'
                    v = wrapper.description
                elseif k == 'description' then
                    k = 'log_string'
                    v = wrapper.log_string
                elseif k == 'log_string' then
                    k = 'en'
                    v = wrapper.en
                elseif k == 'en' then
                    k = 'ja'
                    v = wrapper.ja
                elseif k == 'ja' then
                    k, v = next(t, start)
                else
                    k, v = next(t, k)
                end
                return k, v
            end, t, nil
        end,
    })
end

local by_name
do
    local item_type_map = types.type_map

    local compare_name = function(name, item)
        local strings = item._strings

        if strings.count >= 0x40 or 0 >= strings.count then
            return false
        end

        local entry = strings.entries[0]
        local offset = entry.offset
        if offset >= 0x270 then
            return false
        end

        local type = entry.type
        if type ~= 0 then
            return false
        end

        local ptr = ffi_cast(raw_data_ptr, item) + ffi_offsetof(item, '__strings') + offset + 0x1C
        for i = 1, #name do
            if string_byte(name, i) ~= ptr[i - 1] then
                return false
            end
        end
        return ptr[#name] == 0
    end

    by_name = function(_, name, language)
        if type(name) ~= 'string' then
            error('bad argument #2 to \'by_name\' (string expected, got ' .. type(name) .. ')')
        end

        if language == nil then
            language = client_language
        elseif language ~= 'en' and language ~= 'ja' then
            error('bad argument #3 to \'by_name\' (\'en\' or \'ja\' expected, got ' .. language .. ')')
        end

        local results = {}
        for range_index = 1, #item_type_map do
            local range = item_type_map[range_index]
            for id = range.first, range.last do
                local item = get_item(id, language)
                if item ~= nil and compare_name(name, item[1]) then
                    results[#results + 1] = wrap_item(item, language)
                end
            end
        end
        return results
    end
end

local items = setmetatable({
    count = {some = some},
    article = {definite = definite, indefinite = indefinite, numeric = numeric, none = none},
    en = {},
    ja = {},
    by_name = by_name,
}, {
    __index = function(_, id)
        local item = get_item(id, last_language)
        if item == nil then
            return nil
        end
        return wrap_item(item, last_language)
    end,
})

return items

--[[
Copyright © 2019, Windower Dev Team
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
