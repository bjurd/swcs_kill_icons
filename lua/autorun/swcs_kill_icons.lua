--- @class DeathNoticeLerp
--- @field x number
--- @field y number

--- @class DeathNotice
--- @field time number
--- @field left string|nil
--- @field right string
--- @field icon string
--- @field flags number
--- @field color1 Color
--- @field color2 Color
--- @field lerp DeathNoticeLerp|nil

--- @class KillIcon

DEATH_NOTICE_FLASHBANGED = bit.lshift(1, 2)
DEATH_NOTICE_HEAD_SHOT = bit.lshift(1, 3)
DEATH_NOTICE_NO_SCOPE = bit.lshift(1, 4)
DEATH_NOTICE_THROUGH_SMOKE = bit.lshift(1, 5)
DEATH_NOTICE_WALL_BANG = bit.lshift(1, 6)

if SERVER then
	AddCSLuaFile("swcs_kill_icons/cl_icons.lua")
	AddCSLuaFile("swcs_kill_icons/cl_deathnotice.lua")

	include("swcs_kill_icons/sv_bullet_track.lua")
	include("swcs_kill_icons/sv_deathnotice.lua")
elseif CLIENT then
	include("swcs_kill_icons/cl_icons.lua")
	include("swcs_kill_icons/cl_deathnotice.lua")
end
