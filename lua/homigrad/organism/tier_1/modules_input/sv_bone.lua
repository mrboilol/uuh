--local Organism = hg.organism
if SERVER then
    util.AddNetworkString("headtrauma_flash")
end

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

local dismember_leg = {
	"MY LEG! IT'S GONE!",
	"HELP! MY LEG IS BLOWN OFF!",
	"I CAN'T WALK! MY LEG IS GONE!",
	"FUCK- WHERE'S MY LEG?!",
	"IT'S SEVERED! OH GOD, MY LEG IS SEVERED!",
	"I CAN SEE THE BONE! MY LEG'S GONE!",
}

local dismember_arm = {
	"MY ARM! IT'S GONE! OH GOD!",
	"FUCK! MY ARM IS OFF!",
	"I CAN'T FEEL MY ARM! IT'S GONE!",
	"IT'S RIPPED OFF! MY ARM IS RIPPED OFF!",
	"LOOK AT MY ARM! IT'S JUST GONE!",
	"JESUS CHRIST, MY ARM IS MISSING!",
}

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

		-- oooooooooooooooooowwww
		if org.isPly and org[key.."amputated"] then
			org.owner:Notify(dismember_leg[math.random(#dismember_leg)], true, "dismember_"..key, 3)
		end

		--if org.isPly and !org[key.."amputated"] then org.owner:Notify(broke_leg[math.random(#broke_leg)], 1, "broke"..key, 1, nil, nil) end
		
		-- Gruesome fracture logic
		if dmg > 1.5 or (oldDmg > 0.8 and dmg > 0.5) then
			org.painadd = org.painadd + 40
			org.immobilization = org.immobilization + 20
			org[key.."gruesome"] = true
			
			if org.isPly then
				org.owner:EmitSound("owfuck"..math.random(1,4)..".ogg", 75, 100, 1, CHAN_AUTO) -- Fallback handled if missing
			end
		end

		timer.Simple(0, function() hg.LightStunPlayer(org.owner,2) end)
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
		//broken
	else
		//org[key] = 0.5
		org[key.."dislocation"] = true

		org.painadd = org.painadd + 35
		org.owner:AddNaturalAdrenaline(0.5)
		org.immobilization = org.immobilization + dmg * 10
		org.fearadd = org.fearadd + 0.5

		--if org.isPly and !org[key.."amputated"] then org.owner:Notify(dislocated_leg[math.random(#dislocated_leg)], 1, "dislocated"..key, 1, nil, nil) end
		
		-- Gruesome dislocation logic
		if dmg > 0.8 then
			org.painadd = org.painadd + 30
			org.immobilization = org.immobilization + 15
			org[key.."gruesome_dislocation"] = true
			
			if org.isPly then
				org.owner:EmitSound("disloc"..math.random(1,2)..".ogg", 75, 100, 1, CHAN_AUTO) -- Fallback handled if missing
			end
		end

		timer.Simple(0, function() hg.LightStunPlayer(org.owner,2) end)
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
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


		if org.isPly and org[key.."amputated"] then
			org.owner:Notify(dismember_arm[math.random(#dismember_arm)], true, "dismember_"..key, 3)
		end

		--if org.isPly and !org[key.."amputated"] then org.owner:Notify(broke_arm[math.random(#broke_arm)], 1, "broke"..key, 1, nil, nil) end

		-- Gruesome fracture logic
		if dmg > 1.5 or (oldDmg > 0.8 and dmg > 0.5) then
			org.painadd = org.painadd + 40
			org[key.."gruesome"] = true
			
			if org.isPly then
				org.owner:EmitSound("owfuck"..math.random(1,4)..".ogg", 75, 100, 1, CHAN_AUTO)
			end
		end

		--timer.Simple(0, function() hg.LightStunPlayer(org.owner,1) end)
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
		//broken
	else
		org[key.."dislocation"] = true
		//org[key] = 0.5

		org.painadd = org.painadd + 35
		org.owner:AddNaturalAdrenaline(0.5)
		org.fearadd = org.fearadd + 0.5

		--if org.isPly and !org[key.."amputated"] then org.owner:Notify(dislocated_arm[math.random(#dislocated_arm)], 1, "dislocated"..key, 1, nil, nil) end

		-- Gruesome dislocation logic
		if dmg > 0.8 then
			org.painadd = org.painadd + 30
			org[key.."gruesome_dislocation"] = true
			
			if org.isPly then
				org.owner:EmitSound("disloc"..math.random(1,2)..".ogg", 75, 100, 1, CHAN_AUTO)
			end
		end

		--timer.Simple(0, function() hg.LightStunPlayer(org.owner,1) end)
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
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

	local name = "spine" .. number
	local name2 = "fake_spine" .. number
	if org[name] >= hg.organism[name2] then return 0 end
	local oldDmg = org[name]

	local result, vecrand = damageBone(org, 0.1, isCrush(dmgInfo) and dmg * 2 or dmg * 2, dmgInfo, name, boneindex, dir, hit, ricochet)
	
	hg.AddHarmToAttacker(dmgInfo, (org[name] - oldDmg) * 5, "Spine bone damage harm")
	
	if (name == "spine3" || name == "spine2") then
		hg.AddHarmToAttacker(dmgInfo, (org[name] - oldDmg) * 8, "Broken spine harm")
	end

	if org[name] >= hg.organism[name2] and org.isPly then
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
		org.owner:Notify(huyasd[name], true, name, 2)
		org.painadd = org.painadd + 25
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

hook.Add("PlayerDisconnected", "CleanupTinnitusSounds", function(ply)
	if IsValid(ply) then
		local timerName = "TinnitusCheck_" .. ply:SteamID64()
		local disorientTimerName = "TinnitusDisorient_" .. ply:SteamID64()
		timer.Remove(timerName)
		timer.Remove(disorientTimerName)
		if ply.organism then
			ply.organism.tinnitusLongPlaying = false
		end
	end
end)

hook.Add("PlayerDeath", "CleanupTinnitusOnDeath", function(ply)
	if IsValid(ply) then
		local timerName = "TinnitusCheck_" .. ply:SteamID64()
		local disorientTimerName = "TinnitusDisorient_" .. ply:SteamID64()
		timer.Remove(timerName)
		timer.Remove(disorientTimerName)
		if ply.organism then
			ply.organism.tinnitusLongPlaying = false
		end
	end
end)

local function shouldTriggerTinnitus(dmgInfo, damage)
	if damage < 0.1 then 
		return false 
	end
	
	local chance = 30
	local damageType = "OTHER"
	if dmgInfo:IsDamageType(DMG_CLUB) then
		chance = 50 
		damageType = "CLUB"
	elseif dmgInfo:IsDamageType(DMG_SLASH) then
		chance = 20 
		damageType = "SLASH"
	end
	
	-- Roll for chance
	local roll = math.random(100)
	local success = roll <= chance
	
	return success
end

local function manageTinnitusSound(org, targetPlayer)
	if not IsValid(targetPlayer) or not targetPlayer:IsPlayer() then return end
	

	
	local skullDmg = org.skull
	
	if skullDmg >= 0.6 then

		if not org.tinnitusActive or (skullDmg >= 0.8 and not org.severeTinnitusActive) then
			org.tinnitusActive = true
			org.severeTinnitusActive = (skullDmg >= 0.8)
			
			local soundFile = org.severeTinnitusActive and "tinnituslong.wav" or "tinnitus.wav"
			local duration = org.severeTinnitusActive and 15.0 or 5.0
			
			targetPlayer:PlayCustomTinnitus(soundFile)
			
			local timerName = "TinnitusClear_" .. targetPlayer:SteamID64()
			timer.Create(timerName, duration, 1, function()
				if IsValid(targetPlayer) and targetPlayer.organism then
					targetPlayer.organism.tinnitusActive = false
					targetPlayer.organism.severeTinnitusActive = false
				end
			end)
			

			local disorientTimerName = "TinnitusDisorient_" .. targetPlayer:SteamID64()
			local disorientIntensity = org.severeTinnitusActive and 0.05 or 0.02
			
			timer.Create(disorientTimerName, 0.1, duration * 10, function()
				if IsValid(targetPlayer) and targetPlayer.organism then

					targetPlayer.organism.disorientation = math.min(targetPlayer.organism.disorientation + disorientIntensity, 1.5)
				else
					timer.Remove(disorientTimerName)
				end
			end)
		end
	end
end

local input_list = hg.organism.input_list
input_list.jaw = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet)
    local oldDmg = org.jaw
    local isBullet = dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT)

	local result, vecrand = damageBone(org, 0.25, dmg, dmgInfo, "jaw", boneindex, dir, hit, ricochet)

	hg.AddHarmToAttacker(dmgInfo, (org.jaw - oldDmg) * 3, "Jaw bone damage harm")

	if org.jaw == 1 and (org.jaw - oldDmg) > 0 and org.isPly then org.owner:Notify(jaw_broken_msg[math.random(#jaw_broken_msg)], true, "jaw", 2) end

	local dislocated = (org.jaw - oldDmg) > math.Rand(0.1, 0.3)

    if org.jaw == 1 then

        org.shock = org.shock + (isBullet and dmg * 20 or dmg * 40)
        org.avgpain = org.avgpain + dmg * 30

		if oldDmg != 1 then org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO) end
	end

    org.shock = org.shock + (isBullet and dmg * 2 or dmg * 3)

    if dislocated then

        org.shock = org.shock + (isBullet and dmg * 12 or dmg * 20)
        org.avgpain = org.avgpain + dmg * 20
		
    if !org.jawdislocation then
			org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
		end

        org.jawdislocation = true
    
        if org.isPly then org.owner:Notify(jaw_dislocated_msg[math.random(#jaw_dislocated_msg)], true, "jaw", 2) end
	end


	if (org.jaw - oldDmg) > 0.15 then
		local disorientationAdd = dmg * 0.5
		org.disorientation = math.min(org.disorientation + disorientationAdd, 1.5)
		

		if org.isPly and disorientationAdd > 0.1 and shouldTriggerTinnitus(dmgInfo, dmg) then

			local targetPlayer = org.owner
			if IsValid(org.owner.FakeRagdoll) then

				local ragdoll = org.owner.FakeRagdoll
				if IsValid(ragdoll.ply) then
					targetPlayer = ragdoll.ply
				end
			end
			
			if IsValid(targetPlayer) and targetPlayer:IsPlayer() then

				targetPlayer:PlayCustomTinnitus("tinnitus.wav")
			end
		end
	end

	if org.isPly then
		local targetPlayer = org.owner
		if IsValid(org.owner.FakeRagdoll) then
			local ragdoll = org.owner.FakeRagdoll
			if IsValid(ragdoll.ply) then
				targetPlayer = ragdoll.ply
			end
		end
		if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
			local skullDelta = math.max(org.jaw - oldDmg, 0)
			if dmg < 0.35 or skullDelta <= 0.15 then return result, vecrand end
			local flashTime = math.Clamp(0.25 + skullDelta * 0.8, 0.25, 1.0)
			local eyePos = targetPlayer:EyePos()
			local ang = targetPlayer:EyeAngles()
			local incomingPos = dmgInfo:GetDamagePosition()
			local incDir = (incomingPos - eyePos):GetNormalized()
			local dotRight = ang:Right():Dot(incDir)
            local offset = ang:Right() * (dotRight * 160)
			local worldPos = eyePos + offset + ang:Forward() * 16
			local flashSize = math.Clamp(1400 + skullDelta * 1400, 1200, 2800)

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

	if dmg > 0.2 then
		if org.isPly then timer.Simple(0, function() hg.LightStunPlayer(org.owner,1 + dmg) end) end
	end

	return result,vecrand
end

hook.Add("CanListenOthers", "CantHaveShitInDetroit", function(output, input, isChat, teamonly, text)
	if IsValid(output) and (output.organism.jaw == 1 or output.organism.jawdislocation) and output:Alive() and (output:IsSpeaking() or isChat) then
		-- and !isChat and output:IsSpeaking()
		output.organism.painadd = output.organism.painadd + 2 * (output:IsSpeaking() and 1 or (isChat and 5 or 0))
		output:Notify("My jaw is really hurting when I speak.", 60, "painfromjawspeak", 0, nil, Color(255, 210, 210))
	end
end)

input_list.skull = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet)
	if dmgInfo:IsDamageType(DMG_BURN) or dmgInfo:IsDamageType(DMG_SLOWBURN) then return 0 end
    local oldDmg = org.skull
    local isBullet = dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT)
    local isSlash = dmgInfo:IsDamageType(DMG_SLASH)

    if isSlash then
        dmg = dmg * 0.6
    end

    local boneMul = isSlash and 0.35 or 0.25
    local result, vecrand = damageBone(org, boneMul, dmg, dmgInfo, "skull", boneindex, dir, hit, ricochet)

	hg.AddHarmToAttacker(dmgInfo, (org.skull - oldDmg) * 4, "Skull bone damage harm")

    if org.skull == 1 then
        -- bullet: softer shock on fully broken skull
        org.shock = org.shock + (isBullet and dmg * 20 or dmg * 40)
        org.avgpain = org.avgpain + dmg * 30

		if oldDmg != 1 then 
			org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)

			org.owner:EmitSound("flesh"..math.random(10)..".wav", 75, math.random(95, 120), 1, CHAN_AUTO)

			org.owner:EmitSound("gore/skullopen"..math.random(1, 3)..".wav", 75, math.random(95, 110), 1, CHAN_AUTO, 0, 0, 175)
		end
	end

    org.shock = org.shock + (isBullet and dmg * 2 or dmg * 3)

    if isSlash then
        dmgInfo:ScaleDamage(0.85) -- extra reduction vs slashes
    end

	org.brain = math.min(org.brain + (math.random(10) == 1 and dmg * 0.05 or 0), 1)
	
	if (org.skull - oldDmg) > 0.6 then
		org.brain = math.min(org.brain + 0.1, 1)
	end

	if dmg > 0.4 then
		if org.isPly then
			timer.Simple(0, function()
				hg.LightStunPlayer(org.owner,1 + dmg)
			end)
		end
	end
	
    org.shock = org.shock + (isBullet and (dmg > 1 and 35 or dmg * 6) or (dmg > 1 and 50 or dmg * 10))

	if org.skull == 1 then
		if org.isPly then
			org.owner:Notify(huyasd["skull"],true,"skull",4)
		end

		if dir then
			net.Start("hg_bloodimpact")
			net.WriteVector(dmgInfo:GetDamagePosition())
			net.WriteVector(dir / 10)
			net.WriteFloat(3)
			net.WriteInt(1,8)
			net.Broadcast()


			org.owner:EmitSound("flesh"..math.random(10)..".wav", 75, math.random(95, 120), 1, CHAN_AUTO)
		end
	end


    if (org.skull - oldDmg) > 0.08 then 

        local disorientationAdd = math.min(dmg * 1.2, 1.5)
        org.disorientation = math.min(org.disorientation + disorientationAdd, 1.5)


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


                if dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_SLASH) or dmgInfo:IsDamageType(DMG_CRUSH) then
                    local eyePos = tp:EyePos()
                    local ang = tp:EyeAngles()
                    local incomingPos = dmgInfo:GetDamagePosition()
                    local incDir = (incomingPos - eyePos):GetNormalized()
                    local dotRight = ang:Right():Dot(incDir)

                    local offset = ang:Right() * (dotRight * 160)
                    local worldPos = eyePos + offset + ang:Forward() * 16

                    tp.HeadDisorientFlashCooldown = tp.HeadDisorientFlashCooldown or 0
                    if tp.HeadDisorientFlashCooldown < CurTime() then
                        net.Start("headtrauma_flash")
                            net.WriteVector(worldPos)
                            net.WriteFloat(baseFlashTime)
                            net.WriteInt(baseFlashSize, 20)
                        net.Send(tp)

                        tp:PlayCustomTinnitus("headhit.mp3")
                        tp.HeadDisorientFlashCooldown = CurTime() + 0.2
                    end
                end

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

                        tp:PlayCustomTinnitus("headhit.mp3")
                        tp.HeadDisorientFlashCooldown = CurTime() + 0.2
                    end
                end
            end
        end
		

		if org.isPly and disorientationAdd > 0.05 and shouldTriggerTinnitus(dmgInfo, dmg) then

			local targetPlayer = org.owner
			if IsValid(org.owner.FakeRagdoll) then

				local ragdoll = org.owner.FakeRagdoll
				if IsValid(ragdoll.ply) then
					targetPlayer = ragdoll.ply
				end
			end
			
			if IsValid(targetPlayer) and targetPlayer:IsPlayer() then

				targetPlayer:PlayCustomTinnitus("tinnitus.wav")
				

				manageTinnitusSound(org, targetPlayer)
			end
		end
	elseif org.isPly then

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


    local eyeChance = 0
    if dmgInfo:IsDamageType(DMG_SLASH) then
        eyeChance = 30 
    elseif dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT) then
        eyeChance = 20
    elseif dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_GENERIC) or dmgInfo:IsDamageType(DMG_CRUSH) then
        eyeChance = 8
    end

    if eyeChance > 0 and math.random(100) <= eyeChance then
        local which = (math.random(2) == 1) and "eyeL" or "eyeR"
        local eyeFunc = hg.organism.input_list[which]
        if eyeFunc then eyeFunc(org, 1, dmg, dmgInfo) end
    end

	return result,vecrand
end

local ribs = {
	"I THINK I BROKE A RIB",
	"MY CHEST IS PAINING",
	"ONE OF MY RIBS BROKE",
	"FUCK- MY CHEST SNAPPED",
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
		org.owner:Notify("MY PELVIS HURTS A LOT.", true, "pelvis", 4)
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