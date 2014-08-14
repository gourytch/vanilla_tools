function backup(fname)
    local f = io.open(fname, 'r');
    if f ~= nil then
        local fbak = io.open(fname..".backup", 'w');
        if fbak ~= nil then
--            print("create backup for "..fname);
            fbak:write(f:read('*a'));
            fbak:close();
        end;
        f:close();
    end;
end;
