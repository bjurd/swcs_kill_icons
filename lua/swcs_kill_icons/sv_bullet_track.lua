--- @class Entity
--- @field m_iLastFiredTick number|nil
--- @field m_pLastFiredBullets FiredBullet[]

hook.Add("PostEntityFireBullets", "swcs_kill_icons", function(Entity, Data)
	if not IsFirstTimePredicted() then return end

	if Entity:IsPlayer() then
		--- @cast Entity Player
		local Weapon = Entity:GetActiveWeapon()

		if Weapon:IsValid() and Weapon.IsSWCSWeapon then
			local TickCount = engine.TickCount()

			if not Entity.m_iLastFiredTick or Entity.m_iLastFiredTick < TickCount then
				Entity.m_iLastFiredTick = TickCount
				Entity.m_pLastFiredBullets = {}
			end

			if Entity.m_iLastFiredTick == TickCount then
				if not Entity.m_pLastFiredBullets then
					Entity.m_pLastFiredBullets = {}
				end

				table.insert(Entity.m_pLastFiredBullets, Data)
			end
		else
			Entity.m_iLastFiredTick = nil
			Entity.m_pLastFiredBullets = nil
		end
	end
end)
