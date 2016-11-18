local ffi = require 'ffi'
local type = type
local tonumber = tonumber
local ffi_c = ffi.C
local ffi_new = ffi.new
local ffi_gc = ffi.gc
local ffi_string = ffi.string
local ffi_typeof = ffi.typeof
local ffi_errno = ffi.errno
ffi.cdef[[
    typedef void *iconv_t;
    iconv_t iconv_open (const char *__tocode, const char *__fromcode);
    size_t iconv (
        iconv_t __cd,
        char ** __inbuf, size_t * __inbytesleft,
        char ** __outbuf, size_t * __outbytesleft
    );
    int iconv_close (iconv_t __cd);
]]

local maxsize = 4096
local char_ptr_ptr = ffi_typeof('char *[1]')
local sizet_ptr = ffi_typeof('size_t[1]')

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

local _M = new_tab(0, 8)
_M._VERSION = '0.1.0'

local mt = { __index = _M }

function _M.new(self, to, from, _maxsize)
    if not to or 'string' ~= type(to) or 1 > #to then
        return nil, 'dst charset required'
    end
    if not from or 'string' ~= type(from) or 1 > #from then
        return nil, 'src charset required'
    end
    _maxsize = tonumber(_maxsize) or maxsize
    local ctx = ffi_c.iconv_open(to, from)
    local err = ffi_errno()
    if 0 == err then
        ctx = ffi_gc(ctx, ffi_c.iconv_close)
        local dst_buff = ffi_new(char_ptr_ptr)
        dst_buff[0] = ffi_new('char[' .. _maxsize .. ']')
        return setmetatable({
            ctx = ctx,
            maxsize = _maxsize,
            dst_buff = dst_buff,
        }, mt)
    else
        return nil, ('conversion from %s to %s is not supported'):format(from, to)
    end
end


function _M.convert(self, text)
    local ctx = self.ctx
    if not ctx then
        return nil, 'not initialized'
    end
    if not text or 'string' ~= type(text) or 1 > #text then
        return nil, 'text required'
    end
    local maxsize = self.maxsize
    local dst_len = ffi_new(sizet_ptr, maxsize)
    local dst_buff = self.dst_buff
        
    local src_len = ffi_new(sizet_ptr, #text)
    local src_buff = ffi_new(char_ptr_ptr)
    src_buff[0] = ffi_new('char['.. #text .. ']', text)

    -- backup the dst_buff pointer, iconv will modify it
    local _dst_buff = ffi_new(char_ptr_ptr, dst_buff)
    local ok = ffi_c.iconv(ctx, src_buff, src_len, _dst_buff, dst_len)
    if 0 <= ok then
        local len = maxsize - dst_len[0]
        local dst = ffi_string(dst_buff[0], len)
        return dst, tonumber(ok)
    else
        local err = ffi_errno()
        return nil, 'failed to convert, errno ' .. err
    end
end

function _M.finish(self)
    local ctx = self.ctx
    if not ctx then
        return nil, 'not initialized'
    end
    return ffi_c.iconv_close(ffi_gc(ctx, nil))
end

return _M