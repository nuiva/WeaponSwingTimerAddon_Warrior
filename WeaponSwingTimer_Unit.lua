local addon_name, addon_data = ...

addon_data.unit = {}
addon_data.unit.__index = addon_data.unit

addon_data.unit.new = function(self, unitId)
	local a = {}
	a.unitId = unitId
	setmetatable(a, self)
	return a
end

addon_data.unit.UpdateWeaponSpeed = function(self)
	local mainSpeed, offSpeed = UnitAttackSpeed(self.unitId)
	if mainSpeed == self.main_weapon_speed_current then return end
	local haste = mainSpeed / (self.main_weapon_speed_current or mainSpeed)
	self.main_weapon_speed_current = mainSpeed
	self.off_weapon_speed_current = offSpeed
	if self.ignoreNextHaste then
		self.ignoreNextHaste = false
		return
	end
	self.main_swing_timer = self.main_swing_timer * haste
	self.main_weapon_speed = self.main_weapon_speed * haste
	if self.has_offhand then
		self.off_swing_timer = self.off_swing_timer * haste
		self.off_weapon_speed = self.off_weapon_speed * haste
	end
end
	