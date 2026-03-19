--================================================================================
-- Standalone Limb Damage Indicator
-- Features: Smooth fading, color transitions (Gray > Orange > Red), amputation hiding
--================================================================================

if SERVER then
	-- Limb sprites
	local SPRITES = {
		"materials/vgui/hud/health_head.png",
		"materials/vgui/hud/health_torso.png",
		"materials/vgui/hud/health_right_arm.png",
		"materials/vgui/hud/health_left_arm.png",
		"materials/vgui/hud/health_right_leg.png",
		"materials/vgui/hud/health_left_leg.png",
	}
	
	for _, path in ipairs(SPRITES) do resource.AddFile(path) end
	
	-- Make sure to change this string to whatever you name this lua file in your autorun folder
	AddCSLuaFile("autorun/zb_limb_indicator.lua") 
	
	return
end

--================================================================================
-- CLIENT SIDE 
--================================================================================

local math_min, math_max, math_floor, Lerp = math.min, math.max, math.floor, Lerp
local Color = Color
local draw_SimpleText = draw.SimpleText
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local ScrW, ScrH = ScrW, ScrH
local FrameTime = FrameTime

-- Safe value getter
local function getOrgVal(org, key, def)
	local v = org[key]
	return type(v) == "number" and v or (def or 0)
end

-- Get nested table value
local function getOrgTableVal(org, tbl, key, index, def)
	if not org[tbl] or type(org[tbl]) ~= "table" then return def or 0 end
	local val = org[tbl][key]
	if index and type(val) == "table" then
		val = val[index]
	end
	return type(val) == "number" and val or (def or 0)
end

-- Limb color scheme (Gray → Orange → Red)
local function getLimbColor(damage)
	local ratio = math_min(math_max(damage, 0), 1)
	if ratio <= 0.3 then return Color(128, 128, 128, 255)    -- Gray = healthy
	elseif ratio <= 0.6 then return Color(255, 165, 0, 255)  -- Orange = moderate
	else return Color(255, 0, 0, 255) end                    -- Red = severe
end

-- Check if any limb is damaged
local function hasAnyLimbDamage(org)
	return (getOrgVal(org, "skull", 0) > 0.01 or
			getOrgVal(org, "jaw", 0) > 0.01 or
			getOrgVal(org, "chest", 0) > 0.01 or
			getOrgVal(org, "spine1", 0) > 0.01 or
			getOrgVal(org, "spine2", 0) > 0.01 or
			getOrgVal(org, "spine3", 0) > 0.01 or
			getOrgVal(org, "pelvis", 0) > 0.01 or
			getOrgVal(org, "rarm", 0) > 0.01 or
			getOrgVal(org, "larm", 0) > 0.01 or
			getOrgVal(org, "rleg", 0) > 0.01 or
			getOrgVal(org, "lleg", 0) > 0.01)
end

-- ===== CONFIGURATION =====
local HUD = {
	enabled = true,
	base_x = nil,
	base_y = nil,
	
	limb_offsets = {
		head =        { x = 55,   y = -15 },
		torso =       { x = 54,   y = 33 },
		right_arm =   { x = 83,   y = 36 },
		left_arm =    { x = 24,   y = 38 },
		right_leg =   { x = 66,   y = 92 },
		left_leg =    { x = 35,   y = 106 },
	},
	
	limb_scale = {
		head =        { w = 1, h = 1 },
		torso =       { w = 1.4, h = 1.8 },
		right_arm =   { w = 1, h = 2 },
		left_arm =    { w = 1, h = 2 },
		right_leg =   { w = 1.2, h = 3.5 },
		left_leg =    { w = 1.2, h = 2.7 },
	},
	
	sprite_visibility = 100,
	always_show_limbs = false,
	show_damage_percent = false,
	limb_fade_speed = 3.0,
}

-- Material cache
local sprites = {}
local debug_done = false

-- Limb fade states for smooth transitions
local limbFadeStates = {
	head = {alpha = 0, target = 0},
	torso = {alpha = 0, target = 0},
	right_arm = {alpha = 0, target = 0},
	left_arm = {alpha = 0, target = 0},
	right_leg = {alpha = 0, target = 0},
	left_leg = {alpha = 0, target = 0},
}

