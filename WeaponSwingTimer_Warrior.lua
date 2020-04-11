local addon_name, addon_data = ...

addon_data.warrior = {}
local frame = CreateFrame("FRAME")
local slotLists = {}
local bar = nil
local tickMark = nil

local spellState = 1
local spellIds = {}

local function GetQueuedAction()
	for i,v in pairs(spellIds) do
		if IsCurrentSpell(i) then
			return v
		end
	end
	return 1
end

local function SetBarColor(queuedAction)
	local s = character_player_settings
	local barColors = {
		[1] = {s.main_r, s.main_g, s.main_b},
		[2] = {.5, .5, 0},
		[3] = {0, .5, 0}
	}
	addon_data.player.frame.main_bar:SetVertexColor(unpack(barColors[queuedAction]))
end

local function OnUpdate()
	-- Update tick
	if not bar or not tickMark then return end
	local latency_s = (select(4, GetNetStats()) or 0) / 1000
	local barwidth_px = character_player_settings.width
	local barwidth_s = addon_data.player.main_weapon_speed
	local px_per_second = barwidth_px / barwidth_s
	local tickwidth = max(2, latency_s * px_per_second)
	local mh_remaining = addon_data.player.main_swing_timer
	local oh_remaining = addon_data.player.off_swing_timer
	tickMark:ClearAllPoints()
	tickMark:SetSize(tickwidth, bar:GetHeight())
	if oh_remaining <= mh_remaining then
		tickMark:SetPoint("RIGHT", bar, "RIGHT", oh_remaining * px_per_second, 0)
	else
		tickMark:SetPoint("LEFT", bar, "LEFT", (oh_remaining - mh_remaining) * px_per_second - tickwidth, 0)
	end
end

local function GetSpells()
	local hsId = select(7, GetSpellInfo("Heroic Strike"))
	local cleaveId = select(7, GetSpellInfo("Cleave"))
	if hsId then
		spellIds[hsId] = 2
	end
	if cleaveId then
		spellIds[cleaveId] = 3
	end
end

local function OnEvent(self,e)
	if e == "CURRENT_SPELL_CAST_CHANGED" then
		local state = GetQueuedAction()
		if state ~= spellState then
			SetBarColor(state)
			spellState = state
		end
	else
		GetSpells()
	end
end

addon_data.warrior.InitializeVisuals = function()
	local barframe = addon_data.player.frame
	bar = barframe.main_bar
	tickMark = barframe:CreateTexture()
	tickMark:SetColorTexture(1,0,0,1)
	tickMark:SetDrawLayer("ARTWORK", 1)
end

--[[frame:RegisterEvent("ACTIONBAR_UPDATE_STATE")
frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
frame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")]]
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("LEARNED_SPELL_IN_TAB")
frame:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
frame:SetScript("OnEvent", OnEvent)
frame:SetScript("OnUpdate", OnUpdate)

