--- @class Player
--- @field SWCS_IsFlashBangActive fun(self: Player): boolean

--- @class Weapon
--- @field IsSWCSWeapon boolean|nil

--- @class SWCSWeapon : Weapon
--- @field GetIsScoped fun(self: SWCSWeapon) : boolean
--- @field GetWeaponType fun(self: SWCSWeapon): string

--- @param Attacker Player
--- @param Weapon SWCSWeapon
--- @param Victim Entity|string
--- @param Flags number
local function WriteSWCSDeathNotice(Attacker, Weapon, Victim, Flags)
	local Flashbanged = Attacker:SWCS_IsFlashBangActive()
	local HeadShot = false
	local NoScope = Weapon:GetWeaponType() == "sniperrifle" and not Weapon:GetIsScoped()
	local ThroughSmoke = false
	local WallBang = false

	local VictimIsEntity = isentity(Victim)

	if VictimIsEntity then
		--- @cast Victim Entity
		if Victim:IsPlayer() then
			--- @cast Victim Player
			HeadShot = Victim:LastHitGroup() == HITGROUP_HEAD
		end
		--- @cast Victim Entity
	end

	local GAMEMODE = gmod.GetGamemode()

	local LastFiredBullets = Attacker.m_pLastFiredBullets
	if LastFiredBullets then
		local Count = #LastFiredBullets

		for i = 1, Count do
			local Bullet = LastFiredBullets[i]
			local BulletTrace = Bullet.Trace

			if not BulletTrace.Hit then continue end

			local HitEntity = BulletTrace.Entity
			local HitClass = (HitEntity and IsValid(HitEntity)) and HitEntity:GetClass() or nil
			local HitVictim = false

			if VictimIsEntity then
				HitVictim = HitEntity == Victim
			else
				--- @cast Victim string
				--- @diagnostic disable-next-line: param-type-mismatch, need-check-nil
				HitVictim = GAMEMODE:GetDeathNoticeEntityName(HitEntity) == Victim -- They really should have made this always pass in an entity, also the LuaLS definition for this function is fucked up
			end

			--- @diagnostic disable-next-line: undefined-global
			if swcs.IsLineBlockedBySmoke(BulletTrace.StartPos, BulletTrace.HitPos, 1) --[[and HitEntity == Victim]] then -- From SWCS
				ThroughSmoke = true
			end

			if HitVictim then
				-- TODO: This does not work for NPCs when they get wallbanged
				if not HeadShot and BulletTrace.HitGroup == HITGROUP_HEAD then
					HeadShot = true
				end

				continue
			end

			-- TODO: This is kind of lazy
			if BulletTrace.HitWorld or bit.band(BulletTrace.Contents, CONTENTS_SOLID) == CONTENTS_SOLID then
				WallBang = true
				break
			end
		end
	end

	-- TODO: Maybe writing a second Flags bit for addon compatibility would be wise
	local IsZeus = Weapon:GetClass() == "weapon_swcs_taser"
	local IsKnife = Weapon:GetWeaponType() == "knife"

	if Flashbanged then Flags = bit.bor(Flags, DEATH_NOTICE_FLASHBANGED) end

	if not IsKnife then
		if not IsZeus and HeadShot then Flags = bit.bor(Flags, DEATH_NOTICE_HEAD_SHOT) end
		if NoScope then Flags = bit.bor(Flags, DEATH_NOTICE_NO_SCOPE) end
		if not IsZeus and ThroughSmoke then Flags = bit.bor(Flags, DEATH_NOTICE_THROUGH_SMOKE) end
		if WallBang then Flags = bit.bor(Flags, DEATH_NOTICE_WALL_BANG) end
	end

	net.Start("DeathNoticeEvent")
		net.WriteUInt(2, 2)
		net.WriteEntity(Attacker)

		net.WriteString(Weapon:GetClass()) -- 0-512? nah.

		if isstring(Victim) then
			--- @cast Victim string
			net.WriteUInt(1, 2)
			net.WriteString(Victim)
		elseif IsValid(Victim) then
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
					--- @cast Weapon SWCSWeapon
					WriteSWCSDeathNotice(Attacker, Weapon, Victim, Flags)
					return
				end
			end
		end

		self:_SendDeathNotice(Attacker, Inflictor, Victim, Flags)
	end
end)
