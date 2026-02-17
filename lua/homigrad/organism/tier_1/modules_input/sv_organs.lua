include("homigrad/organism/tier_1/modules/sv_blood.lua")
--local Organism = hg.organism
if SERVER then
    util.AddNetworkString("hg_play_client_sound")
    util.AddNetworkString("blood particle explode")
    CreateConVar("hg_isshitworking", "0", FCVAR_SERVER_CAN_EXECUTE, "Debug biological events", 0, 1)
end

local function isCrush(dmgInfo)
	return not dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH + DMG_BLAST)
end

local function damageOrgan(org, dmg, dmgInfo, key)
	if not org or not org[key] then return 0 end
	local prot = math.max(0.3 - org[key],0)
	local oldval = org[key]
	org[key] = math.Round(math.min(org[key] + dmg * (isCrush(dmgInfo) and 1 or 3), 1), 3)
	
	//local damage = org[key] - oldval
	//dmgInfo:SetDamage(dmgInfo:GetDamage() + (damage * 5))

	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 0 or prot
end

local input_list = hg.organism.input_list
input_list.heart = function(org, bone, dmg, dmgInfo)
	if not org or not org.heart then return 0 end
	local oldDmg = org.heart

	local result = damageOrgan(org, dmg * 0.3, dmgInfo, "heart")

	hg.AddHarmToAttacker(dmgInfo, (org.heart - oldDmg) * 10, "Heart damage harm")
	
	org.shock = org.shock + dmg * 20
	org.internalBleed = org.internalBleed + (org.heart - oldDmg) * 10

	return result
end

input_list.liver = function(org, bone, dmg, dmgInfo)
	if not org or not org.liver then return 0 end
	local oldDmg = org.liver
	local prot = math.max(0.3 - org.liver,0)
	
	hg.AddHarmToAttacker(dmgInfo, (org.liver - oldDmg) * 3, "Liver damage harm")
	
	org.shock = org.shock + dmg * 20
	org.painadd = org.painadd + dmg * 50
	
	org.liver = math.min(org.liver + dmg, 1)
	local harmed = (org.liver - oldDmg)
	if org.analgesia < 0.4 and harmed >= 0.2 then
		if harmed > 0 then -- wtf? whatever
			hg.StunPlayer(org.owner,2)
		else
			hg.LightStunPlayer(org.owner,2)
		end
	end

	org.internalBleed = org.internalBleed + harmed * 10
	
	dmgInfo:ScaleDamage(0.8)

	return 0
end

input_list.stomach = function(org, bone, dmg, dmgInfo)
	if not org or not org.stomach then return 0 end
	local oldDmg = org.stomach

	local result = damageOrgan(org, dmg, dmgInfo, "stomach")

	hg.AddHarmToAttacker(dmgInfo, (org.stomach - oldDmg) * 2, "Stomach damage harm")
    
    org.painadd = org.painadd + dmg * 50
	
	org.internalBleed = org.internalBleed + (org.stomach - oldDmg) * 12

	if (org.stomach - oldDmg) > 0.3 and math.random(3) == 1 then
		hg.organism.CoughUpBlood(org)
	end

	return result
end

