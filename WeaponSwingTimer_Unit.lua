local addon_name, addon_data = ...

addon_data.unit = {}
addon_data.unit.__index = addon_data.unit

addon_data.unit.new = function(self, unitId)
	local a = {}
	a.unitId = unitId
	setmetatable(a, self)
	return a
end

addon_data.unit.nextHasteMultiplier = 1
local hasteMultipliers = {
	["Seal of the Crusader"] = 1.4,
}

addon_data.unit.UpdateWeaponSpeed = function(self)
	local mainSpeed, offSpeed = UnitAttackSpeed(self.unitId)
	if mainSpeed == self.main_weapon_speed_current then return end
	local haste = mainSpeed / (self.main_weapon_speed_current or mainSpeed)
	self.main_weapon_speed_current = mainSpeed
	self.off_weapon_speed_current = offSpeed
	haste = haste * self.nextHasteMultiplier
	self.nextHasteMultiplier = 1
	self.main_swing_timer = self.main_swing_timer * haste
	self.main_weapon_speed = self.main_weapon_speed * haste
	if self.has_offhand then
		self.off_swing_timer = self.off_swing_timer * haste
		self.off_weapon_speed = self.off_weapon_speed * haste
	end
end

-- Reads swing speed again for mainhand (false), offhand (true) or both (nil)
addon_data.unit.ResetWeaponSpeed = function(self, isOffhand)
	if isOffhand == nil then
		self:ResetMainWeaponSpeed()
		self:ResetOffWeaponSpeed()
	elseif isOffhand then
		self:ResetOffWeaponSpeed()
	else
		self:ResetMainWeaponSpeed()
	end
end
addon_data.unit.ResetMainWeaponSpeed = function(self)
	self.main_weapon_speed, _ = UnitAttackSpeed(self.unitId)
	self.main_weapon_speed_current = self.main_weapon_speed
end
addon_data.unit.ResetOffWeaponSpeed = function(self)
	_, self.off_weapon_speed = UnitAttackSpeed(self.unitId)
	self.has_offhand = self.off_weapon_speed ~= nil
	if not self.has_offhand then return end
	self.off_weapon_speed_current = self.off_weapon_speed
end

-- Starts a new swing for mainhand (false), offhand (true) or both (nil)
addon_data.unit.ResetSwingTimer = function(self, isOffhand)
	if isOffhand == nil then
		self:ResetMainSwingTimer()
		self:ResetOffSwingTimer()
	elseif isOffhand then
		self:ResetOffSwingTimer()
	else
		self:ResetMainSwingTimer()
	end
end
addon_data.unit.ResetMainSwingTimer = function(self)
    self.main_swing_timer = self.main_weapon_speed
end
addon_data.unit.ResetOffSwingTimer = function(self)
	if not self.has_offhand then return end
    self.off_swing_timer = self.off_weapon_speed
end

addon_data.unit.ZeroizeSwingTimers = function(self)
    self.main_swing_timer = 0
    self.off_swing_timer = 0
end

addon_data.unit.Initialize = function(self)
	local settingString = "character_" .. self.unitId .. "_settings"
	self.settings = _G[settingString] or {enabled = false}
	self:ResetWeaponSpeed()
	self:ZeroizeSwingTimers()
end

addon_data.unit.UpdateSwingTimer = function(self, elapsed)
	self.main_swing_timer = max(0, self.main_swing_timer - elapsed)
	if self.has_offhand then
		self.off_swing_timer = max(0, self.off_swing_timer - elapsed)
	end
end

addon_data.unit.OnUpdate = function(self, elapsed)
	if not self.settings.enabled then return end
	self:UpdateWeaponSpeed()
	self:UpdateSwingTimer(elapsed)
	self:UpdateVisualsOnUpdate()
end

addon_data.unit.OnCombatLogUnfiltered = function(self, combat_info)
    local _, event, _, source_guid, _, _, _, dest_guid, _, _, _, _, spell_name, _ = unpack(combat_info)
    if source_guid == UnitGUID(self.unitId) then
        if event == "SWING_DAMAGE" then
			self:ResetWeaponSpeed(combat_info[21])
			self:ResetSwingTimer(combat_info[21])
		elseif event == "SWING_MISSED" then
			self:ResetWeaponSpeed(combat_info[13])
			self:ResetSwingTimer(combat_info[13])
		elseif event == "SPELL_AURA_APPLIED" then
			local c = hasteMultipliers[combat_info[13]]
			if c == nil then return end
			self.nextHasteMultiplier = self.nextHasteMultiplier * c
		elseif event == "SPELL_AURA_REMOVED" then
			local c = hasteMultipliers[combat_info[13]]
			if c == nil then return end
			self.nextHasteMultiplier = self.nextHasteMultiplier / c
        end
    end
	if dest_guid == UnitGUID(self.unitId) then
		local miss_type
		local is_offhand = false
		if event == "SWING_MISSED" then
			miss_type = combat_info[12]
			is_offhand = combat_info[13]
		elseif event == "SPELL_MISSED" then
			miss_type = combat_info[15]
		else
			return
		end
		if miss_type ~= "PARRY" then return end
		-- Parry haste mechanics from magey's github wiki
		local c = max(0, min(0.4, self.main_swing_timer / self.main_weapon_speed - .2))
		self.main_swing_timer = self.main_swing_timer - c * self.main_weapon_speed
	end
end
