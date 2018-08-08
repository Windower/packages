local ffi = require('ffi')
local shared = require('shared')
local windower = require('windower')
local structs = require('structs')

ffi.cdef[[
    void* HeapAlloc(void*, uint32_t, size_t);
    void* HeapCreate(uint32_t, size_t, size_t);
    bool HeapDestroy(void*);
]]

local C = ffi.C
local ffi_cast = ffi.cast
local ffi_cdef = ffi.cdef
local ffi_gc = ffi.gc
local ffi_sizeof = ffi.sizeof
local shared_new = shared.new
local structs_from_ptr = structs.from_ptr

cache = {}

cache.heap = ffi_gc(C.HeapCreate(0, 0, 0), C.HeapDestroy)

local make_ptr = function(identifier)
    return C.HeapAlloc(cache.heap, 8, ffi_sizeof(identifier))
end

local service_name = windower.package_path:gsub('(.+\\)', '')

return {
    new = function(name, ftype)
        name, ftype = ftype and name or 'data', ftype or name

        local server = shared_new(service_name .. '_' .. name)
        cache[name] = server

        local ptr = make_ptr(ftype.cdef)
        server.data = {
            ptr = tonumber(ffi_cast('intptr_t', ptr)),
            ftype = ftype,
        }

        return structs.from_ptr(ftype, ptr)
    end,
}
