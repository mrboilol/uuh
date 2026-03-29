local CurTime, IsValid = CurTime, IsValid
local math_min, math_clamp, math_rand, math_random, math_sin = math.min, math.Clamp, math.Rand, math.random, math.sin
local VectorRand = VectorRand

local CHANCE, FORCE, VIBRATION = 0.95, 1200, 150
local extendDur, rigorDur, flexionDur, decorticateDur, decerebrateDur = {4, 10}, {60, 120}, {6, 12}, {8, 15}, {8, 15}
local RIGOR_DAMP, FLEXION_FORCE = 8, 400

local spasmTypes = {[1] = {35, "extend"}, [2] = {25, "rigor"}, [3] = {15,"flexion"}, [4] = {50, "decorticate"}, [5] = {50, "decerebrate"}} --;; Че хотите добавляйте изменяйте

local extendBones = {
	["ValveBiped.Bip01_R_Hand"] = true, ["ValveBiped.Bip01_L_Hand"] = true,
	["ValveBiped.Bip01_R_Foot"] = true, ["ValveBiped.Bip01_L_Foot"] = true,
	["ValveBiped.Bip01_R_Forearm"] = true, ["ValveBiped.Bip01_L_Forearm"] = true,
	["ValveBiped.Bip01_R_Calf"] = true, ["ValveBiped.Bip01_L_Calf"] = true,
	["ValveBiped.Bip01_R_UpperArm"] = true, ["ValveBiped.Bip01_L_UpperArm"] = true,
	["ValveBiped.Bip01_R_Thigh"] = true, ["ValveBiped.Bip01_L_Thigh"] = true,
}

