--- @enum DeathDrawType
local DeathDrawType = {
	STRING = 1,
	ICON = 2
}

--- @class DeathNoticeDraw
--- @field Type DeathDrawType
--- @field Data string

local hud_deathnotice_time = nil
local cl_drawhud = nil

--- @param DeathDraws DeathNoticeDraw[]
--- @return number, number
local function GetDeathDrawSize(DeathDraws)
	local Width = 0
	local Height = 0

	for i = 1, #DeathDraws do
		local DeathDraw = DeathDraws[i]

		if DeathDraw.Type == DeathDrawType.STRING then
			surface.SetFont("ChatFont")
			local TWidth, THeight = surface.GetTextSize(DeathDraw.Data)

			Width = Width + TWidth + 16
		elseif DeathDraw.Type == DeathDrawType.ICON then
			local IWidth, IHeight = killicon.GetSize(DeathDraw.Data)

			Width = Width + IWidth + 16
			Height = math.max(Height, IHeight)
		end
	end

	Width = Width - 16

	return Width, Height
end

--- @param x number
--- @param y number
--- @param Death DeathNotice
--- @param Time number
--- @return number
local function DrawDeathNotice(x, y, Death, Time)
	local Width, Height = killicon.GetSize(Death.icon)
	if not Width or not Height then return 0 end

	local Fade = (Death.time + Time) - CurTime()

	local Alpha = math.Clamp(Fade * 255, 0, 255)

	local Flags = Death.flags
	--- @type DeathNoticeDraw[]
	local Order = {}

	if bit.band(Flags, DEATH_NOTICE_FLASHBANGED) == DEATH_NOTICE_FLASHBANGED then
		Order[#Order + 1] = {
			Type = DeathDrawType.ICON,
			Data = "swcs_flashbanged"
		}
	end

	if Death.left then
		Order[#Order + 1] = {
			Type = DeathDrawType.STRING,
			Data = Death.left
		}
	end

	Order[#Order + 1] = {
		Type = DeathDrawType.ICON,
		Data = Death.icon
	}

	if bit.band(Flags, DEATH_NOTICE_THROUGH_SMOKE) == DEATH_NOTICE_THROUGH_SMOKE then
		Order[#Order + 1] = {
			Type = DeathDrawType.ICON,
			Data = "swcs_through_smoke"
		}
	end

	if bit.band(Flags, DEATH_NOTICE_WALL_BANG) == DEATH_NOTICE_WALL_BANG then
		Order[#Order + 1] = {
			Type = DeathDrawType.ICON,
			Data = "swcs_wall_bang"
		}
	end

	if bit.band(Flags, DEATH_NOTICE_HEAD_SHOT) == DEATH_NOTICE_HEAD_SHOT then
		Order[#Order + 1] = {
			Type = DeathDrawType.ICON,
			Data = "swcs_head_shot"
		}
	end

	Order[#Order + 1] = {
		Type = DeathDrawType.STRING,
		Data = Death.right
	}

	local DrawWidth, DrawHeight = GetDeathDrawSize(Order)
	x = x - DrawWidth

	for i = 1, #Order do
		local DeathDraw = Order[i]

		if DeathDraw.Type == DeathDrawType.STRING then
			surface.SetFont("ChatFont")
			local TWidth, THeight = surface.GetTextSize(DeathDraw.Data)

			surface.SetAlphaMultiplier(Fade)
				surface.SetTextColor(255, 255, 255, 255) -- TODO: color1, color2
				surface.SetTextPos(x, y + ((Height * 0.5) - (THeight * 0.5)))
				surface.DrawText(DeathDraw.Data)
			surface.SetAlphaMultiplier(1)

			x = x + TWidth + 16
		elseif DeathDraw.Type == DeathDrawType.ICON then
			local IWidth, IHeight = killicon.GetSize(DeathDraw.Data)
			killicon.Render(x, y, DeathDraw.Data, Alpha)

			x = x + IWidth + 16
		end
	end

	return math.ceil(y + Height * 0.75)
end

hook.Add("PostGamemodeLoaded", "swcs_kill_icons", function()
	hud_deathnotice_time = GetConVar("hud_deathnotice_time")
	cl_drawhud = GetConVar("cl_drawhud")

	local GAMEMODE = gmod.GetGamemode()
	local _, Deaths = debug.getupvalue(GAMEMODE.AddDeathNotice, 2)

	if not istable(Deaths) then
		return
	end
	--- @cast Deaths table<number, DeathNotice>

	function GAMEMODE:DrawDeathNotice(x, y)
		if not cl_drawhud:GetBool() then
			return
		end

		local Time = hud_deathnotice_time:GetFloat()
		local Reset = Deaths[1] ~= nil

		x = x * ScrW()
		y = y * ScrH()

		local Count = #Deaths

		for i = 1, Count do
			local Death = Deaths[i]

			if Death.time + Time < CurTime() then
				continue
			end

			if Death.lerp then
				x = x * 0.3 + Death.lerp.x * 0.7
				y = y * 0.3 + Death.lerp.y * 0.7
			else
				--- @diagnostic disable-next-line: missing-fields
				Death.lerp = {}
			end

			Death.lerp.x = x
			Death.lerp.y = y

			y = DrawDeathNotice(math.floor(x), math.floor(y), Death, Time)
			Reset = false
		end

		if Reset then
			table.Empty(Deaths)
		end
	end

	-- --- @diagnostic disable-next-line: redundant-parameter
	-- hook.Add("AddDeathNotice", "swcs_kill_icons", function(Attacker, AttackerTeam, Inflictor, Victim, VictimTeam, Flags) -- Flags is undocumented
	-- 	--- @type DeathNotice
	-- 	local Death = {
	-- 		time = CurTime(),

	-- 		left = Attacker,
	-- 		right = Victim,

	-- 		icon = Inflictor,
	-- 		flags = Flags,

	-- 		color1 = color_white,
	-- 		color2 = color_white
	-- 	}

	-- 	table.insert(Deaths, Death)

	-- 	return true
	-- end)
end)
