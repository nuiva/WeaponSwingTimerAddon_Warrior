local addon_name, addon_data = ...
local L = addon_data.localization_table


addon_data.core = {}

addon_data.core.core_frame = CreateFrame("Frame", addon_name .. "CoreFrame", UIParent)
addon_data.core.core_frame:RegisterEvent("ADDON_LOADED")

addon_data.core.all_timers = {
    addon_data.player, addon_data.target
}

local version = "4.1.0"

local load_message = L["Thank you for installing WeaponSwingTimer Version"] .. " " .. version .. 
                     " " .. L["by LeftHandedGlove! Use |cFFFFC300/wst|r for more options."]
                     
addon_data.core.default_settings = {
    one_frame = false
}

addon_data.core.in_combat = false

local swing_reset_spells = {
	-- Druid: Maul
	[6807] = -1,
	[6808] = -1,
	[6809] = -1,
	[8972] = -1,
	[9745] = -1,
	[9880] = -1,
	[9881] = -1,
	-- Hunter: Raptor Strike
	[2973] = 0,
	[14260] = 0,
	[14261] = 0,
	[14262] = 0,
	[14263] = 0,
	[14264] = 0,
	[14265] = 0,
	[14266] = 0,
	-- Warrior: Cleave
	[845] = 0,
	[7369] = 0,
	[11608] = 0,
	[11609] = 0,
	[20569] = 0,
	-- Warrior: Heroic Strike
	[78] = 0,
	[284] = 0,
	[285] = 0,
	[1608] = 0,
	[11564] = 0,
	[11565] = 0,
	[11566] = 0,
	[11567] = 0,
	[25286] = 0,
}

local function LoadAllSettings()
    addon_data.core.LoadSettings()
    addon_data.player.LoadSettings()
    addon_data.target.LoadSettings()
    addon_data.hunter.LoadSettings()
end

addon_data.core.RestoreAllDefaults = function()
    addon_data.core.RestoreDefaults()
    addon_data.player.RestoreDefaults()
    addon_data.target.RestoreDefaults()
    addon_data.hunter.RestoreDefaults()
end

local function InitializeAllVisuals()
    addon_data.player.InitializeVisuals()
    addon_data.target.InitializeVisuals()
    addon_data.hunter.InitializeVisuals()
    addon_data.config.InitializeVisuals()
	addon_data.warrior.InitializeVisuals()
end


addon_data.core.UpdateAllVisualsOnSettingsChange = function()
    addon_data.player.UpdateVisualsOnSettingsChange()
    addon_data.target.UpdateVisualsOnSettingsChange()
    addon_data.hunter.UpdateVisualsOnSettingsChange()
end

addon_data.core.LoadSettings = function()
    -- If the carried over settings dont exist then make them
    if not character_core_settings then
        character_core_settings = {}
    end
    -- If the carried over settings aren't set then set them to the defaults
    for setting, value in pairs(addon_data.core.default_settings) do
        if character_core_settings[setting] == nil then
            character_core_settings[setting] = value
        end
    end
end

addon_data.core.RestoreDefaults = function()
    for setting, value in pairs(addon_data.core.default_settings) do
        character_core_settings[setting] = value
    end
end

local function CoreFrame_OnUpdate(self, elapsed)
    addon_data.player:OnUpdate(elapsed)
    addon_data.target:OnUpdate(elapsed)
    addon_data.hunter.OnUpdate(elapsed)
end

local function ResetUnitSwingTimer(unit)
	local t = addon_data[unit]
	if t == nil then
		--addon_data.utils.PrintMsg("ResetUnitSwingTimer: No data table for unit " .. unit)
		return
	end
	t:UpdateWeaponSpeed()
	t:ResetSwingTimer()
end

addon_data.core.SpellHandler = function(unit, spell_id)
	if unit == nil then return end
	local t = addon_data[unit]
	if t == nil then return end
	local castTime = select(4, GetSpellInfo(spell_id))
	if castTime > 0 then
		t:UpdateWeaponSpeed()
		t:ResetSwingTimer()
		return
	end
	local resetType = swing_reset_spells[spell_id]
	if resetType == nil then return end
	t:UpdateWeaponSpeed(resetType)
	t:ResetSwingTimer(resetType)
