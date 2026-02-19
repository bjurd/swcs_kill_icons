--- @class DeathNoticeDraw
--- @field Renderer function
--- @field Arguments any[]

local hud_deathnotice_time = nil
local cl_drawhud = nil

local _, KillIcons = debug.getupvalue(killicon.Add, 1)
--- @cast KillIcons table<string, KillIcon>

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
	Death.color1.a = Alpha
	Death.color2.a = Alpha

	local Flags = Death.flags
	--- @type DeathNoticeDraw[]
	local Order = {}

	if bit.band(Flags, DEATH_NOTICE_FLASHBANGED) == DEATH_NOTICE_FLASHBANGED then
		local Offset = killicon.GetSize(Death.icon)

		if Death.left then
			surface.SetFont("ChatFont")
			local LWidth, LHeight = surface.GetTextSize(Death.left)

			Offset = Offset + LWidth
		end

		table.insert(Order, {
			Renderer = killicon.Render,
			Arguments = { x - (Width * 0.5) - Offset, y, "swcs_flashbanged", Alpha }
		})
	end

	table.insert(Order, {
		Renderer = killicon.Render,
		Arguments = { x - (Width * 0.5), y, Death.icon, Alpha }
	})

	if Death.left then
		table.insert(Order, {
			Renderer = draw.SimpleText,
			Arguments = { Death.left, "ChatFont", x - (Width / 2) - 16, y + Height / 2, Death.color1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER }
		})
	end

	table.insert(Order, {
		Renderer = draw.SimpleText,
		Arguments = { Death.right, "ChatFont", x + (Width / 2) + 16, y + Height / 2, Death.color2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER }
	})

	for i = 1, #Order do
		local DeathNoticeDraw = Order[i]
		DeathNoticeDraw.Renderer(unpack(DeathNoticeDraw.Arguments))
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
