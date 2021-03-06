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

require "pprint";
require "backup";

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
            num_updated = 0,
            num_skipped = 0,
            verbose     = false,
            dirty       = false,
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
    self.fname = fname;
    local _GatherItems = GatherItems;
    local _GatherConfig = GatherConfig;
    GatherItems = {};
    GatherConfig = {};
    dofile(fname);
    self.db = GatherItems or {};
    self.cf = GatherConfig or {};
    GatherItems = _GatherItems;
    GatherConfig = _GatherConfig;
    if self.verbose then
        print("loaded " .. self:num_nodes () .. " nodes in "
            .. self:num_zones () .. " zones from " .. self.fname);
    end;
    self.dirty = false;
end;


function GatherDB:save(fname, force)
    if fname ~= nil then
        self.fname = fname;
    end;
    assert(self.fname ~= nil, "unnamed database cannot be saved");
    if not self.dirty and not force then
        if self.verbose then
            print("database is not modified. saving not required");
        end;
        return;
    end;
    backup(self.fname);
    if self.verbose then
        print("store " .. self:num_nodes ()
            .. " nodes (and config) to ".. self.fname);
    end;
    local f = io.open(self.fname, 'w');
    f:write('GatherItems = ' .. pprint(self.db,1)..'\n');
    f:write('GatherConfig = ' .. pprint(self.cf,1)..'\n');
    f:close();
end;


function GatherDB:merge(that)
    assert(type(that) == 'table');
    assert(getmetatable(that) == GatherDB);

    self.num_added   = 0;
    self.num_updated = 0;
    self.num_skipped = 0;
    self.num_total   = 0;

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
                            if vr.count < v.count then
                                vr.count = v.count;
                                self.dirty = true;
                                self.num_updated = self.num_updated + 1;
                            else
                                self.num_skipped = self.num_skipped + 1;
                            end;
                            found = true;
                            break;
                        end;
                    end;
                    if not found then
                        r[#r+1] = deepcopy(v);
                        self.num_added = self.num_added + 1;
                        self.num_total = self.num_total + 1;
                        self.dirty = true;
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
    if self.verbose then
        print("merge results: compared=" .. self.num_total ..
            ", added=" ..  self.num_added ..
            ", updated=".. self.num_updated ..
            ", skipped=".. self.num_skipped ..
            ", size=" .. self:num_nodes());
    end;
end; -- merge