input_list.intestines = function(org, bone, dmg, dmgInfo)
	if not org or not org.intestines then return 0 end
	local oldDmg = org.intestines

	local result = damageOrgan(org, dmg, dmgInfo, "intestines")

	hg.AddHarmToAttacker(dmgInfo, (org.intestines - oldDmg) * 2, "Intestines damage harm")
    
    org.painadd = org.painadd + dmg * 50

	org.internalBleed = org.internalBleed + (org.intestines - oldDmg) * 12

	if (org.intestines - oldDmg) > 0.3 and math.random(3) == 1 then
		hg.organism.CoughUpBlood(org)
	end
	if org.isPly and not org.disemboweled then
		local severeDamage = dmg > 0.8
		local isSlash = dmgInfo:IsDamageType(DMG_SLASH)
		local isBullet = dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT)
		
		if severeDamage and (isSlash or isBullet) then
			local chance = isSlash and 70 or 30
			if math.random(100) <= chance then
				org.disemboweled = true
				hg.AttachStomachGore(org.owner)
				
				-- Increased bleeding
				org.bleed = org.bleed + 5
				org.internalBleed = org.internalBleed + 5

				-- Stamina drain
				org.stamina[1] = 0

				-- Chance to drop weapon
				if math.random(3) == 1 and IsValid(org.owner:GetActiveWeapon()) then
					org.owner:DropWeapon(org.owner:GetActiveWeapon())
				end

				local gut_msg = {
					"OH GOD- MY GUTS!",
					"IT'S SPILLING OUT! MY INSIDES ARE SPILLING OUT!",
					"FUCK! I CAN SEE MY INTESTINES!",
					"HELP! I'M DISEMBOWELED!",
					"MY STOMACH IS OPEN! GOD HELP ME!"
				}
				org.owner:Notify(gut_msg[math.random(#gut_msg)], true, "disembowel", 3)
				end
		end
	end
	
	return result
end

if SERVER then
    util.AddNetworkString("hg_head_trauma_saturation")
end

input_list.brain = function(org, bone, dmg, dmgInfo)
	if not org or not org.brain then return 0 end
	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 50 end
	local oldDmg = org.brain
	local result = damageOrgan(org, dmg * 1, dmgInfo, "brain")

	hg.AddHarmToAttacker(dmgInfo, (org.brain - oldDmg) * 15, "Brain damage harm")

	if dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) then
		ParticleEffect( "headshot", dmgInfo:GetDamagePosition(), dmgInfo:GetDamageForce():GetNormalized():Angle() )
	end
-- i wonder what this does
	if org.brain >= 0.01 and (org.brain - oldDmg) > 0.01 and math.random(3) == 1 then
		hg.applyFencingToPlayer(org.owner, org)
		org.shock = 70

		timer.Simple(0.1, function()
			local rag = hg.GetCurrentCharacter(org.owner)

			if rag:IsRagdoll() then
				local stype = hg.getRandomSpasm()
				hg.applySpasm(rag, stype)
				if rag.organism then rag.organism.spasm, rag.organism.spasmType = true, stype end
			end
		end)
	end

	if dmg > 0.1 then
        -- ooo blyat
		org.consciousness = math.Approach(org.consciousness, 0, dmg * 3)
		org.disorientation = org.disorientation + dmg * 1
		org.shock = org.shock + dmg * 3
        
        if org.isPly then
            local intensity = math.min((org.brain - oldDmg) * 5, 2.0)
            if org.otrub then
                org.saturationFlashOnWake = true
                org.saturationFlashIntensity = intensity
            else
                if GetConVar("hg_isshitworking"):GetBool() then PrintMessage(HUD_PRINTTALK, "Saturation Flash Triggered (Brain Damage)") end
                net.Start("hg_head_trauma_saturation")
                net.WriteFloat(intensity)
                net.Send(org.owner)
            end
        end
	else
        org.consciousness = math.Approach(org.consciousness, 0, dmg * 3)
        org.disorientation = org.disorientation + dmg * 1
        org.shock = org.shock + dmg * 3
    end
	
	org.painadd = org.painadd + dmg * 10
	
	if dmg > 0.01 and org.isPly then
		local tp = org.owner
		if IsValid(tp) and tp:IsPlayer() then
			local flashTime = math.Clamp(0.2 + dmg * 0.5, 0.2, 0.8)
			local flashSize = math.Clamp(1000 + dmg * 1000, 1000, 2000)
			local eyePos = tp:EyePos()
			local ang = tp:EyeAngles()
			local worldPos = eyePos + ang:Forward() * 16
			
			tp.HeadDisorientFlashCooldown = tp.HeadDisorientFlashCooldown or 0
			if tp.HeadDisorientFlashCooldown < CurTime() then
				net.Start("headtrauma_flash")
					net.WriteVector(worldPos)
					net.WriteFloat(flashTime)
					net.WriteInt(flashSize, 20)
				net.Send(tp)
				
				net.Start("hg_play_client_sound")
				net.WriteString("concussion"..math.random(1,4)..".mp3")
				net.Send(tp)
				
				tp.HeadDisorientFlashCooldown = CurTime() + 0.2
			end
		end
	end
	
	return result
end

local angZero = Angle(0, 0, 0)
local vecZero = Vector(0, 0, 0)
local function getlocalshit(ent, bone, dmgInfo, dir, hit)
	if IsValid(ent) and bone then
		local ent = IsValid(ent.FakeRagdoll) and ent.FakeRagdoll or ent
		local bonePos, boneAng = ent:GetBonePosition(bone)
		local dmgPos = not isbool(hit) and hit or bonePos
		
		local localPos, localAng = WorldToLocal(dmgPos, angZero, bonePos, boneAng)
		local _, dir2 = WorldToLocal(vecZero, dir:Angle(), vecZero, boneAng)
		dir2 = dir2:Forward()
		return localPos, localAng, dir2
	end
end

local arterySize = {
	["arteria"] = 14,
	["rarmartery"] = 6,
	["larmartery"] = 6,
	["rlegartery"] = 9,
	["llegartery"] = 9,
	["spineartery"] = 10,
}

local arteryMessages ={
	"I can feel blood rushing from my neck...",
	"My neck.. it's... pumping out blood.",
	"I'm bleeding out of my neck!"
}

local function hitArtery(artery, org, dmg, dmgInfo, boneindex, dir, hit)
	if not org or not org[artery] then return 0 end
	if isCrush(dmgInfo) then return 1 end
	if dmgInfo:IsDamageType(DMG_BLAST) then return 1 end
	if dmgInfo:IsDamageType(DMG_SLASH) and (math.random(5) != 1) and dmg < 2 then return end
	org.painadd = org.painadd + dmg * 1
	if org[artery] == 1 then return 0 end
	if org[string.Replace(artery, "artery", "").."amputated"] then return end

	if artery ~= "arteria" then
		hg.AddHarmToAttacker(dmgInfo, 4, "Random artery punctured harm")//((1 - org[artery]) - math.max((1 - org[artery]) - dmg,0)) / 4
	else
		if org.isPly and not org.otrub then
			org.owner:Notify(table.Random(arteryMessages), true, "arteria", 0)
		end
		
		hg.AddHarmToAttacker(dmgInfo, 15, "Carotid artery punctured harm")
	end

	org[artery] = math.min(org[artery] + 1, 1)

	local owner = org.owner
	local bonea = owner:LookupBone(boneindex)
	local localPos, localAng, dir2 = getlocalshit(owner, bonea, dmgInfo, dir, hit)
	table.insert(org.arterialwounds, {arterySize[artery], localPos, localAng, boneindex, CurTime(), dir2 * 100, artery})
	owner:SetNetVar("arterialwounds", org.arterialwounds)
	--if IsValid(owner:GetNWEntity("RagdollDeath")) then owner:GetNWEntity("RagdollDeath"):SetNetVar("wounds",org.arterialwounds) end
	return 0
end

input_list.arteria = function(org, bone, dmg, dmgInfo, boneindex, dir, hit)
	return hitArtery("arteria", org, dmg, dmgInfo, "ValveBiped.Bip01_Neck1", dir, hit)
end

input_list.rarmartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("rarmartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.larmartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("larmartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.rlegartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("rlegartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.llegartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("llegartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.spineartery = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitArtery("spineartery", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.lungsL = function(org, bone, dmg, dmgInfo)
	if not org or not org.lungsL then return 0 end
	local prot = math.max(0.3 - org.lungsL[1],0)
	local oldval = org.lungsL[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung left damage harm")

	org.lungsL[1] = math.min(org.lungsL[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsL[2] = math.min(org.lungsL[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsL[1] - oldval) * 2
	
	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 1 or prot
end

input_list.lungsR = function(org, bone, dmg, dmgInfo)
	if not org or not org.lungsR then return 0 end
	local oldval = org.lungsR[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung right damage harm")

	org.lungsR[1] = math.min(org.lungsR[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsR[2] = math.min(org.lungsR[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsR[1] - oldval) * 2

	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 1 or prot
end
--im so funny fr fr
input_list.trachea = function(org, bone, dmg, dmgInfo)
	if not org or not org.trachea then return 0 end
	local oldDmg = org.trachea

	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 5 end

	local result = damageOrgan(org, dmg * 2, dmgInfo, "trachea")

	hg.AddHarmToAttacker(dmgInfo, (org.trachea - oldDmg) * 8, "Trachea damage harm")

    org.internalBleed = org.internalBleed + dmg * 2

	return result
end

input_list.eyeL = function(org, bone, dmg, dmgInfo)
	if not org or not org.eyeL then return 0 end
	local oldDmg = org.eyeL or 0
	local result = damageOrgan(org, dmg * 3, dmgInfo, "eyeL") -- HIGHLY vulnerable

	hg.AddHarmToAttacker(dmgInfo, math.max(org.eyeL - oldDmg, 0) * 10, "Left eye damage harm")

	if hg.organism.enhancedPain then
		hg.organism.enhancedPain.applyPain(org, dmg * 50, dmgInfo, "eyeL", false)
	else
		org.painadd = org.painadd + dmg * 50
	end
	org.shock = org.shock + dmg * 15
	org.disorientation = org.disorientation + dmg * 4

	-- bleed from any damaging hit type
	org.bleed = org.bleed + dmg * 1.5

	org.pulse = math.min(org.pulse + dmg * 10, 180)

	-- eye popped: play short-range cue
	if oldDmg < 1 and org.eyeL >= 1 then
		if GetConVar("hg_isshitworking"):GetBool() then PrintMessage(HUD_PRINTTALK, "Left Eye Destroyed") end
		if IsValid(org.owner) then
			net.Start("hg_play_client_sound")
			net.WriteString("cuteye.ogg")
			net.Send(org.owner)

			org.owner:EmitSound("eyegone.mp3")
            
            -- Red flash
            net.Start("AddFlash")
            net.WriteVector(org.owner:EyePos())
            net.WriteFloat(0.5)
            net.WriteInt(50, 20)
            net.WriteColor(Color(255, 0, 0))
            net.WriteString("sprites/light_glow02_add")
            net.Send(org.owner)

			org.bleed = org.bleed + 1
		end
	elseif org.eyeL > 0.1 then
		-- Slight disorientation for eye damage
		org.disorientation = math.min(org.disorientation + dmg * 1, 1.0)
	end

	return result
end

input_list.eyeR = function(org, bone, dmg, dmgInfo)
	if not org or not org.eyeR then return 0 end
	local oldDmg = org.eyeR or 0
	local result = damageOrgan(org, dmg * 3, dmgInfo, "eyeR") -- HIGHLY vulnerable

	hg.AddHarmToAttacker(dmgInfo, math.max(org.eyeR - oldDmg, 0) * 10, "Right eye damage harm")

	if hg.organism.enhancedPain then
		hg.organism.enhancedPain.applyPain(org, dmg * 50, dmgInfo, "eyeR", false)
	else
		org.painadd = org.painadd + dmg * 50
	end
	org.shock = org.shock + dmg * 15
	org.disorientation = org.disorientation + dmg * 4

	-- bleed from any damaging hit type
	org.bleed = org.bleed + dmg * 1.5

	org.pulse = math.min(org.pulse + dmg * 10, 180)

	-- eye popped: play short-range cue
	if oldDmg < 1 and org.eyeR >= 1 then
		if GetConVar("hg_isshitworking"):GetBool() then PrintMessage(HUD_PRINTTALK, "Right Eye Destroyed") end
		if IsValid(org.owner) then
			net.Start("hg_play_client_sound")
			net.WriteString("cuteye.ogg")
			net.Send(org.owner)

			org.owner:EmitSound("eyegone.mp3")
            
            -- Red flash
            net.Start("AddFlash")
            net.WriteVector(org.owner:EyePos())
            net.WriteFloat(0.5)
            net.WriteInt(50, 20)
            net.WriteColor(Color(255, 0, 0))
            net.WriteString("sprites/light_glow02_add")
            net.Send(org.owner)

			org.bleed = org.bleed + 1
		end
	elseif org.eyeR > 0.1 then
		-- Slight disorientation for eye damage
		org.disorientation = math.min(org.disorientation + dmg * 1, 1.0)
	end

	return result
end

input_list.nose = function(org, bone, dmg, dmgInfo)
	if not org or not org.nose then return 0 end
	local oldDmg = org.nose or 0
	local result = damageOrgan(org, dmg * 4, dmgInfo, "nose") -- nose is extremely sensitive

	-- Nose breakage threshold
	if oldDmg < 0.5 and org.nose >= 0.5 then
		if GetConVar("hg_isshitworking"):GetBool() then PrintMessage(HUD_PRINTTALK, "Nose Broken") end
		if IsValid(org.owner) then
			-- blyat
			local broken_nose_msg = {
				"My nose feels split in two.",
				"Fuck... I think my nose is broken.",
				"I smell a lot of copper..."
			}
			org.owner:Notify(broken_nose_msg[math.random(#broken_nose_msg)], true, "nose_broken", 2)
			org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
            
            -- Red flash
            net.Start("AddFlash")
            net.WriteVector(org.owner:EyePos())
            net.WriteFloat(0.5)
            net.WriteInt(50, 20)
            net.WriteColor(Color(255, 0, 0))
            net.WriteString("sprites/light_glow02_add")
            net.Send(org.owner)
			
			org.bleed = org.bleed + 1

			-- Pain increase
			if hg.organism.enhancedPain then
				hg.organism.enhancedPain.applyPain(org, 35, dmgInfo, "nose", false)
			else
				org.painadd = org.painadd + 35
			end
			
			-- Disorientation (similar to eye damage)
			org.disorientation = math.min(org.disorientation + 0.8, 1.2)
			
			-- Bleeding effect
			org.bleed = org.bleed + 1.0
		end
	end
	
	if org.nose > 0.1 then
		org.painadd = org.painadd + dmg * 8
	end

	return result
end

-- input_list.rarmup = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet) return arms(org, bone * 1.25, dmg, dmgInfo, "rarm", boneindex, dir, hit, ricochet) end
-- Note: 'arms' function is undefined in this file scope. This definition is redundant or incorrect here.
