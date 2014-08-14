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
--]]

local mindist = 1.0;
local auto_sync = true;

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
    print(num_nodes (GatherItems) .. " nodes loaded from "..fname);
    return GatherItems;
end;


function pprint(v,lvl)
    function spc(lvl)
        local s = '';
        for i = 1, lvl do
            s = s .. '\t';
        end;
        return s;
    end;
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
        table.sort(keys, function(a,b) return a < b end);
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
end; -- pprint

function backup(fname)
    local f = io.open(fname, 'r');
    if f ~= nil then
        local fbak = io.open(fname..".backup", 'w');
        if fbak ~= nil then
            print("create backup for "..fname);
            fbak:write(f:read('*a'));
            fbak:close();
        end;
        f:close();
    end;
end;


function db_save(fname, data, config)
    backup(fname);
    print("store " .. num_nodes (data) .. " nodes (and config) to "..fname);
    local f = io.open(fname, 'w');
    f:write('GatherItems = ' .. pprint(data,1)..'\n');
    f:write('GatherConfig = ' .. pprint(config,1)..'\n');
    f:close();
end;


function merge_base(a, b)

    function merge_continent(a, b)

        function merge_zone(a, b)

            function merge_nodeset(a, b)

                function is_same_node(a, b)
                    return ((a.x - b.x)^2 + (a.y - b.y)^2) < mindist^2;
                end; -- is_same_node

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
            end; -- merge_nodeset

            local r = {};
            for k, v in pairs(a) do
                r[k] = v;
            end;
            for k, v in pairs(b) do
                r[k] = merge_nodeset(r[k] or {}, v);
            end;
            return r;
        end; -- merge_zone

        local r = {};
        for k, v in pairs(a) do
            r[k] = v;
        end;
        for k, v in pairs(b) do
            r[k] = merge_zone(r[k] or {}, v);
        end;
        return r;
    end; -- merge_continent
    assert(type(a) == 'table');
    assert(type(b) == 'table');
    num_total, num_added, num_skipped = 0,0,0
    local r = {};
    for k, v in pairs(a) do
        r[k] = v;
    end;
    for k, v in pairs(b) do
        r[k] = merge_continent(r[k] or {}, v);
    end;
    print("merge results: compared=" .. num_total ..
        ", added=" .. num_added ..
        ", skipped="..num_skipped..
        ", size="..num_nodes(r));
    return r;
end; -- merge_base

---------------------------------------------------

local basedir = arg[0]:match('^.*/') or './';
local master = basedir .. "MASTER.lua";

db = db_load(master) or {};
local initial_size = num_nodes(db);
for i = 1, #arg do
    db = merge_base(db, db_load(arg[i]));
end;

local final_size = num_nodes(db);
if initial_size < final_size then
    print("master base now contained ".. final_size .. " nodes. save them");
    db_save(master, db, GatherConfig or {});
end;

if auto_sync then
    for i = 1, #arg do
        print("synchronize ".. arg[i]);
        db_load(arg[i]); -- load GatherConfig
        db_save(arg[i], db, GatherConfig or {});
    end;
end;
