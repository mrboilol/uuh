--local Organism = hg.organism
local function isCrush(dmgInfo)
	return not dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT + DMG_SLASH + DMG_BLAST)
end

local function damageOrgan(org, dmg, dmgInfo, key)
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
	local oldDmg = org.heart

	local result = damageOrgan(org, dmg * 0.3, dmgInfo, "heart")

	hg.AddHarmToAttacker(dmgInfo, (org.heart - oldDmg) * 10, "Heart damage harm")
	
	org.shock = org.shock + dmg * 20
	org.internalBleed = org.internalBleed + (org.heart - oldDmg) * 10
	org.bleed = (org.bleed or 0) + (org.heart - oldDmg) * 0.2

	local staminaLoss = dmg * 3.0
	org.stamina[1] = math.max(org.stamina[1] - staminaLoss, 0)

	return result
end

input_list.liver = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.liver
	local prot = math.max(0.3 - org.liver,0)
	
	hg.AddHarmToAttacker(dmgInfo, (org.liver - oldDmg) * 3, "Liver damage harm")
	
	org.shock = org.shock + dmg * 20
	org.painadd = org.painadd + dmg * 35
	
	org.liver = math.min(org.liver + dmg, 1)
	local harmed = (org.liver - oldDmg)
	if org.analgesia < 0.4 and harmed >= 0.2 then
		timer.Simple(0, function()
			if harmed > 0 then -- wtf? whatever
				hg.StunPlayer(org.owner,2)
			else
				hg.LightStunPlayer(org.owner,2)
			end
		end)
	end

	org.internalBleed = org.internalBleed + harmed * 4
	org.bleed = (org.bleed or 0) + harmed * 0.1
	
	if isCrush(dmgInfo) or dmgInfo:IsDamageType(DMG_CLUB) then
		local staminaLoss = dmg * 1.5
		org.stamina[1] = math.max(org.stamina[1] - staminaLoss, 0)
	end

	dmgInfo:ScaleDamage(0.8)

	return 0
end

input_list.stomach = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.stomach

	local result = damageOrgan(org, dmg, dmgInfo, "stomach")

	hg.AddHarmToAttacker(dmgInfo, (org.stomach - oldDmg) * 2, "Stomach damage harm")
	
	org.internalBleed = org.internalBleed + (org.stomach - oldDmg) * 2
	org.bleed = (org.bleed or 0) + (org.stomach - oldDmg) * 0.1

	if isCrush(dmgInfo) or dmgInfo:IsDamageType(DMG_CLUB) then
		local staminaLoss = dmg * 1.5
		org.stamina[1] = math.max(org.stamina[1] - staminaLoss, 0)
	end

	return result
end

input_list.intestines = function(org, bone, dmg, dmgInfo)
	local oldDmg = org.intestines

	local result = damageOrgan(org, dmg, dmgInfo, "intestines")

	hg.AddHarmToAttacker(dmgInfo, (org.intestines - oldDmg) * 2, "Intestines damage harm")

	org.internalBleed = org.internalBleed + (org.intestines - oldDmg) * 2
	org.bleed = (org.bleed or 0) + (org.intestines - oldDmg) * 0.1

	if isCrush(dmgInfo) or dmgInfo:IsDamageType(DMG_CLUB) then
		local staminaLoss = dmg * 1.5
		org.stamina[1] = math.max(org.stamina[1] - staminaLoss, 0)
	end

	return result
end

