# lua-resty-iconv
LuaJIT FFI bindings for libiconv - Character encoding conversion in OpenResty

## Sample
```lua
    location =/test {
        content_by_lua_block {
            local iconv = require 'resty.iconv'

            local from = 'UTF-8'
            local to   = 'GBK'

            ngx.header['Content-Type'] = 'text/plain;charset=' .. to
            local i, err = iconv:new(to, from)
            if not i then
                return ngx.say(err)
            end
            local t, count = i:convert('文件编码UTF-8')
            if not t then
                return ngx.say(count)
            end
            ngx.say('text : ', t)
            ngx.say('non-reversible characters : ', count)
        }
    }
```

## Benchmark @ `Intel(R) Core(TM) i3-4150 CPU @ 3.50GHz` using `ab -c10 -n50000 -k`
```
Server Software:        openresty/1.11.2.2
Server Hostname:        localhost
Server Port:            80

Document Path:          /test
Document Length:        51 bytes

Concurrency Level:      10
Time taken for tests:   1.585 seconds
Complete requests:      50000
Failed requests:        0
Write errors:           0
Keep-Alive requests:    49504
Total transferred:      10847520 bytes
HTML transferred:       2550000 bytes
Requests per second:    31541.34 [#/sec] (mean)
Time per request:       0.317 [ms] (mean)
Time per request:       0.032 [ms] (mean, across all concurrent requests)
Transfer rate:          6682.53 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   0.0      0       0
Processing:     0    0   0.1      0       3
Waiting:        0    0   0.1      0       3
Total:          0    0   0.1      0       3

Percentage of the requests served within a certain time (ms)
  50%      0
  66%      0
  75%      0
  80%      0
  90%      0
  95%      0
  98%      0
  99%      0
 100%      3 (longest request)
```