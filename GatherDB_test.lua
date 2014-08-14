#! /usr/bin/env lua

require('GatherDB');

local basedir = arg[0]:match('^.*/') or './';
local main = basedir .. "0.lua";
local add1 = basedir .. "1.lua";
local dst  = basedir .. "r.lua";
local db_main = GatherDB.new(main);
local db_add1 = GatherDB.new(add1);
db_main:merge(db_add1);
db_main:save(dst);