end

local function OnAddonLoaded(self)
    -- Attach the rest of the events and scripts to the core frame
    addon_data.core.core_frame:SetScript("OnUpdate", CoreFrame_OnUpdate)
    addon_data.core.core_frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    addon_data.core.core_frame:RegisterEvent("PLAYER_REGEN_DISABLED")
    addon_data.core.core_frame:RegisterEvent("PLAYER_TARGET_CHANGED")
    addon_data.core.core_frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
    addon_data.core.core_frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    addon_data.core.core_frame:RegisterEvent("START_AUTOREPEAT_SPELL")
    addon_data.core.core_frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_START")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
    addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET")
	addon_data.core.core_frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
    -- Load the settings for the core and all timers
    LoadAllSettings()
    InitializeAllVisuals()
    -- Any other misc operations that happen at the start
	addon_data.player:Initialize()
	addon_data.target:Initialize()
    addon_data.utils.PrintMsg(load_message)
end

local function CoreFrame_OnEvent(self, event, ...)
    local args = {...}
    if event == "ADDON_LOADED" then
        if args[1] == "WeaponSwingTimer" then
            OnAddonLoaded()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        addon_data.core.in_combat = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        addon_data.core.in_combat = true
    elseif event == "PLAYER_TARGET_CHANGED" then
        addon_data.target.OnPlayerTargetChanged()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local combat_info = {CombatLogGetCurrentEventInfo()}
        addon_data.player:OnCombatLogUnfiltered(combat_info)
        addon_data.target:OnCombatLogUnfiltered(combat_info)
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        addon_data.player.OnInventoryChange()
    elseif event == "START_AUTOREPEAT_SPELL" then
        addon_data.hunter.OnStartAutorepeatSpell()
    elseif event == "STOP_AUTOREPEAT_SPELL" then
        addon_data.hunter.OnStopAutorepeatSpell()
    elseif event == "UNIT_SPELLCAST_START" then
        addon_data.hunter.OnUnitSpellCastStart(args[1], args[3])
    elseif event == "UNIT_SPELLCAST_STOP" then
        addon_data.hunter.OnUnitSpellCastStop(args[1], args[3])
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		addon_data.core.SpellHandler(args[1], args[3])
        addon_data.hunter.OnUnitSpellCastSucceeded(args[1], args[3])
	elseif event == "UNIT_SPELLCAST_CHANNEL_START" then
		ResetUnitSwingTimer(args[1])
    elseif event == "UNIT_SPELLCAST_DELAYED" then
        addon_data.hunter.OnUnitSpellCastDelayed(args[1], args[3])
    elseif event == "UNIT_SPELLCAST_FAILED" then
        addon_data.hunter.OnUnitSpellCastFailed(args[1], args[3])
    elseif event == "UNIT_SPELLCAST_INTERRUPTED" then
        addon_data.hunter.OnUnitSpellCastInterrupted(args[1], args[3])
    elseif event == "UNIT_SPELLCAST_FAILED_QUIET" then
        addon_data.hunter.OnUnitSpellCastFailedQuiet(args[1], args[3])
    end
end

-- Add a slash command to bring up the config window
SLASH_WEAPONSWINGTIMER_CONFIG1 = "/WeaponSwingTimer"
SLASH_WEAPONSWINGTIMER_CONFIG2 = "/weaponswingtimer"
SLASH_WEAPONSWINGTIMER_CONFIG3 = "/wst"
SlashCmdList["WEAPONSWINGTIMER_CONFIG"] = function(option)
    InterfaceOptionsFrame_OpenToCategory("WeaponSwingTimer")
    InterfaceOptionsFrame_OpenToCategory("WeaponSwingTimer")
end

-- Setup the core of the addon (This is like calling main in C)
addon_data.core.core_frame:SetScript("OnEvent", CoreFrame_OnEvent)
