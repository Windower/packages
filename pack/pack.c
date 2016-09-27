/*
* lpack.c
* a Lua library for packing and unpacking binary data
* Luiz Henrique de Figueiredo <lhf@tecgraf.puc-rio.br>
* 29 Jun 2007 19:27:20
* This code is hereby placed in the public domain.
* with contributions from Ignacio Castaño <castanyo@yahoo.es> and
* Roberto Ierusalimschy <roberto@inf.puc-rio.br>.
*/

/* Changes by Arcon:
* Added 'B' for booleans.
* Added 'S' for fixed-length strings
* Renamed 'b' to 'C' for unsigned chars
* Added 'b' for bit-packed numbers
* Added 'q' for bit-packed booleans
*/

#define    OP_ZSTRING       'z'     /* zero-terminated string */
#define    OP_BSTRING       'p'     /* string preceded by length byte */
#define    OP_WSTRING       'P'     /* string preceded by length word */
#define    OP_SSTRING       'a'     /* string preceded by length size_t */
#define    OP_STRING        'A'     /* string */
#define    OP_FLOAT         'f'     /* float */
#define    OP_DOUBLE        'd'     /* double */
#define    OP_NUMBER        'n'     /* Lua number */
#define    OP_CHAR          'c'     /* char */
// Custom: Changed OP_BYTE from 'b' to 'C'
#define    OP_BYTE          'C'     /* byte = unsigned char */
#define    OP_SHORT         'h'     /* short */
#define    OP_USHORT        'H'     /* unsigned short */
#define    OP_INT           'i'     /* int */
#define    OP_UINT          'I'     /* unsigned int */
#define    OP_LONG          'l'     /* long */
#define    OP_ULONG         'L'     /* unsigned long */
#define    OP_LITTLEENDIAN  '<'     /* little endian */
#define    OP_BIGENDIAN     '>'     /* big endian */
#define    OP_NATIVE        '='     /* native endian */
// Custom
#define    OP_BIT           'b'     /* Bits */
#define    OP_BOOLBIT       'q'     /* Bits representing a boolean */
#define    OP_BOOL          'B'     /* Boolean */
#define    OP_FSTRING       'S'     /* Fixed-length string (requires a length argument) */

#include <ctype.h>
#include <string.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

static void badcode(lua_State *L, int c)
{
    char s[]="bad code `?'";
    s[sizeof(s)-3]=c;
    luaL_argerror(L,1,s);
}

static int doendian(int c)
{
    int x=1;
    int e=*(char*)&x;
    if (c==OP_LITTLEENDIAN) return !e;
    if (c==OP_BIGENDIAN) return e;
    if (c==OP_NATIVE) return 0;
    return 0;
}

static void doswap(int swap, void *p, size_t n)
{
    if (swap)
    {
        char *a=p;
        int i,j;
        for (i=0, j=n-1, n=n/2; n--; i++, j--)
        {
            char t=a[i]; a[i]=a[j]; a[j]=t;
        }
    }
}

#define UNPACKNUMBER(OP,T)               \
    case OP:                             \
    {                                    \
        T a;                             \
        int m=sizeof(a);                 \
        if (i+m>len) goto done;          \
        memcpy(&a,s+i,m);                \
        i+=m;                            \
        doswap(swap,&a,m);               \
        lua_pushnumber(L,(lua_Number)a); \
        ++n;                             \
        break;                           \
    }

#define UNPACKSTRING(OP,T)               \
    case OP:                             \
    {                                    \
        T l;                             \
        int m=sizeof(l);                 \
        if (i+m>len) goto done;          \
        memcpy(&l,s+i,m);                \
        doswap(swap,&l,m);               \
        if (i+m+l>len) goto done;        \
        i+=m;                            \
        lua_pushlstring(L,s+i,l);        \
        i+=l;                            \
        ++n;                             \
        break;                           \
    }

