if SERVER then
    util.AddNetworkString("headtrauma_flash")
end
--local Organism = hg.organism
local function isCrush(dmgInfo)
	return (not dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_BLAST)) or dmgInfo:GetInflictor().RubberBullets
end

local halfValue2 = util.halfValue2
local function damageBone(org, bone, dmg, dmgInfo, key, boneindex, dir, hit, ricochet, nodmgchange)
	local crush = isCrush(dmgInfo)
	
	if dmgInfo:IsDamageType(DMG_SLASH) and dmg > 1.5 then
		//crush = false
	end
	
	dmg = dmg * (dmgInfo:GetInflictor().BreakBoneMul or 1)
	
	if crush then
		crush = halfValue2(1 - org[key], 1, 0.5)
		dmg = dmg / math.max(10 * crush * (bone or 1), 1)
		if dmgInfo:GetInflictor().RubberBullets then dmg = dmg * dmgInfo:GetInflictor().Penetration end
	end

	local val = org[key]
	org[key] = math.min(org[key] + dmg, 1)
	local scale = 1 - (org[key] - val)
	
	if !nodmgchange then dmgInfo:ScaleDamage(1 - (crush and 1 * crush * math.max((1 - org[key]) ^ 0.1, 0.5) or (1 - org[key]) * (bone))) end

	return (crush and 1 * crush * math.max((1 - org[key]) ^ 0.1, 0.5) or (1 - org[key]) * (bone)), VectorRand(-0.2,0.2) / math.Clamp(dmg,0.4,0.8)
end

local huyasd = {
	["spine1"] = "I don't feel anything below my hips.",
	["spine2"] = "I cant't feel or move anything below my torso.",
	["spine3"] = "I can't move at all. I can barely even breathe.",
	["skull"] = "My head is aching.",
}

local broke_arm = {
	"AAAAH OH GOD, IT'S BROKEN! MY ARM! IT'S BROKEN!",
	"FUCK MY FUCKING ARM IS BROKEN!",
	"NONONO MY ARM IS BENT ALL WRONG!",
	"IT'S.. MY ARM.. SNAPPED- I HEARD IT SNAP!",
	"MY ARM IS NOT SUPPOSED TO BEND IN HALF!",
}

local dislocated_arm = {
	"MY ARM- GOD, IT'S POPPED OUT OF THE SOCKET!",
	"FUCK- THE SHOULDER'S JUST- HANGING LOOSE!",
	"MY ARM..! IT'S DISLOCATED! I CAN SEE THE BULGE WHERE IT'S WRONG!",
	"THE ARM'S JUST- DEAD WEIGHT- IT'S NOT ATTACHED RIGHT!",
	"SHIT! I CAN FEEL THE BONE OUT OF PLACE!",
}

local broke_leg = {
	"MY LEG- FUCK, IT'S BROKEN- I HEARD THE SNAP!",
	"FUCK! THE SHIN'S SNAPPED CLEAN THROUGH!",
	"THE KNEE'S WRONG- THE WHOLE LEG'S TWISTED WRONG!",
	"MY LEG..! IT'S JUST- HANGING BY MUSCLE AND SKIN!",
	"THE PAIN'S SHOOTING UP TO MY HIP- FUCK, IT'S BAD!",
	"I CAN'T MOVE MY FOOT- THE ANKLE'S BROKEN TOO!",
}

local dislocated_leg = {
	"MY LEG- FUCK, IT'S DISLOCATED AT THE KNEE!",
	"I CAN SEE THE KNEECAP IN THE WRONG PLACE!",
	"AGHH- THE HIP'S POPPED OUT- IT'S STUCK OUTWARD!",
	"IT'S BENT BACKWARD- THE KNEE SHOULDN'T BEND THIS WAY!",
	"FUCK! THE HIP'S DISLOCATED!",
	"THE ANKLE'S TWISTED- BUT THE KNEE'S THE REAL PROBLEM!",
}

    local destroyed_eye = {
	"I CANT SEE OUT OF MY EYE!",
	"MY EYE- MY EYE IS GONE!",
	"My eye- Im bleeding out of my eye...",
}

local function PlayInjurySound(owner, injuryType)
    if math.random(10) <= 3 then -- 30% chance
        owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
        return
    end

    if injuryType == "break" then
        owner:EmitSound("owfuck" .. math.random(1, 4) .. ".ogg", 75, 100, 1, CHAN_AUTO)
    elseif injuryType == "dislocation" then
        owner:EmitSound("disloc" .. math.random(1, 2) .. ".ogg", 75, 100, 1, CHAN_AUTO)
    end
end

