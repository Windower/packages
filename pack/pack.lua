--[[/*
* lpack.c
* a Lua library for packing and unpacking binary data
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 29 Jun 2007 19:27:20
* This code is hereby placed in the public domain.
* with contributions from Ignacio Castaño <castanyo@yahoo.es> and
* Roberto Ierusalimschy <roberto@inf.puc-rio.br>.
*/
-- Conversion from C to lua by Angelo Yazar, 2013.
]]
local ffi = require "ffi"
local bit = require "bit"
local C = ffi.C
local tonumber = tonumber
local string = string
local assert = assert

ffi.cdef [[ 
  int isdigit( int ch ); 
]]

local OP_ZSTRING    = 'z' --/* zero-terminated string */
local OP_BSTRING    = 'p' --/* string preceded by length byte */
local OP_WSTRING    = 'P' --/* string preceded by length word */
local OP_SSTRING    = 'a' --/* string preceded by length size_t */
local OP_STRING     = 'A' --/* string */
local OP_FLOAT      = 'f' --/* float */
local OP_DOUBLE     = 'd' --/* double */
local OP_NUMBER     = 'n' --/* Lua number */
local OP_CHAR     = 'c' --/* char */
--/* Custom: Changed OP_BYTE from 'b' to 'C'*/
local OP_BYTE     = 'C' --/* byte = unsigned char */
local OP_SHORT      = 'h' --/* short */
local OP_USHORT     = 'H' --/* unsigned short */
local OP_INT      = 'i' --/* int */
local OP_UINT     = 'I' --/* unsigned int */
local OP_LONG     = 'l' --/* long */
local OP_ULONG      = 'L' --/* unsigned long */
local OP_LITTLEENDIAN = '<' --/* little endian */
local OP_BIGENDIAN    = '>' --/* big endian */
local OP_NATIVE     = '=' --/* native endian */
local OP_NONE     = function() end
--/* Custom <need to implement> */
local OP_BIT        =  'b'     --/* Bits */
local OP_BOOLBIT    =  'q'     --/* Bits representing a boolean */
local OP_BOOL       =  'B'     --/* Boolean */
local OP_FSTRING    =  'S'     --/* Fixed-length string (requires a length argument) */

function badcode(c)
  assert( false, "bad character code: '" .. tostring(c) .. "'" )
end

local function isLittleEndian()
  local x = ffi.new("short[1]", 0x1001)
  local e = tonumber( ( ffi.new("char[1]", x[0]) )[0] )
  if e == 1 then
    return true
  end
  return false
end

function doendian(c)
  local e = isLittleEndian()
  if c == OP_LITTLEENDIAN then
    return not e
  elseif c == OP_BIGENDIAN then
    return e
  elseif c == OP_NATIVE then 
    return false
  end
  return false
end

function doswap(swap, a, T)
 if T == "byte" or T == "char" then
  return a
 end
 if swap then
 -- if T == "double" or T == "float" then
    -- this part makes me unhappy --
    a = ffi.new(T.."[1]",a)
    local m = ffi.sizeof(T)
    local str = ffi.string( a, m )
    str = str:reverse()
    ffi.copy(a, str, m)
    return tonumber( a[0] )
  --else
  --  return bit.bswap( a )
  --end
 end
 return a
end

function isdigit(c)
  --//CUSTOM BECAUSE ffi.C.isdigit currently doesn't work
  return type(c) == 'number' and c > 0x29 and c < 0x3A
  --return C.isdigit( string.byte(c) ) == 1
end

