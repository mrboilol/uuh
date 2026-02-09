
local plyModel
local wepModel
local wasFaking = false
local matWhite = Material("models/debug/debugwhite")

-- Global cleanup to prevent duplicates on reload or multiple instances
if IsValid(HG_Silhouette_PlyModel) then HG_Silhouette_PlyModel:Remove() end
if IsValid(HG_Silhouette_WepModel) then HG_Silhouette_WepModel:Remove() end

local function GetSilhouetteModels(ply, isFaking, ragdoll)
    local targetModel = isFaking and ragdoll:GetModel() or ply:GetModel()
    
    -- Recreate player model if needed
    if not IsValid(HG_Silhouette_PlyModel) or HG_Silhouette_PlyModel:GetModel() ~= targetModel then
        if IsValid(HG_Silhouette_PlyModel) then HG_Silhouette_PlyModel:Remove() end
        HG_Silhouette_PlyModel = ClientsideModel(targetModel)
        if IsValid(HG_Silhouette_PlyModel) then
            HG_Silhouette_PlyModel:SetNoDraw(true)
            HG_Silhouette_PlyModel:SetIK(false)
        end
    end
    plyModel = HG_Silhouette_PlyModel
    
    return plyModel
end

hook.Add("HUDPaint", "subrosa", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    if ply.organism and ply.organism.otrub then return end

    local ragdoll = ply.FakeRagdoll
    if not IsValid(ragdoll) then ragdoll = ply:GetRagdollEntity() end
    
    local isFaking = IsValid(ragdoll) and (ragdoll:GetModel() == ply:GetModel())
    
    GetSilhouetteModels(ply, isFaking, ragdoll)
    
    if not IsValid(plyModel) then return end
    
    -- Ensure it's hidden from world view
    plyModel:SetNoDraw(true)
    
    local sourceEnt = isFaking and ragdoll or ply
    
    -- Force update bones to get current pose
    sourceEnt:InvalidateBoneCache()
    sourceEnt:SetupBones()
    
    plyModel:SetPos(Vector(0, 0, 0))
    plyModel:SetAngles(Angle(0, 0, 0))
    
    -- Copy bones relative to pelvis (root)
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

    -- Weapon Model Handling
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) and not isFaking then
        local modelName = wep.WorldModel
        if not modelName or modelName == "" then modelName = wep:GetModel() end

        if modelName and modelName ~= "" then
             if not IsValid(HG_Silhouette_WepModel) or HG_Silhouette_WepModel:GetModel() ~= modelName then
                 if IsValid(HG_Silhouette_WepModel) then HG_Silhouette_WepModel:Remove() end
                 HG_Silhouette_WepModel = ClientsideModel(modelName)
                 if IsValid(HG_Silhouette_WepModel) then
                     HG_Silhouette_WepModel:SetNoDraw(true)
                     HG_Silhouette_WepModel:SetParent(plyModel)
                     HG_Silhouette_WepModel:AddEffects(EF_BONEMERGE)
                 end
             end
             wepModel = HG_Silhouette_WepModel
             if IsValid(wepModel) then wepModel:SetNoDraw(true) end
        else
            if IsValid(HG_Silhouette_WepModel) then HG_Silhouette_WepModel:Remove() HG_Silhouette_WepModel=nil end
            wepModel = nil
        end
    else
        if IsValid(HG_Silhouette_WepModel) then HG_Silhouette_WepModel:Remove() HG_Silhouette_WepModel=nil end
        wepModel = nil
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
        if IsValid(wepModel) then wepModel:DrawModel() end
    cam.End3D()

    render.SetBlend(1)
    render.SuppressEngineLighting(false)
    render.SetColorModulation(1, 1, 1)
    render.MaterialOverride(nil)
end)

hook.Add("PostCleanupMap", "ResetSilhouetteModel", function()
    if IsValid(HG_Silhouette_PlyModel) then
        HG_Silhouette_PlyModel:Remove()
        HG_Silhouette_PlyModel = nil
    end
    if IsValid(HG_Silhouette_WepModel) then
        HG_Silhouette_WepModel:Remove()
        HG_Silhouette_WepModel = nil
    end
    plyModel = nil
    wepModel = nil
end)
