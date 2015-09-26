--
--  P e t X P
--


function PetXP_Show(text)
  if (DEFAULT_CHAT_FRAME) then
    DEFAULT_CHAT_FRAME:AddMessage(RED_FONT_COLOR_CODE.."[PetXP] "..GREEN_FONT_COLOR_CODE..text..FONT_COLOR_CODE_CLOSE);
  end
end

--[[
NUM_PET_STATS = 5;
function PetXP_CheckStats()
  for i = 1, NUM_PET_STATS, 1 do
  	local stat, effectiveStat, posBuff, negBuff = UnitStat("pet", i);
    local baseval = stat - posBuff - negBuff;
    PetXP_Show(format("STAT %s: %d", effectiveStat, baseval));
  end
end
--]]

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
      local left = nextXP - currXP;
      local perc = left * 100.0 / nextXP;
      local kills = (left + delta - 1) / delta;
      if levelup then
        PetXP_Show(format("GRATZ! NEXT LEVEL FOR YOUR Pet!"));
      end
      PetXP_Show(format("+%d xp, %d kills to level", delta, kills));
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
    else
      PetXP_Show(format("something wrong with pet. dismiss an recall it"));
      this.currXP = -1;
      this.nextXP = -1;
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
