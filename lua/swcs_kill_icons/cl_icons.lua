local _, KillIcons = debug.getupvalue(killicon.Add, 1)
--- @cast KillIcons table<string, KillIcon>
local COLOR_ICON = Color(255, 80, 0)

--- Adds a custom kill icon, same as the function from SWCS
--- @param Name string
--- @param Path string
local function AddKillIcon(Name, Path)
	local IconMaterial = Material(Path, "smooth")
	IconMaterial:SetInt("$flags", bit.bor(IconMaterial:GetInt("$flags"), 128)) -- $additive
	IconMaterial:Recompute()

	KillIcons[Name] = {
		type = 1,
		color = COLOR_ICON,
		material = IconMaterial,
		texture = surface.GetTextureID("hud/killicons/default.vmt")
	}
end

AddKillIcon("swcs_flashbang_assist", "hud/swcs/flashbang_assist.png")
AddKillIcon("swcs_flashbanged", "hud/swcs/flashbanged.png")
AddKillIcon("swcs_head_shot", "hud/swcs/head_shot.png")
AddKillIcon("swcs_no_scope", "hud/swcs/no_scope.png")
AddKillIcon("swcs_through_smoke", "hud/swcs/through_smoke.png")
AddKillIcon("swcs_wall_bang", "hud/swcs/wall_bang.png")
