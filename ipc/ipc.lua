local bit = require('bit')
local event = require('core.event')
local ffi = require('ffi')
local table = require('table')
local windower = require('core.windower')

local data_ptr = ffi.typeof[[struct {
    int32_t next_id[1];
    struct {
        int32_t id[1];
        uint32_t pid;
        uint16_t size;
        char data[506];
    } messages[127];
}*]]

ffi.cdef[[
int CloseHandle(void*);
void* CreateFileMappingW(void*, void*, unsigned long, unsigned long, unsigned long, wchar_t const*);
void* CreateMutexW(void*, int, wchar_t const*);
unsigned int GetCurrentProcessId();
unsigned long GetLastError();
long __cdecl InterlockedCompareExchange(long volatile*, long, long);
long __cdecl InterlockedExchange(long volatile*, long);
long __cdecl InterlockedIncrement(long volatile*);
void* MapViewOfFile(void*, unsigned long, unsigned long, unsigned long, size_t);
int ReleaseMutex(void*);
int UnmapViewOfFile(void const*);
unsigned long WaitForSingleObject(void*, unsigned long);
]]

local c = ffi.C

local mt = {__metatable = false, keep_alive = {}}
local ipc = setmetatable({}, mt)

local pid = c.GetCurrentProcessId()

ipc.received = event.new()

local mutex
local data
do
    local invalid_handle = ffi.cast('void*', -1)

    -- Doesn't properly handle Unicode, but it doesn't actually matter
    -- here; the result should still be valid UCS-16 and unique.
    local wide
    do
        local wide_string = ffi.typeof('wchar_t[?]')
        wide = function(str)
            local buffer = wide_string(#str + 1)
            for i = 1, #str do
                buffer[i - 1] = str:byte(i)
            end
            return buffer
        end
    end

    local name = wide('windower:' .. windower.version .. ':ipc:' .. (package.name or '[:script:]'))

    do
        local handle = c.CreateMutexW(nil, 0, name)
        if handle == nil or handle == invalid_handle then
            error('error creating ipc mutex [error code: ' .. c.GetLastError() .. ']')
        end
        mutex = ffi.gc(handle, c.CloseHandle)
    end

    do
        local handle = c.CreateFileMappingW(invalid_handle, nil, --[[PAGE_READWRITE]] 0x4, 0, 0x10000, name)
        if handle == nil or handle == invalid_handle then
            error('error creating ipc memory mapped file [error code: ' .. c.GetLastError() .. ']')
        end
        handle = ffi.gc(handle, c.CloseHandle)
        table.insert(mt.keep_alive, handle)

        local view = c.MapViewOfFile(handle, --[[FILE_MAP_WRITE]] 0x2, 0, 0, 0)
        if view == nil then
            error('error creating ipc memory mapped file view [error code: ' .. c.GetLastError() .. ']')
        end
        data = ffi.gc(data_ptr(view), c.UnmapViewOfFile)
    end

    do
        local coroutine_sleep_frame = coroutine.sleep_frame
        local bit_band = bit.band
        local bit_tobit = bit.tobit
        local ffi_string = ffi.string

        local received = ipc.received
        local current_id = tonumber(c.InterlockedCompareExchange(data.next_id, 0, 0))
        coroutine.schedule(function()
            while true do
                local next_id = c.InterlockedCompareExchange(data.next_id, 0, 0)
                while current_id ~= next_id do
                    local index = bit_band(current_id, 0x7F)
                    if data.messages[index].pid ~= pid then
                        local message = ffi_string(data.messages[index].data, data.messages[index].size)
                        received:trigger(message)
                    end
                    current_id = bit_tobit(current_id + 1)
                    next_id = c.InterlockedCompareExchange(data.next_id, 0, 0)
                end
                coroutine_sleep_frame()
            end
        end)
    end
end

do
    local bit_band = bit.band
    local bit_tobit = bit.tobit
    local ffi_copy = ffi.copy
    ipc.send = function(message)
        local size = #message
        if size > 506 then
            error('message exceeds maxiumum length of 506 bytes')
        end

        local lock_result = c.WaitForSingleObject(mutex, --[[INFINITE]] 0xFFFFFFFF)
        if lock_result == 0x80 then
            print('WARNING: ipc mutex was abandoned by another process')
        elseif lock_result == 0xFFFFFFFF then
            error('error locking ipc mutex [error code: ' .. c.GetLastError() .. ']')
        end

        local next_id = bit_tobit(data.next_id[0])
        local index = bit_band(next_id, 0x7F)
        c.InterlockedExchange(data.messages[index].id, next_id)
        data.messages[index].pid = pid
        data.messages[index].size = size
        ffi_copy(data.messages[index].data, message, size)
        c.InterlockedIncrement(data.next_id)

        if c.ReleaseMutex(mutex) == 0 then
            error('error releasing ipc mutex [error code: ' .. c.GetLastError() .. ']')
        end
    end
end

return ipc

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
