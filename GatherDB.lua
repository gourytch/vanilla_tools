--[ GatherDB.lua ]--

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


GatherDB = {};
GatherDB.__index = GatherDB;


local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        -- setmetatable(copy, deepcopy(getmetatable(orig)))
        setmetatable(copy, getmetatable(orig))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


function GatherDB.new(that)
    local t = type(that);
    local obj;
    if (t == 'nil') or (t == 'string') then
        obj = setmetatable({
            db          = {},
            cf          = {},
            min_dist    = 0.1,
            num_total   = 0,
            num_added   = 0,
            num_skipped = 0,
        }, GatherDB);
        if t == 'string' then
            obj:load(that);
        end;
    elseif type(that) == 'table' then
        assert(getmetatable(that) == GatherDB);
        obj = deepcopy(that);
    else
        error("bad GatherDB initializer type: "..t);
    end;
    return obj;
end;


function GatherDB:num_zones()
    local n = 0;
    for _,continent in pairs(self.db) do
        for _,zone in pairs(continent) do
            for _,kind in pairs(zone) do
                n = n + 1;
            end;
        end;
    end;
    return n;
end;


function GatherDB:num_nodes()
    local n = 0;
    for _,continent in pairs(self.db) do
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


function GatherDB:load(fname)
    local _GatherItems = GatherItems;
    local _GatherConfig = GatherConfig;
    GatherItems = {};
    GatherConfig = {};
    dofile(fname);
    self.db = GatherItems;
    GatherItems = _GatherItems;
    GatherConfig = _GatherConfig;
    print("loaded " .. self:num_nodes () .. " nodes in "
        .. self:num_zones () .. " zones");
end;


local function pprint(v,lvl)
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


local function backup(fname)
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


function GatherDB:save(fname)
    backup(fname);
    print("store " .. self:num_nodes () .. " nodes (and config) to "..fname);
    local f = io.open(fname, 'w');
    f:write('GatherItems = ' .. pprint(self.db,1)..'\n');
    f:write('GatherConfig = ' .. pprint(self.cf,1)..'\n');
    f:close();
end;


function GatherDB:merge(that)
    assert(type(that) == 'table');
    assert(getmetatable(that) == GatherDB);

    local function merge_continent(a, b)

        local function merge_zone(a, b)

            local function merge_nodeset(a, b)

                local function is_same_node(a, b)
                    return ((a.x - b.x)^2 + (a.y - b.y)^2) < self.min_dist^2;
                end; -- is_same_node

                local r = {};
                for _, v in pairs(a) do
                    r[#r+1] = deepcopy(v);
                    self.num_total = self.num_total + 1;
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
                        self.num_skipped = self.num_skipped + 1;
                    else
                        r[#r+1] = deepcopy(v);
                        self.num_added = self.num_added + 1;
                        self.num_total = self.num_total + 1;
                    end;
                end;
                return r;
            end; -- merge_nodeset

            local r = {};
            for k, v in pairs(a) do
                r[k] = deepcopy(v);
            end;
            for k, v in pairs(b) do
                r[k] = merge_nodeset(r[k] or {}, v);
            end;
            return r;
        end; -- merge_zone

        local r = {};
        for k, v in pairs(a) do
            r[k] = deepcopy(v);
        end;
        for k, v in pairs(b) do
            r[k] = merge_zone(r[k] or {}, v);
        end;
        return r;
    end; -- merge_continent

    for k, v in pairs(that.db) do
        self.db[k] = merge_continent(self.db[k] or {}, v);
    end;
    print("merge results: compared=" .. self.num_total ..
        ", added=" ..  self.num_added ..
        ", skipped=".. self.num_skipped..
        ", size=".. self:num_nodes());
end; -- merge
