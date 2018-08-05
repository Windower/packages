local ffi = require('ffi')
local shared = require('shared')
local windower = require('windower')

ffi.cdef[[
    void* HeapAlloc(void*, uint32_t, size_t);
    void* HeapCreate(uint32_t, size_t, size_t);
    bool HeapDestroy(void*);
]]

local C = ffi.C
local ffi_cast = ffi.cast
local ffi_gc = ffi.gc
local ffi_sizeof = ffi.sizeof

cache = {}

cache.heap = ffi_gc(C.HeapCreate(0, 0, 0), C.HeapDestroy)

local make_ptr = function(def)
    return C.HeapAlloc(cache.heap, 8, ffi_sizeof(def))
end

local service_name = windower.package_path:gsub('(.+\\)', '')

local make_shared = function(name)
    local server = shared.new(service_name .. '_' .. name)
    server.data = {}
    server.env = {}
    cache[name] = server

    return server
end

return {
    new = function(struct)
        local data_server = make_shared('data')

        local ptr = make_ptr(struct.name)
        data_server.data.ptr = tonumber(ffi_cast('intptr_t', ptr))
        data_server.data.struct = struct

        local cdata = ffi_cast(struct.name .. '*', ptr)

        local events_server = make_shared('events')

        return cdata[0], events_server.data
    end,
}
