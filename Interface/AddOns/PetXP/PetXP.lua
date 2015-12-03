--
--  P e t X P
--

local CLR_TITLE = "|cffff8822";
local CLR_TEXT = "|cffaaeeaa";
local CLR_NUM = "|cffaaaaee";
local CLR_NEG = "|cffcc0000";
local CLR_POS = "|cff33ff33";
local CLR_HI = "|cffffff44";
local CLR_ERR = "|cff880000";

local STAT_ID = {"strength","agility", "stamina", "intellect", "spirit"}

function PetXP_Show(text)
  if (DEFAULT_CHAT_FRAME) then
    DEFAULT_CHAT_FRAME:AddMessage(CLR_TITLE.."[PetXP] "..CLR_TEXT..text);
  end
end

NUM_PET_STATS = 5;

function colored_int(v)
  if (v < 0) then
    return CLR_NEG..format("%+d", v)..CLR_TEXT;
  else
    return CLR_POS..format("%+d", v)..CLR_TEXT;
  end
end


function PetXP_InitStats()
  this.pet_basestat = {0,0,0,0,0};
  for i = 1, NUM_PET_STATS do
    local base, eff, buff, debuff = UnitStat("pet", i);
    this.pet_basestat[i] = base;
    local s = format("%s = %s", STAT_ID[i], colored_int(eff))
    if buff ~= 0 or debuff ~= 0 then
      s = s..format("; base:%s, buff:%s, debuff:%s",
        colored_int(base), colored_int(buff), colored_int(debuff));
    end
    PetXP_Show(s);
  end
end

function PetXP_ShowUpdatedStats()
  if (not UnitExists("pet")) then
    return;
  end
  for i = 1, NUM_PET_STATS do
    local base, _, _, _ = UnitStat("pet", i);
    local delta = base - this.pet_basestat[i];
    if (delta ~= 0) then
      PetXP_Show(format("pet's %s base value changed to %s, and is %s now",
        STAT_ID[i], colored_int(delta), base));
        this.pet_basestat[i] = baseval;
    end
  end
end

local history_size = 20

function PetXP_memorize(delta)
  if this.history == nil then
    this.history = {};
  end
  for i = 1, history_size, 1 do
    if this.history[i] == nil then
      this.history[i] = delta;
      return;
    end
  end
  for i = 2, history_size do
    this.history[i-1] = this.history[i];
  end
  this.history[history_size] = delta;
end

function PetXP_hist_count()
  if this.history == nil then
    return 0;
  end
  local n = 0;
  for i = 1, history_size do
    if this.history[i] == nil then
      break;
    end
    n = n + 1;
  end
  return n;
end

function PetXP_hist_avg()
  if this.history == nil then
    return nil;
  end
  local s, n = 0, 0;
  for i = 1, history_size do
    if this.history[i] == nil then
      break;
    end
    s = s + this.history[i];
    n = n + 1;
  end
  return s / n;
end


function PetXP_hist_dsp()
  if this.history == nil then
    return nil;
  end
  local s, n = 0, 0;
  local m = PetXP_hist_avg();
  for i = 1, history_size do
    if this.history[i] == nil then
      break;
    end
    local d = m - this.history[i];
    s = s + d * d;
    n = n + 1;
  end
  return math.sqrt(s / n);
end


