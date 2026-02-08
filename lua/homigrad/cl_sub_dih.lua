
local plyModel
local wasFaking = false
local matWhite = Material("models/debug/debugwhite")

hook.Add("HUDPaint", "subrosa", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if ply.organism and ply.organism.otrub then return end

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

    if plyModel:GetModel() ~= (isFaking and ragdoll:GetModel() or ply:GetModel()) then
        plyModel:SetModel(isFaking and ragdoll:GetModel() or ply:GetModel())
    end

    plyModel:SetPos(Vector(0, 0, 0))
    plyModel:SetAngles(Angle(0, 0, 0))
    
    local sourceEnt = isFaking and ragdoll or ply
    
    if not isFaking then
        plyModel:SetSequence(ply:GetSequence())
        plyModel:SetCycle(ply:GetCycle())
        plyModel:SetPlaybackRate(ply:GetPlaybackRate())

        for i = 0, ply:GetNumPoseParameters() - 1 do
            local name = ply:GetPoseParameterName(i)
            plyModel:SetPoseParameter(name, ply:GetPoseParameter(i))
        end
    end

    local rootBone = sourceEnt:LookupBone("ValveBiped.Bip01_Pelvis")
    if not rootBone then rootBone = 0 end

    local rootMat = sourceEnt:GetBoneMatrix(rootBone)
    
    if rootMat then
        local rootInv = rootMat:GetInverse()
        
        for i = 0, plyModel:GetBoneCount() - 1 do
            local boneName = plyModel:GetBoneName(i)
            local sourceBone = sourceEnt:LookupBone(boneName)
            
            if sourceBone then
                local mat = sourceEnt:GetBoneMatrix(sourceBone)
                if mat then
                    local newMat = mat * rootInv
                    plyModel:SetBoneMatrix(i, newMat)
                end
            end
        end
    end

    local w, h = ScrW(), ScrH()
    local size = h * 0.25
    local x = w / 2 - size / 2
    local y = h * 0.65 

    render.MaterialOverride(matWhite)
    render.SetColorModulation(1, 1, 1)
    render.SuppressEngineLighting(true)
    render.SetBlend(1) 


    local camDist = 120 
    local camPos = Vector(camDist, 0, 0)
    local camLookAt = Vector(0, 0, 0)
    
    local camAng = (camLookAt - camPos):Angle()

    cam.Start3D(camPos, camAng, 50, x, y, size, size)
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
