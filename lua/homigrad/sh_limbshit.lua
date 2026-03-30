--================================================================================
-- Standalone Limb Damage Indicator
-- Features: Smooth fading, color transitions (Gray > Orange > Red), amputation hiding
--================================================================================

if SERVER then
	-- Make sure to change this string to whatever you name this lua file in your autorun folder
	AddCSLuaFile("homigrad/sh_limbshit.lua") 
	
	return
end

--================================================================================
-- CLIENT SIDE 
--================================================================================

local math_min, math_max, math_floor, Lerp, sin, rad, cos = math.min, math.max, math.floor, Lerp, math.sin, math.rad, math.cos
local Color = Color
local draw_SimpleText = draw.SimpleText
local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_SetMaterial = surface.SetMaterial
local surface_DrawTexturedRect = surface.DrawTexturedRect
local ScrW, ScrH = ScrW, ScrH
local FrameTime = FrameTime
local RealTime = RealTime

local prev_view_angles = Angle(0,0,0)
local sway_offset_x = 0
local sway_offset_y = 0
local sway_rotation = 0

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

-- Limb color scheme (Gray > Red, Orange for specific conditions)
local function getLimbColor(limb, org, is_otrub)
    if is_otrub then
        local dmg = math.min(limb.dmg, 1)
        local intensity = 128 - (120 * dmg)
        return Color(intensity, intensity, intensity, 255)
    end

    -- Orange for dislocations, arterial bleeding, or near-breaking
    if limb.dislocation or limb.artery > 0 or (limb.dmg > 0.8 and limb.dmg < 1) then
        return Color(255, 165, 0, 255)
    end

    -- Red if broken or severely damaged
    if limb.dmg >= 1 then
        return Color(255, 0, 0, 255)
    end
    
    -- Smooth transition from gray to red
    local r = 128 + (127 * limb.dmg)
    local g = 128 - (128 * limb.dmg)
    local b = 128 - (128 * limb.dmg)
    
    return Color(r, g, b, 255)
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
	base_x = 150, -- Top-left position
	base_y = 150, -- Top-left position
	
	limb_offsets = {
		head =        { x = 0,   y = -55 },
		torso =       { x = 0,   y = 0 },
		right_arm =   { x = 45,  y = -5 },
		left_arm =    { x = -45, y = -5 },
		right_leg =   { x = 25,  y = 65 },
		left_leg =    { x = -25, y = 65 },
	},
	
	limb_scale = {
		head =        { w = 50, h = 50 },
		torso =       { w = 60, h = 80 },
		right_arm =   { w = 25, h = 75 },
		left_arm =    { w = 25, h = 75 },
		right_leg =   { w = 30, h = 85 },
		left_leg =    { w = 30, h = 85 },
	},
	
	sprite_visibility = 100,
	always_show_limbs = false,
	show_damage_percent = true, -- Changed to true
	limb_fade_speed = 3.0,
}

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

    local org = ply.organism
    if org and (org.desensitized or 0) > 0.8 then -- Hide if desensitized level is above 0.8
        return
    end

	-- Sway effect
    local current_view_angles = ply:EyeAngles()
    local angle_diff_y = current_view_angles.y - prev_view_angles.y
    local angle_diff_p = current_view_angles.p - prev_view_angles.p
    prev_view_angles = current_view_angles

    sway_offset_x = Lerp(FrameTime() * 5, sway_offset_x, -angle_diff_y * 2)
    sway_offset_y = Lerp(FrameTime() * 5, sway_offset_y, angle_diff_p * 2)
    sway_rotation = Lerp(FrameTime() * 5, sway_rotation, -angle_diff_y * 1)
	
	
	
	local org = ply.organism
	local base_x = HUD.base_x
	local base_y = HUD.base_y
	local dt = FrameTime() * HUD.limb_fade_speed
	
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
		{name = "head", dmg = math_max(getOrgVal(org, "skull", 0), getOrgVal(org, "jaw", 0) * 0.7), artery = getOrgVal(org, "arteria", 0), internal = 0, dislocation = org.jawdislocation, amput = "headamputated", label = "H"},
		{name = "torso", dmg = math_max(getOrgVal(org, "chest", 0), getOrgVal(org, "spine1", 0), getOrgVal(org, "spine2", 0), getOrgVal(org, "spine3", 0), getOrgVal(org, "pelvis", 0) * 0.9), artery = 0, internal = math_max(getOrgVal(org, "heart", 0), getOrgTableVal(org, "lungsL", 1, nil, 0), getOrgTableVal(org, "lungsR", 1, nil, 0)), dislocation = (org.spine1dislocation or org.spine2dislocation or org.spine3dislocation), amput = nil, label = "T"},
		{name = "right_arm", dmg = getOrgVal(org, "rarm", 0), artery = math_max(getOrgVal(org, "rarmartery", 0), getOrgVal(org, "rarmvein", 0)), internal = 0, dislocation = org.rarmdislocation, amput = "rarmamputated", label = "RA"},
		{name = "left_arm", dmg = getOrgVal(org, "larm", 0), artery = math_max(getOrgVal(org, "larmartery", 0), getOrgVal(org, "larmvein", 0)), internal = 0, dislocation = org.larmdislocation, amput = "larmamputated", label = "LA"},
		{name = "right_leg", dmg = getOrgVal(org, "rleg", 0), artery = math_max(getOrgVal(org, "rlegartery", 0), getOrgVal(org, "rlegvein", 0)), internal = 0, dislocation = org.rlegdislocation, amput = "rlegamputated", label = "RL"},
		{name = "left_leg", dmg = getOrgVal(org, "lleg", 0), artery = math_max(getOrgVal(org, "llegartery", 0), getOrgVal(org, "llegvein", 0)), internal = 0, dislocation = org.llegdislocation, amput = "llegamputated", label = "LL"},
	}

    -- Find the limb with the most pain
    local max_pain = 0
    local pain_source_limb = nil
    for _, limb in ipairs(limbs) do
        local pain = limb.dmg + (limb.dislocation and 0.5 or 0) + (limb.artery > 0 and 0.8 or 0)
        if pain > max_pain then
            max_pain = pain
            pain_source_limb = limb.name
        end
    end
	
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
		local scale = HUD.limb_scale[limb.name] or {w = 40, h = 40}
		
		local x = base_x + ofs.x + sway_offset_x
		local y = base_y + ofs.y + sway_offset_y

        if limb.name == pain_source_limb and max_pain > 0.1 then -- Lowered threshold
            local shake_intensity = math.min(max_pain * 10, 15) -- Increased intensity and cap
            x = x + math.random(-shake_intensity, shake_intensity)
            y = y + math.random(-shake_intensity, shake_intensity)
        end
		
		local width = scale.w
		local height = scale.h
		
		local col = getLimbColor(limb, org)
		local alpha = math_floor(state.alpha * (HUD.sprite_visibility / 100))

        surface.SetDrawColor(col.r, col.g, col.b, alpha)
        
        -- Draw rotated rectangle
        local cx, cy = x + width/2, y + height/2
        local angle = rad(sway_rotation)
        local c, s = cos(angle), sin(angle)

        local x1 = -width/2
        local y1 = -height/2
        
        local x2 = width/2
        local y2 = -height/2
        
        local x3 = width/2
        local y3 = height/2
        
        local x4 = -width/2
        local y4 = height/2

        local poly = {
            { x = cx + x1 * c - y1 * s, y = cy + x1 * s + y1 * c },
            { x = cx + x2 * c - y2 * s, y = cy + x2 * s + y2 * c },
            { x = cx + x3 * c - y3 * s, y = cy + x3 * s + y3 * c },
            { x = cx + x4 * c - y4 * s, y = cy + x4 * s + y4 * c }
        }
        surface.DrawPoly(poly)

		if HUD.show_damage_percent then
			local dmg_percent = math_floor(dmg * 100)
			local label = limb.label
			
			-- Draw label and damage percentage
			local text = label .. "\n" .. dmg_percent .. "%"
			draw_SimpleText(text, "Default", x + width / 2, y + height / 2, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