input_list.brain = function(org, bone, dmg, dmgInfo)
	if dmgInfo:IsDamageType(DMG_BLAST) then 
		dmg = dmg / 50
		damageOrgan(org, dmg * 1.5, dmgInfo, "lefteye")
		damageOrgan(org, dmg * 1.5, dmgInfo, "righteye")
	end
	local oldDmg = org.brain
	local result = damageOrgan(org, dmg * 1, dmgInfo, "brain")

	hg.AddHarmToAttacker(dmgInfo, (org.brain - oldDmg) * 15, "Brain damage harm")

	if dmgInfo:IsDamageType(DMG_BULLET + DMG_BUCKSHOT) then
		local dmgPos = dmgInfo:GetDamagePosition()
		local dirCool = dmgInfo:GetDamageForce():GetNormalized()

		local effdata = EffectData()
		effdata:SetOrigin(dmgPos)
		effdata:SetRadius(dmg / 10)
		effdata:SetMagnitude(dmg / 10)
		effdata:SetScale(1)
		util.Effect("BloodImpact",effdata)

		local ent = hg.GetCurrentCharacter(org.owner)
		
		if !ent.organism.SpawnedBrainChunks and math.random(5) == 1 then
			SpawnMeatGore(ent, dmgPos + dirCool * 5, 3, dirCool * 1000, 0.4)
			ent.organism.SpawnedBrainChunks = true
		end
	end

	if org.brain >= 0.01 and (org.brain - oldDmg) > 0.01 and math.random(3) == 1 then
		--hg.applyFencingToPlayer(org.owner, org)
		org.shock = 70

		timer.Simple(0.1, function()
			local rag = hg.GetCurrentCharacter(org.owner)

			if IsValid(rag) and rag:IsRagdoll() then
				hg.applyFencingToPlayer(org.owner, org) -- looks more appealing anyways
				--local stype = "rigor"--hg.getRandomSpasm()
				--hg.applySpasm(rag, stype)
				--if rag.organism then rag.organism.spasm, rag.organism.spasmType = true, stype end
			end
		end)
	end

	org.shock = org.shock + dmg * 3
	org.painadd = org.painadd + dmg * 10

	if org.isPly then
		local targetPlayer = org.owner
		if IsValid(org.owner.FakeRagdoll) then
			local ragdoll = org.owner.FakeRagdoll
			if IsValid(ragdoll.ply) then
				targetPlayer = ragdoll.ply
			end
		end

        if IsValid(targetPlayer) and targetPlayer:IsPlayer() then
            local brainDelta = org.brain - oldDmg
            if brainDelta > 0.01 then -- Only if there is some damage
                if brainDelta <= 0.1 then
                    hg.organism.headTraumaFlash(targetPlayer, dmgInfo, nil, oldDmg, org.brain)
                else
                    -- Major brain damage: Concussion
                    if hg.organism.ApplyConcussion then
                        hg.organism.ApplyConcussion(org, brainDelta, targetPlayer)
                    end
                end
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
	["arteria"] = 18,
	["rarmartery"] = 8,
	["larmartery"] = 8,
	["rlegartery"] = 12,
	["llegartery"] = 12,
	["spineartery"] = 14,
}

local veinSize = {
	["vein"] = 12,
	["rarmvein"] = 4,
	["larmvein"] = 4,
	["rlegvein"] = 6,
	["llegvein"] = 6,
	["spinevein"] = 8,
}

local arteryMessages ={
	"Oh god- OH GOD IM BLEEDING FROM MY NECK",
	"MY NECK IS BLEEDING- ITS BLEEDING SO MUCH",
	"NO NO NO NO, MY NECK- MY NECK IS BLEEDING SO MUCH"
}

local function hitArtery(artery, org, dmg, dmgInfo, boneindex, dir, hit)
	if isCrush(dmgInfo) then return 1 end
	if dmgInfo:IsDamageType(DMG_BLAST) then return 1 end
	-- if dmgInfo:IsDamageType(DMG_SLASH) and (math.random(5) != 1) and dmg < 2 then return end
	org.painadd = (org.painadd or 0) + dmg * 1
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
local function hitVein(vein, org, dmg, dmgInfo, boneindex, dir, hit)
	-- if isCrush(dmgInfo) then return 1 end
	if dmgInfo:IsDamageType(DMG_BLAST) then return 1 end

	org.painadd = (org.painadd or 0) + dmg * 0.5
	if org[vein] == 1 then return 0 end
	if org[string.Replace(vein, "vein", "").."amputated"] then return end

	hg.AddHarmToAttacker(dmgInfo, 2, "Vein punctured harm")

	org[vein] = math.min(org[vein] + 1, 1)

	local owner = org.owner
	local bonea = owner:LookupBone(boneindex)
	local localPos, localAng, dir2 = getlocalshit(owner, bonea, dmgInfo, dir, hit)
	table.insert(org.veinwounds, {veinSize[vein], localPos, localAng, boneindex, CurTime(), dir2 * 50, vein})
	owner:SetNetVar("veinwounds", org.veinwounds)
	return 0
end

input_list.vein = function(org, bone, dmg, dmgInfo, boneindex, dir, hit)
	return hitVein("vein", org, dmg, dmgInfo, "ValveBiped.Bip01_Neck1", dir, hit)
end

