local addon_name, addon_data = ...

addon_data.warrior = {}
local frame = CreateFrame("FRAME")
local slotList = nil
local state = false
local bar = nil
local tickMark = nil

local function SetTick()
	if not bar or not tickMark then return end
	local latency_s = (select(4, GetNetStats()) or 0) / 1000
	local barwidth_px = character_player_settings.width
	local barwidth_s = addon_data.player.main_weapon_speed
	local px_per_second = barwidth_px / barwidth_s
	local tickwidth = max(2, latency_s * px_per_second)
	local timeleft = addon_data.player.off_swing_timer
	tickMark:ClearAllPoints()
	tickMark:SetSize(tickwidth, bar:GetHeight())
	tickMark:SetPoint("RIGHT", bar, "RIGHT", timeleft * px_per_second, 0)
end

local function GetActionbarState()
	local spellid = select(7, GetSpellInfo("Heroic Strike"))
	if spellid then
		slotList = C_ActionBar.FindSpellActionButtons(spellid)
	end
end

local function HeroicStrikeActive()
	if state then return end
	state = true
	addon_data.player.frame.main_bar:SetVertexColor(.5,.5,0);
end

local function HeroicStrikeInactive()
	if not state then return end
	state = false
	local s = character_player_settings
	addon_data.player.frame.main_bar:SetVertexColor(s.main_r, s.main_g, s.main_b)
end

local function OnEvent(self,e)
	if e == "ACTIONBAR_UPDATE_STATE" then
		if slotList and IsCurrentAction(slotList[1]) then
			HeroicStrikeActive()
		else
			HeroicStrikeInactive()
		end
	elseif e == "ADDON_LOADED" then
		
	else
		GetActionbarState()
	end
end

addon_data.warrior.InitializeVisuals = function()
	local barframe = addon_data.player.frame
	bar = barframe.main_bar
	tickMark = barframe:CreateTexture()
	tickMark:SetColorTexture(1,0,0,1)
	tickMark:SetDrawLayer("ARTWORK", 1)
end

frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", OnEvent)
frame:SetScript("OnUpdate", SetTick)

GetActionbarState()
