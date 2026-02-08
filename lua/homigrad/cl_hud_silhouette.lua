
local plyModel
local wasFaking = false
local matWhite = Material("models/debug/debugwhite")

hook.Add("HUDPaint", "fakesubrosa", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    
    local ragdoll = ply.FakeRagdoll
    local isFaking = IsValid(ragdoll) and (ragdoll:GetModel() == ply:GetModel())

    if isFaking ~= wasFaking then
        if IsValid(plyModel) then
            plyModel:Remove()
            plyModel = nil
        end
        wasFaking = isFaking
    end

    if not IsValid(plyModel) then
        plyModel = ClientsideModel(ply:GetModel())
        if not IsValid(plyModel) then return end
        plyModel:SetNoDraw(true)
    end

    if plyModel:GetModel() ~= ply:GetModel() then
        plyModel:SetModel(ply:GetModel())
    end


    plyModel:SetPos(Vector(0, 0, 0))
    plyModel:SetAngles(Angle(0, 0, 0))
    
    if isFaking then
        local rootBone = ragdoll:LookupBone("ValveBiped.Bip01_Pelvis")
        local rootMat = ragdoll:GetBoneMatrix(rootBone)
        
        if rootMat then
            local rootInv = rootMat:GetInverse()
            for i = 0, plyModel:GetBoneCount() - 1 do
                local boneName = plyModel:GetBoneName(i)
                local ragBone = ragdoll:LookupBone(boneName)
                if ragBone then
                    local mat = ragdoll:GetBoneMatrix(ragBone)
                    if mat then
                        local newMat = mat * rootInv
                        plyModel:SetBoneMatrix(i, newMat)
                    end
                end
            end
        end
    else
        plyModel:SetSequence(ply:GetSequence())
        plyModel:SetCycle(ply:GetCycle())
        plyModel:SetPlaybackRate(ply:GetPlaybackRate())
        
        for i = 0, ply:GetNumPoseParameters() - 1 do
            local name = ply:GetPoseParameterName(i)
            plyModel:SetPoseParameter(name, ply:GetPoseParameter(i))
        end

        for i = 0, ply:GetNumBodyGroups() - 1 do
            plyModel:SetBodygroup(i, ply:GetBodygroup(i))
        end
    end

    local w, h = ScrW(), ScrH()
    local size = h * 0.25
    local x = w / 2 - size / 2
    local y = h * 0.65 -- Below middle

    render.MaterialOverride(matWhite)
    render.SetColorModulation(1, 1, 1)
    render.SuppressEngineLighting(true)
    render.SetBlend(1) 

    -- Camera setup
    local camPos = Vector(80, 0, 36)
    local camLookAt = Vector(0, 0, 36)
    
    if isFaking then
        camPos = Vector(80, 0, 0)
        camLookAt = Vector(0, 0, 0)
    elseif ply:Crouching() then
        camPos.z = 28
        camLookAt.z = 28
    end

    local camAng = (camLookAt - camPos):Angle()

    cam.Start3D(camPos, camAng, 90, x, y, size, size)
        plyModel:DrawModel()
    cam.End3D()

    render.SetBlend(1)
    render.SuppressEngineLighting(false)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
end)

hook.Add("PostCleanupMap", "ResetSilhouetteModel", function()
    if IsValid(plyModel) then
        plyModel:Remove()
        plyModel = nil
    end
end)