input_list.rarmvein = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitVein("rarmvein", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.larmvein = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitVein("larmvein", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.rlegvein = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitVein("rlegvein", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.llegvein = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitVein("llegvein", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.spinevein = function(org, bone, dmg, dmgInfo, boneindex, dir, hit) return hitVein("spinevein", org, dmg, dmgInfo, boneindex, dir, hit) end
input_list.lungsL = function(org, bone, dmg, dmgInfo)
	local prot = math.max(0.3 - org.lungsL[1],0)
	local oldval = org.lungsL[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung left damage harm")

	org.lungsL[1] = math.min(org.lungsL[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsL[2] = math.min(org.lungsL[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsL[1] - oldval) * 2
	org.bleed = (org.bleed or 0) + (org.lungsL[1] - oldval) * 0.1
	
	local staminaLoss = dmg * 2.0
	org.stamina[1] = math.max(org.stamina[1] - staminaLoss, 0)

	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 1 or prot
end

input_list.lungsR = function(org, bone, dmg, dmgInfo)
	local oldval = org.lungsR[1]

	hg.AddHarmToAttacker(dmgInfo, (dmg * 0.25), "Lung right damage harm")

	org.lungsR[1] = math.min(org.lungsR[1] + dmg / 4, 1)
	if (dmgInfo:IsDamageType(DMG_BULLET+DMG_SLASH+DMG_BUCKSHOT)) or (math.random(3) == 1) then org.lungsR[2] = math.min(org.lungsR[2] + dmg * 1, 1) end

	org.internalBleed = org.internalBleed + (org.lungsR[1] - oldval) * 2
	org.bleed = (org.bleed or 0) + (org.lungsR[1] - oldval) * 0.1

	local staminaLoss = dmg * 2.0
	org.stamina[1] = math.max(org.stamina[1] - staminaLoss, 0)

	dmgInfo:ScaleDamage(0.8)

	return 0//isCrush(dmgInfo) and 1 or prot
end

input_list.trachea = function(org, bone, dmg, dmgInfo, boneindex, dir, hit)
	local oldDmg = org.trachea

	if not dmgInfo:IsDamageType(DMG_BLAST) and math.random(1, 10) ~= 1 then -- haha blocked
		dmgInfo:ScaleDamage(0.1)
	end

	if dmgInfo:IsDamageType(DMG_BLAST) then dmg = dmg / 5 end

	local result = damageOrgan(org, dmg * 2, dmgInfo, "trachea")

	hg.AddHarmToAttacker(dmgInfo, (org.trachea - oldDmg) * 8, "Trachea damage harm")

	org.internalBleed = org.internalBleed + dmg * 2
	org.bleed = (org.bleed or 0) + dmg * 0.2

	if math.random(1, 4) == 1 then -- 25% chance to hit artery on trachea hit
		hitArtery("arteria", org, dmg, dmgInfo, "ValveBiped.Bip01_Neck1", dir, hit)
	end

	return result
end

input_list.lefteye = function(org, bone, dmg, dmgInfo)
    local oldDmg = org.lefteye or 0
    local result = damageOrgan(org, dmg * 1.5, dmgInfo, "lefteye") -- eyes are more fragile now

    hg.AddHarmToAttacker(dmgInfo, math.max((org.lefteye or 0) - oldDmg, 0) * 6, "Left eye damage harm")

    -- strong pain and shock response
    org.painadd = (org.painadd or 0) + dmg * 35
    org.shock = org.shock + dmg * 10
    org.disorientation = org.disorientation + dmg * 2

    -- bleed from any damaging hit type
    org.bleed = org.bleed + dmg * 0.8

    -- eye popped: play short-range cue
    if oldDmg < 1 and (org.lefteye or 0) >= 1 then
        if IsValid(org.owner) then
            org.owner:EmitSound("eyegone.mp3")
        end
    end

    return result
end

input_list.righteye = function(org, bone, dmg, dmgInfo)
    local oldDmg = org.righteye or 0
    local result = damageOrgan(org, dmg * 1.5, dmgInfo, "righteye") -- eyes are more fragile now

    hg.AddHarmToAttacker(dmgInfo, math.max((org.righteye or 0) - oldDmg, 0) * 6, "Right eye damage harm")

    org.painadd = (org.painadd or 0) + dmg * 35
    org.shock = org.shock + dmg * 10
    org.disorientation = org.disorientation + dmg * 2

    -- bleed from any damaging hit type
    org.bleed = org.bleed + dmg * 0.8


    -- eye popped: play short-range cue
    if oldDmg < 1 and (org.righteye or 0) >= 1 then
        if IsValid(org.owner) then
            org.owner:EmitSound("eyegone.mp3")
        end
    end

    return result
end

input_list.spine1 = function(org, bone, dmg, dmgInfo)
    if isCrush(dmgInfo) then dmg = dmg * 0.8 end -- Reduce crush damage
	local result = damageOrgan(org, dmg, dmgInfo, "spine1")
	return result
end
input_list.spine2 = function(org, bone, dmg, dmgInfo)
    if isCrush(dmgInfo) then dmg = dmg * 0.8 end -- Reduce crush damage
	local result = damageOrgan(org, dmg, dmgInfo, "spine2")
	return result
end
input_list.spine3 = function(org, bone, dmg, dmgInfo)
    if isCrush(dmgInfo) then dmg = dmg * 0.8 end -- Reduce crush damage
	local result = damageOrgan(org, dmg, dmgInfo, "spine3")
	return result
end