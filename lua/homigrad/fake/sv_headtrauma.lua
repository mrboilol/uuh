if not SERVER then return end

hook.Add("PhysgunDrop", "RagdollHeadFlash", function(ply, ent) 
    if not IsValid(ent) or not ent:IsRagdoll() then return end

    local phys = ent:GetPhysicsObjectNum(0)
    if not IsValid(phys) then return end

    local vel = phys:GetVelocity():Length()
    if vel < 400 then return end

    local tr = util.TraceLine({
        start = ent:GetPos(),
        endpos = ent:GetPos() - Vector(0, 0, 1000),
        filter = ent
    })

    if not tr.Hit then return end

    local boneName = ent:GetBoneName(ent:GetPhysicsObject(0):GetClosestPoint(tr.HitPos):GetBone())

    if boneName == "ValveBiped.Bip01_Head1" then
        local owner = hg.RagdollOwner(ent)
        if IsValid(owner) and owner:IsPlayer() then
            local hitpos = tr.HitPos or ent:GetPos()
            owner:PlayCustomTinnitus("headhit.mp3")
            net.Start("headtrauma_flash")
                net.WriteVector(hitpos)
                net.WriteFloat(0.6)
                net.WriteInt(2200, 20)
            net.Send(owner)
        end
    end
end)

hook.Add("RagdollCollide", "RagdollHeadFlashImpact", function(ragdoll, data) 
    if not IsValid(ragdoll) then return end

    local owner = hg.RagdollOwner(ragdoll)
    if not IsValid(owner) or not owner:IsPlayer() then return end

    if data.Speed < 300 then return end

    local boneName = GetBoneNameFromPhysBone(ragdoll, data.PhysBone)
    if boneName ~= "ValveBiped.Bip01_Head1" then return end

    if ragdoll.lastHeadHit and (CurTime() - ragdoll.lastHeadHit < 0.5) then return end
    ragdoll.lastHeadHit = CurTime()

    local hitpos = data.HitPos or ragdoll:GetPos()
    owner:PlayCustomTinnitus("headhit.mp3")
    net.Start("headtrauma_flash")
        net.WriteVector(hitpos)
        net.WriteFloat(0.6)
        net.WriteInt(2200, 20)
    net.Send(owner)
end)

local function GetBoneNameFromPhysBone(ragdoll, physBone)
    local bone = ragdoll:TranslatePhysBoneToBone(physBone)
    if bone < 0 then return nil end
    return ragdoll:GetBoneName(bone)
end

hook.Add("PlayerCollide", "PlayerHeadFlashImpact", function(ply, ent, data)
    if not IsValid(ply) or not ply:Alive() or not IsValid(ent) then return end
    if ent:IsPlayer() or ent:IsPlayerHolding() or ent:GetClass() == "prop_ragdoll" then return end

    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return end

    if data.Speed > 200 and phys:GetMass() > 10 then
        local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
        if not headBone then return end

        local headPos, _ = ply:GetBonePosition(headBone)
        local dist = headPos:Distance(data.HitPosition)

        if dist < 25 then
            local speed = data.Speed
            local size = math.Clamp(speed * 5, 1000, 5000)
            local time = math.Clamp(speed / 1000, 0.4, 1.0)

            ply:PlayCustomTinnitus("headhit.mp3")
            net.Start("headtrauma_flash")
                net.WriteVector(data.HitPosition)
                net.WriteFloat(time)
                net.WriteInt(size, 20)
            net.Send(ply)

            local dmgInfo = DamageInfo()
            dmgInfo:SetDamage(speed / 50)
            dmgInfo:SetAttacker(ent)
            dmgInfo:SetInflictor(ent)
            dmgInfo:SetDamageType(DMG_CRUSH)
            ply:TakeDamageInfo(dmgInfo)
        end
    end
end)