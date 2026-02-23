--- @class SWCSBulletTrace
--- @field dmg number
--- @field ent Entity
--- @field mainTrace boolean|nil
--- @field trace TraceResult

--- @class SWCSStoredBulletTrace : SWCSBulletTrace
--- @field AttackFlags number

--- @class Entity
--- @field m_iSWCSLastFiredTick number|nil
--- @field m_pSWCSTracedAttacks SWCSStoredBulletTrace[]|nil

hook.Add("SWCSBulletTraceDamage", "swcs_kill_icons", function(BulletTrace, DamageInfo)
	--- @cast BulletTrace SWCSBulletTrace
	--- @cast DamageInfo CTakeDamageInfo

	local Attacker = DamageInfo:GetAttacker()
	local Inflictor = DamageInfo:GetInflictor() --[[@as Weapon]]
	local Victim = BulletTrace.ent

	if not Attacker:IsValid() or not (Attacker:IsPlayer() or Attacker:IsNPC()) then
		return
	end
	--- @cast Attacker Player|NPC

	if not Inflictor:IsValid() or not Inflictor:IsWeapon() or not Inflictor.IsSWCSWeapon then
		-- This should never happen
		return
	end

	if not Victim:IsValid() then
		return
	end

	local Weapon = Inflictor --[[@as SWCSWeapon]]
	local IsZeus = Weapon:GetClass() == "weapon_swcs_taser"

	local TickCount = engine.TickCount()
	local LastFiredTick = Attacker.m_iSWCSLastFiredTick

	if not LastFiredTick or LastFiredTick < TickCount then
		Attacker.m_iSWCSLastFiredTick = TickCount
		Attacker.m_pSWCSTracedAttacks = {}
	end

	local AttackFlags = 0

	local StoredTrace = table.Copy(BulletTrace) --[[@as SWCSStoredBulletTrace]]
	local Trace = StoredTrace.trace

	if Attacker:IsPlayer() then
		--- @cast Attacker Player
		if Attacker:SWCS_IsFlashBangActive() then
			AttackFlags = bit.bor(AttackFlags, DEATH_NOTICE_FLASHBANGED)
		end
	end

	if not IsZeus and Trace.HitGroup == HITGROUP_HEAD then
		AttackFlags = bit.bor(AttackFlags, DEATH_NOTICE_HEAD_SHOT)
	end

	if Weapon:GetWeaponType() == "sniperrifle" and not Weapon:GetIsScoped() then
		AttackFlags = bit.bor(AttackFlags, DEATH_NOTICE_NO_SCOPE)
	end

	--- @diagnostic disable-next-line: undefined-global
	if not IsZeus and swcs.IsLineBlockedBySmoke(Trace.StartPos, Trace.HitPos, 1) then
		AttackFlags = bit.bor(AttackFlags, DEATH_NOTICE_THROUGH_SMOKE)
	end

	if not StoredTrace.mainTrace then
		AttackFlags = bit.bor(AttackFlags, DEATH_NOTICE_WALL_BANG)
	end

	StoredTrace.AttackFlags = AttackFlags

	table.insert(Attacker.m_pSWCSTracedAttacks, StoredTrace)
end)