function PetXP_Check()
  -- DEFAULT_CHAT_FRAME:AddMessage("PetXP_Check() called");
  if (UnitExists("pet")) then
    local currXP, nextXP = GetPetExperience();
    if (currXP == this.currXP and nextXP == this.nextXP) then
      return;
    elseif (this.currXP > -1) then
      local levelup = (currXP < this.currXP);
      local delta;
      if (levelup) then
        delta = this.nextXP - this.currXP + currXP;
      else
        delta = currXP - this.currXP;
      end
      PetXP_memorize(delta);
      local left = nextXP - currXP;
      local perc = left * 100.0 / nextXP;
      if levelup then
        PetXP_Show(format(CLR_HI.."LEVEL UP!"..CLR_TEXT));
        PetXP_ShowUpdatedStats();
      end
      local c = PetXP_hist_count();
      local a = PetXP_hist_avg();
      local d = PetXP_hist_dsp();
      local p = d * 100 / a;
      local e = math.floor((left + a - 1) / a);
      local dmin = a - d; if dmin < 1 then dmin = 1; end;
      local dmax = a + d;
      local kmin = math.floor((left + dmax - 1) / dmax);
      local kmax = math.floor((left + dmin - 1) / dmin);
      local sessionSec = GetTime() - this.start_sec;
      if (sessionSec < 0.0001) then sessionSec = 0.1; end;
      this.sessionXP = this.sessionXP + delta;
      this.sessionKills = this.sessionKills + 1;
      local XPperSec = this.sessionXP / sessionSec;
      if XPperSec < 0.00001 then XPperSec = 0.00001; end;
      local t_s = math.floor(left / XPperSec);
      local t_s_sav = t_s;
      local estT = "";
      local t_h = math.floor(t_s / 3600); t_s = t_s - t_h * 3600;
      local t_m = math.floor(t_s / 60); t_s = t_s - t_m * 60;
      if (t_h > 0) then
        estT = format("; est. ~%.1f hour(s)", (t_h + t_m / 60));
      elseif (t_m > 0) then
        estT = format("; est. ~%d minute(s)", (t_m));
      else
        estT = "; est. less than a minute! =)";
      end
      PetXP_Show(format("xp history: count=%d, avg=%.1f, dsp=%.1f(%d%%), estN=%d", c, a, d, p, e));
      PetXP_Show(format("xp speed: gain %d xp for %d kills for %d sec. (%.2fxp/s), %dxp spends %ds",
                        this.sessionXP, this.sessionKills, sessionSec, XPperSec, left, t_s_sav));
--      if d ~= 0 then
      if kmin ~= kmax then
        PetXP_Show(format("%s xp, "..CLR_NUM.."%d"..CLR_TEXT.."…"..CLR_NUM.."%d"..CLR_TEXT.." kills to level%s",
                          colored_int(delta), kmin, kmax, estT));
      else
        local kills = (left + delta - 1) / delta;
        PetXP_Show(format("%s xp, "..CLR_NUM.."%d"..CLR_TEXT.." kills to level%s", colored_int(delta), kills, estT));
      end
    end
    this.currXP = currXP;
    this.nextXP = nextXP;
  else
    this.currXP = -1;
    this.nextXP = -1;
  end
end

function PetXP_Init()
  -- DEFAULT_CHAT_FRAME:AddMessage("PetXP_Init() called");
  if (UnitExists("pet")) then
    -- DEFAULT_CHAT_FRAME:AddMessage("PetXP_Init:: pet exists");
    local currXP, nextXP = GetPetExperience();
    if nextXP > 0 then
      -- DEFAULT_CHAT_FRAME:AddMessage("currXP="..currXP..", nextXP="..nextXP);
      local left = nextXP - currXP;
      local perc = left * 100.0 / nextXP;
      PetXP_Show(format("%d of %d, %d xp (%d%%) left to next level", currXP, nextXP, left, perc));
      this.currXP = currXP;
      this.nextXP = nextXP;
      this.sessionXP = 0;
      this.sessionKills = 0;
      this.start_sec = GetTime();
      PetXP_InitStats()
    else
      PetXP_Show(format(CLR_ERR.."something wrong with pet. dismiss it and recall"..CLR_TEXT));
      this.currXP = -1;
      this.nextXP = -1;
      this.pet_stats = {0, 0, 0, 0, 0};
    end
  else
    if 0 <= this.nextXP then
      PetXP_Show(format("pet dismissed"));
    end
    this.currXP = -1;
    this.nextXP = -1;
  end
end


function PetXP_OnEvent(event)
--  DEFAULT_CHAT_FRAME:AddMessage("PetXP_OnEvent("..event..") called");
  if (event == "UNIT_PET") then
    PetXP_Init();
  elseif (event == "PLAYER_PET_CHANGED") then
    PetXP_Init();
  elseif (event == "UNIT_PET_EXPERIENCE") then
   PetXP_Check();
  else
    PetXP_Show(format("got event <%s>", event));
  end
end


function PetXP_OnLoad()
  -- DEFAULT_CHAT_FRAME:AddMessage("PetXP_OnLoad() called");
  PetXP_Show(format("Loading ..."));
  this.currXP = -1
  this.nextXP = -1
  this:RegisterEvent("PLAYER_PET_CHANGED");
  this:RegisterEvent("PLAYER_ENTERED_WORLD");
  this:RegisterEvent("UNIT_LEVEL");
  this:RegisterEvent("UNIT_PET_EXPERIENCE");
  --this:RegisterEvent("UNIT_PET_TRAINING_POINTS");
  this:RegisterEvent("UNIT_PET");
  -- this:RegisterEvent("UNIT_HAPPINESS");
  PetXP_Show(format("... Loaded."));
  if (UnitExists("pet")) then
    PetXP_Init();
  end
end