local limbsRevealed = false

--================================================================================
-- DRAW: Limb sprites
--================================================================================
local function draw_sprites()
	if not HUD.enabled then return end
	
	local ply = LocalPlayer()
	if not IsValid(ply) or not ply.organism then return end
	
	local sideMoodles = GetConVar("hg_sidemoodles"):GetBool()

	if sideMoodles then
		HUD.base_x = 16
		HUD.base_y = 60
	else
		if HUD.base_x == nil then HUD.base_x = ScrW() - 120 end
		HUD.base_y = 60
	end
	
	local org = ply.organism
	local base_x = HUD.base_x
	local base_y = HUD.base_y
	local dt = FrameTime() * HUD.limb_fade_speed
	
	if not debug_done then
		debug_done = true
		local paths = {
			head = {"vgui/hud/health_head.png", "vgui/hud/health_head"},
			torso = {"vgui/hud/health_torso.png", "vgui/hud/health_torso"},
			right_arm = {"vgui/hud/health_right_arm.png", "vgui/hud/health_right_arm"},
			left_arm = {"vgui/hud/health_left_arm.png", "vgui/hud/health_left_arm"},
			right_leg = {"vgui/hud/health_right_leg.png", "vgui/hud/health_right_leg"},
			left_leg = {"vgui/hud/health_left_leg.png", "vgui/hud/health_left_leg"},
		}
		
		for name, tries in pairs(paths) do
			for _, path in ipairs(tries) do
				local mat = Material(path, "smooth")
				if mat and not mat:IsError() then
					sprites[name] = mat
					break
				end
			end
			if not sprites[name] then sprites[name] = false end
		end
	end
	
	-- Check if any limb is damaged
	local anyDamage = hasAnyLimbDamage(org)
	
	-- Update reveal state
	if anyDamage and not limbsRevealed then
		limbsRevealed = true
	elseif not anyDamage and limbsRevealed then
		limbsRevealed = false
	end
	
	-- Define limbs with their damage values and amputation flags
	local limbs = {
		{name = "head", dmg = math_max(getOrgVal(org, "skull", 0), getOrgVal(org, "jaw", 0) * 0.7, getOrgVal(org, "arteria", 0), getOrgVal(org, "vein", 0), getOrgVal(org, "arteria_l", 0), getOrgVal(org, "arteria_r", 0), getOrgVal(org, "vein_l", 0), getOrgVal(org, "vein_r", 0)), amput = "headamputated", label = "H"},
		{name = "torso", dmg = math_max(getOrgVal(org, "chest", 0), getOrgVal(org, "spine1", 0), getOrgVal(org, "spine2", 0), getOrgVal(org, "spine3", 0), getOrgVal(org, "pelvis", 0) * 0.9, getOrgVal(org, "heart", 0), getOrgTableVal(org, "lungsL", 1, nil, 0), getOrgTableVal(org, "lungsR", 1, nil, 0), getOrgVal(org, "trachea", 0), getOrgVal(org, "liver", 0), getOrgVal(org, "stomach", 0), getOrgVal(org, "intestines", 0)), amput = nil, label = "T"},
		{name = "right_arm", dmg = math_max(getOrgVal(org, "rarm", 0), getOrgVal(org, "rarmartery", 0), getOrgVal(org, "rarmvein", 0), getOrgVal(org, "rarmartery_1", 0), getOrgVal(org, "rarmartery_2", 0)), amput = "rarmamputated", label = "RA"},
		{name = "left_arm", dmg = math_max(getOrgVal(org, "larm", 0), getOrgVal(org, "larmartery", 0), getOrgVal(org, "larmvein", 0), getOrgVal(org, "larmartery_1", 0), getOrgVal(org, "larmartery_2", 0)), amput = "larmamputated", label = "LA"},
		{name = "right_leg", dmg = math_max(getOrgVal(org, "rleg", 0), getOrgVal(org, "rlegartery", 0), getOrgVal(org, "rlegvein", 0)), amput = "rlegamputated", label = "RL"},
		{name = "left_leg", dmg = math_max(getOrgVal(org, "lleg", 0), getOrgVal(org, "llegartery", 0), getOrgVal(org, "llegvein", 0)), amput = "llegamputated", label = "LL"},
	}
	
	-- Update fade states for each limb
	for _, limb in ipairs(limbs) do
		local state = limbFadeStates[limb.name]
		if not state then continue end
		
		-- Skip if limb is amputated (always hidden)
		if limb.amput and org[limb.amput] then
			state.target = 0
		else
			-- Set target alpha based on reveal state
			if HUD.always_show_limbs then
				state.target = 255
			else
				-- Show all limbs when any damage is present, hide when completely healed
				state.target = limbsRevealed and 255 or 0
			end
		end
		
		-- Smoothly interpolate alpha
		state.alpha = Lerp(dt, state.alpha, state.target)
		
		-- If alpha is very low, skip drawing (optimization)
		if state.alpha < 1 then
			continue
		end
		
		local dmg = limb.dmg
		local ofs = HUD.limb_offsets[limb.name] or {x = 0, y = 0}
		local scale = HUD.limb_scale[limb.name] or {w = 1.0, h = 1.0}
		
		local x = base_x + ofs.x
		local y = base_y + ofs.y
		
		local base_size = 40
		local width = base_size * scale.w
		local height = base_size * scale.h
		
		local col = getLimbColor(dmg)
		local damage_boost = math_min(dmg * 150, 100)
		local total_visibility = math_min(HUD.sprite_visibility + damage_boost, 100)
		local alpha = math_floor(state.alpha * (total_visibility / 100))
		
		local mat = sprites[limb.name]
		if mat and not mat:IsError() then
			surface_SetDrawColor(col.r, col.g, col.b, alpha)
			surface_SetMaterial(mat)
			surface_DrawTexturedRect(x - width * 0.5, y - height * 0.5, width, height)
		else
			surface_SetDrawColor(0, 0, 0, math_floor(alpha * 0.5))
			surface_DrawRect(x - width * 0.5 + 2, y - height * 0.5 + 2, width - 4, height - 4)
			surface_SetDrawColor(col.r, col.g, col.b, alpha)
			surface_DrawRect(x - width * 0.5 + 4, y - height * 0.5 + 4, width - 8, height - 8)
			draw_SimpleText(limb.label, "TargetID", x, y, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		end
	end
end

-- Register hook
hook.Add("HUDPaint", "ZB_Limb_Indicator_Standalone", draw_sprites)

--================================================================================
-- Console commands
--================================================================================
concommand.Add("mzb_limbs_toggle", function(ply, cmd, args)
	HUD.enabled = args[1] and (tonumber(args[1]) ~= 0) or not HUD.enabled
	chat.AddText(Color(0, 200, 255), "Limb HUD ", HUD.enabled and "Enabled" or "Disabled")
end)

concommand.Add("mzb_limbs_alpha", function(ply, cmd, args)
	if args[1] then
		local v = tonumber(args[1])
		if v then
			HUD.sprite_visibility = math.Clamp(v, 0, 100)
			chat.AddText(Color(0, 200, 255), "Limb visibility: ", Color(255, 255, 255), HUD.sprite_visibility .. "%")
		end
	end
end)

concommand.Add("mzb_popalimbs", function(ply, cmd, args)
	HUD.always_show_limbs = not HUD.always_show_limbs
	local status = HUD.always_show_limbs and "ON (always visible)" or "OFF (show if damaged)"
	chat.AddText(Color(0, 200, 255), "Limbs Viewer: ", HUD.always_show_limbs and Color(100, 255, 100, 255) or Color(255, 100, 100, 255), status)
end)

concommand.Add("mzb_limbs_fade_speed", function(ply, cmd, args)
	if args[1] then
		local v = tonumber(args[1])
		if v then
			HUD.limb_fade_speed = math.Clamp(v, 0.5, 10)
			chat.AddText(Color(0, 200, 255), "Limb fade speed: ", Color(255, 255, 255), HUD.limb_fade_speed)
		end
	end
end)

concommand.Add("mzb_limbs_percent", function(ply, cmd, args)
	HUD.show_damage_percent = not HUD.show_damage_percent
	chat.AddText(Color(0, 200, 255), "Limb damage percent: ", HUD.show_damage_percent and Color(100, 255, 100, 255) or Color(255, 100, 100, 255), HUD.show_damage_percent and "ON" or "OFF")
end)