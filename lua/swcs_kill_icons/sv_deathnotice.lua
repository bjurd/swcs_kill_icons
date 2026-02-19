--- @class Player
--- @field SWCS_IsFlashBangActive fun(self: Player): boolean

--- @class Weapon
--- @field IsSWCSWeapon boolean|nil

--- @param Attacker Player
--- @param Weapon Weapon
--- @param Victim Entity|string
--- @param Flags number
local function WriteSWCSDeathNotice(Attacker, Weapon, Victim, Flags)
	local Flashbanged = Attacker:SWCS_IsFlashBangActive()
	local HeadShot = false
	local NoScope = false
	local ThroughSmoke = false
	local WallBang = false

	if isentity(Victim) then
		--- @cast Victim Entity
		if Victim:IsPlayer() then
			--- @cast Victim Player
			HeadShot = Victim:LastHitGroup() == HITGROUP_HEAD
		end
	end

	-- TODO: Maybe writing a second Flags bit for addon compatibility would be wise
	if Flashbanged then Flags = bit.bor(Flags, DEATH_NOTICE_FLASHBANGED) end
	if HeadShot then Flags = bit.bor(Flags, DEATH_NOTICE_HEAD_SHOT) end
	if NoScope then Flags = bit.bor(Flags, DEATH_NOTICE_NO_SCOPE) end
	if ThroughSmoke then Flags = bit.bor(Flags, DEATH_NOTICE_THROUGH_SMOKE) end
	if WallBang then Flags = bit.bor(Flags, DEATH_NOTICE_WALL_BANG) end

	net.Start("DeathNoticeEvent")
		net.WriteUInt(2, 2)
		net.WriteEntity(Attacker)

		net.WriteString(Weapon:GetClass()) -- 0-512? nah.

		if isstring(Victim) then
			--- @cast Victim string
			net.WriteUInt(1, 2)
			net.WriteString(Victim)
		elseif Victim:IsValid() then
			--- @cast Victim Entity
			net.WriteUInt(2, 2)
			net.WriteEntity(Victim)
		else
			net.WriteUInt(0, 2)
		end

		net.WriteUInt(Flags, 8)
	net.Broadcast()
end

hook.Add("PostGamemodeLoaded", "swcs_kill_icons", function()
	local GAMEMODE = gmod.GetGamemode()

	GAMEMODE._SendDeathNotice = GAMEMODE._SendDeathNotice or GAMEMODE.SendDeathNotice
	function GAMEMODE:SendDeathNotice(Attacker, Inflictor, Victim, Flags)
		if isentity(Attacker) then
			--- @cast Attacker Entity
			if Attacker:IsPlayer() then -- LuaLS making me write ugly ifs :/
				--- @cast Attacker Player
				local Weapon = Attacker:GetActiveWeapon()

				if Weapon:IsValid() and Weapon.IsSWCSWeapon then
					WriteSWCSDeathNotice(Attacker, Weapon, Victim, Flags)
					return
				end
			end
		end

		self:_SendDeathNotice(Attacker, Inflictor, Victim, Flags)
	end
end)
