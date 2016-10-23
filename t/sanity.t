# vim:set ft= ts=4 sw=4 et:

use lib 'test-nginx/lib';
use Test::Nginx::Socket::Lua;
use Cwd qw(cwd);

repeat_each(2);

plan tests => repeat_each() * (3 * blocks());

my $pwd = cwd();

our $HttpConfig = qq{
    lua_package_path "lib/?.lua;;";
};

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';

no_long_string();

run_tests();

__DATA__

=== TEST 1: basic
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local parser = require "resty.multipart.parser"
            ngx.req.read_body()
            local body = ngx.req.get_body_data()

            local p, err = parser.new(ngx.req.get_body_data(), ngx.var.http_content_type)
            if not p then
               ngx.say("failed to create parser: ", err)
               return
            end
            while true do
               local part_body, name, mime, filename = p:parse_part()
               if not part_body then
                  break
               end
               ngx.say("== part ==")
               ngx.say("name: [", name, "]")
               ngx.say("file: [", filename, "]")
               ngx.say("mime: [", mime, "]")
               ngx.say("body: [", part_body, "]")
            end
        }
    }
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
qq{POST /t\n-----------------------------820127721219505131303151179\r
Content-Disposition: form-data; name="file1"; filename="a.txt"\r
Content-Type: text/plain\r
\r
Hello, world\r\n-----------------------------820127721219505131303151179\r
Content-Disposition: form-data; name="test"\r
\r
value\r
\r\n-----------------------------820127721219505131303151179--\r
}
--- response_body eval
"== part ==
name: [file1]
file: [a.txt]
mime: [text/plain]
body: [Hello, world]
== part ==
name: [test]
file: [nil]
mime: [nil]
body: [value\r
]
"
--- no_error_log
[error]



=== TEST 2: Content-Disposition is not the first header
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local parser = require "resty.multipart.parser"
            ngx.req.read_body()
            local body = ngx.req.get_body_data()

            local p, err = parser.new(ngx.req.get_body_data(), ngx.var.http_content_type)
            if not p then
               ngx.say("failed to create parser: ", err)
               return
            end
            while true do
               local part_body, name, mime, filename = p:parse_part()
               if not part_body then
                  break
               end
               ngx.say("== part ==")
               ngx.say("name: [", name, "]")
               ngx.say("file: [", filename, "]")
               ngx.say("mime: [", mime, "]")
               ngx.say("body: [", part_body, "]")
            end
        }
    }
--- more_headers
Content-Type: multipart/form-data; boundary=---------------------------820127721219505131303151179
--- request eval
qq{POST /t\n-----------------------------820127721219505131303151179\r
Content-Type: text/plain\r
Content-Disposition: form-data; name="file1"; filename="aa.txt"\r
\r
Hello, world\r\n-----------------------------820127721219505131303151179\r
Content-Disposition: form-data; name="test"\r
\r
value\r
\r\n-----------------------------820127721219505131303151179--\r
}
--- response_body eval
"== part ==
name: [file1]
file: [aa.txt]
mime: [text/plain]
body: [Hello, world]
== part ==
name: [test]
file: [nil]
mime: [nil]
body: [value\r
]
"
--- no_error_log
[error]



=== TEST 3: quoted boundary in Content-Type header
--- http_config eval: $::HttpConfig
--- config
    location /t {
        content_by_lua_block {
            local parser = require "resty.multipart.parser"
            ngx.req.read_body()
            local body = ngx.req.get_body_data()

            local p, err = parser.new(ngx.req.get_body_data(), ngx.var.http_content_type)
            if not p then
               ngx.say("failed to create parser: ", err)
               return
            end
            while true do
               local part_body, name, mime, filename = p:parse_part()
               if not part_body then
                  break
               end
               ngx.say("== part ==")
               ngx.say("name: [", name, "]")
               ngx.say("file: [", filename, "]")
               ngx.say("mime: [", mime, "]")
               ngx.say("body: [", part_body, "]")
            end
        }
    }
--- more_headers
Content-Type: multipart/form-data; boundary="---------------------------820127721219505131303151179"
--- request eval
qq{POST /t\n-----------------------------820127721219505131303151179\r
Content-Type: text/plain\r
Content-Disposition: form-data; name="file1"; filename="a.txt"\r
\r
Hello, world\r\n-----------------------------820127721219505131303151179\r
Content-Disposition: form-data; name="test"\r
\r
value\r
\r\n-----------------------------820127721219505131303151179--\r
}
--- response_body eval
"== part ==
name: [file1]
file: [a.txt]
mime: [text/plain]
body: [Hello, world]
== part ==
name: [test]
file: [nil]
mime: [nil]
body: [value\r
]
"
--- no_error_log
[error]