local flexionBones = {
	{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_Spine2", 1.2},
	{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_Spine2", 1.2},
	{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_Spine2", 1.0},
	{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_Spine2", 1.0},
	{"ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Spine2", 0.6},
}

local decorticateBones = {
	flexion = {
		{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_Spine2", 1.2},
		{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_Spine2", 1.2},
		{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_Spine2", 1.0},
		{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_Spine2", 1.0},
	},
	extension = {
		["ValveBiped.Bip01_R_Foot"] = true, ["ValveBiped.Bip01_L_Foot"] = true,
		["ValveBiped.Bip01_R_Calf"] = true, ["ValveBiped.Bip01_L_Calf"] = true,
		["ValveBiped.Bip01_R_Thigh"] = true, ["ValveBiped.Bip01_L_Thigh"] = true,
	}
}

-- Decerebrate: Extension of arms and legs.
local decerebrateBones = {
	["ValveBiped.Bip01_R_Hand"] = true, ["ValveBiped.Bip01_L_Hand"] = true,
	["ValveBiped.Bip01_R_Foot"] = true, ["ValveBiped.Bip01_L_Foot"] = true,
	["ValveBiped.Bip01_R_Forearm"] = true, ["ValveBiped.Bip01_L_Forearm"] = true,
	["ValveBiped.Bip01_R_Calf"] = true, ["ValveBiped.Bip01_L_Calf"] = true,
	["ValveBiped.Bip01_R_UpperArm"] = true, ["ValveBiped.Bip01_L_UpperArm"] = true,
	["ValveBiped.Bip01_R_Thigh"] = true, ["ValveBiped.Bip01_L_Thigh"] = true,
}

local rigorBones = {
	"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_L_Foot",
	"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_L_Calf",
	"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_L_UpperArm",
	"ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_L_Thigh",
	"ValveBiped.Bip01_Head1", "ValveBiped.Bip01_Spine", "ValveBiped.Bip01_Spine1", "ValveBiped.Bip01_Spine2",
}



local fencingArmBones = {
	{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_UpperArm", 1.0},     
	{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_UpperArm", 1.0},
	{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_Spine2", 0.8},       
	{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_Spine2", 0.8},
	{"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Spine2", 0.5},      
	{"ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_Spine2", 0.5},
}
local fencingLegBones = {
	{"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_R_Thigh", 0.6},         
	{"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Thigh", 0.4},         
}

local function getRandomSpasm()
	local _, stype = hg.WeightedRandomSelect(spasmTypes, 1)

	return stype
end

hg.getRandomSpasm = getRandomSpasm

local function applySpasm(rag, stype)
	if not IsValid(rag) then return end
	local dur = stype == "extend" and extendDur or stype == "rigor" and rigorDur or stype == "flexion" and flexionDur or stype == "decorticate" and decorticateDur or stype == "decerebrate" and decerebrateDur
	dur = math_rand(dur[1], dur[2])
	
	rag.spasm, rag.spasmType, rag.spasmDur, rag.spasmForce = true, stype, dur, FORCE
	rag.spasmEnd, rag.spasmStart = CurTime() + dur, CurTime()
	
	if stype == "rigor" then
		rag.rigorActive = true
	end
	--rag:EmitSound("physics/body/body_medium_break" .. math_random(2, 4) .. ".wav", 60, math_random(70, 90), 0.4)
end

hg.applySpasm = applySpasm

local function processExtend(rag, fade)
	local force, pulse = rag.spasmForce or FORCE, 0.7 + math_sin(CurTime() * 8) * 0.3
	local pelvis = rag:LookupBone("ValveBiped.Bip01_Pelvis")
	if not pelvis then return end
	local pelvisPos = rag:GetBonePosition(pelvis)
	
	for name in pairs(extendBones) do
		local bone = rag:LookupBone(name)
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		local dir = (rag:GetBonePosition(bone) - pelvisPos):GetNormalized()
		phys:ApplyForceCenter((dir * force * fade * pulse) + VectorRand(-VIBRATION, VIBRATION) * fade)
	end
end

local function processRigor(rag, fade)
	if not rag.rigorActive then return end
	local damp = RIGOR_DAMP * fade + 0.5
	
	for i = 1, #rigorBones do
		local bone = rag:LookupBone(rigorBones[i])
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		--phys:SetDamping(damp, damp * 2)
		if fade > 0.3 then phys:ApplyForceCenter(VectorRand(-45, 45) * fade) end
	end
end

local function processFlexion(rag, fade)
	local force, pulse = FLEXION_FORCE, 0.8 + math_sin(CurTime() * 5) * 0.2
	for i = 1, #flexionBones do
		local d = flexionBones[i]
		local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])
		if not bone or not targetBone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		local dir = (rag:GetBonePosition(targetBone) - rag:GetBonePosition(bone)):GetNormalized()
		phys:ApplyForceCenter((dir * force * d[3] * fade * pulse) + VectorRand(-30, 30) * fade)
	end
end

local function processDecorticate(rag, fade)
	-- Flexion for arms
	local force, pulse = FLEXION_FORCE, 0.8 + math_sin(CurTime() * 5) * 0.2
	for i = 1, #decorticateBones.flexion do
		local d = decorticateBones.flexion[i]
		local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])
		if not bone or not targetBone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		local dir = (rag:GetBonePosition(targetBone) - rag:GetBonePosition(bone)):GetNormalized()
		phys:ApplyForceCenter((dir * force * d[3] * fade * pulse) + VectorRand(-30, 30) * fade)
	end

	-- Extension for legs
	local force, pulse = rag.spasmForce or FORCE, 0.7 + math_sin(CurTime() * 8) * 0.3
	local pelvis = rag:LookupBone("ValveBiped.Bip01_Pelvis")
	if not pelvis then return end
	local pelvisPos = rag:GetBonePosition(pelvis)
	
	for name in pairs(decorticateBones.extension) do
		local bone = rag:LookupBone(name)
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		local dir = (rag:GetBonePosition(bone) - pelvisPos):GetNormalized()
		phys:ApplyForceCenter((dir * force * fade * pulse) + VectorRand(-VIBRATION, VIBRATION) * fade)
	end
end

local function processDecerebrate(rag, fade)
	local force, pulse = rag.spasmForce or FORCE, 0.7 + math_sin(CurTime() * 8) * 0.3
	local pelvis = rag:LookupBone("ValveBiped.Bip01_Pelvis")
	if not pelvis then return end
	local pelvisPos = rag:GetBonePosition(pelvis)
	
	for name in pairs(decerebrateBones) do
		local bone = rag:LookupBone(name)
		if not bone then continue end
		local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
		if not IsValid(phys) then continue end
		local dir = (rag:GetBonePosition(bone) - pelvisPos):GetNormalized()
		phys:ApplyForceCenter((dir * force * fade * pulse) + VectorRand(-VIBRATION, VIBRATION) * fade)
	end
end

--;; when furfag
local function applyFencingToPlayer(ply, org)
	if not IsValid(ply) or not ply:Alive() then return end
	if org.fencing then return end 
	
	local dur = math_rand(3, 8) 
	org.fencing = true
	org.fencingEnd = CurTime() + dur
	org.fencingDur = dur
	

	if ply.FakeRagdoll and IsValid(ply.FakeRagdoll) then
		local rag = ply.FakeRagdoll
		rag.fencing = true
		rag.fencingEnd = org.fencingEnd
		rag.fencingDur = dur
	end
end

hg.applyFencingToPlayer = applyFencingToPlayer

local function processFencing(rag, fade)
	local org = rag.organism
	local force = 350 * fade
	local pulse = 0.85 + math_sin(CurTime() * 4) * 0.15

	if org.spine2 < hg.organism.fake_spine2 and org.spine3 < hg.organism.fake_spine3 then
		for i = 1, #fencingArmBones do
			local d = fencingArmBones[i]
			local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])
			if not bone or not targetBone then continue end
			local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
			if not IsValid(phys) then continue end
			local bonePos, targetPos = rag:GetBonePosition(bone), rag:GetBonePosition(targetBone)
			local dir = (targetPos - bonePos):GetNormalized()
			phys:ApplyForceCenter((dir * force * d[3] * pulse) + VectorRand(-15, 15) * fade)
		end
	end
	
	if org.spine2 < hg.organism.fake_spine2 and org.spine3 < hg.organism.fake_spine3 and org.spine1 < hg.organism.fake_spine1 then
		for i = 1, #fencingLegBones do
			local d = fencingLegBones[i]
			local bone, targetBone = rag:LookupBone(d[1]), rag:LookupBone(d[2])
			if not bone or not targetBone then continue end
			local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
			if not IsValid(phys) then continue end
			local bonePos, targetPos = rag:GetBonePosition(bone), rag:GetBonePosition(targetBone)
			local dir = (targetPos - bonePos):GetNormalized()
			phys:ApplyForceCenter((dir * force * d[3] * pulse) + VectorRand(-10, 10) * fade)
		end
	end
end

local function clearFencing(rag)
	rag.fencing, rag.fencingEnd, rag.fencingDur = nil, nil, nil
end

local seizuremsgs = {
    "bllllhlhmmmbmmmmbmbmb",
    "bbb b-bbbbbb bllmbmmbb",
    "ddgdgg-d bbbglgggg",
    "mmmmammmm aaghbgbblllb",
    "hhel-bbbphphpppph",
    "zzzzblzzzmzzzzz",
}

local function processGuiltSeizure(owner, org)
    if not owner or not owner:IsPlayer() or org.otrub or not org.isPly then return end
    if not owner:Alive() then return end

    local ply = owner
    local karma = ply.Karma
    local hasKarma = karma ~= nil

    local shouldSeize = false
    if hasKarma and karma < 50 then
        shouldSeize = math.random(math.Clamp(karma, 20, 100) * 300) == 1
    elseif org.brain > 0.2 and math.random(1000) == 1 then -- Probabilistic trigger on brain damage
        shouldSeize = true
    end

    if shouldSeize or org.start_shaking then
        hg.StunPlayer(ply)
        local time = 15
        
        ply:Notify(seizuremsgs[math.random(#seizuremsgs)], 16, "seizure", 1, function()
            if !IsValid(ply) then return end
            
            ply:ChatPrint("You are experiencing an epileptic seizure.")
        end)

        org.start_shaking = org.start_shaking or (CurTime() + time)
        local ent = hg.GetCurrentCharacter(owner)
        local mul = ((org.start_shaking) - CurTime()) / time
        
        if mul > 0 then
            local phys = ent:GetPhysicsObjectNum(math.random(ent:GetPhysicsObjectCount()) - 1)
            if IsValid(phys) then
                phys:ApplyForceCenter(VectorRand(-750 * mul, 750 * mul))
            end
        else
            org.start_shaking = nil
        end
    else
        org.start_shaking = nil
    end

    if hasKarma and karma < 35 then
        if math.random(2000) == 1 then
            hg.organism.Vomit(owner)
        end
    end
end

local function clearSpasm(rag)
	if rag.spasmType == "rigor" and rag.rigorActive then
		for i = 1, #rigorBones do
			local bone = rag:LookupBone(rigorBones[i])
			if not bone then continue end
			local phys = rag:GetPhysicsObjectNum(rag:TranslateBoneToPhysBone(bone))
			if IsValid(phys) then phys:SetDamping(0.5, 1) end
		end
	end
	rag.spasm, rag.spasmEnd, rag.spasmStart, rag.spasmDur, rag.spasmForce, rag.spasmType, rag.rigorActive = nil, nil, nil, nil, nil, nil, nil
end

hook.Add("Should Fake Up", "BrainfuckFencing", function(ply)
	local org = ply.organism
	if org and org.fencing and org.fencingEnd and CurTime() < org.fencingEnd then
		return false
	end
	local rag = ply.FakeRagdoll
	if IsValid(rag) and rag.fencing and rag.fencingEnd and CurTime() < rag.fencingEnd then
		return false
	end
end)

hook.Add("RagdollDeath", "BrainfuckStart", function(ply, rag)
	timer.Simple(0.1, function()
		if not IsValid(ply) or not IsValid(rag) then return end
		local org = ply.organism
		if not org then return end
		if rag.noHead or org.noHead or ply.noHead then return end
		
		local stype = "rigor"
		applySpasm(rag, stype)
		if rag.organism then rag.organism.spasm, rag.organism.spasmType = true, stype end
	end)
end)

hook.Add("Org Think", "BrainfuckThink", function(owner)
	if not IsValid(owner) then return end
	local org = owner.organism or owner
	processGuiltSeizure(owner, org)
	
	if org.fencing and org.fencingEnd then
		local rag = owner.FakeRagdoll
		if IsValid(rag) then
			if CurTime() > org.fencingEnd then
				clearFencing(rag)
				org.fencing, org.fencingEnd, org.fencingDur = nil, nil, nil
			else
				local fade = math_clamp((org.fencingEnd - CurTime()) / (org.fencingDur or 5), 0.1, 1)
				processFencing(rag, fade)
			end
		end
	end
	
	local deathRag = owner.FakeRagdoll
	if IsValid(deathRag) and deathRag.spasm and deathRag.spasmEnd then
		if CurTime() > deathRag.spasmEnd then
			clearSpasm(deathRag)
		else
			local fade = math_clamp((deathRag.spasmEnd - CurTime()) / (deathRag.spasmDur or 5), 0.1, 1)
			local stype = deathRag.spasmType or "extend"

			if stype == "extend" then processExtend(deathRag, fade)
			elseif stype == "rigor" then processRigor(deathRag, fade)
			elseif stype == "flexion" then processFlexion(deathRag, fade)
			elseif stype == "decorticate" then processDecorticate(deathRag, fade)
			elseif stype == "decerebrate" then processDecerebrate(deathRag, fade) end
		end
	end
end)

hook.Add("Org Clear", "BrainfuckClear", function(org)
	if not org or not org.owner then return end
	if IsValid(org.owner) then 
		clearSpasm(org.owner)
		clearFencing(org.owner)
	end
	org.fencing, org.fencingEnd = nil, nil
end)
