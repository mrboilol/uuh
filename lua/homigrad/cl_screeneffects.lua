
include("postprocess/scaf.lua")
include("postprocess/sdle.lua")
include("postprocess/merc_chromaticaberration.lua")
include("postprocess/merc_vignette.lua")
include("postprocess/merc_grayscale.lua")

local homigrad_damage_convar = CreateClientConVar("homigrad_damage", "0", true, false)

local concussion_effect_time = 0
local suppression_effect_time = 0
local concussion_dsp_set = false
local BrainTraumaStation_name = nil

local tired_sound
local sleepy_sound
local bloodvomit_sound
local criticalloop_sound
local criticalloop_sound_name

hook.Add("PlayerDeath", "StopCriticalLoopOnDeath", function(victim, inflictor, attacker)
    if victim == LocalPlayer() and IsValid(criticalloop_sound) then
        criticalloop_sound:FadeOut(0.5)
        criticalloop_sound = nil
        criticalloop_sound_name = nil
    end
end)

net.Receive("PlayerFlinchDirectional", function()
    local dir = net.ReadVector()
    local eye_angles = LocalPlayer():EyeAngles()
    local right = eye_angles:Right()
    local up = eye_angles:Up()

    local pitch = dir:Dot(up) * 5
    local yaw = dir:Dot(right) * 5

    local punch = Angle(pitch, yaw, math.Rand(-1, 1))
    ViewPunch(punch)
end)


