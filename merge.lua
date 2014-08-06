#! /usr/bin/env lua

--[[
структура сохранённой базы:
GatherItems = {
    [НомерКонтинента] = {
        [НомерЗоны] = {
            [НазваниеНоды] = {
                [#] = {
                    ["x"] = координата_X,
                    ["y"] = координата_Y,
                    ["gtype"] = тип,
                    ["count"] = количество_сборов,
                    ["icon"] = тип_иконки,
                }...
            }...
        }...
    }...
}

ноды идентичны если
они лежат в одном и том же [Континент][Зона][Нода] и
их X и Y равны.
]]


local inspect = require('inspect');
local mindist = 1.0;

local num_added     = 0;
local num_skipped   = 0;
local num_total     = 0;


function num_nodes(db)
    local n = 0;
    for _,continent in pairs(db) do
        for _,zone in pairs(continent) do
            for _,kind in pairs(zone) do
                for _,_ in pairs(kind) do
                    n = n + 1;
                end;
            end;
        end;
    end;
    return n;
end;


function db_load(fname)
    dofile(fname);
    print("load " .. num_nodes (GatherItems) .. " nodes from "..fname);
    return GatherItems;
end;


function spc(lvl)
    local s = '';
    for i = 1, lvl do
        s = s .. '\t';
    end;
    return s;
end;


function pprint(v,lvl)
    local t = type(v);
    if t == 'nil' then
        return nil;
    elseif t == 'boolean' then
        return tostring(v);
    elseif t == 'string' then
        return '"'..v..'"';
    elseif t == 'number' then
        return tostring(v);
    elseif t == 'table' then
        local s = '{\n';
        local keys = {};
        for key, _ in pairs(v) do
            table.insert(keys, key);
        end;
        table.sort(keys,function(a,b) return a < b end);
        for ix = 1, #keys do
            key = keys[ix];
            val = v[key];
            s = s .. spc(lvl) ..
                '[' .. pprint(key,0) .. '] = ' ..
                pprint(val, lvl + 1) ..
                ',\n';
        end;
        s = s .. spc(lvl-1) .. '}';
        return s;
    else
        error("unprocessible type ".. t);
    end;
end;


function db_save(fname, data, config)
    print("save " .. num_nodes (data) .. " nodes to "..fname);
    local f = io.open(fname, 'w');
    f:write('GatherItems = ' .. pprint(data,1)..'\n');
    f:write('GatherConfig = ' .. pprint(config,1)..'\n');
    f:close();
end;


function is_same_node(a, b)
    return ((a.x - b.x)^2 + (a.y - b.y)^2) < mindist^2;
end;


function merge_nodeset(a, b)
    local r = {};
    for _, v in pairs(a) do
        r[#r+1] = v;
        num_total = num_total + 1;
    end;
    for _, v in pairs(b) do
        local found = false;
        for _, vr in pairs(r) do
            if is_same_node(v, vr) then
                found = true;
                break;
            end;
        end;
        if found then
            num_skipped = num_skipped + 1;
        else
            r[#r+1] = v;
            num_added = num_added + 1;
            num_total = num_total + 1;
        end;
    end;
    return r;
end;


function merge_zone(a, b)
    local r = {};
    for k, v in pairs(a) do
        r[k] = v;
    end;
    for k, v in pairs(b) do
        r[k] = merge_nodeset(r[k] or {}, v);
    end;
    return r;
end;


function merge_continent(a, b)
    local r = {};
    for k, v in pairs(a) do
        r[k] = v;
    end;
    for k, v in pairs(b) do
        r[k] = merge_zone(r[k] or {}, v);
    end;
    return r;
end;


function merge_base(a, b)
    num_total,num_added,num_skipped = 0,0,0
    local r = {};
    for k, v in pairs(a) do
        r[k] = v;
    end;
    for k, v in pairs(b) do
        r[k] = merge_continent(r[k] or {}, v);
    end;
    print("merge results: total=" .. num_total ..
        ", added=" .. num_added ..
        ", skipped="..num_skipped..
        ", num="..num_nodes(r));
    return r;
end;


---------------------------------------------------

a = db_load("1.lua");
db_save('1_.lua', a, GatherConfig or {});
b = db_load("2.lua");
db_save('2_.lua', b, GatherConfig or {});
c = db_load("3.lua");
db_save('3_.lua', c, GatherConfig or {});

r = {}
r = merge_base(r, a);
r = merge_base(r, b);
r = merge_base(r, c);
db_save('r_.lua', r, GatherConfig or {});