local function legs(org, bone, dmg, dmgInfo, key, boneindex, dir, hit, ricochet)
	local oldDmg = org[key]
	local dmg = dmg * 4

	if dmgInfo:IsDamageType(DMG_CRUSH) and dmg > 4 and !org[key.."amputated"] then
		hg.organism.AmputateLimb(org, key)

		return 0
	end

	if org[key] == 1 then return 0 end

	local result, vecrand = damageBone(org, 0.3, dmg, dmgInfo, key, boneindex, dir, hit, ricochet)
	
	local dmg = org[key]
	
	org[key] = org[key] * 0.5

	if dmg < 0.7 then return 0 end
	if dmg < 1 and !dmgInfo:IsDamageType(DMG_CLUB+DMG_CRUSH+DMG_FALL) then return 0 end

	if org.isPly and !org[key.."amputated"] then org.just_damaged_bone = CurTime() end
	
	if dmg >= 1 and (!dmgInfo:IsDamageType(DMG_CLUB+DMG_CRUSH+DMG_FALL) or math.random(3) != 1) then
		org[key] = 1

		org.painadd = org.painadd + 55
		org.owner:AddNaturalAdrenaline(1)
		org.immobilization = org.immobilization + dmg * 25
		org.fearadd = org.fearadd + 0.5
		org.internalBleed = (org.internalBleed or 0) + 10

		--if org.isPly and !org[key.."amputated"] then org.owner:Notify(broke_leg[math.random(#broke_leg)], 1, "broke"..key, 1, nil, nil) end

		timer.Simple(0, function() hg.LightStunPlayer(org.owner,2) end)
		PlayInjurySound(org.owner, "break")
		//broken
	else
		//org[key] = 0.5
		org[key.."dislocation"] = true

		org.painadd = org.painadd + 35
		org.owner:AddNaturalAdrenaline(0.5)
		org.immobilization = org.immobilization + dmg * 10
		org.fearadd = org.fearadd + 0.5

		--if org.isPly and !org[key.."amputated"] then org.owner:Notify(dislocated_leg[math.random(#dislocated_leg)], 1, "dislocated"..key, 1, nil, nil) end

		timer.Simple(0, function() hg.LightStunPlayer(org.owner,2) end)
		PlayInjurySound(org.owner, "dislocation")
		//dislocated
	end

	hg.AddHarmToAttacker(dmgInfo, (org[key] - oldDmg) * 2, "Legs bone damage harm")

	return result, vecrand
end

local function arms(org, bone, dmg, dmgInfo, key, boneindex, dir, hit, ricochet)
	local oldDmg = org[key]
	local dmg = dmg * 4
	
	if dmgInfo:IsDamageType(DMG_CRUSH) and dmg > 4 and !org[key.."amputated"] then
		hg.organism.AmputateLimb(org, key)

		return 0
	end

	if org[key] == 1 then return 0 end

	local result, vecrand = damageBone(org, 0.3, dmg, dmgInfo, key, boneindex, dir, hit, ricochet)
	
	local dmg = org[key]
	
	org[key] = org[key] * 0.5

	if dmg < 0.6 then return 0 end
	if dmg < 1 and !dmgInfo:IsDamageType(DMG_CLUB+DMG_CRUSH+DMG_FALL) then return 0 end

	if org.isPly and !org[key.."amputated"] then org.just_damaged_bone = CurTime() end
	
	if dmg >= 1 and (!dmgInfo:IsDamageType(DMG_CLUB+DMG_CRUSH+DMG_FALL) or math.random(3) != 1) then
		org[key] = 1

		org.painadd = org.painadd + 55
		org.owner:AddNaturalAdrenaline(1)
		org.fearadd = org.fearadd + 0.5

		--if org.isPly and !org[key.."amputated"] then org.owner:Notify(broke_arm[math.random(#broke_arm)], 1, "broke"..key, 1, nil, nil) end

		--timer.Simple(0, function() hg.LightStunPlayer(org.owner,1) end)
		PlayInjurySound(org.owner, "break")
		//broken
	else
		org[key.."dislocation"] = true
		//org[key] = 0.5

		org.painadd = org.painadd + 35
		org.owner:AddNaturalAdrenaline(0.5)
		org.fearadd = org.fearadd + 0.5

		--if org.isPly and !org[key.."amputated"] then org.owner:Notify(dislocated_arm[math.random(#dislocated_arm)], 1, "dislocated"..key, 1, nil, nil) end

		--timer.Simple(0, function() hg.LightStunPlayer(org.owner,1) end)
		PlayInjurySound(org.owner, "dislocation")
		//dislocated
	end

	hg.AddHarmToAttacker(dmgInfo, (org[key] - oldDmg) * 1.5, "Arms bone damage harm")

	if org[key] == 1 and key == "rarm" and org.isPly then
		local wep = org.owner.GetActiveWeapon and org.owner:GetActiveWeapon()
		
		/*if IsValid(wep) then
			local inv = org.owner:GetNetVar("Inventory",{})
			if not (inv["Weapons"] and inv["Weapons"]["hg_sling"] and ishgweapon(wep) and not wep:IsPistolHoldType()) then
				hg.drop(org.owner)
			else
				org.owner:SetActiveWeapon(org.owner:GetWeapon("weapon_hands_sh"))
			end
		end*/
	end

	return result, vecrand
end

local function spine(org, bone, dmg, dmgInfo, number, boneindex, dir, hit, ricochet)
	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 3 end

	if number == 3 then
		dmg = dmg * 1.3
	end

	local name = "spine" .. number
	local name2 = "fake_spine" .. number
	if org[name] >= 1 then return 0 end
	local oldDmg = org[name]

	local result, vecrand = damageBone(org, 0.1, isCrush(dmgInfo) and dmg * 2.5 or dmg * 2.5, dmgInfo, name, boneindex, dir, hit, ricochet)
	
	hg.AddHarmToAttacker(dmgInfo, (org[name] - oldDmg) * 5, "Spine bone damage harm")
	
	if (name == "spine3" || name == "spine2") then
		hg.AddHarmToAttacker(dmgInfo, (org[name] - oldDmg) * 8, "Broken spine harm")
	end

	if org[name] >= (number == 3 and 0.75 or 1) then
	elseif number == 3 and org[name] > 0.5 then
		--org.paralyzed = true
		org.stamina[1] = math.max(org.stamina[1] - 50, 0)
		if org.o2 and org.o2[1] then
			org.o2[1] = math.max(org.o2[1] - 20, 0)
		end
		org.consciousness = math.max(org.consciousness - 0.2, 0)
		org.disorientation = (org.disorientation or 0) + 5
	end

	if org[name] >= 1 and org.isPly then
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
		if org.owner:IsPlayer() then
			org.owner:Notify(huyasd[name], true, name, 2)
		end
		org.painadd = org.painadd + 25
		
		if number == 1 then
			org.owner:SetJumpPower(0)
			org.owner:SetRunSpeed(1)
			org.owner:SetWalkSpeed(1)
		elseif number == 2 then
			org.owner:SetJumpPower(0)
			org.owner:SetRunSpeed(1)
			org.owner:SetWalkSpeed(1)
			org.SwayAdd = (org.SwayAdd or 0) + 1
			org.RecoilAdd = (org.RecoilAdd or 0) + 1
			org.MeleeDamageMul = 0
		end
	elseif org[name] > 0.75 then
		local spine_damage = org[name]
		
		if math.random(1, 10) <= 3 then -- 30% chance of dislocation
			org[name.."dislocation"] = true
			if org.isPly then
				--org.owner:Notify("Your spine feels dislocated!", 1, "dislocated"..name, 1, nil, nil)
			end
			PlayInjurySound(org.owner, "dislocation")
		else
			if org.isPly then
				--org.owner:Notify("Your spine is severely damaged!", 1, "damaged"..name, 1, nil, nil)
			end
			PlayInjurySound(org.owner, "break")
		end
	end
	
	if dmg > 0.2 then
		--org.owner:Notify("Your spinal cord is damaged.",true,"spinalcord",4)
	end

	org.painadd = org.painadd + dmg * 2
	timer.Simple(0, function() hg.LightStunPlayer(org.owner) end)
	org.shock = org.shock + dmg * 5
	return result,vecrand
end

local jaw_broken_msg = {
	"I FEEL PIECES OF MY JAW... FUCK-FUCK-FUCK",
	"MY JAW IS FUCKING FLOATING IN MY HEAD",
	"MY JAW... OHH IT HURTS REALLY BAD... I FEEL PIECES OF IT MOVING",
}

local jaw_dislocated_msg = {
	"I CAN'T CLOSE MY JAW... IT FUCKING HURTS",
	"MY JAW... ITS JUST STUCK THERE-- OH ITS PAINING",
	"I CANT MOVE MY JAW AT ALL... AND ITS REALLY ACHING",
	//"I CANT EVEN SPEAK, I NEED TO PUNCH IT BACK IN PLACE... BUT IT HURTS REAL BAD",
}

local input_list = hg.organism.input_list
input_list.jaw = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet)
	local oldDmg = org.jaw

	local result, vecrand = damageBone(org, 0.25, dmg, dmgInfo, "jaw", boneindex, dir, hit, ricochet)

	hg.AddHarmToAttacker(dmgInfo, (org.jaw - oldDmg) * 3, "Jaw bone damage harm")

	if org.jaw == 1 and (org.jaw - oldDmg) > 0 and org.isPly then org.owner:Notify(jaw_broken_msg[math.random(#jaw_broken_msg)], true, "jaw", 2) end

	local dislocated = (org.jaw - oldDmg) > math.Rand(0.1, 0.3)

	if org.jaw == 1 then
		org.shock = org.shock + dmg * 40
		org.avgpain = org.avgpain + dmg * 30

		if oldDmg != 1 then org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO) end
	end

	org.shock = org.shock + dmg * 3

	if dislocated then
		org.shock = org.shock + dmg * 20
		org.avgpain = org.avgpain + dmg * 20
		
		if !org.jawdislocation then
			org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
		end

		org.jawdislocation = true

		if org.isPly then org.owner:Notify(jaw_dislocated_msg[math.random(#jaw_dislocated_msg)], true, "jaw", 2) end
	end

	if dmg > 0.2 then
		if org.isPly then timer.Simple(0, function() hg.LightStunPlayer(org.owner,1 + dmg) end) end
	end

	return result, vecrand
end

local nose_broken_msg = {
	"I smell copper...",
	"I can feel blood running down my nose.",
	"I think I broke my nose...",
}

input_list.nose = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet)
	local oldDmg = org.nose or 0
	-- Nose is fragile, high damage multiplier
	local result, vecrand = damageBone(org, 0.1, dmg * 3, dmgInfo, "nose", boneindex, dir, hit, ricochet)

	hg.AddHarmToAttacker(dmgInfo, ((org.nose or 0) - oldDmg) * 4, "Nose bone damage harm")

	if (org.nose or 0) >= 1 and oldDmg < 1 then
		owner:EmitSound("owfuck" .. math.random(1, 4) .. ".ogg", 75, 100, 1, CHAN_AUTO)
		if org.isPly then org.owner:Notify(nose_broken_msg[math.random(#nose_broken_msg)], true, "nose", 2) end
	end
	
	-- Effects
	org.painadd = org.painadd + dmg * 25
	org.shock = org.shock + dmg * 15
	org.disorientation = org.disorientation + dmg * 2
	org.bleed = org.bleed + dmg * 2

	if dmg > 0.3 then
		if org.isPly then timer.Simple(0, function() hg.LightStunPlayer(org.owner, 1 + dmg) end) end
	end

	return result, vecrand
end

hook.Add("CanListenOthers", "CantHaveShitInDetroit", function(output, input, isChat, teamonly, text)
	if IsValid(output) and (output.organism.jaw == 1 or output.organism.jawdislocation) and output:Alive() and (output:IsSpeaking() or isChat) then
		-- and !isChat and output:IsSpeaking()
		output.organism.painadd = output.organism.painadd + 2 * (output:IsSpeaking() and 1 or (isChat and 5 or 0))
		output:Notify("My jaw is really hurting when I speak.", 60, "painfromjawspeak", 0, nil, Color(255, 210, 210))
	end
end)

local function shouldTriggerTinnitus(dmgInfo, damage)
	-- Require minimum 0.1 damage (adjusted for 0-1 damage scale)
	if damage < 0.1 then 
		return false 
	end
	
	-- Determine chance based on damage type - REDUCED for balance
	local chance = 30 -- Reduced from 60% to 30% for other damage types
	local damageType = "OTHER"
	if dmgInfo:IsDamageType(DMG_CLUB) then
		chance = 50 -- Reduced from 80% to 50% for club damage
		damageType = "CLUB"
	elseif dmgInfo:IsDamageType(DMG_SLASH) then
		chance = 20 -- Reduced from 40% to 20% for slash damage
		damageType = "SLASH"
	end
	
	-- Roll for chance
	local roll = math.random(100)
	local success = roll <= chance
	
	return success
end

local function manageTinnitusSound(org, targetPlayer)
	if not IsValid(targetPlayer) or not targetPlayer:IsPlayer() then return end
	
	-- Check if skull health is at 40% or lower (skull >= 0.6)
	if org.skull >= 0.6 then
		-- Start long tinnitus loop if not already playing
		if not org.tinnitusLongPlaying then
			org.tinnitusLongPlaying = true
			
			-- Play the long tinnitus sound immediately only to victim
			targetPlayer:PlayCustomTinnitus("tinnituslong.wav")
			
			-- Create a timer to loop the sound and apply constant disorientation
			local timerName = "TinnitusCheck_" .. targetPlayer:SteamID64()
			timer.Create(timerName, 8.0, 0, function() -- Loop every 8 seconds (duration of tinnituslong.wav)
				if not IsValid(targetPlayer) or not targetPlayer:Alive() or org.skull < 0.6 then
					-- Stop the long tinnitus effect
					org.tinnitusLongPlaying = false
					timer.Remove(timerName)
				else
					-- Play the sound again to loop it only to victim
					targetPlayer:PlayCustomTinnitus("tinnituslong.wav")
				end
			end)
			
			-- Create a separate timer for disorientation application
			local disorientTimerName = "TinnitusDisorient_" .. targetPlayer:SteamID64()
			timer.Create(disorientTimerName, 0.1, 0, function()
				if not IsValid(targetPlayer) or not targetPlayer:Alive() or org.skull < 0.6 then
					timer.Remove(disorientTimerName)
				else
					-- Apply constant disorientation - NERFED for balance (0.6 per second, 0.06 per 0.1 second tick)
					org.disorientation = math.min(org.disorientation + 0.06, 1.5)
				end
			end)
		end
	else
		-- Stop long tinnitus if skull healed above 40%
		if org.tinnitusLongPlaying then
			org.tinnitusLongPlaying = false
			timer.Remove("TinnitusCheck_" .. targetPlayer:SteamID64())
			timer.Remove("TinnitusDisorient_" .. targetPlayer:SteamID64())
		end
	end
end

local function ApplyConcussion(org, dmg, targetPlayer)
    if not (IsValid(targetPlayer) and targetPlayer:IsPlayer()) then return end

    -- Reduce consciousness temporarily
    org.consciousness = math.max(org.consciousness - dmg * 0.3, 0)
    timer.Simple(15, function()
        if IsValid(org.owner) and org.owner:Alive() then
            org.consciousness = math.min(org.consciousness + dmg * 0.3, 1)
        end
    end)

    -- Add disorientation
    org.disorientation = math.min(org.disorientation + dmg * 2.0, 2.5)

    -- Play concussion sound
    local idx = math.random(1, 4)
    local snd = "concussion" .. idx .. ".mp3"
    net.Start("hg_play_client_sound_file")
    net.WriteString(snd)
    net.Send(targetPlayer)
end
hg.organism.ApplyConcussion = ApplyConcussion

local function headTraumaFlash(targetPlayer, dmgInfo, skullDelta, oldBrain, newBrain)
	if not (IsValid(targetPlayer) and targetPlayer:IsPlayer()) then return end

	local flashTime, flashSize
	local worldPos

	if skullDelta then
		-- Melee/Collision flash
		flashTime = math.Clamp(0.5 + skullDelta * 1.5, 0.5, 2.0)
		flashSize = math.Clamp(1600 + skullDelta * 2000, 1600, 4000)
		local eyePos = targetPlayer:EyePos()
		local ang = targetPlayer:EyeAngles()
		local incomingPos = dmgInfo:GetDamagePosition()
		local incDir = (incomingPos - eyePos):GetNormalized()
		local dotRight = ang:Right():Dot(incDir)
		local offset = ang:Right() * (dotRight * 160)
		worldPos = eyePos + offset + ang:Forward() * 16
	elseif oldBrain and newBrain then
		-- Brain damage flash
		local brainDelta = math.max(newBrain - oldBrain, 0)
		if brainDelta <= 0.15 then return end

		flashTime = math.Clamp(0.25 + brainDelta * 0.8, 0.25, 1.0)
		flashSize = math.Clamp(1400 + brainDelta * 1600, 1200, 3000)
		local eyePos = targetPlayer:EyePos()
		local ang = targetPlayer:EyeAngles()
		local incomingPos = dmgInfo:GetDamagePosition()
		local incDir = (incomingPos - eyePos):GetNormalized()
		local dotRight = ang:Right():Dot(incDir)
		local offset = ang:Right() * (dotRight * 160)
		worldPos = eyePos + offset + ang:Forward() * 16
	end

	if flashTime and flashSize and worldPos then
		targetPlayer.HeadDisorientFlashCooldown = targetPlayer.HeadDisorientFlashCooldown or 0
		if targetPlayer.HeadDisorientFlashCooldown < CurTime() then
			net.Start("headtrauma_flash")
			net.WriteVector(worldPos)
			net.WriteFloat(flashTime)
			net.WriteInt(flashSize, 20)
			net.Send(targetPlayer)
			targetPlayer:PlayCustomTinnitus("headhit.mp3")
			targetPlayer.HeadDisorientFlashCooldown = CurTime() + 0.8
		end
	end
end
hg.organism.headTraumaFlash = headTraumaFlash

input_list.skull = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet)
	if dmgInfo:IsDamageType(DMG_BURN) or dmgInfo:IsDamageType(DMG_SLOWBURN) then return 0 end
    local oldDmg = org.skull
    local isBullet = dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT)
    local isSlash = dmgInfo:IsDamageType(DMG_SLASH)
    local brain_damage_multiplier = 1

    if isBullet then
        dmg = dmg * 1.5 -- More damage for bullets
        if math.random(100) <= 15 then
            brain_damage_multiplier = 5 -- 5x brain damage
        end
    end

    if isSlash then
        dmg = dmg * 0.7 -- a bit more damage for slash
    end

    local boneMul = isSlash and 0.4 or 0.3
    local result, vecrand = damageBone(org, boneMul, dmg, dmgInfo, "skull", boneindex, dir, hit, ricochet)

	hg.AddHarmToAttacker(dmgInfo, (org.skull - oldDmg) * 4, "Skull bone damage harm")

    if org.skull == 1 then
        -- bullet: softer shock on fully broken skull
        org.shock = org.shock + (isBullet and dmg * 20 or dmg * 40)
        org.avgpain = org.avgpain + dmg * 30

		if oldDmg != 1 then 
			org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
			-- Play flesh sound when skull is fully damaged (open skull exposes brain)
			org.owner:EmitSound("flesh"..math.random(10)..".wav", 75, math.random(95, 120), 1, CHAN_AUTO)
			-- Play skull opening sound when skull is broken
			org.owner:EmitSound("gore/skullopen"..math.random(1, 3)..".wav", 75, math.random(95, 110), 1, CHAN_AUTO, 0, 0, 175)
		end
	end

    org.shock = org.shock + (isBullet and dmg * 2 or dmg * 3)

    if isSlash then
        dmgInfo:ScaleDamage(0.85) -- extra reduction vs slashes
    end

	local oldBrain = org.brain
	local brain_damage_to_add = 0
	if math.random(10) == 1 then
		brain_damage_to_add = brain_damage_to_add + (dmg * 0.05)
	end
	
	if (org.skull - oldDmg) > 0.6 then
		brain_damage_to_add = brain_damage_to_add + 0.1
	end

	org.brain = math.min(org.brain + (brain_damage_to_add * brain_damage_multiplier), 1)

	if org.brain >= 0.01 and math.random(3) == 1 and (rnd or (org.skull - oldDmg) > 0.6) then
		--hg.applyFencingToPlayer(org.owner, org)
		org.shock = 70

		timer.Simple(0.1, function()
			local rag = hg.GetCurrentCharacter(org.owner)

			if IsValid(rag) and rag:IsRagdoll() then
				hg.applyFencingToPlayer(org.owner, org)
				--local stype = "rigor"--hg.getRandomSpasm()
				--hg.applySpasm(rag, stype)
				--if rag.organism then rag.organism.spasm, rag.organism.spasmType = true, stype end
			end
		end)
	end

	if dmg > 0.4 then
		if org.isPly then
			timer.Simple(0, function()
				hg.LightStunPlayer(org.owner,1 + dmg)
			end)
		end
	end
	


	-- directional flash for victim on club head hits (and rare slash)
	if org.isPly then
		local targetPlayer = org.owner
		if IsValid(org.owner.FakeRagdoll) then
			local ragdoll = org.owner.FakeRagdoll
			if IsValid(ragdoll.ply) then
				targetPlayer = ragdoll.ply
			end
		end

		if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
            -- melee to skull: club, slash, crush (fists)
            if dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_SLASH) or dmgInfo:IsDamageType(DMG_CRUSH) then
                local eyePos = targetPlayer:EyePos()
                local ang = targetPlayer:EyeAngles()
                local incomingPos = dmgInfo:GetDamagePosition()

                local incDir = (incomingPos - eyePos):GetNormalized()
                local dotRight = ang:Right():Dot(incDir)
                -- scale offset by dot to keep flashes nearer center
                local offset = ang:Right() * (dotRight * 160)
                local worldPos = eyePos + offset + ang:Forward() * 16

                    local skullDelta = math.max(org.skull - oldDmg, 0)
                    local flashTime = math.Clamp(0.5 + skullDelta * 1.5, 0.5, 2.0)
                    local flashSize = math.Clamp(1600 + skullDelta * 2000, 1600, 4000)
                    
                    -- play local head-hit tinnitus for victim only

                    net.Start("headtrauma_flash")
                        net.WriteVector(worldPos)
                        net.WriteFloat(flashTime)
                        net.WriteInt(flashSize, 20)
                    net.Send(targetPlayer)
			end
		end
	end

	if org.skull == 1 then
		if org.isPly then
			//org.owner:Notify(huyasd["skull"],true,"skull",4)
		end

		if dir then
			net.Start("hg_bloodimpact")
			net.WriteVector(dmgInfo:GetDamagePosition())
			net.WriteVector(dir / 10)
			net.WriteFloat(3)
			net.WriteInt(1,8)
			net.Broadcast()
			-- Play flesh sound when skull damage causes blood impact (brain exposed)

			org.owner:EmitSound("flesh"..math.random(10)..".wav", 75, math.random(95, 120), 1, CHAN_AUTO)
		end
	end

	-- Enhanced head trauma disorientation system for skull damage
	if (org.skull - oldDmg) > 0.02 then
		-- Skull gives more disorientation than jaw - REDUCED for balance (1.5x multiplier, max 2.0)
		local disorientationAdd = math.min(dmg * 2.5, 3.0)
        org.disorientation = math.min(org.disorientation + disorientationAdd, 2.5)

		-- universal skull flash independent of tinnitus gating
		if org.isPly then
			local tp = org.owner
			if IsValid(org.owner.FakeRagdoll) then
				local ragdoll = org.owner.FakeRagdoll
				if IsValid(ragdoll.ply) then
					tp = ragdoll.ply
				end
			end
			if IsValid(tp) and tp:IsPlayer() then
				local skullDelta = math.max(org.skull - oldDmg, 0)
				local baseFlashTime = math.Clamp(0.3 + skullDelta * 0.9, 0.3, 1.2)
				local baseFlashSize = math.Clamp(1400 + skullDelta * 1600, 1400, 3000)

				-- directional melee flash (club/slash/crush) with cooldown
				if dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_SLASH) or dmgInfo:IsDamageType(DMG_CRUSH) then
					local eyePos = tp:EyePos()
					local ang = tp:EyeAngles()
					local incomingPos = dmgInfo:GetDamagePosition()
					local incDir = (incomingPos - eyePos):GetNormalized()
					local dotRight = ang:Right():Dot(incDir)
					local offset = (dotRight >= 0) and ang:Right() * 160 or ang:Right() * -160
					local worldPos = eyePos + offset + ang:Forward() * 16

					tp.HeadDisorientFlashCooldown = tp.HeadDisorientFlashCooldown or 0
					if tp.HeadDisorientFlashCooldown < CurTime() then
						net.Start("headtrauma_flash")
							net.WriteVector(worldPos)
							net.WriteFloat(baseFlashTime)
							net.WriteInt(baseFlashSize, 20)
						net.Send(tp)
						-- local tinnitus ping
						tp.HeadDisorientFlashCooldown = CurTime() + 0.2
					end
				end

				-- fallback flash on disorientation increase (even when tinnitus gating fails)
				if disorientationAdd > 0.05 then
					local eyePos2 = tp:EyePos()
					local ang2 = tp:EyeAngles()
					local worldPos2 = eyePos2 + ang2:Forward() * 16

					tp.HeadDisorientFlashCooldown = tp.HeadDisorientFlashCooldown or 0
					if tp.HeadDisorientFlashCooldown < CurTime() then
						net.Start("headtrauma_flash")
							net.WriteVector(worldPos2)
							net.WriteFloat(baseFlashTime)
							net.WriteInt(baseFlashSize, 20)
						net.Send(tp)
						-- local tinnitus ping
						tp:PlayCustomTinnitus("headhit.mp3")
						tp.HeadDisorientFlashCooldown = CurTime() + 0.2
					end
				end
			end
		end
		
		-- Play tinnitus sound for head trauma (only to the victim) with damage and chance requirements
		if org.isPly and disorientationAdd > 0.05 and shouldTriggerTinnitus(dmgInfo, dmg) then
			-- Get the actual player entity (handle ragdoll case)
			local targetPlayer = org.owner
			if IsValid(org.owner.FakeRagdoll) then
				-- If player is ragdolled, find the real player
				local ragdoll = org.owner.FakeRagdoll
				if IsValid(ragdoll.ply) then
					targetPlayer = ragdoll.ply
				end
			end
			
			if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
				-- Debug print for tinnitus trigger
				-- Play custom tinnitus sound only to victim
				targetPlayer:PlayCustomTinnitus("tinnitus.wav")
				
				-- Manage long tinnitus loop for low skull health
				manageTinnitusSound(org, targetPlayer)

				-- fallback: flash on skull disorientation increase
				if disorientationAdd > 0.05 then
					local eyePos = targetPlayer:EyePos()
					local ang = targetPlayer:EyeAngles()
					local worldPos = eyePos + ang:Forward() * 16

					local skullDelta = math.max(org.skull - oldDmg, 0)
					local flashTime = math.Clamp(0.3 + skullDelta * 0.9, 0.3, 1.2)
					local flashSize = math.Clamp(1400 + skullDelta * 1600, 1400, 3000)

					-- simple cooldown to avoid doubling with melee block
					targetPlayer.HeadDisorientFlashCooldown = targetPlayer.HeadDisorientFlashCooldown or 0
					if targetPlayer.HeadDisorientFlashCooldown < CurTime() then
						net.Start("headtrauma_flash")
							net.WriteVector(worldPos)
							net.WriteFloat(flashTime)
							net.WriteInt(flashSize, 20)
						net.Send(targetPlayer)
						-- local tinnitus ping
						targetPlayer:PlayCustomTinnitus("headhit.mp3")
						targetPlayer.HeadDisorientFlashCooldown = CurTime() + 0.2
					end
				end

				-- short directional flash on head hit (club), rarely on slash
                -- melee to skull: club, slash, crush (fists)
                if dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_SLASH) or dmgInfo:IsDamageType(DMG_CRUSH) then
                    local eyePos = targetPlayer:EyePos()
                    local ang = targetPlayer:EyeAngles()
                    local incomingPos = dmgInfo:GetDamagePosition()

                    -- pick side using incoming direction vs player right
                    local incDir = (incomingPos - eyePos):GetNormalized()
                    local dotRight = ang:Right():Dot(incDir)
                    -- scale offset by dot to keep flashes nearer center
                    local offset = ang:Right() * (dotRight * 160)
                    local worldPos = eyePos + offset + ang:Forward() * 16

                    local skullDelta = math.max(org.skull - oldDmg, 0)
                    local flashTime = math.Clamp(0.3 + skullDelta * 0.9, 0.3, 1.2)
                    local flashSize = math.Clamp(1400 + skullDelta * 1600, 1400, 3000)
                    
                    -- play local head-hit tinnitus for victim only
                    targetPlayer:PlayCustomTinnitus("headhit.mp3")

                    net.Start("headtrauma_flash")
                        net.WriteVector(worldPos)
                        net.WriteFloat(flashTime)
                        net.WriteInt(flashSize, 20)
                    net.Send(targetPlayer)
				end
			end
		end
	elseif org.isPly then
		-- Check tinnitus management even without new damage (for healing)
		local targetPlayer = org.owner
		if IsValid(org.owner.FakeRagdoll) then
			local ragdoll = org.owner.FakeRagdoll
			if IsValid(ragdoll.ply) then
				targetPlayer = ragdoll.ply
			end
		end
		
		if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
			manageTinnitusSound(org, targetPlayer)
		end
	end

    -- chance to injure an eye from nearby head damage
    local eyeChance = 0
    if dmgInfo:IsDamageType(DMG_SLASH) then
        eyeChance = 45 -- bump: slashes more often catch an eye
    elseif dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT) then
        eyeChance = 35 -- bump bullets/buckshot
    elseif dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_GENERIC) or dmgInfo:IsDamageType(DMG_CRUSH) then
        eyeChance = 12 -- bump blunt head damage chance
    end

    if eyeChance > 0 and math.random(100) <= eyeChance then
        local which = (math.random(2) == 1) and "lefteye" or "righteye"
        local eyeFunc = hg.organism.input_list[which]
        if eyeFunc then eyeFunc(org, 1, dmg, dmgInfo) end
    end

	return result,vecrand
end

local ribs = {
	"Fuck, I think I broke a rib",
	"I can feel something poking my lungs.",
	"Something just broke inside my chest...",
	"My chest isnt supposed to cave inwards...",
}

input_list.chest = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet)	
	local oldDmg = org.chest

	if dmgInfo:IsDamageType(DMG_SLASH+DMG_BULLET+DMG_BUCKSHOT) and math.random(5) == 1 then return 0, vector_origin end --random chance it passed through ribs

	local result, vecrand = damageBone(org, 0.1, dmg / 4, dmgInfo, "chest", boneindex, dir, hit, ricochet, true)
	
	hg.AddHarmToAttacker(dmgInfo, (org.chest - oldDmg) * 3, "Ribs bone damage harm")

	org.painadd = org.painadd + dmg * 1
	org.shock = org.shock + dmg * 1

	if org.isPly and (not org.brokenribs or (org.brokenribs ~= math.Round(org.chest * 3))) then
		org.brokenribs = math.Round(org.chest * 3)
		
		if org.brokenribs > 0 then
			org.owner:Notify(ribs[math.random(#ribs)], 5, "ribs", 4)

			org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)

			return math.min(0, result)
		end
	end

	return result * 0.5, vecrand
end

input_list.pelvis = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet)
	local oldDmg = org.pelvis
	org.painadd = org.painadd + dmg * 1
	org.shock = org.shock + dmg * 1

	local result = damageBone(org, bone, dmg * 0.5, dmgInfo, "pelvis", boneindex, dir, hit, ricochet)
	
	hg.AddHarmToAttacker(dmgInfo, (org.pelvis - oldDmg) / 2, "Pelvis bone damage harm")

	if org.isPly and org.pelvis == 1 then
		org.owner:Notify("My pelvis is agonizingly hurting.", true, "pelvis", 4)
	end

	return result
end

input_list.rarmup = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return arms(org, bone * 1.25, dmg, dmgInfo, "rarm", boneindex, dir, hit, ricochet) end
input_list.rarmdown = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return arms(org, bone, dmg, dmgInfo, "rarm", boneindex, dir, hit, ricochet) end
input_list.larmup = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return arms(org, bone * 1.25, dmg, dmgInfo, "larm", boneindex, dir, hit, ricochet) end
input_list.larmdown = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return arms(org, bone, dmg, dmgInfo, "larm", boneindex, dir, hit, ricochet) end
input_list.rlegup = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return legs(org, bone, dmg * 1.25, dmgInfo, "rleg", boneindex, dir, hit, ricochet) end
input_list.rlegdown = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return legs(org, bone, dmg, dmgInfo, "rleg", boneindex, dir, hit, ricochet) end
input_list.llegup = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return legs(org, bone, dmg * 1.25, dmgInfo, "lleg", boneindex, dir, hit, ricochet) end
input_list.llegdown = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return legs(org, bone, dmg, dmgInfo, "lleg", boneindex, dir, hit, ricochet) end
input_list.spine1 = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return spine(org, bone, dmg, dmgInfo, 1, boneindex, dir, hit, ricochet) end
input_list.spine2 = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return spine(org, bone, dmg, dmgInfo, 2, boneindex, dir, hit, ricochet) end
input_list.spine3 = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return spine(org, bone, dmg, dmgInfo, 3, boneindex, dir, hit, ricochet) end