static int l_unpack(lua_State *L)         /** unpack(s,f,[init]) */
{
    size_t len;
    const char *s=luaL_checklstring(L,1,&len);
    const char *f=luaL_checkstring(L,2);
    int i=luaL_optnumber(L,3,1)-1;
    int n=0;
    int swap=0;
    // Custom
    int bitoffset = luaL_optnumber(L, 4, 1) - 1;
    i += bitoffset/8;
    bitoffset %= 8;

    while (*f)
    {
        int c=*f++;
        int N=1;

        // Custom: Adjustment for bit-packed values
        if (bitoffset && c != OP_BIT && c != OP_BOOLBIT)
        {
            bitoffset = 0;
            ++i;
        }

        if (isdigit(*f)) 
        {
            N=0;
            while (isdigit(*f)) N=10*N+(*f++)-'0';
            if (N==0 && c==OP_STRING) { lua_pushliteral(L,""); ++n; }
        }

        while (N--) switch (c)
        {
        case OP_LITTLEENDIAN:
        case OP_BIGENDIAN:
        case OP_NATIVE:
            {
                swap=doendian(c);
                N=0;
                break;
            }
        case OP_STRING:
            {
                ++N;
                if (i+N>len) goto done;
                lua_pushlstring(L,s+i,N);
                i+=N;
                ++n;
                N=0;
                break;
            }
        case OP_ZSTRING:
            {
                size_t l;
                if (i>=len) goto done;
                l=strlen(s+i);
                lua_pushlstring(L,s+i,l);
                i+=l+1;
                ++n;
                break;
            }
        UNPACKSTRING(OP_BSTRING, unsigned char)
        UNPACKSTRING(OP_WSTRING, unsigned short)
        UNPACKSTRING(OP_SSTRING, size_t)
        UNPACKNUMBER(OP_NUMBER, lua_Number)
        UNPACKNUMBER(OP_DOUBLE, double)
        UNPACKNUMBER(OP_FLOAT, float)
        UNPACKNUMBER(OP_CHAR, char)
        UNPACKNUMBER(OP_BYTE, unsigned char)
        UNPACKNUMBER(OP_SHORT, short)
        UNPACKNUMBER(OP_USHORT, unsigned short)
        UNPACKNUMBER(OP_INT, int)
        UNPACKNUMBER(OP_UINT, unsigned int)
        UNPACKNUMBER(OP_LONG, long)
        UNPACKNUMBER(OP_ULONG, unsigned long)

        // Custom functions
        case OP_BIT:
        case OP_BOOLBIT:
            {
                unsigned char const bits = 8;
                unsigned long long int b = 0;
                int j;

                ++N;
                if (i > len || N > bits * sizeof b || N > (len - i) * bits - bitoffset)
                {
                    goto done;
                }

                memcpy(&b, s + i, i + sizeof b > len ? len - i : sizeof b);
                b >>= bitoffset;
                b &= (1ull << N) - 1;
                bitoffset += N;
                i += bitoffset / bits;
                bitoffset %= bits;
                if (c == OP_BIT)
                {
                    lua_pushnumber(L, b);
                    ++n;
                }
                else if (c == OP_BOOLBIT)
                {
                    for (j = 0; j < N; ++j)
                    {
                        lua_pushboolean(L, b >> j & 1);
                    }
                    n += N;
                }
                N = 0;
                break;
            }
        case OP_BOOL:
            {
                unsigned char b;
                if (i + 1 > len)
                {
                    goto done;
                }

                memcpy(&b, s + i, sizeof b);
                ++i;
                lua_pushboolean(L, b);
                ++n;
                break;
            }
        case OP_FSTRING:
            {
                size_t z;
                char const* str = s + i;
                if (*f != '*')
                {
                    ++N;
                    if (i + N > len)
                    {
                        goto done;
                    }
                }
                else
                {
                    f++;
                }

                for (z = 0; z < N && str[z]; ++z);

                lua_pushlstring(L, str, z);
                i += N;
                ++n;
                N = 0;
                break;
            }

        case ' ': case ',':
            break;
        default:
            badcode(L,c);
            break;
            }
    }
done:
    return n;
}

#define PACKNUMBER(OP,T)                           \
    case OP:                                       \
    {                                              \
        T a=(T)luaL_checknumber(L,i++);            \
        doswap(swap,&a,sizeof(a));                 \
        luaL_addlstring(&b,(void*)&a,sizeof(a));   \
        break;                                     \
    }

#define PACKSTRING(OP,T)                           \
    case OP:                                       \
    {                                              \
        size_t l;                                  \
        const char *a=luaL_checklstring(L,i++,&l); \
        T ll=(T)l;                                 \
        doswap(swap,&ll,sizeof(ll));               \
        luaL_addlstring(&b,(void*)&ll,sizeof(ll)); \
        luaL_addlstring(&b,a,l);                   \
        break;                                     \
    }

