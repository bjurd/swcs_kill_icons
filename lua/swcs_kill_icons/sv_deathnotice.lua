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
	if Attacker:SWCS_IsFlashBangActive() then
		-- For things that don't fire bullets (knives)
		Flags = bit.bor(Flags, DEATH_NOTICE_FLASHBANGED)
	end

	--- @type SWCSStoredBulletTrace
	local AttackToUse = nil
	local VictimIsEntity = isentity(Victim)

	local LastTracedAttacks = Attacker.m_pSWCSTracedAttacks
	if istable(LastTracedAttacks) and Attacker.m_iSWCSLastFiredTick == engine.TickCount() then
		--- @cast LastTracedAttacks SWCSStoredBulletTrace[]

		local GAMEMODE = gmod.GetGamemode()

		local Count = #LastTracedAttacks
		for i = Count, 1, -1 do
			local Attack = LastTracedAttacks[i]

			if VictimIsEntity then
				if Attack.ent == Victim then
					-- TODO: This is bad if they take damage from multiple bullets in a tick
					-- because it's difficult to know which one actually killed them
					AttackToUse = Attack
					break
				end
			else
				local HitEntity = Attack.trace.Entity

				--- @diagnostic disable-next-line: param-type-mismatch
				if GAMEMODE:GetDeathNoticeEntityName(HitEntity) == Victim then
					-- TODO: This is also bad if they attack multiple of the same entity in a tick
					AttackToUse = Attack
					break
				end
			end
		end
	end

	if AttackToUse then
		Flags = bit.bor(Flags, AttackToUse.AttackFlags)

		-- This is always valid if AttackToUse is valid
		--- @cast LastTracedAttacks SWCSStoredBulletTrace[]
		-- This is done so that if multiple things of the same class are killed, but differently, the feeds don't get duplicated
		-- Which means that technically it's possible for the feeds to be backwards as the entities can be mistaken for each other,
		-- but since all that's shown is their display name, it isn't possible to tell which is which and shouldn't be noticeable
		table.RemoveByValue(LastTracedAttacks, AttackToUse)
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

				if Weapon:IsValid() and Weapon.IsSWCSWeapon and Weapon:GetClass() == Inflictor then
					--- @cast Weapon SWCSWeapon
					WriteSWCSDeathNotice(Attacker, Weapon, Victim, Flags)
					return
				end
			end
		end

		self:_SendDeathNotice(Attacker, Inflictor, Victim, Flags)
	end
end)