local suicide_input_locked = false
hook.Add("Think", "DesensitizedSuicideEffect", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    if ply:GetNWFloat("willsuicide", 0) > 0 and (ply.organism and (ply.organism.desensitized or 0) > 0.9) then
        if not suicide_input_locked then
            -- Lock input
            hook.Add("PlayerBindPress", "LockSuicideInput", function(ply, bind, pressed)
                if bind ~= "+attack" then
                    return true -- block all other binds
                end
            end)
            suicide_input_locked = true
        end

        -- Grayscale effect
        local saturation = 0.5
        DrawColorModify({
            ["$pp_colour_colour"] = saturation,
        })

        -- Show thought
        if not ply.suicide_thought_shown then
            ply:Notify(hg.suicide_thoughts[math.random(#hg.suicide_thoughts)], 10, "suicide_thought", 0, nil, Color(200, 200, 200, 255))
            ply.suicide_thought_shown = true
        end
    else
        if suicide_input_locked then
            -- Unlock input
            hook.Remove("PlayerBindPress", "LockSuicideInput")
            suicide_input_locked = false
        end
        ply.suicide_thought_shown = false
    end
end)

hook.Add("PostDrawPlayerAppearance", "DesensitizedFaceEffect", function(ent, ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() then return end
    if ply == LocalPlayer() then return end -- Don't draw on self

    local lply = LocalPlayer()
    local lply_org = lply.organism
    if not lply_org or not lply_org.desensitized or lply_org.desensitized < 0.9 then return end

    local bone = ply:LookupBone("ValveBiped.Bip01_Head1")
    if not bone then return end

    local pos, ang = ply:GetBoneMatrix(bone)
    if not pos then return end

    cam.Start3D(EyePos(), EyeAngles())
        render.SetMaterial(Material("sprites/black"))
        for i = 1, 5 do
            local size = math.random(5, 15)
            local offset = Vector(math.Rand(-10, 10), math.Rand(-10, 10), math.Rand(-10, 10))
            render.DrawQuad(pos + offset, ang:Up(), ang:Right(), size, size, color_white)
        end
    cam.End3D()
end)

hook.Add("PlayerSpawn", "StopCriticalLoopOnSpawn", function(ply)
    if ply == LocalPlayer() and IsValid(criticalloop_sound) then
        criticalloop_sound:Stop()
        criticalloop_sound = nil
        criticalloop_sound_name = nil
    end
end)

local function DrawSunEffect()
	local sun = util.GetSunInfo()
	if not sun then return end
	if not sun.obstruction == 0 or sun.obstruction == 0 or !sun.direction then return end
	local sunpos = EyePos() + sun.direction * 1024 * 4
	local scrpos = sunpos:ToScreen()
	local dot = (sun.direction:Dot(EyeVector()) - 0.8) * 5
	if dot <= 0 then return end
	DrawSunbeams(0.1, 0.15 * dot * sun.obstruction, 0.1, scrpos.x / ScrW(), scrpos.y / ScrH())
end

local function DrawArc(centerX, centerY, radius, thickness, start_angle, end_angle, segments, color)
    local poly = {}
    segments = math.max(2, segments or 0)
    
    for i = 0, segments do
        local angle = start_angle + (i / segments) * (end_angle - start_angle)
        local rad = math.rad(angle)
        local x = centerX + radius * math.cos(rad)
        local y = centerY + radius * math.sin(rad)
        table.insert(poly, {x=x, y=y})
    end

    for i = segments, 0, -1 do
        local angle = start_angle + (i / segments) * (end_angle - start_angle)
        local rad = math.rad(angle)
        local x = centerX + (radius - thickness) * math.cos(rad)
        local y = centerY + (radius - thickness) * math.sin(rad)
        table.insert(poly, {x=x, y=y})
    end
    surface.SetDrawColor(color)
    surface.DrawPoly(poly)
end

hg.postprocess = hg.postprocess or {}
local postprs = hg.postprocess
postprs.addtiveLayer = {
	bloom_darken = 0,
	bloom_mul = 0,
	bloom_sizex = 0,
	bloom_sizey = 0,
	bloom_passes = 0,
	bloom_colormul = 0,
	bloom_colorr = 0,
	bloom_colorg = 0,
	bloom_colorb = 0,
	blur_addalpha = 0,
	blur_drawalpha = 0,
	blur_delay = 0,
	toytown = 0,
	toytown_h = 0,
	brightness = 0,
	sharpen = 0,
	sharpen_dist = 0
}

postprs.layers = postprs.layers or {}
damage_blur_time = 0

local layers = postprs.layers
local layers_name = {}
function postprs.LayerAdd(name, tab)
	tab.weight = 0
	layers_name[#layers_name+1] = name
	layers[name] = tab
end

function postprs.LayerWeight(name, lerp, value)
	layers[name].weight = LerpFT(lerp, layers[name].weight, value)
end

function postprs.LayerSetWeight(name, value)
	layers[name].weight = value
end

local addtiveLayer = postprs.addtiveLayer
local tab = {
	["$pp_colour_brightness"] = 0,
	["$pp_colour_contrast"] = 1,
	["$pp_colour_colour"] = 1
}


--local potatopc = GetConVar("hg_potatopc") or CreateClientConVar("hg_potatopc", "0", true, false, "enable this if you are noob", 0, 1)
local hook_Run = hook.Run
hook.Add("RenderScreenspaceEffects", "homigrad", function()
	//if potatopc:GetInt() >= 1 then return end
	hook_Run("Post Processing")
	//DrawSunEffect()
	for _, layer in ipairs(layers_name) do
		layer = layers[layer]
		local weight = layer.weight
		--for k, v in pairs(layer) do
			--if k == "weight" then continue end
		addtiveLayer["brightness"] = Lerp(weight, 0, layer["brightness"] or 0)
		--end
	end
	
	//DrawBloom(addtiveLayer.bloom_darken, addtiveLayer.bloom_mul, addtiveLayer.bloom_sizex, addtiveLayer.bloom_sizey, addtiveLayer.bloom_passes, addtiveLayer.bloom_colormul, addtiveLayer.bloom_colorr, addtiveLayer.bloom_colorg, addtiveLayer.bloom_colorb)
	//DrawSharpen(addtiveLayer.sharpen, addtiveLayer.sharpen_dist)
	//if not brain_motionblur then DrawMotionBlur(addtiveLayer.blur_addalpha, addtiveLayer.blur_drawalpha, addtiveLayer.blur_delay) end
    if damage_blur_time > 0 then
        -- DrawMotionBlur(0, math.min(damage_blur_time, 0.9), 0.01)
        local blur_amount = math.min(damage_blur_time, 0.9)
        local focus_size = 1 - blur_amount
        DrawToyTown(0.5 - focus_size / 2, 0.5 + focus_size / 2)
    end
	//DrawToyTown(addtiveLayer.toytown, addtiveLayer.toytown_h * ScrH())
	tab["$pp_colour_brightness"] = addtiveLayer.brightness
	DrawColorModify(tab)

	hook_Run("Post Pre Post Processing")

	hook_Run("Post Post Processing")
	hook_Run("Post Post Pre Post Processing")
end)

local postprs = hg.postprocess
postprs.LayerAdd("main", {
	bloom_darken = 0.64,
	bloom_mul = 0.5,
	bloom_sizex = 4,
	bloom_sizey = 4,
	bloom_passes = 2,
	bloom_colormul = 1,
	bloom_colorr = 1,
	bloom_colorg = 1,
	bloom_colorb = 1
})

postprs.LayerAdd("water", {
	bloom_darken = 0.15,
	bloom_mul = 1,
	bloom_sizex = 30,
	bloom_sizey = 30,
	bloom_passes = 2,
	bloom_colormul = 1,
	bloom_colorr = 0.05,
	bloom_colorg = 0.5,
	bloom_colorb = 1,
	blur_addalpha = 0.1,
	blur_drawalpha = 0.5,
	blur_delay = 0.01
})

postprs.LayerAdd("water2", {
	toytown = 6,
	toytown_h = 4
})

postprs.LayerAdd("water3", {
	brightness = -0.5
})

local oldWaterLevel, lastWater = 0, 0
local LayerWeight = postprs.LayerWeight
local LayerSetWeight = postprs.LayerSetWeight
local CurTime = CurTime
local timecheck = CurTime()
hook.Add("Post Processing", "Main", function()
	//if potatopc:GetInt() >= 1 then return end
	//if !lply:Alive() then return end
	local ply = lply:Alive() and lply or lply:GetNWEntity("spect")
	if !IsValid(ply) then return end
	local waterLevel = oldWaterLevel
	if timecheck < CurTime() then
		local pos = hg.eye(lply)
		
		if !pos then return end

		waterLevel = (ply:WaterLevel() == 3) or ((ply:WaterLevel() > 1) and bit.band(util.PointContents(pos), CONTENTS_WATER) == CONTENTS_WATER)//lply:WaterLevel()

		timecheck = CurTime() + 0.1
	end

	local time = CurTime()

	if oldWaterLevel ~= waterLevel and waterLevel then
		lastWater = time + 2
	end

	local animpos = lastWater - time
	if animpos > 0 then
		LayerSetWeight("water3", animpos)
	else
		LayerSetWeight("water3", 0)
	end

	if waterLevel then
		LayerWeight("main", 0.1, 0)
		LayerWeight("water", 0.1, 1)
		LayerWeight("water2", 0.1, 1)
	else
		LayerWeight("main", 0.5, 1)
		LayerWeight("water", 0.5, 0)
		LayerWeight("water2", 0.01, 0)
	end

	oldWaterLevel = waterLevel

	DrawSunEffect()
end)

local color_red = Color( 56, 43, 0, 255)
local haloents = {
	["attachment_base"] = true,
	["ammo_base"] = true,
	["armor_base"] = true,
	["hg_flashlight"] = true,
	["homigrad_base"] = true,
	["weapon_melee"] = true,
	["weapon_bandage_sh"] = true,
	["hg_sling"] = true,
	["hg_brassknuckles"] = true,
	["weapon_m4super"] = true,
	["weapon_revolver2"] = true,
	["weapon_hg_f1_tpik"] = true
}

hook.Add( "PreDrawHalos", "AddPropHalos", function() -- вариант с подсветкой всего в радиусе
	local pickuphalo = {}
	 
	local lpos = lply:GetPos()
	for _, ent in ipairs(ents.FindInSphere(lpos, 256)) do
		if IsValid(ent) and (haloents[ent.Base] or haloents[ent:GetClass()]) and not IsValid(ent:GetOwner()) then
		table.insert(pickuphalo, ent)
		local dist = lpos:Distance(ent:GetPos()) * 0.02
		--print(dist)
		color_red.r = Lerp(FrameTime()*5,color_red.r,56 / dist)
		color_red.g = Lerp(FrameTime()*5,color_red.g,43 / dist)
		end
	end
	halo.Add( pickuphalo, color_red, 1, 1, 1 )
end )

hook.Add( "PreDrawHalos", "AddPropHalos", function() -- вариант с подсвечиванием только когда смотришь
	local pickuphalo = {}
	 
	local tr = hg.eyeTrace(lply,72)
	if tr and IsValid(tr.Entity) and haloents[tr.Entity.Base] then
		table.insert(pickuphalo, tr.Entity)
		local dist = lply:GetPos():Distance(tr.Entity:GetPos()) * 0.03
		--print(dist)
		color_red.r = Lerp(FrameTime()*2,color_red.r,56 / dist)
		color_red.g = Lerp(FrameTime()*2,color_red.g,43 / dist)
	else
		color_red.r = Lerp(FrameTime()*2,color_red.r,0)
		color_red.g = Lerp(FrameTime()*2,color_red.g,0)
	end
	halo.Add( pickuphalo, color_red, 1, 1, 1 )
end )

-- funny :)

--that one furry game


local painMat = Material("effects/shaders/zb_grain")
local noiseMat = Material("effects/shaders/zb_grainwhite")
local vignetteMat = Material("effects/shaders/zb_vignette")
local assimilationMat = Material("effects/shaders/zb_assimilation")
local coldMat = Material("effects/shaders/zb_colda")
local grainMat = Material("effects/shaders/zb_grain2")
local heatMat = Material("effects/shaders/zb_heat")
local blindMat = Material("effects/shaders/zb_blind")
local tunnelWaveMat = Material("effects/shaders/zb_tunnelwave")

-- eye loss overlays (use same material draw style)
local LEFT_EYE_GONE_OVERLAY = Material("overlays/lefteyegone.png")
local RIGHT_EYE_GONE_OVERLAY = Material("overlays/righteyegone.png")

local lobotomy_mats = {
	[1] = Material("overlays/photopsiaoverlay1.png"),
	[2] = Material("overlays/photopsiaoverlay2.png"),
	[3] = Material("overlays/photopsiaoverlay3.png"),
	[4] = Material("overlays/photopsiaoverlay4.png"),
	[5] = Material("overlays/peripheralorboverlay.png"),
	[6] = Material("overlays/tallflash1.png"),
	[7] = Material("overlays/tallflash2.png"),
	[8] = Material("overlays/tallflash3.png")
}

local show_image_time = 0
local lobotomy_index = 0
local lobotomy_dir = Vector(0,0,0)
local HEAD_TRAUMA_DURATION = 1.5

local show_red_trauma_time = 0
local RED_TRAUMA_DURATION = 1.5

-- sway state for eye overlays
local lastViewAngles = Angle(0, 0, 0)
local eyeOffsetX, eyeOffsetY = 0, 0
local lastUpdate = 0
local swayInterval = 0.016 -- ~60 fps

local damage_indicator_dir = Vector(0,0,0)
local damage_indicator_time = 0
local DAMAGE_INDICATOR_DURATION = 2 -- seconds

local suppression_fade_time = 0
local suppression_severity = 0
local suppression_chromatic_aberration = 0
local suppression_dof = 0
local suppression_vignette = 0
local suppression_dirt = 0
_G.suppression_severity = 0
_G.damage_overlay_intensity = 0

local dirtMat = Material("dlenstexture/dlensmat", "noclamp")
local chromaticMat = Material("effects/shaders/merc_chromaticaberration")



local red_flash_time = 0
local damage_fade_time = 0

net.Receive("PlayerSuppressed", function()
    local severity = net.ReadFloat()
    _G.suppression_severity = math.min(severity, 1.0)

    local wep_damage = net.ReadFloat()
	local dir_to_bullet = net.ReadVector()
    suppression_fade_time = math.min(severity * 0.5, 0.8)
    suppression_effect_time = math.min((suppression_effect_time or 0) + 7.5 * severity, 15.0) -- Longer effect time

    -- New effects are now based on the total accumulated suppression
    suppression_chromatic_aberration = math.min((suppression_chromatic_aberration or 0) + severity * 0.02, 0.7) -- More severe start, longer lasting

    suppression_dof = _G.suppression_severity * 1.5 -- Increased
    suppression_vignette = math.min((suppression_vignette or 0) + severity * 25, 100)
    _G.damage_overlay_intensity = math.min((_G.damage_overlay_intensity or 0) + severity * 0.5, 1.0)

    if severity > 0.5 then -- Only for close bullets
        suppression_dirt = math.min((suppression_dirt or 0) + severity * 0.025, 0.5) -- Less severe, apply more often
    else
        --suppression_dirt = 0

    end

    damage_blur_time = suppression_dof
    --_G.suppression_shake = severity

    -- Flinching based on incoming severity to avoid excessive shake
	local eye_angles = LocalPlayer():EyeAngles()
	local forward = eye_angles:Forward()
	local right = eye_angles:Right()
	local up = eye_angles:Up()

	local pitch = -dir_to_bullet:Dot(up) * 15 * severity
	local yaw = -dir_to_bullet:Dot(right) * 15 * severity

    local punch = Angle(pitch, yaw, math.Rand(-3, 3) * severity)
    ViewPunch(punch)

    -- Ragdoll on high suppression and damage
    local should_ragdoll = false
    if severity > 0.9 then -- a single, very suppressive shot
        should_ragdoll = true
    elseif wep_damage > 100 then -- a high-damage bullet whizzing by
        should_ragdoll = true
    elseif _G.suppression_severity > 1.5 and wep_damage > 30 then -- high accumulated suppression and a decent hit
        should_ragdoll = true
    end

    if should_ragdoll then
        timer.Simple(0, function()
            net.Start("RequestRagdoll")
            net.SendToServer()
        end)
    end
end)



net.Receive("headtrauma_flash", function()
    local pos = net.ReadVector()
    local time = net.ReadFloat()
    local size = net.ReadInt(20)
	local sound = net.ReadString()
    local lply = LocalPlayer()
	if not IsValid(lply) then return end
	if sound ~= "" then
			surface.PlaySound(sound)
		end
    hg.AddFlash(lply:EyePos(), 1, pos, time, size)
end)

net.Receive("hg_DamageIndicator", function()
    --[[damage_indicator_dir = net.ReadVector()
    damage_indicator_time = DAMAGE_INDICATOR_DURATION]]
end)

net.Receive("hg_MeleeHeadViewpunch", function()
    local dir = net.ReadVector()
    local punch = Angle(dir.y * 10, dir.x * -10, 0)
    ViewPunch(punch)
end)

net.Receive("hg_CancelScreenEffects", function()
    suppression_fade_time = 0
end)

local tinnitus_sound

net.Receive("hg_PlayTinnitus", function()
    local sound_name = net.ReadString()
    local duration = net.ReadFloat()

    if IsValid(tinnitus_sound) then
        tinnitus_sound:Stop()
    end

    tinnitus_sound = CreateSound(LocalPlayer(), sound_name)
    if IsValid(tinnitus_sound) then
        tinnitus_sound:Play()
    end
end)

net.Receive("hg_PlayPainSound", function()
    local sound_name = net.ReadString()
    surface.PlaySound(sound_name)
end)



local blood_effect_time = 0
local last_health = 100
local last_damage_time = 0
local damage_cooldown = 0.25
local hurtoverlay_blood = Material("zcity/neurotrauma/damageOverlay.png", "smooth")

hook.Add("Think", "hg_DamageWatcher", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if not ply:Alive() then
        last_health = 100
        return
    end

    local current_health = ply:Health()
    if current_health < last_health then
        if CurTime() > last_damage_time + damage_cooldown then
            blood_effect_time = 1.0 -- duration of the effect
            last_damage_time = CurTime()
            
            -- Play sound
            local sounds = {"physics/flesh/flesh_impact_bullet1.wav", "physics/flesh/flesh_impact_bullet2.wav", "physics/flesh/flesh_impact_bullet3.wav"}
            ply:EmitSound(sounds[math.random(#sounds)])
        end
    end
    last_health = current_health
end)

hook.Add("HUDPaint", "hg_damage_flash", function()
    if _G.suppression_severity and _G.suppression_severity > 0 then
        _G.suppression_severity = math.max(0, _G.suppression_severity - FrameTime() * 0.5)
    end

    if suppression_chromatic_aberration > 0 then
        local fade_rate
        if suppression_chromatic_aberration > 0.6 then
            fade_rate = 0.5
        else
            fade_rate = math.Remap(suppression_chromatic_aberration, 0, 0.6, 0.2, 0.05)
        end
        suppression_chromatic_aberration = math.max(0, suppression_chromatic_aberration - FrameTime() * fade_rate)
    end

    if suppression_dirt > 0 then
        suppression_dirt = math.max(0, suppression_dirt - FrameTime() * 0.5) -- Faster fade
    end

    if suppression_vignette > 0 then
        suppression_vignette = math.max(0, suppression_vignette - FrameTime() * 2.5)
    end

    if suppression_fade_time > 0 then
        suppression_fade_time = math.max(suppression_fade_time - FrameTime() * 0.25, 0)
        local black_fade_alpha = 255 * suppression_fade_time
        surface.SetDrawColor(0, 0, 0, black_fade_alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end

    if _G.damage_overlay_intensity > 0 then
        _G.damage_overlay_intensity = math.max(0, _G.damage_overlay_intensity - FrameTime() * 0.5)
        local alpha = 255 * _G.damage_overlay_intensity
        
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetMaterial(hurtoverlay_blood)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

        -- Vignette
        render.UpdateScreenEffectTexture()
        vignetteMat:SetFloat("$c1_y", _G.damage_overlay_intensity * 20)
        render.SetMaterial(vignetteMat)
        render.DrawScreenQuad()
    end



    damage_blur_time = math.max(damage_blur_time - FrameTime() * 0.3, 0)
    if show_red_trauma_time > 0 then -- normal damage
        show_red_trauma_time = math.max(show_red_trauma_time - FrameTime(), 0)
        local red_fade_alpha = 75 * (show_red_trauma_time / 1.0) -- Use the ratio
        surface.SetDrawColor(255, 0, 0, red_fade_alpha)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end

    if blood_effect_time > 0 then
        blood_effect_time = math.max(0, blood_effect_time - FrameTime() * 2)
        local alpha = 200 * blood_effect_time
        
        surface.SetDrawColor(255, 255, 255, alpha)
        surface.SetMaterial(hurtoverlay_blood)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end
end)

local PainLerp = 0
local O2Lerp = 0
local assimilatedLerp = 0
local tempLerp = 36.6
local unconscious_time_start = nil

local show_some_images_time = 0

local pvpModes = {
	tdm = true,
	gwars = true,
	hl2dm = true,
	dm = true,
	tdm_cstrike = true,
	smo = true,
	sfd = true,
	scugarena = true,
	bart_vs_homer = true
}

local teamPvpModes = {
	tdm = true,
	gwars = true,
	hl2dm = true,
	tdm_cstrike = true,
	smo = true
}

local function getDeadBodyOwner(ply)
	if not IsValid(ply) then return nil end
	local tr = hg.eyeTrace(ply, 160)
	if not tr or not IsValid(tr.Entity) then return nil end
	local ent = tr.Entity
	if ent:IsPlayer() then
		return not ent:Alive() and ent or nil
	end
	if ent:IsRagdoll() then
		local owner = hg.RagdollOwner(ent) or ent:GetNWEntity("ply") or ent.ply
		if IsValid(owner) and owner:IsPlayer() then
			return not owner:Alive() and owner or nil
		end
		return nil
	end
	return nil
end

local function isDeadBodyAllowed(ply, owner)
	if not IsValid(ply) then return false end
	if ply.isTraitor then return false end
	local mode = GAMEMODE and GAMEMODE.CurrentRound and GAMEMODE:CurrentRound()
	local modeName = mode and (mode.Type or mode.name) or nil
	if modeName and pvpModes[modeName] then
		if not teamPvpModes[modeName] then return false end
		if not IsValid(owner) or not owner:IsPlayer() then return false end
		return owner:Team() == ply:Team() and ply:Team() != TEAM_SPECTATOR
	end
	return true
end

local function isSuicideIntent(ply)
	if not IsValid(ply) then return false end
	local wep = ply.GetActiveWeapon and ply:GetActiveWeapon() or nil
	local wepCanSuicide = IsValid(wep) and wep.CanSuicide
	local weaponSuicide = wepCanSuicide and (wep.SuicideStart or wep.cutthroat)
	local suicideNet = ply:GetNWBool("suiciding", false)
	local suiciding = ply.suiciding or suicideNet
	if ply:GetNWFloat("willsuicide", 0) > 0 then return true end
	if weaponSuicide then return true end
	if suiciding and (wepCanSuicide or hg.CanSuicide(ply)) then return true end
	return false
end

local tunnelWaveFade = 0
local tunnelWaveBase = 0.9
local deadBodyHoldUntil = 0
local deadBodyHoldSeconds = 1.2
hook.Add("Post Post Processing", "TunnelwaveDeadOrSuicide", function()
	if not IsValid(lply) or not lply:Alive() then return end
	local deadOwner = getDeadBodyOwner(lply)
	local mode = GAMEMODE and GAMEMODE.CurrentRound and GAMEMODE:CurrentRound()
	local modeName = mode and (mode.Type or mode.name) or nil
	if lply.isTraitor or (modeName and pvpModes[modeName] and not teamPvpModes[modeName]) then
		deadBodyHoldUntil = 0
	else
		if deadOwner then
			if isDeadBodyAllowed(lply, deadOwner) then
				deadBodyHoldUntil = CurTime() + deadBodyHoldSeconds
			else
				deadBodyHoldUntil = 0
			end
		end
	end
	local deadActive = deadBodyHoldUntil > CurTime()
	local active = deadActive or isSuicideIntent(lply)
	tunnelWaveFade = LerpFT(0.08, tunnelWaveFade, active and 1 or 0)
	if tunnelWaveFade < 0.01 then return end
	render.UpdateScreenEffectTexture()
	tunnelWaveMat:SetFloat("$c1_w", tunnelWaveBase * tunnelWaveFade)
	render.SetMaterial(tunnelWaveMat)
	render.DrawScreenQuad()
end)

local use_agony = false
local o2_sounds = {
    "sound/zbattle/conscioustypebeat.ogg",
    "sound/despair.ogg",
    "sound/dying.ogg"
}
local pain_sounds = {
    "sound/zbattle/pain_beat.ogg",
    "sound/agony.mp3",
}

hook.Add("PlayerSpawn", "reset_agony_chance", function(ply)
    if ply == LocalPlayer() then
        use_agony = math.random(1, 5) == 1
    end
end)

local lobotomy_flash_active = false
local lobotomy_flash_end_time = 0

local vignette_active = false
local vignette_end_time = 0

local wave_effect_active = false
local wave_effect_end_time = 0

local vignette_intensity_lerped = 0
local grayscale_intensity_lerped = 0

_G.stopthings = function()
	PainLerp = 0
	O2Lerp = 0
	shockLerp = 0
	assimilatedLerp = 0
	tempLerp = 36.6
	consciousnessLerp = 1

    suppression_fade_time = 0
    suppression_effect_time = 0
    _G.suppression_severity = 0
    suppression_chromatic_aberration = 0
    suppression_dof = 0
    suppression_vignette = 0
    suppression_dirt = 0

	lply.tinnitus = 0
	
	--[[if IsValid(PainStation) then
		PainStation:Stop()
		PainStation = nil
	end--]]

	if IsValid(NoiseStation) then
		NoiseStation:Stop()
		NoiseStation = nil
	end

	if IsValid(NoiseStation2) then
		NoiseStation2:Stop()
		NoiseStation2 = nil
	end

	if IsValid(BrainTraumaStation) then
		BrainTraumaStation:Stop()
		BrainTraumaStation = nil
		BrainTraumaStation_name = nil
	end

	if IsValid(BrainTraumaStation2) then
		BrainTraumaStation2:Stop()
		BrainTraumaStation2 = nil
	end

	if IsValid(BrainTraumaStation3) then
		BrainTraumaStation3:Stop()
		BrainTraumaStation3 = nil
	end

	if IsValid(BrainTraumaStation4) then
		BrainTraumaStation4:Stop()
		BrainTraumaStation4 = nil
	end

	if IsValid(BrainTraumaStation5) then
		BrainTraumaStation5:Stop()
		BrainTraumaStation5 = nil
	end

	if IsValid(Tinnitus) then
		Tinnitus:Stop()
		Tinnitus = nil
	end

    if IsValid(criticalloop_sound) then
        criticalloop_sound:Stop()
        criticalloop_sound = nil
		criticalloop_sound_name = nil
    end

	if IsValid(AssimilationStation) then
		AssimilationStation:Stop()
		AssimilationStation = nil
	end
end

local stations = {
	0.06,
	0.1,
	0.15,
	0.22,
	0.27,
}

local choosera = 1
local tempolerp = 0
local lerpblood = 0
local addtime = CurTime()
local hurtoverlay = Material("zcity/neurotrauma/damageOverlay.png", "smooth")
hook.Add("Post Post Processing", "ItHurts", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local org = ply.organism
    if not org then return end

    -- Get player state
    local pain = org.pain or 0
    local shock = org.shock or 0
    local fear = org.fear or 0
    local adrenaline = org.adrenaline or 0
    local suppression = _G.suppression_severity or 0
    local blood = org.blood or 5000

    if org.blood < 4000 then
        local blood_deficiency = (4000 - org.blood) / 1000
        _G.damage_overlay_intensity = math.min((_G.damage_overlay_intensity or 0) + blood_deficiency * FrameTime(), 1.0)
    end

    -- Chromatic Aberration
    local c_intensity = 0
    c_intensity = c_intensity + (pain / 100)
    c_intensity = c_intensity + (suppression * 2.5) -- Increased intensity
    c_intensity = c_intensity + (adrenaline * 10.0) -- Increased intensity
    c_intensity = c_intensity + (fear * 1.5) -- Increased intensity
    if c_intensity > 0 and merc_chromaticaberration then
        local args = {
            aberration = c_intensity
        }
        merc_chromaticaberration(args)
    end

    -- Vignette
    local vignette_intensity_target = 0
    vignette_intensity_target = vignette_intensity_target + (fear * 5)
    vignette_intensity_lerped = Lerp(FrameTime() * 2, vignette_intensity_lerped, vignette_intensity_target)

    if vignette_intensity_lerped > 0.01 and merc_vignette then
        local args = {
            vignette_intensity = vignette_intensity_lerped
        }
        merc_vignette(args)
    end

    -- Desaturation
    local desaturation_intensity_target = 0
    if blood < 4000 then
        desaturation_intensity_target = math.max(desaturation_intensity_target, 1 - (blood / 4000))
    end
    desaturation_intensity_target = math.max(desaturation_intensity_target, fear * 0.5)
    if pain > 50 then
        desaturation_intensity_target = math.max(desaturation_intensity_target, (pain - 50) / 50)
    end
    grayscale_intensity_lerped = Lerp(FrameTime() * 2, grayscale_intensity_lerped, desaturation_intensity_target)

    if grayscale_intensity_lerped > 0.01 and merc_grayscale then
        local args = {
            grayscale = grayscale_intensity_lerped
        }
        merc_grayscale(args)
    end

    -- Dirty Lens
    if suppression > 0.6 then
        sdle.Damage(suppression * 1.0, math.Rand(0.5, 1), true, true)
    end

    -- Flinching (removed pain flinch)
    -- if pain > 10 then
    --     local punch = Angle(math.Rand(-1, 1) * (pain / 320), math.Rand(-1, 1) * (pain / 320), 0) -- Reduced intensity
    --     ViewPunch(punch)
    -- end
    if suppression_effect_time > 0 then
        -- Chromatic Aberration
        if suppression_chromatic_aberration > 0 then
            render.UpdateScreenEffectTexture()
            chromaticMat:SetFloat("$c0_x", suppression_chromatic_aberration * 0.2)
            render.SetMaterial(chromaticMat)
            render.DrawScreenQuad()
        end



        -- Dirt
        --[[if suppression_dirt > 0 then
            surface.SetDrawColor(255, 255, 255, suppression_dirt * 150) -- Reduced intensity
            surface.SetMaterial(dirtMat)
            surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
        end)]]

        --[[ Grain/Pixelation
        if _G.suppression_severity > 0.5 then
            local grain_intensity = (_G.suppression_severity - 0.5) * 2 -- scale from 0 to 1
            render.UpdateScreenEffectTexture()
            render.UpdateFullScreenDepthTexture()
            
            grainMat:SetFloat("$c0_x", CurTime()) -- time
            grainMat:SetFloat("$c0_y", 0.5) -- gate
            grainMat:SetFloat("$c0_z", grain_intensity * 2) -- Pixelize
            grainMat:SetFloat("$c1_x", grain_intensity) -- lerp
            grainMat:SetFloat("$c1_y", grain_intensity * 5) -- vignette intensity
            grainMat:SetFloat("$c1_z", grain_intensity) -- BlurIntensity
            grainMat:SetFloat("$c2_x", 0) -- r
            grainMat:SetFloat("$c2_y", 0) -- g
            grainMat:SetFloat("$c2_z", 0) -- b
            grainMat:SetFloat("$c3_x", 0) -- ImageIntensity
        
            render.SetMaterial(grainMat)
            render.DrawScreenQuad()
        end]]
    end
	if homigrad_damage_convar:GetBool() then 
        local org = lply.organism
        if org then
            local pain = org.pain or 0
            pain = math.max(pain - 15, 0)
            local shock = (org.shock or 0) * 1 + (1 - org.consciousness) * 40
            local shockLerp = LerpFT(0.01, shockLerp or 0, shock + (lply.suiciding and math.max(0, org.heartbeat - 90) or 0))

            if (pain > 0.001 or shockLerp > 5) or org.otrub or blindness_intensity > 0 then
                local strobe = math.ease.InOutSine(math.abs(math.cos(CurTime() * 2))) * pain / 2
                pain = pain + strobe
                shock = shockLerp
                render.UpdateScreenEffectTexture()

                vignetteMat:SetFloat("$c2_x", CurTime() + 10000) --Time
                vignetteMat:SetFloat("$c0_z", (org.otrub and 5 or (pain / 40 + math.max(shock - 5, 0) / 3)) + blindness_intensity) //ColorIntensity
		vignetteMat:SetFloat("$c1_y", ((org.otrub and 10 or (pain / 40 + math.max(shock - 5, 0) / 3)) + blindness_intensity) + suppression_vignette) //Vignette

		render.SetMaterial(vignetteMat)
                render.DrawScreenQuad()
            end
        end
        return 
    end
	if damage_blur_time > 0 then
		damage_blur_time = math.max(damage_blur_time - FrameTime(), 0)
		-- DrawMotionBlur(0.2, 0.8, 0.05)
	end
	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")
	local ply = lply:Alive() and lply or spect
	
	if IsValid(PainStation) then
		PainStation:SetVolume(0)
	end
	
	if !lply:Alive() and !IsValid(spect) then stopthings() return end
	if !lply:Alive() and viewmode != 1 then stopthings() return end
	local organism = lply:Alive() and lply.organism or (IsValid(spect) and spect.organism)
	if not organism then stopthings() return end
	if not organism.brain then stopthings() return end
	local org = organism
	
	if concussion_effect_time > 0 then
		if not concussion_dsp_set then
			lply:SetDSP(35)
			concussion_dsp_set = true
		end
		concussion_effect_time = math.max(concussion_effect_time - FrameTime(), 0)
		local severity_multiplier = 0.5
		DrawMotionBlur(0.2 * severity_multiplier, 0.8 * severity_multiplier, 0.05)
		local curTime = CurTime()
		local wobble = math.sin(curTime * (10 + 5 * severity_multiplier)) * (0.5 * severity_multiplier)
		-- ViewPunch(Angle(wobble * 0.2, wobble * 0.2, wobble * 0.2))
	else
		if concussion_dsp_set then
			lply:SetDSP(0)
			concussion_dsp_set = false
		end
	end

	--[[if suppression_effect_time > 0 then
		suppression_effect_time = math.max(suppression_effect_time - FrameTime(), 0)
		local severity_multiplier = suppression_severity
		DrawMotionBlur(0.2 * severity_multiplier, 0.8 * severity_multiplier, 0.05)
	end]]

	if org.blindness or amtflashed >= 0.8 then
		local blindness = ((org.blindness and math.Round(org.blindness) == 0) or amtflashed >= 0.8) and 0 or (org.blindness)
		render.UpdateScreenEffectTexture()
		render.UpdateFullScreenDepthTexture()

		blindMat:SetFloat("$c0_x", 5)
		blindMat:SetFloat("$c0_y", CurTime())
		blindMat:SetFloat("$c0_z", math.Round(blindness))

		render.SetMaterial(blindMat)
		render.DrawScreenQuad()
	end

    local conc_sev = org.concussion_severity or 0
    if conc_sev > 0 then
        local severity_multiplier = math.Clamp(conc_sev / 10, 0, 1)
        show_image_time = HEAD_TRAUMA_DURATION * (1 + severity_multiplier * 2) -- Longer effect for more severe concussions
        lobotomy_index = math.random(#lobotomy_mats)
        lobotomy_dir = Vector(0,0,0)
        DrawMotionBlur(0.2 * severity_multiplier, 0.8 * severity_multiplier, 0.05)
        if severity_multiplier > 0.7 then
            lply:SetDSP(1) -- More intense DSP
        elseif severity_multiplier > 0.3 then
            lply:SetDSP(35)
        else
            lply:SetDSP(17)
        end
        local curTime = CurTime()
        local wobble = math.sin(curTime * (10 + 15 * severity_multiplier)) * (0.5 * severity_multiplier) -- More intense wobble
        -- ViewPunch(Angle(wobble * 0.2, wobble * 0.1, wobble * 0.1))
    end

	if (org.consciousness < 0.7) then
		lerpblood = LerpFT(0.01, lerpblood or 0, math.Clamp((0.7 - org.consciousness) * 5, 0, 1) * 255)
		local lowblood = (3600 - (org.blood or 5000)) / 600

		addtime = addtime + FrameTime() / 6
		local amt = (math.cos(addtime) + math.sin(addtime * 3) + math.sin(addtime * 2)) / 90
		local amt2 = (math.sin(addtime) + math.cos(addtime * 5) + math.sin(addtime * 6)) / 90
		local mat = Matrix({
			{1 - amt, amt, 0, -amt2 / 2},
			{amt2, 1 - amt2, 0, -amt / 2},
			{0, 0, 1, 0},
			{0, 0, 0, 1},
		})
		hurtoverlay:SetMatrix("$basetexturetransform", mat)
		surface.SetMaterial(hurtoverlay)
		surface.SetDrawColor(0, 0, 0, lerpblood)
		surface.DrawTexturedRect(-ScrW() * 2.0, -ScrH() * 2.0, ScrW() * 5, ScrH() * 5)
		//ViewPunch(Angle(-amt * 1, amt2 * 1,0))
		//ViewPunch2(Angle(-amt * 1, amt2 * 1,0))
	end

	local pain_sound_choice = pain_sounds[math.random(#pain_sounds)]
		if not IsValid(PainStation) or PainStation:GetState() ~= GMOD_CHANNEL_PLAYING then
			sound.PlayFile(pain_sound_choice, "noblock noplay", function(station)
				if IsValid(station) then
					station:SetVolume(0)
					station:SetPlaybackRate(math.Rand(0.75, 1.1))
					station:Play()
					station:SetTime(math.min(math.Rand(0, station:GetLength()), 139))
					PainStation = station
					station:EnableLooping(true)
				end
			end)
		end

	local LerpFT = LerpFT or Lerp

	if !org or !org.o2 or !isnumber(org.o2[1]) or !org.analgesia then stopthings() return end

	local o2 = org.o2[1] or 0
	o2 = o2 + (org.CO or 0)

	if org.stamina and org.stamina[1] and org.stamina.max then
        local stamina_percent = org.stamina[1] / org.stamina.max
        if stamina_percent < 0.2 then
            if not tired_sound then
                tired_sound = CreateSound(ply, "tired.ogg")
                tired_sound:Play()
                tired_sound:ChangeVolume(0, 0)
            end
            local volume = 1 - (stamina_percent / 0.2)
            tired_sound:ChangeVolume(volume, 0.5)
        elseif tired_sound then
            tired_sound:FadeOut(0.5)
            tired_sound = nil
        end
    end

    -- Low consciousness sound
    if org.consciousness then
        if org.consciousness < 0.5 then
            if not sleepy_sound then
                sleepy_sound = CreateSound(ply, "sleepy.ogg")
                sleepy_sound:Play()
                sleepy_sound:ChangeVolume(0, 0)
            end
            local volume = 1 - (org.consciousness / 0.5)
            sleepy_sound:ChangeVolume(volume, 0.5)
        elseif sleepy_sound then
            sleepy_sound:FadeOut(0.5)
            sleepy_sound = nil
        end
    end

    -- Vomiting sound
    if org.wantToVomit and org.wantToVomit > 0.95 then
        if not bloodvomit_sound then
            bloodvomit_sound = CreateSound(ply, "bloodvomit.ogg")
            bloodvomit_sound:Play()
        end
    elseif bloodvomit_sound then
        bloodvomit_sound:Stop()
        bloodvomit_sound = nil
    end

    -- Critical condition sounds
    local is_critical = org.critical or org.incapacitated
    local has_pulse = org.pulse and org.pulse > 0
    local last_sound_change = 0

        if is_critical and has_pulse and not org.heartstop and (lply:Alive() or org.otrub) then
        local volume = (org.incapacitated and not org.critical) and 0.4 or 1.0
        local sound_to_play = (org.consciousness or 1) > 0.4 and "criticalloop.ogg" or "criticalloop-unconscious.ogg"

        if org.otrub then
            sound_to_play = "criticalloop-unconscious.ogg"
            volume = 1.0
        end

        if (not criticalloop_sound or criticalloop_sound_name ~= sound_to_play) and (last_sound_change == 0 or last_sound_change < CurTime() - 2) then
            if IsValid(criticalloop_sound) then criticalloop_sound:FadeOut(0.5) end

            criticalloop_sound = CreateSound(ply, sound_to_play)
            if criticalloop_sound then
                criticalloop_sound:Play()
                criticalloop_sound_name = sound_to_play
                last_sound_change = CurTime()
            end
        end

        if IsValid(criticalloop_sound) and criticalloop_sound:IsPlaying() then
            criticalloop_sound:ChangeVolume(volume, 0.5)
        end
    elseif IsValid(criticalloop_sound) then
        if org.heartstop then
            criticalloop_sound:FadeOut(2) -- Fade out over 2 seconds
        else
            criticalloop_sound:FadeOut(0.5)
        end
        criticalloop_sound = nil
        criticalloop_sound_name = nil
    end
	local brain = org.brain or 0
	O2Lerp = LerpFT(0.01, O2Lerp, (30 - o2) * (org.otrub and 2 or 10) + (brain * 100) * (org.otrub and 1 or 5))

	tempLerp = LerpFT(0.01, tempLerp, org.temperature or 36.6)

	if tempLerp > 38 then
		local heat = tempLerp - 38

		render.UpdateScreenEffectTexture()

		heatMat:SetFloat("$c0_x", -CurTime() * 0.25)//math.sin(CurTime() * 0.1) * CurTime() * 0.01) //time
		heatMat:SetFloat("$c0_y", 0.06 * heat)//(math.sin(CurTime()) + 1) * 2) //intensity (strict)
		heatMat:SetFloat("$c2_x", (math.sin(CurTime()) - 2) * heat)

		render.SetMaterial(heatMat)
		render.DrawScreenQuad()
	end

	local pain = org.pain or 0
	pain = math.max(pain - 15, 0)
	local shock = (org.shock or 0) * 1 + (1 - org.consciousness) * 40
	shockLerp = LerpFT(0.01, shockLerp or 0, shock + (lply.suiciding and math.max(0, org.heartbeat - 90) or 0))
	consciousnessLerp = LerpFT(org.consciousness < (consciousnessLerp or 1) and 1 or 0.01, consciousnessLerp or 1, org.consciousness)

	local UNCONSCIOUS_THRESHOLD = 0.2
	local MEMORY_TRIGGER_DURATION = 5

	if consciousnessLerp < UNCONSCIOUS_THRESHOLD then
		if not unconscious_time_start then
			unconscious_time_start = CurTime()
		elseif (CurTime() - unconscious_time_start) > MEMORY_TRIGGER_DURATION then
			show_some_images_time = 250
			unconscious_time_start = nil
		end
	else
		unconscious_time_start = nil
	end

	-- local immobilization = org.immobilization
	PainLerp = LerpFT(0.05, PainLerp, math.max(pain * (org.otrub and 0.2 or 1), 0))
	assimilatedLerp = LerpFT(0.01, assimilatedLerp, (org.assimilated or 0))

	if PainLerp > 0.1 then
        local blur_intensity = math.Clamp(PainLerp / 100, 0, 0.8)
        DrawMotionBlur(0, blur_intensity, 0.01)
    end

	if assimilatedLerp > 0.001 then
		render.UpdateScreenEffectTexture()

		assimilationMat:SetFloat("$c0_x", -CurTime())//math.sin(CurTime() * 0.1) * CurTime() * 0.01) //time
		assimilationMat:SetFloat("$c0_y", assimilatedLerp * 3)//(math.sin(CurTime()) + 1) * 2) //intensity (strict)
		local ctime = CurTime() * 2
		local val = math.Clamp(3 - 1 / 3 * (math.sin(ctime * 2.8862) + math.cos(ctime * 1.115) - math.sin(ctime * 0.6215) + 3), 0, 5)
		local val2 = math.Clamp(1 - 1 / 6 * (math.sin(ctime * 1.1862) + math.cos(ctime * 2.315) - math.sin(ctime * 0.9215) + 3), 0, 1)
		assimilationMat:SetFloat("$c1_y", val)
		assimilationMat:SetFloat("$c1_x", val2 - 0.5)

		if !IsValid(AssimilationStation) or AssimilationStation:GetState() != GMOD_CHANNEL_PLAYING then
			sound.PlayFile("sound/zbattle/furry/conversion/assimilation_noise3.ogg", "noblock noplay", function(station, err)
				if IsValid(station) then
					station:SetVolume(0)
					station:Play()
					AssimilationStation = station
					station:EnableLooping(true)
				end
			end)
		else
			AssimilationStation:SetVolume(assimilatedLerp * 2)
			//AssimilationStation:SetPlaybackRate(assimilatedLerp * 1)
		end

		render.SetMaterial(assimilationMat)
		render.DrawScreenQuad()
	else
		if IsValid(AssimilationStation) then
			AssimilationStation:Stop()
			AssimilationStation = nil
		end
	end

	if (org.consciousness or 0) < 1 or (org.concussion_severity or 0) > 0 then
		local consciousness = 1 - consciousnessLerp
		if (org.brain or 0) > 0.055 then consciousness = consciousness * 2 end
        if (org.concussion_severity or 0) > 0 then
            consciousness = consciousness + (org.concussion_severity or 0) / 5
        end
		render.UpdateScreenEffectTexture()
		render.UpdateFullScreenDepthTexture()
		
		grainMat:SetFloat("$c0_x", CurTime()) -- time
		grainMat:SetFloat("$c0_y", 0.5) -- gate
		grainMat:SetFloat("$c0_z", consciousness * 3) -- Pixelize
		grainMat:SetFloat("$c1_x", consciousness) -- lerp
		grainMat:SetFloat("$c1_y", 10) -- vignette intensity
		grainMat:SetFloat("$c1_z", consciousness) -- BlurIntensity
		grainMat:SetFloat("$c2_x", 0) -- r
		grainMat:SetFloat("$c2_y", 0) -- g
		grainMat:SetFloat("$c2_z", 0) -- b
		grainMat:SetFloat("$c3_x", 0) -- ImageIntensity
	
		render.SetMaterial(grainMat)
		render.DrawScreenQuad()
	end

	local tempo = math.Clamp((5 - (tempLerp - 29)) * 0.5 - 5 * (org.heartbeat < 1 and 1 or 0), 0, 5)
	tempolerp = LerpFT(0.01, tempolerp, tempo)
	
	if (tempolerp > 0) then
		render.UpdateScreenEffectTexture()

		coldMat:SetFloat("$c0_y", tempolerp)
		
		render.SetMaterial(coldMat)
		render.DrawScreenQuad()
	end

	local blindness_intensity = 0
	if org then
		local leftGone = (org.lefteye or 0) >= 1
		local rightGone = (org.righteye or 0) >= 1

		if leftGone or rightGone then
			-- update sway
			local ct = CurTime()
			if ct - lastUpdate > swayInterval then
				lastUpdate = ct
				local ang = lply:EyeAngles()
				local diffP = math.NormalizeAngle(ang.p - lastViewAngles.p)
				local diffY = math.NormalizeAngle(ang.y - lastViewAngles.y)
				local sway = 5
				local targetX = math.Clamp(diffY * sway, -30, 30)
				local targetY = math.Clamp(-diffP * sway, -20, 20)
				eyeOffsetX = Lerp(FrameTime() * 8, eyeOffsetX, targetX) * 0.95
				eyeOffsetY = Lerp(FrameTime() * 8, eyeOffsetY, targetY) * 0.95
				lastViewAngles = ang
			end

			-- slight shaking
			local shakeX = math.random(-4, 4)
			local shakeY = math.random(-3, 3)

			-- scale 15% bigger and center
			local w, h = ScrW() * 1.15, ScrH() * 1.15
			local left = -(w - ScrW()) / 2 + eyeOffsetX + shakeX
			local top = -(h - ScrH()) / 2 + eyeOffsetY + shakeY

			if leftGone and rightGone then
				surface.SetDrawColor(0, 0, 0, 255)
				surface.DrawRect(0, 0, ScrW(), ScrH())
				blindness_intensity = 20
			else
				surface.SetDrawColor(255, 255, 255, 255)
				if leftGone then
					surface.SetMaterial(LEFT_EYE_GONE_OVERLAY)
					surface.DrawTexturedRect(left, top, w, h)
				end
				if rightGone then
					surface.SetMaterial(RIGHT_EYE_GONE_OVERLAY)
					surface.DrawTexturedRect(left, top, w, h)
				end
			end
		end
	end

	if (PainLerp > 0.001 or shockLerp > 5) or org.otrub or blindness_intensity > 0 then
		local strobe = math.ease.InOutSine(math.abs(math.cos(CurTime() * 2))) * PainLerp / 2
		pain = PainLerp + strobe
		shock = shockLerp
		render.UpdateScreenEffectTexture()

		vignetteMat:SetFloat("$c2_x", CurTime() + 10000) //Time
		vignetteMat:SetFloat("$c0_z", (org.otrub and 5 or (pain / 40 + math.max(shock - 5, 0) / 3)) + blindness_intensity) //ColorIntensity
		vignetteMat:SetFloat("$c1_y", ((org.otrub and 10 or (pain / 40 + math.max(shock - 5, 0) / 3)) + blindness_intensity) + suppression_vignette) //Vignette

		render.SetMaterial(vignetteMat)
		render.DrawScreenQuad()

		render.UpdateScreenEffectTexture()

		painMat:SetFloat("$c2_x", CurTime() + 10000) //Time
		painMat:SetFloat("$c0_y", 0.8) //Gate
		painMat:SetFloat("$c0_z", 1) //ColorIntensity
		painMat:SetFloat("$c1_x", math.Clamp(pain / 90, 0, 0.75)) //Lerp
		painMat:SetFloat("$c1_y", math.Clamp(pain / 90, 0, 0.75)) //Vignette

		render.SetMaterial(painMat)
		render.DrawScreenQuad()

		if org.otrub then
				DrawMotionBlur(0.1, 1., 0.01)
				lply:ScreenFade( SCREENFADE.IN, Color(0,0,0), 2, 0.5 )
		end


		//if pain > 10 then
			if IsValid(PainStation) then
				PainStation:SetVolume(math.Clamp(math.Remap(PainLerp, 0, 120, 0, 2), 0, 2))
				--local rate = org.otrub and 1 or math.Rand(0.75, 1.1)
				--PainStation:SetPlaybackRate(rate)
			end
		//else
		//	if IsValid(PainStation) then
		//		PainStation:Stop()
		//		PainStation = nil
		//	end
		//end
	else
		//if IsValid(PainStation) then
		//	PainStation:Stop()
		//	PainStation = nil
		//end
	end

	if brain > 0.055 then
		local sound_name = "sound/robotomy.ogg"
		if not IsValid(BrainTraumaStation) or BrainTraumaStation_name ~= sound_name then
			if IsValid(BrainTraumaStation) then
				BrainTraumaStation:Stop()
			end
			if IsValid(Tinnitus) then
				Tinnitus:Stop()
				Tinnitus = nil
			end
			lply.tinnitus = 0
			sound.PlayFile(sound_name, "noblock noplay", function(station, err)
				if IsValid(station) then
					station:SetVolume(1)
					station:Play()
					BrainTraumaStation = station
					BrainTraumaStation_name = sound_name
					station:EnableLooping(true)
				end
			end)
		end
		hg.AddFlash(lply:EyePos(), 1, lply:EyePos(), 4, 500)

		-- Apply a more severe long term concussion
		org.concussion_severity = (org.concussion_severity or 0) + 15
		concussion_effect_time = math.max(concussion_effect_time, 60)
		-- More visuals
		show_some_images_time = 1000
	elseif brain > 0.01 then
		local chooser = 1
		for i, choose in ipairs(stations) do
			if choose < brain then
				chooser = i
			end
		end
	
		local sound_name = "sound/zcitysnd/real_sonar/brainhemorrhagestage"..chooser..".mp3"
		if !IsValid(BrainTraumaStation) or choosera != chooser or BrainTraumaStation:GetState() != GMOD_CHANNEL_PLAYING or BrainTraumaStation_name != sound_name then
			if IsValid(BrainTraumaStation) then
		BrainTraumaStation:Stop()
		BrainTraumaStation = nil
		BrainTraumaStation_name = nil
	end

			sound.PlayFile(sound_name, "noblock noplay", function(station, err)
				if IsValid(station) then
					station:SetVolume(0)
					station:Play()
					BrainTraumaStation = station
					BrainTraumaStation_name = sound_name
					station:EnableLooping(true)
				end
			end)
			choosera = chooser
		end

		if IsValid(BrainTraumaStation) then
			BrainTraumaStation:SetVolume(math.Clamp(!org.otrub and brain * 2 or 0.05, 0, 1))
		end
	else
		if IsValid(BrainTraumaStation) then
			BrainTraumaStation:Stop()
			BrainTraumaStation = nil
			BrainTraumaStation_name = nil
		end
	end

	//if brain > 0.1 and not org.otrub and show_some_images_time > 0 and false then
	if lply.tinnitus and lply.tinnitus > CurTime() and lply:Alive() then
		if !IsValid(Tinnitus) or Tinnitus:GetState() != GMOD_CHANNEL_PLAYING  then
			sound.PlayFile("sound/zcitysnd/real_sonar/tinnitus"..math.random(3)..".mp3", "noblock noplay", function(station, err)
				if IsValid(station) then
					station:SetVolume(0)
					station:Play()
					Tinnitus = station
					station:EnableLooping(true)
				end
			end)
		end

		if IsValid(Tinnitus) then
			Tinnitus:SetVolume(org.otrub and 0.05 or math.min(math.max(lply.tinnitus - CurTime(), 0) / 10, 1))
            Tinnitus:SetPlaybackRate(1)
		end
	else
		if IsValid(Tinnitus) then
			Tinnitus:Stop()
			Tinnitus = nil
		end
	end
	
	if brain > 0.1 and not org.otrub then
		if show_some_images_time > 0 then
			brain_motionblur = true
			DrawMotionBlur(0.1, 1., 0.1)
			show_some_images_time = show_some_images_time - 1
			if show_image_time <= 0 and math.random(10 * (1 - brain)) < 2 then
				show_image_time = 250 * (0.1 * 3) * math.Rand(0.1, 1) * (math.random(2) == 1 and 0.1 or 1)
				lobotomy_index = math.random(#lobotomy_mats)
			end

			if show_image_time > 0 then
				show_image_time = show_image_time - 1

				if lobotomy_index then
					surface.SetDrawColor(255,255,255,255)
					surface.SetMaterial(lobotomy_mats[lobotomy_index])
					local rand = 5
					surface.DrawTexturedRect(-math.random(rand), -math.random(rand), ScrW() + math.random(rand), ScrH() + math.random(rand))
				end
			end
		else
			brain_motionblur = false
			show_some_images_time = math.random(1200) < (brain * 15) and 250 or 0
		end
	else
		brain_motionblur = false
		show_image_time = 0
		lobotomy_index = 0
	end
	
	if O2Lerp > 1 then
		render.UpdateScreenEffectTexture()
		
		o2 = O2Lerp
		
		noiseMat:SetFloat("$c0_y", 1 - o2 / 200) //Gate
		noiseMat:SetFloat("$c0_z", 1) //ColorIntensity
		noiseMat:SetFloat("$c1_x", math.Clamp(o2 / 200, 0, 2)) //Lerp
		noiseMat:SetFloat("$c1_y", o2 * (!org.otrub and 0.05 or 1)) //Vignette
		noiseMat:SetFloat("$c2_x", CurTime() + 10000) //Time

		render.SetMaterial(noiseMat)
		render.DrawScreenQuad()
		
		if o2 > 50 and !org.otrub then
			if !IsValid(NoiseStation2) or NoiseStation2:GetState() != GMOD_CHANNEL_PLAYING then
				local o2_sound_choice = o2_sounds[math.random(#o2_sounds)]
				sound.PlayFile(o2_sound_choice, "noblock noplay", function(station)
					if IsValid(station) then
						station:SetVolume(0)
						station:SetPlaybackRate(math.Rand(0.75, 1.1))
						station:Play()
						station:SetTime(math.min(brain / 0.5 * station:GetLength()), 87)
						NoiseStation2 = station
						station:EnableLooping(true)
					end
				end)
			end
			
			if IsValid(NoiseStation2) then
				NoiseStation2:SetVolume(math.Clamp((o2 - 50) / 100 + (brain > 0.3 and (brain - 0.3) * 5 or 0), 0, 0.25))
			end
		else
			if IsValid(NoiseStation2) then
				NoiseStation2:SetVolume(0)
			end
		end
		
		if o2 > 20 and org.otrub then
			if !IsValid(NoiseStation) or NoiseStation:GetState() != GMOD_CHANNEL_PLAYING then
				sound.PlayFile("sound/zbattle/unconscious_type_beat.ogg", "noblock noplay", function(station)
					if IsValid(station) then
						station:SetVolume(0)
						station:Play()
						station:SetTime(math.min(brain / 0.5 * station:GetLength(), 200))
						NoiseStation = station
						station:EnableLooping(true)
					end
				end)
			end

			if IsValid(NoiseStation) then
				NoiseStation:SetVolume(math.Clamp((o2 - 30) / 100 + (brain > 0.3 and (brain - 0.3) * 5 or 0), 0, 0.2))
			end
		else
			if IsValid(NoiseStation) then
				NoiseStation:SetVolume(0)
			end
		end
	else
		if IsValid(NoiseStation) then
			NoiseStation:Stop()
			NoiseStation = nil
		end
	end
end)

hook.Add("Player_Death", "ItDoesntNow", function(ply)
	if !((ply == lply) or (ply == lply:GetNWEntity("spect"))) then return end

	stopthings()
end)

hook.Add("Player Spawn", "ItDoesntNow", function(ply)
	if ply != lply then return end

	stopthings()
end)


local function removeflash()
	if IsValid(lply.blindflash) then
		lply.blindflash:Remove()
	end
end

hook.Add("PreDrawOpaqueRenderables", "renderblindnessflash", function()
	local spect = IsValid(lply:GetNWEntity("spect")) and lply:GetNWEntity("spect")
	
	if !lply:Alive() and !IsValid(spect) then removeflash() return end
	if !lply:Alive() and viewmode != 1 then removeflash() return end

	local organism = lply:Alive() and lply.organism or (IsValid(spect) and spect.organism)
	if not organism or isbool(organism) then return end

	if !(organism.blindness or (amtflashed or 0) >= 0.8) then removeflash() return end
	local blindness = ((organism.blindness and math.Round(organism.blindness) == 0) or amtflashed >= 0.8) and 0 or (organism.blindness)

	local eyesmode = math.Round(blindness)

	local view = render.GetViewSetup(true)
	
	if not IsValid(lply.blindflash) then
		lply.blindflash = ProjectedTexture()
		lply.blindflash:SetTexture("effects/flashlight001")
		lply.blindflash:SetEnableShadows(false)
		lply.blindflash:SetConstantAttenuation(.1)
	end
	
	local Ang = view.angles
	Ang[2] = Ang[2] + (eyesmode == 2 and 90 or eyesmode == 1 and -90 or 0)
	Ang[1] = eyesmode == 0 and Ang[1] or 0
	lply.blindflash:SetFarZ(40)
	lply.blindflash:SetFOV(160)
	lply.blindflash:SetBrightness(1)
	lply.blindflash:SetPos(view.origin)
	lply.blindflash:SetAngles(Ang)
	lply.blindflash:Update()
end)


local fatman = {
	nextCheck = 0,
	activeUntil = 0,
	startedAt = 0,
	duration = 0,
	regular = CreateMaterial("hg_fatman_regular", "UnlitGeneric", {
		["$basetexture"] = "custom/REGULARfatman",
		["$vertexcolor"] = "1",
		["$vertexalpha"] = "1"
	}),
	shocked = CreateMaterial("hg_fatman_shocked", "UnlitGeneric", {
		["$basetexture"] = "custom/SHOCKEDfatman",
		["$vertexcolor"] = "1",
		["$vertexalpha"] = "1"
	}),
	dead = CreateMaterial("hg_fatman_dead", "UnlitGeneric", {
		["$basetexture"] = "custom/DEADfatman",
		["$vertexcolor"] = "1",
		["$vertexalpha"] = "1"
	})
}

hook.Add("Post Post Processing", "CustomEffects", function()
    local suppression_vignette = 0
    local ply = lply
    if not IsValid(ply) or not ply:Alive() then return end

    local org = ply.organism
    if not org then return end

	vignette_intensity = vignette_intensity or 0
	local saturation = 1
	local wave_effect_active = false



    -- Vomit vignette
    local vomit_vignette = org.wantToVomit and org.wantToVomit > 0.95

    -- Fear effects
    local fear = org.fear or 0
    local fear_intensity = math.Clamp(fear, 0, 1)

    if fear_intensity > 0.01 then
        -- Vignette
        vignette_intensity = vignette_intensity + (fear_intensity * 40) -- max 40 intensity from fear

        -- Grayscale
        local fear_saturation = 1 - (fear_intensity * 0.9) -- max 90% desaturation from fear
        saturation = math.min(saturation, fear_saturation)

        -- Wave effect for high fear
        if fear_intensity > 0.6 then
            wave_effect_active = true
        end
    end

    local desensitized = org.desensitized or 0
    if desensitized > 0.5 then
        local desensitized_saturation = 1 - (desensitized - 0.5) * 0.5 -- max 25% desaturation from desensitized
        saturation = math.min(saturation, desensitized_saturation)
    end

    -- Low mood vignette
    local low_mood_vignette = (org.mood and org.mood < 40)

    -- Suicidal vignette
    local suicidal_vignette = org.mood and org.mood < 10

    if vomit_vignette then vignette_intensity = vignette_intensity + 5 end
    if low_mood_vignette then vignette_intensity = vignette_intensity + 7 end
    if suicidal_vignette then vignette_intensity = vignette_intensity + 12 end

    if wave_effect_active then
        render.UpdateScreenEffectTexture()
        tunnelWaveMat:SetFloat("$c1_w", 0.5)
        render.SetMaterial(tunnelWaveMat)
        render.DrawScreenQuad()
    end

    -- Low blood grayscale
    local blood_val = org.blood or 5000
    
    -- Only calculate if the condition is met
    if blood_val < 4500 then
        -- Calculate saturation based on blood, defaults to 1 if blood is not low
        local blood_saturation = (blood_val < 4500) and math.Clamp(math.Remap(blood_val, 1000, 4500, 0, 1), 0, 1) or 1
        
        -- The final saturation is the minimum of the two, so the strongest effect applies
        saturation = math.min(saturation, blood_saturation)
    end
    
    -- Only draw if the effect is active
    if saturation < 1 then
        local tab = {}
        tab["$pp_colour_colour"] = saturation
        DrawColorModify(tab)
    end

    if vignette_intensity > 0 then
        render.UpdateScreenEffectTexture()
        vignetteMat:SetFloat("$c1_y", vignette_intensity)
        render.SetMaterial(vignetteMat)
        render.DrawScreenQuad()
    end
end)

local suppression_sway_intensity = 0
local concussion_disorientation = 0

hook.Add("CalcView", "SuppressionSway", function(ply, pos, angles, fov)
    if not IsValid(ply) or not ply:Alive() then return end

    local suppression = _G.suppression_severity or 0
    suppression_sway_intensity = Lerp(FrameTime() * 1, suppression_sway_intensity, suppression)

    local org = ply.organism
    if org and (org.concussion_severity or 0) > 0 then
        concussion_disorientation = Lerp(FrameTime() * 0.5, concussion_disorientation, org.concussion_severity / 10)
        if concussion_disorientation > 0.1 then
            ply.tinnitus = CurTime() + concussion_disorientation * 5
        end
    else
        concussion_disorientation = Lerp(FrameTime() * 1, concussion_disorientation, 0)
    end

    if suppression_sway_intensity > 0.01 or concussion_disorientation > 0.01 then
        local curTime = CurTime()
        local sway_amount = (suppression_sway_intensity * 2) + (concussion_disorientation * 5)
        angles.p = angles.p + math.sin(curTime * 0.7 + math.cos(curTime * 0.2) * 0.5) * sway_amount * 0.5
        angles.y = angles.y + math.cos(curTime * 0.5 + math.sin(curTime * 0.3) * 0.5) * sway_amount
        angles.r = angles.r + math.sin(curTime * 0.3) * sway_amount * 1.5
    end

    return {
        origin = pos,
        angles = angles,
        fov = fov
    }
end)

hook.Add("Think", "hg-aprilfools-fatman", function()
	if not GetGlobalBool("hg_aprilfools", false) then return end
	local now = CurTime()
	if now < fatman.nextCheck then return end
	fatman.nextCheck = now + 5
	if now < fatman.activeUntil then return end
	if math.random() <= 0.2 then
		local duration = SoundDuration("fatman.wav")
		if not duration or duration <= 0 then
			duration = 3
		end
		fatman.duration = duration
		fatman.startedAt = now
		fatman.activeUntil = now + duration
		surface.PlaySound("fatman.wav")
	end
end)

hook.Add("HUDPaint", "hg-aprilfools-fatman", function()
	local now = CurTime()
	if now >= fatman.activeUntil or fatman.startedAt <= 0 then return end
	local elapsed = now - fatman.startedAt
	local mat
	if elapsed < 1 then
		mat = fatman.regular
	elseif elapsed < 2 then
		mat = fatman.shocked
	else
		mat = fatman.dead
	end
	if not mat then return end
	local scrW, scrH = ScrW(), ScrH()
	local maxW = scrW * 0.6
	local maxH = scrH * 0.8
	local targetW = maxH * (9 / 16)
	local targetH = maxH
	if targetW > maxW then
		targetW = maxW
		targetH = maxW * (16 / 9)
	end
	local x = (scrW - targetW) * 0.5
	local y = (scrH - targetH) * 0.5
	render.SetLightingMode(1)
	surface.SetMaterial(mat)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRect(x, y, targetW, targetH)
	render.SetLightingMode(0)
end)
 