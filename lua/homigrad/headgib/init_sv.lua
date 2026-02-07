local net, hg, pairs, Vector, ents, IsValid, util = net, hg, pairs, Vector, ents, IsValid, util

local vecZero = Vector(0,0,0)
local vecInf = Vector(0,0,0) / 0

local function removeBone(rag, bone, phys_bone, nohuys)
	if !nohuys then rag:ManipulateBoneScale(bone, vecZero) end
	--rag:ManipulateBonePosition(bone,vecInf) -- Thanks Rama (only works on certain graphics cards!)

	if rag.gibRemove[phys_bone] then return end

	local phys_obj = rag:GetPhysicsObjectNum(phys_bone)
	phys_obj:EnableCollisions(false)
	phys_obj:SetMass(0.1)
	--rag:RemoveInternalConstraint(phys_bone)

	constraint.RemoveAll(phys_obj)
	rag.gibRemove[phys_bone] = phys_obj
end

local function recursive_bone(rag, bone, list)
	for i,bone in pairs(rag:GetChildBones(bone)) do
		if bone == 0 then continue end--wtf

		list[#list + 1] = bone

		recursive_bone(rag, bone, list)
	end

end

function Gib_RemoveBone(rag, bone, phys_bone, nohuys)
	rag.gibRemove = rag.gibRemove or {}

	removeBone(rag, bone, phys_bone, nohuys)

	local list = {}
	recursive_bone(rag, bone, list)
	for i, bone in pairs(list) do
		removeBone(rag, bone, rag:TranslateBoneToPhysBone(bone), nohuys)
	end
end

--[[concommand.Add("removebone",function(ply)
	if not ply:IsAdmin() then return end
	local trace = ply:GetEyeTrace()
	local ent = trace.Entity
	if not IsValid(ent) then return end

	local phys_bone = trace.PhysicsBone
	if not phys_bone or phys_bone == 0 then return end

	Gib_RemoveBone(ent,ent:TranslatePhysBoneToBone(phys_bone),phys_bone)
end)]]

gib_ragdols = gib_ragdols or {}
local gib_ragdols = gib_ragdols

local validHitGroup = {
	[HITGROUP_LEFTARM] = true,
	[HITGROUP_RIGHTARM] = true,
	[HITGROUP_LEFTLEG] = true,
	[HITGROUP_RIGHTLEG] = true,
}

local Rand = math.Rand

local validBone = {
	["ValveBiped.Bip01_R_UpperArm"] = true,
	["ValveBiped.Bip01_R_Forearm"] = true ,
	["ValveBiped.Bip01_R_Hand"] = true,
	["ValveBiped.Bip01_L_UpperArm"] = true,
	["ValveBiped.Bip01_L_Forearm"] = true,
	["ValveBiped.Bip01_L_Hand"] = true,

	["ValveBiped.Bip01_L_Thigh"] = true,
	["ValveBiped.Bip01_L_Calf"] = true,
	["ValveBiped.Bip01_L_Foot"] = true,
	["ValveBiped.Bip01_R_Thigh"] = true,
	["ValveBiped.Bip01_R_Calf"] = true,
	["ValveBiped.Bip01_R_Foot"] = true
}

local VectorRand, ents_Create = VectorRand, ents.Create
function SpawnGore(ent, pos, headpos)
	if ent.gibRemove and not ent.gibRemove[ent:TranslateBoneToPhysBone(ent:LookupBone("ValveBiped.Bip01_Head1"))] then
		local ent = ents_Create("prop_physics")
		ent:SetModel("models/Gibs/HGIBS.mdl")
		ent:SetPos(headpos or pos)
		ent:SetVelocity(VectorRand(-100, 100))
		ent:Spawn()
	end

	for i = 1, 2 do
		local ent = ents_Create("prop_physics")
		ent:SetModel("models/Gibs/HGIBS_spine.mdl")
		ent:SetPos(pos)
		ent:SetVelocity(VectorRand(-100, 100))
		ent:Spawn()
		
		local ent = ents_Create("prop_physics")
		ent:SetModel("models/Gibs/HGIBS_scapula.mdl")
		ent:SetPos(pos)
		ent:SetVelocity(VectorRand(-100, 100))
		ent:Spawn()

		local ent = ents_Create("prop_physics")
		ent:SetModel("models/Gibs/HGIBS_rib.mdl")
		ent:SetPos(pos)
		ent:SetVelocity(VectorRand(-100, 100))
		ent:Spawn()
	end
end

local function PhysCallback( ent, data )
	--data.HitPos -- data.HitNormal
	if data.DeltaTime < 0.2 then return end
	ent:EmitSound("physics/flesh/flesh_squishy_impact_hard"..math.random(1,4)..".wav")
	util.Decal("Blood",data.HitPos - data.HitNormal*1,data.HitPos + data.HitNormal*1,ent)
end

local grub = Model("models/grub_nugget_small.mdl")
function SpawnMeatGore(mainent, pos, count, force)
	--models/grub_nugget_small.mdl
	force = force or Vector(0,0,0)
	for i = 1, (count or math.random(8, 10)) do
		local ent = ents_Create("prop_physics")
		ent:SetModel(grub)
		ent:SetSubMaterial(0,"models/flesh")
		ent:SetPos(pos)
		ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
		ent:SetModelScale(math.Rand(0.8,1.1))
		ent:SetAngles(AngleRand(-180,180))
		ent:Activate()
		ent:Spawn()
		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:SetVelocity(mainent:GetVelocity() + VectorRand(-65,65) + force / 10)
			phys:AddAngleVelocity(VectorRand(-65,65))
		end

		ent:AddCallback( "PhysicsCollide", PhysCallback )
	end
end

local headpos_male, headpos_female, headang = Vector(0,0,5), Vector(-2,0,4), Angle(0,0,-0)

util.AddNetworkString("addfountain")

hg.fountains = hg.fountains or {}
local headboom_mdl = Model("models/gleb/zcity/headboom.mdl")
local sounds = {
	Sound("player/zombie_head_explode_01.wav"),
	Sound("player/zombie_head_explode_02.wav"),
	Sound("player/zombie_head_explode_03.wav"),
	Sound("player/zombie_head_explode_04.wav"),
	Sound("player/zombie_head_explode_05.wav"),
	Sound("player/zombie_head_explode_06.wav")
}
util.PrecacheModel(headboom_mdl)
for _, snd in ipairs(sounds) do
	util.PrecacheSound(snd)
end
function Gib_Input(rag, bone, force)
	if not IsValid(rag) then return end
	
	local gibRemove = rag.gibRemove

	if not gibRemove then
		rag.gibRemove = {}
		gibRemove = rag.gibRemove

		gib_ragdols[rag] = true
	end

	local phys_bone = rag:TranslateBoneToPhysBone(bone)
	local phys_obj = rag:GetPhysicsObjectNum(phys_bone)
	
	if (not gibRemove[phys_bone]) and (bone == rag:LookupBone("ValveBiped.Bip01_Head1")) then
		--sound.Emit(rag,"player/headshot" .. math.random(1, 2) .. ".wav")
		--sound.Emit(rag,"physics/flesh/flesh_squishy_impact_hard" .. math.random(2, 4) .. ".wav")
		--sound.Emit(rag,"physics/body/body_medium_break3.wav")
		--sound.Emit(rag,"physics/glass/glass_sheet_step" .. math.random(1,4) .. ".wav", 90, 50, 2)
		rag:EmitSound(sounds[math.random(#sounds)], 70, math.random(95, 105), 2)

		Gib_RemoveBone(rag, bone, phys_bone)
		
		--rag:ManipulateBoneScale(rag:LookupBone("ValveBiped.Bip01_Neck1"),vecZero)
		rag:ManipulateBonePosition(rag:LookupBone("ValveBiped.Bip01_Neck1"),Vector(-1,0,0))

		local ent = ents_Create("prop_dynamic")
		ent:SetModel(headboom_mdl)
		local att = rag:GetAttachment(3)
		local pos, ang = LocalToWorld(ThatPlyIsFemale(rag) and headpos_female or headpos_male, headang, att.Pos, att.Ang)
		ent:SetPos(pos)
		ent:SetAngles(ang)
		--ent:AddEffects(EF_FOLLOWBONE)
		ent:SetParent(rag, 3)--rag:LookupBone("ValveBiped.Bip01_Head1"))
		ent:Spawn()

		SpawnMeatGore(ent, pos, nil, force) --модельки поменять и будет эпик

		local armors = rag:GetNetVar("Armor",{})

		if armors["head"] and !hg.armor["head"][armors["head"]].nodrop then
			local ent = hg.DropArmorForce(rag, armors["head"])
			ent:SetPos(phys_obj:GetPos())
		end
		
		if armors["face"] and !hg.armor["face"][armors["face"]].nodrop then
			local ent = hg.DropArmorForce(rag, armors["face"])
			ent:SetPos(phys_obj:GetPos())
		end

		rag.noHead = true
		rag:SetNWString("PlayerName", "Beheaded body")

		net.Start("addfountain")
		net.WriteEntity(rag)
		net.WriteVector(force or vector_origin)
		net.Broadcast()

		hg.fountains[rag] = {bone = rag:LookupBone("ValveBiped.Bip01_Neck1"), lpos = ThatPlyIsFemale(rag) and Vector(4,0,0) or Vector(5,0,0),lang = Angle(0,0,0)}

		rag:CallOnRemove("removefountain", function()
			hg.fountains[rag] = nil
			SetNetVar("fountains", hg.fountains)
		end)

		SetNetVar("fountains", hg.fountains)
	end
end

local stomachGoreModel = "models/noob_dev2323/gib/intestine.mdl"

local intestineChunkModels = {
    "models/mosi/fnv/props/gore/meatbit02.mdl",
    "models/mosi/fnv/props/gore/meatbit03.mdl",
    "models/mosi/fnv/props/gore/meatbit01.mdl",
    "models/mosi/fnv/props/gore/goreintestine.mdl",
}

local function SpawnIntestineChunks(parentEnt, basePos)
    if not basePos then return end
    for _, mdl in ipairs(intestineChunkModels) do
        local chunk = ents.Create("prop_physics")
        chunk:SetModel(mdl)
        chunk:SetPos(basePos + VectorRand(-6, 6))
        chunk:SetAngles(AngleRand())
        chunk:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        chunk:Spawn()
        local phys = chunk:GetPhysicsObject()
        if IsValid(phys) then
            phys:SetMaterial("flesh")
            phys:SetVelocity((IsValid(parentEnt) and parentEnt:GetVelocity() or vector_origin) + VectorRand(-150, 150) + Vector(0, 0, 80))
            phys:AddAngleVelocity(VectorRand(-200, 200))
        end
    end
end

function hg.AttachStomachGore(target)
    if not IsValid(target) then return end
    if target.StomachGoreEnt and IsValid(target.StomachGoreEnt) then return end

    local attachEnt = target
    if attachEnt:IsPlayer() and IsValid(attachEnt.FakeRagdoll) then
        attachEnt = attachEnt.FakeRagdoll
    end

    local gore = ents.Create("prop_dynamic")
    gore:SetModel(stomachGoreModel)
    gore:SetParent(attachEnt)
    local attachments = attachEnt:GetAttachments()
    local Attachment = nil
    for _, att in pairs(attachments) do
        Attachment = att.name
    end
    if Attachment then
        gore:Fire("SetParentAttachment", Attachment)
        gore:AddEffects(EF_BONEMERGE)
        gore:SetSolid(SOLID_NONE)
    else

        local bone = attachEnt:LookupBone("ValveBiped.Bip01_Pelvis") or 0
        if bone and bone ~= 0 then
            local pos, ang = attachEnt:GetBonePosition(bone)
            if pos and ang then
                gore:SetPos(pos)
                gore:SetAngles(ang)
            end
            gore:FollowBone(attachEnt, bone)
        end
    end
    gore:Spawn()

    do
        if not gore._hgStomachExploded then
            local bone = attachEnt:LookupBone("ValveBiped.Bip01_Spine1") or attachEnt:LookupBone("ValveBiped.Bip01_Spine") or attachEnt:LookupBone("ValveBiped.Bip01_Pelvis") or 0
            local basePos = attachEnt:GetBonePosition(bone) or gore:GetPos()
            net.Start("blood particle explode")
            net.WriteVector(basePos)
            net.Broadcast()
            SpawnIntestineChunks(attachEnt, basePos)
            gore._hgStomachExploded = true
        end
    end

    do
        local bonename = (attachEnt:LookupBone("ValveBiped.Bip01_Spine1") and "ValveBiped.Bip01_Spine1")
            or (attachEnt:LookupBone("ValveBiped.Bip01_Spine") and "ValveBiped.Bip01_Spine")
            or "ValveBiped.Bip01_Pelvis"
        local bone = attachEnt:LookupBone(bonename)
        local mat = attachEnt:GetBoneMatrix(bone)
        if mat then
            local pos = mat:GetTranslation() + mat:GetAngles():Forward() * 3
            local dir = mat:GetAngles():Right() * -2
            attachEnt:SetNWBool("NoVomitView", true)
            net.Start("bloodsquirt2")
                net.WriteEntity(gore)
                net.WriteString(bonename)
                net.WriteMatrix(mat)
                net.WriteVector(pos)
                net.WriteVector(dir)
            net.Broadcast()

            local timerID = "hg_stomach_squirt_" .. gore:EntIndex()
            timer.Create(timerID, 0.2, 30, function()
                if not IsValid(attachEnt) or not IsValid(gore) then
                    timer.Remove(timerID)
                    return
                end
                local mat2 = attachEnt:GetBoneMatrix(bone)
                if not mat2 then return end
                local pos2 = mat2:GetTranslation() + mat2:GetAngles():Forward() * 3
                local dir2 = mat2:GetAngles():Right() * -2
                attachEnt:SetNWBool("NoVomitView", true)
                net.Start("bloodsquirt2")
                    net.WriteEntity(gore)
                    net.WriteString(bonename)
                    net.WriteMatrix(mat2)
                    net.WriteVector(pos2)
                    net.WriteVector(dir2)
                net.Broadcast()
            end)
        end
    end

    -- short-range dismember sound
    local snd = "dismember" .. math.random(1,3) .. ".wav"
    gore:EmitSound(snd, 75, 100, 0.9)

    -- simple drip effect similar to head gib
    gore:CallOnRemove("hg_stomachgore_cleanup", function(ent) end)

    -- store on the actual parent entity to avoid clearing ragdoll gore on player respawn
    attachEnt.StomachGoreEnt = gore
end

hook.Add("Player Spawn", "HG_ClearStomachGoreOnSpawn", function(ply)
    if IsValid(ply.StomachGoreEnt) and ply.StomachGoreEnt:GetParent() == ply then
        ply.StomachGoreEnt:Remove()
        ply.StomachGoreEnt = nil
    end
end)

local function ReparentStomachGore(fromEnt, toEnt)
    if not IsValid(fromEnt) or not IsValid(toEnt) then return end
    local gore = fromEnt.StomachGoreEnt
    if not IsValid(gore) then return end

    gore:SetParent(toEnt)
    local attachments = toEnt:GetAttachments()
    local Attachment = nil
    for _, att in pairs(attachments) do
        Attachment = att.name
    end
    if Attachment then
        gore:Fire("SetParentAttachment", Attachment)
        gore:AddEffects(EF_BONEMERGE)
        gore:SetSolid(SOLID_NONE)
    else
        local bone = toEnt:LookupBone("ValveBiped.Bip01_Pelvis") or 0
        if bone and bone ~= 0 then
            local pos, ang = toEnt:GetBonePosition(bone)
            if pos and ang then
                gore:SetPos(pos)
                gore:SetAngles(ang)
            end
            gore:FollowBone(toEnt, bone)
        end
    end

    toEnt.StomachGoreEnt = gore
    if fromEnt ~= toEnt then
        fromEnt.StomachGoreEnt = nil
    end
end

hook.Add("Fake", "HG_ReparentStomachGoreToRag", function(ply, rag)
    if not IsValid(ply) or not IsValid(rag) then return end
    if IsValid(ply.StomachGoreEnt) then
        ReparentStomachGore(ply, rag)
    end
end)

hook.Add("Player Getup", "HG_ReparentStomachGoreToPlayer", function(ply)
    local rag = ply.FakeRagdoll
    if IsValid(rag) and IsValid(rag.StomachGoreEnt) then
        ReparentStomachGore(rag, ply)
    end
end)

hook.Add("Fake Up", "HG_ReparentStomachGoreBack_Early", function(ply, rag)
    if not IsValid(ply) then return end
    local r = rag or ply.FakeRagdoll
    if IsValid(r) and IsValid(r.StomachGoreEnt) then
        ReparentStomachGore(r, ply)
    end
end)

concommand.Add("hg_disembowel", function(ply, cmd, args)
    local target
    if args and args[1] and string.lower(args[1]) == "self" then
        target = IsValid(ply.FakeRagdoll) and ply.FakeRagdoll or ply
    else
        local tr = ply:GetEyeTrace()
        if IsValid(tr.Entity) then
            target = tr.Entity
        end
    end
    if not IsValid(target) then return end
    hg.AttachStomachGore(target)

    local owner = target
    if target:IsRagdoll() then
        owner = hg.RagdollOwner(target) or owner
    end
    if IsValid(owner) and owner.organism then
        local boneId = owner:LookupBone("ValveBiped.Bip01_Spine1") or owner:LookupBone("ValveBiped.Bip01_Spine") or owner:LookupBone("ValveBiped.Bip01_Pelvis") or 0
        hg.organism.AddWoundManual(owner, 80, vector_origin, Angle(0,0,0), boneId, CurTime())
        owner.organism.painadd = (owner.organism.painadd or 0) + 25
        owner.organism.shock = math.min((owner.organism.shock or 0) + 12, 70)
        owner:SetNetVar("wounds", owner.organism.wounds)
    end
end)

local function CreateStomachGoreOnRagdoll(rag)
    if not IsValid(rag) then return end
    local gore = ents.Create("prop_physics")
    gore:SetModel(stomachGoreModel)
    gore:SetParent(rag)
    local attachments = rag:GetAttachments()
    local Attachment = nil
    for _, att in pairs(attachments) do
        Attachment = att.name
    end
    if Attachment then
        gore:Fire("SetParentAttachment", Attachment)
        gore:AddEffects(EF_BONEMERGE)
        gore:SetSolid(SOLID_NONE)
    else
        local bone = rag:LookupBone("ValveBiped.Bip01_Pelvis") or 0
        if bone and bone ~= 0 then
            local pos, ang = rag:GetBonePosition(bone)
            if pos and ang then
                gore:SetPos(pos)
                gore:SetAngles(ang)
            end
            gore:FollowBone(rag, bone)
        end
    end
    gore:Spawn()

    rag.StomachGoreEnt = gore
end

hook.Add("RagdollDeath", "HG_ConvertStomachGoreToPhysics", function(ply, rag)
    if not IsValid(ply) or not IsValid(rag) then return end
    if IsValid(ply.StomachGoreEnt) then
        local old = ply.StomachGoreEnt
        CreateStomachGoreOnRagdoll(rag)
        old:Remove()
        ply.StomachGoreEnt = nil
        return
    end
    if IsValid(rag.StomachGoreEnt) then
        local old = rag.StomachGoreEnt
        CreateStomachGoreOnRagdoll(rag)
        old:Remove()
        rag.StomachGoreEnt = nil
        return
    end
end)
