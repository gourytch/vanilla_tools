--[ pprint.lua ]--

function pprint(v,lvl)
    function spc(lvl)
        local s = '';
        for i = 1, lvl do
            s = s .. '\t';
        end;
        return s;
    end;
    if type(lvl) ~= 'number' then 
        lvl = 1
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