static int l_pack(lua_State *L)         /** pack(f,...) */
{
    int i=2;
    const char *f=luaL_checkstring(L,1);
    int swap=0;
    luaL_Buffer b;
    unsigned char bitoffset = 0;
    char bitbuffer = 0;
    luaL_buffinit(L,&b);
    while (*f)
    {
        int c=*f++;
        int N=1;

        if (bitoffset && c != OP_BIT && c != OP_BOOLBIT)
        {
            bitoffset = 0;
            bitbuffer = 0;
        }

        if (isdigit(*f)) 
        {
            N=0;
            while (isdigit(*f)) N=10*N+(*f++)-'0';
        }

        while (N--) switch (c)
        {
            case OP_LITTLEENDIAN:
            case OP_BIGENDIAN:
            case OP_NATIVE:
                {
                    swap=doendian(c);
                    N=0;
                    break;
                }
            case OP_STRING:
                {
                    size_t l;
                    const char *a=luaL_checklstring(L,i++,&l);
                    luaL_addlstring(&b, a, l < ++N ? l : N);
                    while (l < N--)
                    {
                        luaL_addchar(&b, '\0');
                    }
                    N = 0;
                    break;
                }
            case OP_ZSTRING:
                {
                    size_t l;
                    const char *a=luaL_checklstring(L,i++,&l);
                    luaL_addlstring(&b,a,l+1);
                    break;
                }
            PACKSTRING(OP_BSTRING, unsigned char)
            PACKSTRING(OP_WSTRING, unsigned short)
            PACKSTRING(OP_SSTRING, size_t)
            PACKNUMBER(OP_NUMBER, lua_Number)
            PACKNUMBER(OP_DOUBLE, double)
            PACKNUMBER(OP_FLOAT, float)
            PACKNUMBER(OP_CHAR, char)
            PACKNUMBER(OP_BYTE, unsigned char)
            PACKNUMBER(OP_SHORT, short)
            PACKNUMBER(OP_USHORT, unsigned short)
            PACKNUMBER(OP_INT, int)
            PACKNUMBER(OP_UINT, unsigned int)
            PACKNUMBER(OP_LONG, long)
            PACKNUMBER(OP_ULONG, unsigned long)

            // Custom functions
            case OP_BIT:
            case OP_BOOLBIT:
                {
                    unsigned char const bits = 8;
                    unsigned long long int const value = (c == OP_BIT ? lua_tointeger(L, i++) : c == OP_BOOLBIT ? lua_toboolean(L, i++) : 0) << bitoffset | bitbuffer;
                    size_t index = (++N + bitoffset) / bits;
                    bitoffset += N;
                    bitoffset %= bits;

                    if (index)
                    {
                        luaL_addlstring(&b, (char const*) &value, index);
                    }
                    bitbuffer = *((char*) &value + index);

                    if (bitoffset && (!*f || i > lua_gettop(L)))
                    {
                        luaL_addlstring(&b, &bitbuffer, sizeof bitbuffer);
                    }

                    N = 0;
                    break;
                }
            case OP_BOOL:
                {
                    char const value = lua_toboolean(L, i++) ? 1 : 0;
                    luaL_addlstring(&b, &value, 1);
                    break;
                }
            case OP_FSTRING:
                if (*f == '*')
                {
                    char str[1024];
                    char const* value = luaL_checkstring(L, i++);
                    size_t length = strlen(value);
                    memset(str, 0, 1024);
                    memcpy(str, value, length <= 1024-1 ? length : 1024-1);
                    luaL_addstring(&b, str);

                    N = 0;
                    f++;
                }
                else
                {
                    char str[1024];
                    char const* value = luaL_checkstring(L, i++);
                    size_t length = strlen(value);
                    size_t minlength = N < 1024-1 ? N+1 : 1024-1;
                    memset(str, 0, 1024);
                    memcpy(str, value, minlength <= length ? minlength : length);
                    luaL_addlstring(&b, str, minlength);

                    N = 0;
                }
                break;
            case ' ':
            case ',':
                break;

            default:
                badcode(L,c);
                break;
        }
    }
    luaL_pushresult(&b);
    return 1;
}

static const luaL_reg R[] =
{
    {"pack",    l_pack},
    {"unpack",    l_unpack},
    {NULL,    NULL}
};

int luaopen_pack(lua_State *L)
{
#ifdef USE_GLOBALS
    lua_register(L,"bpack",l_pack);
    lua_register(L,"bunpack",l_unpack);
#else
    luaL_openlib(L, LUA_STRLIBNAME, R, 0);
#endif
    return 0;
}
