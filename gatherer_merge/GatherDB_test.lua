#! /usr/bin/env lua

require('GatherDB');

local basedir = arg[0]:match('^.*/') or './';
local main = basedir .. "0.lua";
local db_main = GatherDB.new(main);
for i = 1, 4 do
  local add = basedir .. i .. ".lua";
  local db_add = GatherDB.new(add);
  db_main:merge(db_add);
  db_add = nil;
end;
local dst  = basedir .. "r.lua";
db_main:save(dst);
