#! /usr/bin/env lua

require "GatherDB";

auto_sync = true;
verbose = true;

---------------------------------------------------

local basedir = arg[0]:match('^.*/') or './';
local master = basedir .. "MASTER.lua";
local db_master;
local initial_size;
local dbs = {};

function show_help_and_exit()
	print("use: "..arg[0] .. " options gathersaves [...]");
	print([[
options:
  -h|--help   -- this help
  -q|--quiet  -- be as quiet as possible
  -d|--debug  -- be verbose
  -s|--sync   -- update source gathersaves
gatherfiles resides (usually) in
  %WoWDir%/WTF/Account/%accname%/SavedVariables/Gatherer.lua");
]]);
	os.exit(0);
end;

if #arg <= 1 then
	show_help_and_exit();
end;

for i = 1, #arg do
	if arg[i] == '-d' or arg[i] == '--debug' then
		verbose = true;
	elseif arg[i] == '-q' or arg[i] == '--quiet' then
		verbose = false;
	elseif arg[i] == '-s' or arg[i] == '--sync' then
		auto_sync = true;
	elseif arg[i] == '-h' or arg[i] == '--help' then
		show_help_and_exit();
	else
		if db_master == nil then
			db_master = GatherDB.new();
			db_master.verbose = verbose;
			db_master:load(master);
			initial_size = db_master:num_nodes();
		end;
		print("process ".. arg[i]);
		local db = GatherDB.new(arg[i]);
		db_master:merge(db);
		table.insert(dbs, db);
	end;
end;

if db_master == nil then
	return;
end;

local final_size = db_master:num_nodes();
if initial_size < final_size then
    print("master base now contained ".. final_size .. " nodes. save them");
    db_master:save(master);
end;

if auto_sync then
    for _,db in pairs(dbs) do
        print("synchronize ".. db.fname);
		db:merge(db_master);
		db:save();
    end;
end;