function l_unpack(s,f,init)
  local len = #s
  local i = (init or 1)
  local n = 1
  local N = 0
  local cur = OP_NONE
  local swap = false
  --lua_pushnil(L);

  local values = {}

  local function push( value ) 
    values[n] = value
    n = n + 1
  end

  local function done()
    return unpack(values) -- Removed for ease of use
    --return i, unpack(values)
  end

  local endianOp = function(c)
    swap = doendian(c)
      -- N = 0 -- I don't think this is needed
  end

  local stringOp = function(c)
    if i + N - 1 > len then
      return done
    end
    push( s:sub(i,i+N - 1) )
    i = i + N
    N = 0
  end
    
  local zstringOp = function(c)
    local l = 0
    if i >= len then
      return done
    end
    local substr = s:sub(i)
    l = substr:find('\0')
    push( substr:sub(0, l) )
    i = i + l
  end

  function unpackNumber(T)
    return function()   
      local m = ffi.sizeof(T)  
      if i + m - 1 > len then return done end
      local a = ffi.new(T.."[1]")
      ffi.copy(a, s:sub(i,i+m), m)
      push( doswap(swap, tonumber(a[0]), T) )
      i = i + m 
    end   
  end

  function unpackString(T)
    return function() 
      local m = ffi.sizeof(T)   
      if i + m > len then return done end
      local l = ffi.new(T.."[1]")
      ffi.copy(l, s:sub(i), m)
      l = doswap(swap, tonumber(l[0]), T)
      if i + m + l - 1 > len then return done end
      i = i + m
      push( s:sub(i,i+l-1) )
      i = i + l
    end     
  end

  local unpack_ops = {
    [OP_LITTLEENDIAN] = endianOp,
    [OP_BIGENDIAN] = endianOp,
    [OP_NATIVE] = endianOp,
    [OP_ZSTRING] = zstringOp,
    [OP_STRING] = stringOp,
    [OP_BSTRING] = unpackString("unsigned char"),
    [OP_WSTRING] = unpackString("unsigned short"),
    [OP_SSTRING] = unpackString("size_t"),
    [OP_NUMBER] = unpackNumber("double"),
    [OP_DOUBLE] = unpackNumber("double"),
    [OP_FLOAT] = unpackNumber("float"),
    [OP_CHAR] = unpackNumber("char"),
    [OP_BYTE] = unpackNumber("unsigned char"),
    [OP_SHORT] = unpackNumber("short"),
    [OP_USHORT] = unpackNumber("unsigned short"),
    [OP_INT] = unpackNumber("int"),
    [OP_UINT] = unpackNumber("unsigned int"),
    [OP_LONG] = unpackNumber("long"),
    [OP_ULONG] = unpackNumber("unsigned long"),
    [OP_NONE] = OP_NONE,
    [' '] = OP_NONE,
    [','] = OP_NONE,
  }

  for c in (f..'\0'):gmatch'.' do
    if not isdigit( c ) then
      if cur == OP_STRING then
        if N == 0 then push("") else
          if stringOp(cur) == done then
            return done()
          end
        end
      else
        if N == 0 then N = 1 end
        for k=1,N do
          if unpack_ops[cur] then
            if unpack_ops[cur](cur) == done then
              return done()
            end
          else 
            badcode(cur)
          end
        end
      end
      cur = c
      N = 0
    else N = 10*N+tonumber(c) end
  end
  return done()
end

function l_pack(f,...)
  local args = {f,...}
  local i = 1
  local N = 0
  local swap = false
  local b = ""
  local cur = OP_NONE

  local pop = function()
    i = i + 1
    return args[i]
  end

  local endianOp = function(c)
    swap = doendian(c)
    -- N = 0 -- I don't think this is needed
  end

  local stringOp = function(c)
      b = b .. pop()

      if c == OP_ZSTRING then
        b = b .. '\0'
      end
  end

  function packNumber(T)
    return function()
      local a = pop()
      a = doswap(swap, a, T)
      a = ffi.new(T.."[1]",a)
      b = b .. ffi.string( a, ffi.sizeof(T) )
    end   
  end

  function packString(T)
    return function()
      local a = pop()
      local l = #a
      ll = doswap(swap, l, T)
      ll = ffi.new(T.."[1]",ll)
      b = b .. ffi.string( ll, ffi.sizeof(T) )
      b = b .. a
    end     
  end

  local pack_ops = {
    [OP_LITTLEENDIAN] = endianOp,
    [OP_BIGENDIAN] = endianOp,
    [OP_NATIVE] = endianOp,
    [OP_ZSTRING] = stringOp,
    [OP_STRING] = stringOp,
    [OP_BSTRING] = packString("unsigned char"),
    [OP_WSTRING] = packString("unsigned short"),
    [OP_SSTRING] = packString("size_t"),
    [OP_NUMBER] = packNumber("double"),
    [OP_DOUBLE] = packNumber("double"),
    [OP_FLOAT] = packNumber("float"),
    [OP_CHAR] = packNumber("char"),
    [OP_BYTE] = packNumber("unsigned char"),
    [OP_SHORT] = packNumber("short"),
    [OP_USHORT] = packNumber("unsigned short"),
    [OP_INT] = packNumber("int"),
    [OP_UINT] = packNumber("unsigned int"),
    [OP_LONG] = packNumber("long"),
    [OP_ULONG] = packNumber("unsigned long"),
    [OP_NONE] = OP_NONE,
    [' '] = OP_NONE,
    [','] = OP_NONE,
  }
  
  for c in (f..'\0'):gmatch'.' do
    if not isdigit( c ) then
      if N == 0 then N = 1 end
      for k=1,N do
        if pack_ops[cur] then
          pack_ops[cur](cur)
        else 
          badcode(cur)
        end
      end
      cur = c
      N = 0
    else N = 10*N+tonumber(c) end
  end

  return b
end

string.pack = l_pack
string.unpack = l_unpack