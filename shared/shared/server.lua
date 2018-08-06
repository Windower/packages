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

return {
    new = function(name, struct)
        name, struct = struct and name or 'data', struct or name

        local server = shared.new(service_name .. '_' .. name)
        cache[name] = server

        local ptr = make_ptr(struct.name)
        server.data = {
            ptr = tonumber(ffi_cast('intptr_t', ptr)),
            struct = struct,
        }

        return ffi_cast(struct.name .. '*', ptr)[0]
    end,
}
