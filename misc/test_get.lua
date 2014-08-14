#! /usr/bin/env lua

require "socket.http"
require "pprint"

local resp, stat, hdr = socket.http.request{
--  url     = "http://yygame.port0.org/valkyrie_db/index.html"
  url     = "http://www.google.com/",
  method  = "GET",
};

print("RESPONSE: '"..resp.."'");
print("STATUS  : '"..stat.."'");
print("HEADERS : "..pprint(hdr).."");
-- 249882
