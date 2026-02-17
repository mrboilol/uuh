--local Organism = hg.organism
if SERVER then
    util.AddNetworkString("headtrauma_flash")
end

-- Limb bone mapping for visual floppy effects
local limbBoneSegments = {
	-- Left arm segments (3 segments)
	larm = {
		{"ValveBiped.Bip01_L_UpperArm", "ValveBiped.Bip01_Spine2"}, -- upper arm to spine
		{"ValveBiped.Bip01_L_Forearm", "ValveBiped.Bip01_L_UpperArm"}, -- forearm to upper arm
		{"ValveBiped.Bip01_L_Hand", "ValveBiped.Bip01_L_Forearm"} -- hand to forearm
	},
	-- Right arm segments (3 segments)
	rarm = {
		{"ValveBiped.Bip01_R_UpperArm", "ValveBiped.Bip01_Spine2"}, -- upper arm to spine
		{"ValveBiped.Bip01_R_Forearm", "ValveBiped.Bip01_R_UpperArm"}, -- forearm to upper arm
		{"ValveBiped.Bip01_R_Hand", "ValveBiped.Bip01_R_Forearm"} -- hand to forearm
	},
	-- Left leg segments (3 segments)
	lleg = {
		{"ValveBiped.Bip01_L_Thigh", "ValveBiped.Bip01_Pelvis"}, -- thigh to pelvis
		{"ValveBiped.Bip01_L_Calf", "ValveBiped.Bip01_L_Thigh"}, -- calf to thigh
		{"ValveBiped.Bip01_L_Foot", "ValveBiped.Bip01_L_Calf"} -- foot to calf
	},
	-- Right leg segments (3 segments)
	rleg = {
		{"ValveBiped.Bip01_R_Thigh", "ValveBiped.Bip01_Pelvis"}, -- thigh to pelvis
		{"ValveBiped.Bip01_R_Calf", "ValveBiped.Bip01_R_Thigh"}, -- calf to thigh
		{"ValveBiped.Bip01_R_Foot", "ValveBiped.Bip01_R_Calf"} -- foot to calf
	}
}

local maxLimbBreaks = {
    larm = 3,
    rarm = 3,
    lleg = 3,
    rleg = 3
}

-- Bone Buster angle limits for ragdoll constraints
local bb_constraints_limit = {
    ["ValveBiped.Bip01_Pelvis"] = {
        [0] = { [0] = "90",  [1] = "-90" },
        [1] = { [0] = "90",  [1] = "-90" },
        [2] = { [0] = "90",  [1] = "-90" },
    },
    ["ValveBiped.Bip01_R_UpperArm"] = {
        [0] = { [0] = "100", [1] = "-100" },
        [1] = { [0] = "50",  [1] = "-50" },
        [2] = { [0] = "30",  [1] = "-30" },
    },
    ["ValveBiped.Bip01_L_UpperArm"] = {
        [0] = { [0] = "100", [1] = "-100" },
        [1] = { [0] = "50",  [1] = "-50" },
        [2] = { [0] = "30",  [1] = "-30" },
    },
    ["ValveBiped.Bip01_L_Forearm"] = {
        [0] = { [0] = "90",  [1] = "-135" },
        [1] = { [0] = "45",  [1] = "-45" },
        [2] = { [0] = "90",  [1] = "-90" },
    },
    ["ValveBiped.Bip01_R_Forearm"] = {
        [0] = { [0] = "90",  [1] = "-135" },
        [1] = { [0] = "45",  [1] = "-45" },
        [2] = { [0] = "90",  [1] = "-90" },
    },
    ["ValveBiped.Bip01_L_Hand"] = {
        [0] = { [0] = "90",  [1] = "-90" },
        [1] = { [0] = "90",  [1] = "-90" },
        [2] = { [0] = "90",  [1] = "-90" },
    },
    ["ValveBiped.Bip01_R_Hand"] = {
        [0] = { [0] = "90",  [1] = "-90" },
        [1] = { [0] = "90",  [1] = "-90" },
        [2] = { [0] = "90",  [1] = "-90" },
    },
    ["ValveBiped.Bip01_R_Thigh"] = {
        [0] = { [0] = "100", [1] = "-60" },
        [1] = { [0] = "10",  [1] = "-60" },
        [2] = { [0] = "45",  [1] = "-5" },
    },
    ["ValveBiped.Bip01_R_Calf"] = {
        [0] = { [0] = "60",  [1] = "-135" },
        [1] = { [0] = "20",  [1] = "-45" },
        [2] = { [0] = "45",  [1] = "-5" },
    },
    ["ValveBiped.Bip01_L_Thigh"] = {
        [0] = { [0] = "100", [1] = "-60" },
        [1] = { [0] = "60",  [1] = "-10" },
        [2] = { [0] = "5",   [1] = "-45" },
    },
    ["ValveBiped.Bip01_L_Calf"] = {
        [0] = { [0] = "60",  [1] = "-135" },
        [1] = { [0] = "45",  [1] = "-20" },
        [2] = { [0] = "5",   [1] = "-45" },
    },
    ["ValveBiped.Bip01_L_Foot"] = {
        [0] = { [0] = "45",  [1] = "-45" },
        [1] = { [0] = "45",  [1] = "-45" },
        [2] = { [0] = "45",  [1] = "-45" },
    },
    ["ValveBiped.Bip01_R_Foot"] = {
        [0] = { [0] = "45",  [1] = "-45" },
        [1] = { [0] = "45",  [1] = "-45" },
        [2] = { [0] = "45",  [1] = "-45" },
    },
    -- Spine joints (use Bone Buster constraints instead of old ballsocket)
    ["ValveBiped.Bip01_Spine"] = {
        [0] = { [0] = "45",  [1] = "-45" },
        [1] = { [0] = "35",  [1] = "-35" },
        [2] = { [0] = "25",  [1] = "-25" },
    },
    ["ValveBiped.Bip01_Spine2"] = {
        [0] = { [0] = "40",  [1] = "-40" },
        [1] = { [0] = "30",  [1] = "-30" },
        [2] = { [0] = "20",  [1] = "-20" },
    },
}

local matrix_cache = {}

local function getBoneMatrix(rag, boneID)
    local model = rag:GetModel()
    if not matrix_cache[model] then
        local _, tab = util.GetModelMeshes(model)
        if not tab then return end

        matrix_cache[model] = {}
        for i = 0, rag:GetPhysicsObjectCount() - 1 do
            local id = rag:TranslatePhysBoneToBone(i)
            if tab[id] and tab[id].matrix then
                local mat = tab[id].matrix:GetInverse()
                matrix_cache[model][id] = mat
            end
        end
    end
    return matrix_cache[model] and matrix_cache[model][boneID]
end

-- Function to create floppy limb constraint (less floppy than neck)
local function createFloppyLimbConstraint(rag, bone1Name, bone2Name, limbType)
	if not IsValid(rag) or not rag:IsRagdoll() then 
        return false 
    end
	
	local bone1 = rag:LookupBone(bone1Name)
	local bone2 = rag:LookupBone(bone2Name)
	if not bone1 or not bone2 then 
        return false 
    end

    local matrix = getBoneMatrix(rag, bone1)
    local matrix_par = getBoneMatrix(rag, bone2)
    if not matrix or not matrix_par then
        return false
    end

	local phys1 = rag:TranslateBoneToPhysBone(bone1)
	local phys2 = rag:TranslateBoneToPhysBone(bone2)
	if not phys1 or not phys2 or phys1 < 0 or phys2 < 0 then 
        return false 
    end

	local pBone1 = rag:GetPhysicsObjectNum(phys1)
	local pBone2 = rag:GetPhysicsObjectNum(phys2)
	if not (IsValid(pBone1) and IsValid(pBone2)) then 
        return false 
    end

	-- Check for limits before removing existing constraint to prevent detachment
	local limits = bb_constraints_limit[bone1Name]
	if not limits then 
        return false 
    end

    -- Helper to remove any conflicting constraints (like stiffness hinges) between these bones
    if rag.Constraints then
        for k, v in pairs(rag.Constraints) do
            if (v.Bone1 == phys1 and v.Bone2 == phys2) or (v.Bone1 == phys2 and v.Bone2 == phys1) then
                if IsValid(v.Constraint) then v.Constraint:Remove() end
                rag.Constraints[k] = nil
            end
        end
    end

	-- Remove existing rigid constraint
	pcall(function() rag:RemoveInternalConstraint(phys1) end)

    -- Save current state
    local pos_ori = pBone1:GetPos()
	local pos_ori_par = pBone2:GetPos()
	local ang_ori = pBone1:GetAngles()
	local ang_ori_par = pBone2:GetAngles()

	local vel_ori = pBone1:GetVelocity()
	local vel_ori_par = pBone2:GetVelocity()
	local avel_ori = pBone1:GetAngleVelocity()
	local avel_ori_par = pBone2:GetAngleVelocity()

    -- Move to bind pose for accurate constraint creation
    local m_translation = rag:LocalToWorld(matrix:GetTranslation())
	local p_translation = rag:LocalToWorld(matrix_par:GetTranslation())

	pBone1:SetPos(m_translation)
	pBone1:SetAngles(rag:LocalToWorldAngles(matrix:GetAngles()))
	pBone2:SetPos(p_translation)
	pBone2:SetAngles(rag:LocalToWorldAngles(matrix_par:GetAngles()))

    -- Ensure collisions are enabled on both physics objects to avoid funky hits
    if pBone1.EnableCollisions then pBone1:EnableCollisions(true) end
    if pBone2.EnableCollisions then pBone2:EnableCollisions(true) end
    if pBone1.Wake then pBone1:Wake() end
    if pBone2.Wake then pBone2:Wake() end
    pBone1:EnableMotion(true)
    pBone2:EnableMotion(true)

    -- Use spawnflags 1 to disable collision between constrained parts (cleaner than NoCollide)
	local lpos, lang = WorldToLocal(pBone1:GetPos(), pBone1:GetAngles(), pBone2:GetPos(), pBone2:GetAngles())

	local cons = constraint.AdvBallsocket(
		rag, rag,
		phys2, phys1,
		lpos, lpos,
		0, 0,
		tonumber(limits[0][1]), tonumber(limits[1][1]), tonumber(limits[2][1]),
		tonumber(limits[0][0]), tonumber(limits[1][0]), tonumber(limits[2][0]),
		0, 0
	)
    
    -- Restore original state
    pBone1:SetPos(pos_ori)
	pBone1:SetAngles(ang_ori)
	pBone2:SetPos(pos_ori_par)
	pBone2:SetAngles(ang_ori_par)

	pBone1:SetVelocityInstantaneous(vel_ori)
	pBone1:SetVelocity(vel_ori)
	pBone2:SetVelocityInstantaneous(vel_ori_par)
	pBone2:SetVelocity(vel_ori_par)
	pBone1:SetAngleVelocityInstantaneous(avel_ori)
	pBone1:SetAngleVelocity(avel_ori)
	pBone2:SetAngleVelocityInstantaneous(avel_ori_par)
	pBone2:SetAngleVelocity(avel_ori_par)
    
	rag:SetSaveValue("m_ragdoll.allowStretch", false)

	return cons and IsValid(cons) and cons
end

-- Jaw pose: tilt down and slight left/right at random
local function applyJawPose(ent)
    if not IsValid(ent) then return end

    timer.Simple(0.1, function()
        if not IsValid(ent) then return end

        local rag = ent:GetNWEntity("RagdollDeath")
        if not IsValid(rag) then rag = ent:GetNWEntity("FakeRagdoll") end
        if not IsValid(rag) and IsValid(ent.FakeRagdoll) then rag = ent.FakeRagdoll end
        if not IsValid(rag) then rag = ent end

        if not rag:IsRagdoll() then return end

        -- prefer an explicit jaw bone if present; fallback to head
        local targetBone
        local bc = rag.GetBoneCount and rag:GetBoneCount() or 0
        for i = 0, bc - 1 do
            local n = rag:GetBoneName(i)
            if isstring(n) and string.find(string.lower(n), "jaw", 1, true) then
                targetBone = i
                break
            end
        end
        targetBone = targetBone or rag:LookupBone("ValveBiped.Bip01_Head1")
        if not targetBone then return end

        -- Check if bone manipulation is safe to perform
        local physBone = rag:TranslateBoneToPhysBone(targetBone)
        if not physBone or physBone < 0 then return end
        
        local physObj = rag:GetPhysicsObjectNum(physBone)
        if not IsValid(physObj) then return end

        local yaw = (math.random(2) == 1) and -10 or 10
        local pitch = 18
        rag:ManipulateBoneAngles(targetBone, Angle(pitch, yaw, 0))
    end)
end


-- AOOWWOAWAOAOWAAAGAHGWAOWAAAA
local function trackBoneBreak(org, boneKey)
    org.recentBoneBreaks = org.recentBoneBreaks or {}
    
    table.insert(org.recentBoneBreaks, {
        bone = boneKey,
        time = CurTime()
    })
    
    local currentTime = CurTime()
    for i = #org.recentBoneBreaks, 1, -1 do
        if currentTime - org.recentBoneBreaks[i].time > 5 then
            table.remove(org.recentBoneBreaks, i)
        end
    end
end

local function checkForGruesomeAccident(org)
    if not org.recentBoneBreaks then return false end
    
    local currentTime = CurTime()
    local recentBreaks = {}
    local hasNeckBreak = false
    

    for _, breakData in ipairs(org.recentBoneBreaks) do
        if currentTime - breakData.time <= 4 then
            table.insert(recentBreaks, breakData.bone)
            if breakData.bone == "spine3" then
                hasNeckBreak = true
            end
        end
    end
    

    if #recentBreaks >= 3 and hasNeckBreak then
        org.gruesomeAccident = true
        org.gruesomeAccidentTime = currentTime
        
        
        return true
    end
    
    return false
end




-- Function to apply visual floppy effect to a limb
local function applyLimbFloppyEffect(ent, limbKey, segmentOverride)
	if not IsValid(ent) then return end
	
	ent.brokenLimbSegments = ent.brokenLimbSegments or {}
	ent.brokenLimbSegments[limbKey] = ent.brokenLimbSegments[limbKey] or {}

	--if table.Count(ent.brokenLimbSegments[limbKey]) >= (maxLimbBreaks[limbKey] or 3) then return end

	timer.Simple(0.1, function()
		if not IsValid(ent) then return end

		local rag = ent:GetNWEntity("RagdollDeath")
		if not IsValid(rag) then rag = ent:GetNWEntity("FakeRagdoll") end
		if not IsValid(rag) and IsValid(ent.FakeRagdoll) then rag = ent.FakeRagdoll end
		if not IsValid(rag) then rag = ent end

		-- Only apply to ragdolls
		if not rag:IsRagdoll() then return end

		local segments = limbBoneSegments[limbKey]
		if not segments then return end

		-- Select a segment that isn't already broken
		local randomSegment
		local availableSegments = {}
		for i = 1, #segments do
			if not table.HasValue(ent.brokenLimbSegments[limbKey], i) then
				table.insert(availableSegments, i)
			end
		end

		if #availableSegments == 0 then return end -- No more segments to break

		if segmentOverride and table.HasValue(availableSegments, segmentOverride) then
			randomSegment = segmentOverride
		else
			randomSegment = table.Random(availableSegments)
		end

		if not randomSegment then return end

		local selectedSegment = segments[randomSegment]
		
		-- save chosen segment on player for persistence
		if IsValid(ent) and ent:IsPlayer() then
			table.insert(ent.brokenLimbSegments[limbKey], randomSegment)
			ent.HG_FloppyPersistSeg = ent.HG_FloppyPersistSeg or {}
			ent.HG_FloppyPersistSeg[limbKey] = ent.brokenLimbSegments[limbKey]
		end

		if selectedSegment then
			local bone1Name, bone2Name = selectedSegment[1], selectedSegment[2]
			
			-- Check if bones exist before creating constraint
			local bone1 = rag:LookupBone(bone1Name)
			local bone2 = rag:LookupBone(bone2Name)
			if not bone1 or not bone2 then return end
			
			-- Check if physics objects are valid
			local phys1 = rag:TranslateBoneToPhysBone(bone1)
			local phys2 = rag:TranslateBoneToPhysBone(bone2)
			if not phys1 or not phys2 or phys1 < 0 or phys2 < 0 then return end
			
			local physObj1 = rag:GetPhysicsObjectNum(phys1)
			local physObj2 = rag:GetPhysicsObjectNum(phys2)
			if not IsValid(physObj1) or not IsValid(physObj2) then return end
			
			local cons = createFloppyLimbConstraint(rag, bone1Name, bone2Name, limbKey)
			
			if cons then
				-- Store which limb segment is floppy for healing restoration
				rag.floppyLimbs = rag.floppyLimbs or {}
				rag.floppyLimbs[limbKey] = rag.floppyLimbs[limbKey] or {}
				rag.floppyLimbs[limbKey][randomSegment] = {
					segment = randomSegment,
					bone1 = bone1Name,
					bone2 = bone2Name,
					constraint = cons
				}
			end
		end
	end)
end

-- Standing manipulation removed by request

-- Function to restore normal limb constraints (for healing)
function hg.organism.restoreLimbConstraints(rag, limbKey)
    if IsValid(rag) and rag:IsRagdoll() and rag.floppyLimbs and rag.floppyLimbs[limbKey] then
        for segment, floppyData in pairs(rag.floppyLimbs[limbKey]) do
            local bone1 = rag:LookupBone(floppyData.bone1)
            if bone1 then
                local phys1 = rag:TranslateBoneToPhysBone(bone1)
                if phys1 then
                    -- remove floppy constraint
                    pcall(function() rag:RemoveInternalConstraint(phys1) end)
                    if IsValid(floppyData.constraint) then floppyData.constraint:Remove() end
                end
            end
        end
        rag.floppyLimbs[limbKey] = nil
        
        local ent = rag:GetOwner()
        if IsValid(ent) and ent:IsPlayer() and ent.brokenLimbSegments then
            ent.brokenLimbSegments[limbKey] = {}
        end
    end
end

-- Function to create a floppy spine constraint
local function createFloppySpineConstraint(rag, bone1Name, bone2Name)
    if not IsValid(rag) or not rag:IsRagdoll() then return false end

    local bone1 = rag:LookupBone(bone1Name)
    local bone2 = rag:LookupBone(bone2Name)
    if not bone1 or not bone2 then return false end

    local phys1 = rag:TranslateBoneToPhysBone(bone1)
    local phys2 = rag:TranslateBoneToPhysBone(bone2)
    if not phys1 or not phys2 or phys1 < 0 or phys2 < 0 then return false end

    local pBone1 = rag:GetPhysicsObjectNum(phys1)
    local pBone2 = rag:GetPhysicsObjectNum(phys2)
    if not (IsValid(pBone1) and IsValid(pBone2)) then return false end

    -- Remove existing rigid constraint
    pcall(function() rag:RemoveInternalConstraint(phys1) end)

    -- Create a moderately loose ballsocket for a floppy spine
    local lpos, lang = WorldToLocal(
        pBone1:GetPos() + pBone1:GetAngles():Forward() * -1.5 + pBone1:GetAngles():Up() * -1,
        angle_zero,
        pBone2:GetPos(),
        pBone2:GetAngles()
    )

    constraint.AdvBallsocket(
        rag, rag,
        phys2, phys1,
        lpos, nil,
        0, 0,
        -45, -45, -45,
        45, 45, 45,
        0, 0, 0,
        0, 0
    )

    return true
end

-- Function to apply floppy effect to the spine
local function applySpineFloppyEffect(ent)
    if not IsValid(ent) then return end

    timer.Simple(0.1, function()
        if not IsValid(ent) then return end

        local rag = ent:GetNWEntity("RagdollDeath")
        if not IsValid(rag) then rag = ent end
        if not rag:IsRagdoll() then return end

        -- Apply to spine2-spine1 connection
        local success = createFloppySpineConstraint(rag, "ValveBiped.Bip01_Spine2", "ValveBiped.Bip01_Spine1")
        if success then
            rag.floppySpine = true
        end
    end)
end

-- Function to restore spine constraints
function hg.organism.restoreSpineConstraints(rag)
    if IsValid(rag) and rag:IsRagdoll() and rag.floppySpine then
        local bone1 = rag:LookupBone("ValveBiped.Bip01_Spine2")
        local phys1 = rag:TranslateBoneToPhysBone(bone1)
        if phys1 then
            pcall(function() rag:RemoveInternalConstraint(phys1) end)
        end
        rag.floppySpine = false
    end
end


-- Function to create a floppy neck constraint
local function createFloppyNeckConstraint(rag)
    if not IsValid(rag) or not rag:IsRagdoll() then return false end

    local headBone = rag:LookupBone("ValveBiped.Bip01_Head1")
    local spineBone = rag:LookupBone("ValveBiped.Bip01_Spine2")
    if not headBone or not spineBone then return false end

    local headPhys = rag:TranslateBoneToPhysBone(headBone)
    local spinePhys = rag:TranslateBoneToPhysBone(spineBone)
    if not headPhys or not spinePhys or headPhys < 0 or spinePhys < 0 then return false end

    local pHead = rag:GetPhysicsObjectNum(headPhys)
    local pSpine = rag:GetPhysicsObjectNum(spinePhys)
    if not (IsValid(pHead) and IsValid(pSpine)) then return false end

    -- Remove existing rigid constraint
    pcall(function() rag:RemoveInternalConstraint(headPhys) end)

    -- Create a very loose ballsocket for a floppy neck
    local lpos, lang = WorldToLocal(
        pHead:GetPos() + pHead:GetAngles():Forward() * -2 + pHead:GetAngles():Up() * -1.5,
        angle_zero,
        pSpine:GetPos(),
        pSpine:GetAngles()
    )

    constraint.AdvBallsocket(
        rag, rag,
        spinePhys, headPhys,
        lpos, nil,
        0, 0,
        -55, -90, -50,
        55, 35, 50,
        0, 0, 0,
        0, 0
    )

    return true
end

-- Function to apply floppy effect to the neck
local function applyNeckFloppyEffect(ent)
    if not IsValid(ent) then return end

    timer.Simple(0.1, function()
        if not IsValid(ent) then return end

        local rag = ent:GetNWEntity("RagdollDeath")
        if not IsValid(rag) then rag = ent end
        if not rag:IsRagdoll() then return end

        local success = createFloppyNeckConstraint(rag)
        if success then
            rag.floppyNeck = true
        end
    end)
end

-- Function to restore neck constraints
function hg.organism.restoreNeckConstraints(rag)
    if IsValid(rag) and rag:IsRagdoll() and rag.floppyNeck then
        local headBone = rag:LookupBone("ValveBiped.Bip01_Head1")
        local headPhys = rag:TranslateBoneToPhysBone(headBone)
        if headPhys then
            pcall(function() rag:RemoveInternalConstraint(headPhys) end)
        end
        rag.floppyNeck = false
    end
end




local colred = Color(255, 0, 0)

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
	["spine1"] = "I cant feel my legs...",
	["spine2"] = "I cant feel my arms...",
	["spine3"] = "I cant move my body...",
	["skull"] = "MY HEAD HURTS REAL BAD...",
}

local broke_arm = {
	"AAAAH OH GOD, IT'S BROKEN! MY ARM! IT'S BROKEN!",
	"FUCK MY FUCKING ARM IS BROKEN!",
	"NONONO MY ARM IS BENT ALL WRONG!",
	"IT'S.. MY ARM.. SNAPPED- I HEARD IT SNAP!",
	"MY ARM IS NOT SUPPOSED TO BEND IN HALF!",
}

local broke_arm_gruesome = {
	"MY ARM- OH GOD, IT'S- SHATTERED!",
	"I CAN SEE THE BONE- IT'S POKING OUT!",
	"IT'S SHATTERED- MY ARM IS SHATTERED!",
}

local broke_leg_gruesome = {
	"MY LEG- IT'S- IT'S MANGLED!",
	"THE BONE- IT'S STICKING OUT OF MY LEG!",
	"MY LEG IS- IT'S DESTROYED!",
}

local dislocated_arm_gruesome = {
	"MY ARM- IT'S- IT'S COMPLETELY WRECKED!",
	"THE JOINT IS- IT'S TORN APART!",
	"I CAN'T- I CAN'T MOVE IT! IT'S JUST- DANGLING!",
}

local dislocated_leg_gruesome = {
	"MY LEG- IT'S- IT'S BEYOND BROKEN!",
	"THE JOINT- IT'S- IT'S GONE!",
	"I CAN'T- I CAN'T FEEL MY LEG!",
}

local dislocated_arm = {
	"MY ARM- GOD, IT'S POPPED OUT OF THE SOCKET!",
	"ITS STRETCHED OUT OF THE SOCKET...",
	"MY ARM..! IT'S DISLOCATED! I CAN SEE THE BULGE WHERE IT'S WRONG!",
	"MY ARM- ITS NOT ATTACHED RIGHT!",
	"I CAN SEE THE BULGE WHERE MY ARM IS WRONG!",
}

local broke_leg = {
	"MY LEG- MY LEG HURTS SO BAD",
	"I CAN'T MOVE MY FOOT- THE ANKLE'S BROKEN TOO!",
	"AAAGH- ILL NEVER BE ABLE TO WALK RIGHT AGAIN!",
	"FUCK ME- MY LEG IS SPLIT IN TWO!",
	"MY LEG! ITS PAINING REAL BAD!",
	"JESUS CHRIST- I CAN SEE THE BONE!",
}

local dislocated_leg = {
	"MY LEG ISNT SUPPOSED TO DO THAT!",
	"I CAN SEE THE KNEECAP IN THE WRONG PLACE!",
	"AGHH- THE HIP'S POPPED OUT- IT'S STUCK OUTWARD!",
	"IT BENT- ITS BENT REAL BAD!",
	"MY LEG IS TWISTED WRONG!",
	"OH GOD- I CAN SEE THE BULGE WHERE ITS WRONG!",
}

local dismember_leg = {
	"OH MY GOD- I CAN SEE THE BONE!",
	"ITS BLEEDING- ITS BLEEDING SO MUCH",
	"I CANT FEEL MY LEG",
	"MY LEG... ITS JUST GONE...",
	"FUUUCK- ILL NEVER BE ABLE TO WALK AGAIN!",
	"ITS MISSING- WHERE IS MY LEG?",
}

local dismember_arm = {
	"MY ARM- MY ARM IS GONE",
	"I CANT FEEL MY ARM, ITS JUST FUCKING GONE",
	"MY ARM IS BLEEDING- ITS BLEEDING A LOT",
	"IT HURTS... IT HURTS SO MUCH",
	"AAAAGH MY ARM",
	"JESUS CHRIST, MY ARM IS MISSING!",
}

-- Gruesome accident system for catastrophic multi-bone breaks
local function trackBoneBreak(org, boneKey)
	-- Initialize tracking if not present
	org.recentBoneBreaks = org.recentBoneBreaks or {}
	
	-- Add current bone break with timestamp
	table.insert(org.recentBoneBreaks, {
		bone = boneKey,
		time = CurTime()
	})
	
	-- Clean old entries (older than 5 seconds)
	local currentTime = CurTime()
	for i = #org.recentBoneBreaks, 1, -1 do
		if currentTime - org.recentBoneBreaks[i].time > 5 then
			table.remove(org.recentBoneBreaks, i)
		end
	end
end

local function checkForGruesomeAccident(org)
	if not org.recentBoneBreaks then return false end
	
	local currentTime = CurTime()
	local recentBreaks = {}
	local hasNeckBreak = false
	
	-- Count recent breaks (within last 4 seconds)
	for _, breakData in ipairs(org.recentBoneBreaks) do
		if currentTime - breakData.time <= 4 then
			table.insert(recentBreaks, breakData.bone)
			if breakData.bone == "spine3" then
				hasNeckBreak = true
			end
		end
	end
	
	-- Check for gruesome accident: 3+ bones broken + neck break
	if #recentBreaks >= 3 and hasNeckBreak then
		org.gruesomeAccident = true
		org.gruesomeAccidentTime = currentTime
		
		-- Sounds removed - keeping only neck snap
		
		return true
	end
	
	return false
end

local function createGruesomeFloppyConstraint(rag, bone1Name, bone2Name, limbKey)
	local bone1 = rag:LookupBone(bone1Name)
	local bone2 = rag:LookupBone(bone2Name)
	if not bone1 or not bone2 then return false end

	local phys1 = rag:TranslateBoneToPhysBone(bone1)
	local phys2 = rag:TranslateBoneToPhysBone(bone2)
	if not phys1 or not phys2 then return false end

	local p1 = rag:GetPhysicsObjectNum(phys1)
	local p2 = rag:GetPhysicsObjectNum(phys2)
	if not (IsValid(p1) and IsValid(p2)) then return false end

	-- Remove existing rigid constraint
	pcall(function() rag:RemoveInternalConstraint(phys1) end)

	-- Reposition bones for natural constraint alignment (reduced offset for more realistic positioning)
	local posOffset = p2:GetAngles():Forward() * 4 + p2:GetAngles():Right() * math.Rand(-0.5, 0.5)
	if limbKey == "larm" or limbKey == "rarm" then
		posOffset = p2:GetAngles():Forward() * 3 + p2:GetAngles():Right() * 0.3
	elseif limbKey == "lleg" or limbKey == "rleg" then
		posOffset = p2:GetAngles():Forward() * 5 + p2:GetAngles():Up() * 0.5
	end
	p1:SetPos(p2:GetPos() + posOffset)

	-- Create moderately floppy constraint for gruesome accidents (more realistic than before)
	local lpos, lang = WorldToLocal(
		p1:GetPos() + p1:GetAngles():Forward() * -0.8 + p1:GetAngles():Up() * -0.3,
		angle_zero,
		p2:GetPos(),
		p2:GetAngles()
	)

	-- More realistic constraints - still damaged but not completely disconnected
	local minX, minY, minZ = -25, -35, -20
	local maxX, maxY, maxZ = 25, 15, 20

	-- Adjust constraints based on limb type for more realistic movement
	if limbKey == "larm" or limbKey == "rarm" then
		-- Arms: allow more forward/backward movement but limit side-to-side
		minX, maxX = -20, 20
		minY, maxY = -30, 10
		minZ, maxZ = -15, 15
	elseif limbKey == "lleg" or limbKey == "rleg" then
		-- Legs: more restricted movement to simulate weight-bearing damage
		minX, maxX = -15, 15
		minY, maxY = -25, 8
		minZ, maxZ = -12, 12
	end

	constraint.AdvBallsocket(
		rag, rag,
		phys2, phys1,
		lpos, nil,
		0, 0,
		minX, minY, minZ,
		maxX, maxY, maxZ,
		0, 0, 0,
		0, 0
	)

	return true
end

local function applyGruesomeFloppiness(ent, limbKey)
	if not IsValid(ent) then return end
	
	timer.Simple(0.1, function()
		if not IsValid(ent) then return end

		local rag = ent:GetNWEntity("RagdollDeath")
		if not IsValid(rag) then rag = ent end

		-- Only apply to ragdolls
		if not rag:IsRagdoll() then return end

		local segments = limbBoneSegments[limbKey]
		if not segments then return end

		-- Randomly select which segment becomes floppy (1-3)
		local randomSegment = math.random(1, 3)
		local selectedSegment = segments[randomSegment]
		
		if selectedSegment then
			local bone1Name, bone2Name = selectedSegment[1], selectedSegment[2]
			local success = createGruesomeFloppyConstraint(rag, bone1Name, bone2Name, limbKey)
			
			if success then
				-- Store which limb segment is floppy for healing restoration
				rag.floppyLimbs = rag.floppyLimbs or {}
				rag.floppyLimbs[limbKey] = {
					segment = randomSegment,
					bone1 = bone1Name,
					bone2 = bone2Name,
					gruesome = true -- Mark as gruesome accident
				}
				
				-- Sounds removed - keeping only neck snap
			end
		end
	end)
end

-- Function to clean up gruesome accident data
local function cleanupGruesomeAccident(org)
	if org.gruesomeAccident and org.gruesomeAccidentTime then
		-- Clear gruesome accident flag after 10 seconds
		if CurTime() - org.gruesomeAccidentTime > 10 then
			org.gruesomeAccident = false
		end
	end
end

local function legs(org, bone, dmg, dmgInfo, key, boneindex, dir, hit, ricochet)
    if org.lastBoneHitTime and org.lastBoneHitTime[key] and (CurTime() - org.lastBoneHitTime[key] < 2) then
        dmg = dmg * 1.5

        if org[key.."gruesome"] then
            org[key.."_perm_dmg"] = math.min((org[key.."_perm_dmg"] or 0) + 0.1, 1)
            if org.isPly then
                hg.CreateNotification(org.owner, "The damage to your " .. string.gsub(key, "l", "left "):gsub("r", "right ") .. " has worsened!", 3, colred)
            end
        end
    end

    if not org.lastBoneHitTime then
        org.lastBoneHitTime = {}
    end
    org.lastBoneHitTime[key] = CurTime()

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
		if not org.betaBlock or CurTime() > org.betaBlock then
			org.owner:AddNaturalAdrenaline(1)
		end
		org.immobilization = org.immobilization + dmg * 25
		org.fearadd = org.fearadd + 0.5

		-- oooooooooooooooooowwww
		if org.isPly then
			local break_key = key .. "_breaks"
			local limb_gruesome = key .. "_gruesome"
			local current_breaks = org[break_key] or 0
            local max_breaks = maxLimbBreaks[key] or 1

			if org[key.."amputated"] then
				if hg.CreateNotification then hg.CreateNotification(org.owner, dismember_leg[math.random(#dismember_leg)], 3, colred) end
			elseif org[limb_gruesome] then
				if hg.CreateNotification then hg.CreateNotification(org.owner, broke_leg_gruesome[math.random(#broke_leg_gruesome)], 3, colred) end
			else
				if current_breaks < max_breaks then
					org[break_key] = current_breaks + 1
					if hg.CreateNotification then hg.CreateNotification(org.owner, broke_leg[math.random(#broke_leg)] .. " (" .. org[break_key] .. "/" .. max_breaks .. ")", 3, colred) end
				
					if org[break_key] == max_breaks then
						org[limb_gruesome] = true
						if hg.CreateNotification then hg.CreateNotification(org.owner, broke_leg_gruesome[math.random(#broke_leg_gruesome)], 3, colred) end
					end
				else
					if hg.CreateNotification then hg.CreateNotification(org.owner, broke_leg[math.random(#broke_leg)], 3, colred) end
				end
			end
		end
		
		-- Gruesome fracture logic
		if dmg > 1.5 or (oldDmg > 0.8 and dmg > 0.5) then
			if GetConVar("hg_isshitworking"):GetBool() then PrintMessage(HUD_PRINTTALK, "Gruesome Fracture: " .. key) end
			org.painadd = org.painadd + 40
			org.immobilization = org.immobilization + 20
			org[key.."gruesome"] = true
			org[key.."_perm_dmg"] = math.min((org[key.."_perm_dmg"] or 0) + 0.05, 1)
			hg.organism.AddBleed(org, org.owner:GetBoneMatrix(boneindex):GetTranslation(), 5, 15)
			
			if org.isPly then
				if hg.CreateNotification then hg.CreateNotification(org.owner, broke_leg_gruesome[math.random(#broke_leg_gruesome)], 3, colred) end

				org.owner:EmitSound("owfuck"..math.random(1,4)..".ogg", 75, 100, 1, CHAN_AUTO) -- Fallback handled if missing
                
                -- Red flash
                net.Start("AddFlash")
                net.WriteVector(org.owner:EyePos())
                net.WriteFloat(0.5)
                net.WriteInt(50, 20)
                net.WriteColor(Color(255, 0, 0))
                net.WriteString("sprites/light_glow02_add")
                net.Send(org.owner)
			end
		end

		timer.Simple(0, function() hg.LightStunPlayer(org.owner,2) end)
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
        trackBoneBreak(org, key)
        if checkForGruesomeAccident(org) then
            local currentTime = CurTime()
            if org.recentBoneBreaks then
                for _, breakData in ipairs(org.recentBoneBreaks) do
                    if currentTime - breakData.time <= 4 then
                        applyGruesomeFloppiness(org.owner, breakData.bone)
                    end
                end
            end
        else
            if not org.owner.brokenLimbSegments then org.owner.brokenLimbSegments = {} end
            if table.Count(org.owner.brokenLimbSegments[key] or {}) < (maxLimbBreaks[key] or 3) then
                applyLimbFloppyEffect(org.owner, key)
            end
        end
		//broken
	else
		//org[key] = 0.5
		org[key.."dislocation"] = true

		org.painadd = org.painadd + 35
		if not org.betaBlock or CurTime() > org.betaBlock then
			org.owner:AddNaturalAdrenaline(0.5)
		end
		org.immobilization = org.immobilization + dmg * 10
		org.fearadd = org.fearadd + 0.5

		if org.isPly and !org[key.."amputated"] then
			if org[key.."gruesome_dislocation"] then
				if hg.CreateNotification then hg.CreateNotification(org.owner, dislocated_leg_gruesome[math.random(#dislocated_leg_gruesome)], 3, colred) end
			else
				if hg.CreateNotification then hg.CreateNotification(org.owner, dislocated_leg[math.random(#dislocated_leg)], 3, colred) end
			end
		end
		
		-- Gruesome dislocation logic
		if dmg > 0.8 then
			if GetConVar("hg_isshitworking"):GetBool() then PrintMessage(HUD_PRINTTALK, "Gruesome Dislocation: " .. key) end
			org.painadd = org.painadd + 20
			org.immobilization = org.immobilization + 15
			org[key.."gruesome_dislocation"] = true
			org[key.."_perm_dmg"] = math.min((org[key.."_perm_dmg"] or 0) + 0.01, 1)
			hg.organism.AddBleed(org, org.owner:GetBoneMatrix(boneindex):GetTranslation(), 5, 15)
			
			if org.isPly then
				org.owner:EmitSound("disloc"..math.random(1,2)..".ogg", 75, 100, 1, CHAN_AUTO) -- Fallback handled if missing
                
                -- Red flash
                net.Start("AddFlash")
                net.WriteVector(org.owner:EyePos())
                net.WriteFloat(0.4)
                net.WriteInt(40, 20)
                net.WriteColor(Color(255, 0, 0))
                net.WriteString("sprites/light_glow02_add")
                net.Send(org.owner)
			end
		end

		timer.Simple(0, function() hg.LightStunPlayer(org.owner,2) end)
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
        trackBoneBreak(org, key)
        if checkForGruesomeAccident(org) then
            local currentTime = CurTime()
            if org.recentBoneBreaks then
                for _, breakData in ipairs(org.recentBoneBreaks) do
                    if currentTime - breakData.time <= 4 then
                        applyGruesomeFloppiness(org.owner, breakData.bone)
                    end
                end
            end
        else
            if table.Count(org.owner.brokenLimbSegments[key] or {}) < (maxLimbBreaks[key] or 3) then
                applyLimbFloppyEffect(org.owner, key)
            end
        end
		//dislocated
	end

	hg.AddHarmToAttacker(dmgInfo, (org[key] - oldDmg) * 2, "Legs bone damage harm")

	return result, vecrand
end

local function arms(org, bone, dmg, dmgInfo, key, boneindex, dir, hit, ricochet)
    if org.lastBoneHitTime and org.lastBoneHitTime[key] and (CurTime() - org.lastBoneHitTime[key] < 2) then
        dmg = dmg * 1.5

        if org[key.."gruesome"] then
            org[key.."_perm_dmg"] = math.min((org[key.."_perm_dmg"] or 0) + 0.1, 1)
            if org.isPly then
                hg.CreateNotification(org.owner, "The damage to your " .. string.gsub(key, "l", "left "):gsub("r", "right ") .. " has worsened!", 3, colred)
            end
        end
    end

    if not org.lastBoneHitTime then
        org.lastBoneHitTime = {}
    end
    org.lastBoneHitTime[key] = CurTime()

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
		if not org.betaBlock or CurTime() > org.betaBlock then
			org.owner:AddNaturalAdrenaline(1)
		end
		org.fearadd = org.fearadd + 0.5


		if org.isPly then
			local break_key = key .. "_breaks"
			local limb_gruesome = key .. "_gruesome"
			local current_breaks = org[break_key] or 0
            local max_breaks = maxLimbBreaks[key] or 1

			if org[key.."amputated"] then
				if hg.CreateNotification then hg.CreateNotification(org.owner, dismember_arm[math.random(#dismember_arm)], 3, colred) end
			elseif org[limb_gruesome] then
				if hg.CreateNotification then hg.CreateNotification(org.owner, broke_arm_gruesome[math.random(#broke_arm_gruesome)], 3, colred) end
			else
				if current_breaks < max_breaks then
					org[break_key] = current_breaks + 1
					if hg.CreateNotification then hg.CreateNotification(org.owner, broke_arm[math.random(#broke_arm)] .. " (" .. org[break_key] .. "/" .. max_breaks .. ")", 3, colred) end
				
					if org[break_key] == max_breaks then
						org[limb_gruesome] = true
						if hg.CreateNotification then hg.CreateNotification(org.owner, broke_arm_gruesome[math.random(#broke_arm_gruesome)], 3, colred) end
					end
				else
					if hg.CreateNotification then hg.CreateNotification(org.owner, broke_arm[math.random(#broke_arm)], 3, colred) end
				end
			end
		end

		-- Gruesome fracture logic
		if dmg > 1.5 or (oldDmg > 0.8 and dmg > 0.5) then
			org.painadd = org.painadd + 40
			org[key.."gruesome"] = true
			org[key.."_perm_dmg"] = math.min((org[key.."_perm_dmg"] or 0) + 0.05, 1)
			hg.organism.AddBleed(org, org.owner:GetBoneMatrix(boneindex):GetTranslation(), 5, 15)
			
			if org.isPly then
				if hg.CreateNotification then hg.CreateNotification(org.owner, broke_arm_gruesome[math.random(#broke_arm_gruesome)], 3, colred) end
				org.owner:EmitSound("owfuck"..math.random(1,4)..".ogg", 75, 100, 1, CHAN_AUTO)
                
                -- Red flash
                net.Start("AddFlash")
                net.WriteVector(org.owner:EyePos())
                net.WriteFloat(0.5)
                net.WriteInt(50, 20)
                net.WriteColor(Color(255, 0, 0))
                net.WriteString("sprites/light_glow02_add")
                net.Send(org.owner)
			end
		end

		--timer.Simple(0, function() hg.LightStunPlayer(org.owner,1) end)
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
        trackBoneBreak(org, key)
        if checkForGruesomeAccident(org) then
            local currentTime = CurTime()
            if org.recentBoneBreaks then
                for _, breakData in ipairs(org.recentBoneBreaks) do
                    if currentTime - breakData.time <= 4 then
                        applyGruesomeFloppiness(org.owner, breakData.bone)
                    end
                end
            end
        else
            if table.Count(org.owner.brokenLimbSegments[key] or {}) < (maxLimbBreaks[key] or 3) then
                applyLimbFloppyEffect(org.owner, key)
            end
        end
		//broken
	else
		org[key.."dislocation"] = true
		//org[key] = 0.5

		org.painadd = org.painadd + 35
		if not org.betaBlock or CurTime() > org.betaBlock then
			org.owner:AddNaturalAdrenaline(0.5)
		end
		org.fearadd = org.fearadd + 0.5

		if org.isPly and !org[key.."amputated"] then
			if org[key.."gruesome_dislocation"] then
				if hg.CreateNotification then hg.CreateNotification(org.owner, dislocated_arm_gruesome[math.random(#dislocated_arm_gruesome)], 3, colred) end
			else
				if hg.CreateNotification then hg.CreateNotification(org.owner, dislocated_arm[math.random(#dislocated_arm)], 3, colred) end
			end
		end

		-- Gruesome dislocation logic
		if dmg > 0.8 then
			org.painadd = org.painadd + 20
			org.immobilization = org.immobilization + 15
			org[key.."gruesome_dislocation"] = true
			org[key.."_perm_dmg"] = math.min((org[key.."_perm_dmg"] or 0) + 0.01, 1)
			hg.organism.AddBleed(org, org.owner:GetBoneMatrix(boneindex):GetTranslation(), 5, 15)
			
			if org.isPly then
				org.owner:EmitSound("disloc"..math.random(1,2)..".ogg", 75, 100, 1, CHAN_AUTO)

                -- Red flash
                net.Start("AddFlash")
                net.WriteVector(org.owner:EyePos())
                net.WriteFloat(0.4)
                net.WriteInt(40, 20)
                net.WriteColor(Color(255, 0, 0))
                net.WriteString("sprites/light_glow02_add")
                net.Send(org.owner)
			end
		end

		--timer.Simple(0, function() hg.LightStunPlayer(org.owner,1) end)
		org.owner:EmitSound("bones/bone"..math.random(8)..".mp3", 75, 100, 1, CHAN_AUTO)
        trackBoneBreak(org, key)
        if checkForGruesomeAccident(org) then
            local currentTime = CurTime()
            if org.recentBoneBreaks then
                for _, breakData in ipairs(org.recentBoneBreaks) do
                    if currentTime - breakData.time <= 4 then
                        applyGruesomeFloppiness(org.owner, breakData.bone)
                    end
                end
            end
        else
            if table.Count(org.owner.brokenLimbSegments[key] or {}) < (maxLimbBreaks[key] or 3) then
                applyLimbFloppyEffect(org.owner, key)
            end
        end
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
		if name == "spine3" then
			applyNeckFloppyEffect(org.owner)
		end
		if name == "spine1" or name == "spine2" then
			applySpineFloppyEffect(org.owner)
		end
		if org.owner:IsPlayer() then
			org.owner:Notify(huyasd[name], true, name, 2)
		end
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

	if org.jaw == 1 and (org.jaw - oldDmg) > 0 and org.isPly then
		if hg.CreateNotification then hg.CreateNotification(org.owner, jaw_broken_msg[math.random(#jaw_broken_msg)], true, "jaw", 2) end
		net.Start("headtrauma_flash")
		net.Send(org.owner)
		applyJawPose(org.owner)
	end

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
		if hg.CreateNotification then hg.CreateNotification(output, "My jaw is really hurting when I speak.", true, "painfromjawspeak", 4, nil, Color(255, 210, 210)) end
	end
end)

input_list.skull = function(org, bone, dmg, dmgInfo, boneindex, dir, hit, ricochet)
	if dmgInfo:IsDamageType(DMG_BURN) or dmgInfo:IsDamageType(DMG_SLOWBURN) then return 0 end
    local oldDmg = org.skull
    local rawDmg = dmg
    local isBullet = dmgInfo:IsDamageType(DMG_BULLET) or dmgInfo:IsDamageType(DMG_BUCKSHOT)
    local isSlash = dmgInfo:IsDamageType(DMG_SLASH)
    local isCrush = dmgInfo:IsDamageType(DMG_CRUSH) or dmgInfo:IsDamageType(DMG_CLUB) or dmgInfo:IsDamageType(DMG_GENERIC)

    if isSlash then
        dmg = dmg * 0.6
    end

    -- Check for frontal hit
    local isFrontal = false
    local eyeL_hit = false
    local eyeR_hit = false
    local nose_hit = false
    local hitPos = hit or dmgInfo:GetDamagePosition()

    if IsValid(org.owner) then
        local headBone = org.owner:LookupBone("ValveBiped.Bip01_Head1")
        if headBone then
            local headTrans = org.owner:GetBoneMatrix(headBone)
            if headTrans then
                local headPos = headTrans:GetTranslation()
                local headAng = headTrans:GetAngles()
                local headFwd = headAng:Forward()
                
                local dmgDir = dir or dmgInfo:GetDamageForce():GetNormalized()
                if headFwd:Dot(dmgDir) < -0.2 then isFrontal = true end

                -- Precise Hitbox Logic (Simulated)
                -- Offsets approximate standard human head proportions
                local eyeL_pos = headPos + headFwd * 3.5 + headAng:Right() * -1.3 + headAng:Up() * 0.5
                local eyeR_pos = headPos + headFwd * 3.5 + headAng:Right() * 1.3 + headAng:Up() * 0.5
                local nose_pos = headPos + headFwd * 4.2 + headAng:Up() * -0.5

                if hitPos:DistToSqr(eyeL_pos) < 2.5 then eyeL_hit = true end
                if hitPos:DistToSqr(eyeR_pos) < 2.5 then eyeR_hit = true end
                if hitPos:DistToSqr(nose_pos) < 2 then nose_hit = true end
            end
        end
    end

    local boneMul = isSlash and 0.35 or 0.25
    local result, vecrand = damageBone(org, boneMul, dmg, dmgInfo, "skull", boneindex, dir, hit, ricochet)

	hg.AddHarmToAttacker(dmgInfo, (org.skull - oldDmg) * 4, "Skull bone damage harm")

    -- Eyes and Nose Logic (Prone to crush/slash, bypass skull protection)
    local eyeChance = 0
    local noseChance = 0

    if isSlash then
        eyeChance = isFrontal and 90 or 30 -- Prone to slash
        noseChance = isFrontal and 60 or 10
    elseif isBullet then
        eyeChance = isFrontal and 50 or 20
        noseChance = isFrontal and 40 or 10
    elseif isCrush then
        eyeChance = isFrontal and 30 or 10 -- Less prone to crush
        noseChance = isFrontal and 90 or 30 -- Prone to crush
    end

    -- Apply precise hits first
    if eyeL_hit then
        local eyeFunc = hg.organism.input_list["eyeL"]
        if eyeFunc then eyeFunc(org, 1, rawDmg, dmgInfo) end
    end
    
    if eyeR_hit then
        local eyeFunc = hg.organism.input_list["eyeR"]
        if eyeFunc then eyeFunc(org, 1, rawDmg, dmgInfo) end
    end

    if nose_hit then
        local noseFunc = hg.organism.input_list["nose"]
        if noseFunc then noseFunc(org, 1, rawDmg, dmgInfo) end
    end

    -- Random chance (only if not precisely hit)
    if !eyeL_hit and !eyeR_hit and eyeChance > 0 and math.random(100) <= eyeChance then
        local which = (math.random(2) == 1) and "eyeL" or "eyeR"
        local eyeFunc = hg.organism.input_list[which]
        if eyeFunc then eyeFunc(org, 1, rawDmg, dmgInfo) end 
    end

    if !nose_hit and noseChance > 0 and math.random(100) <= noseChance then
        local noseFunc = hg.organism.input_list["nose"]
        if noseFunc then noseFunc(org, 1, rawDmg, dmgInfo) end 
    end

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

			net.Start("headtrauma_flash")
			net.Send(org.owner)
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


    if (org.skull - oldDmg) > 0.01 or dmg > 0.01 then 

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


	return result,vecrand
end

local ribs = {
	"One of my ribs is definitively broken.",
	"My chest is missing a rib.",
	"I think i broke something inside...",
	"Shit... My chest is snapped.",
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
			if hg.CreateNotification then hg.CreateNotification(org.owner, ribs[math.random(#ribs)], 5, "ribs", 4) end

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
		if hg.CreateNotification then hg.CreateNotification(org.owner, "Ohh fuck... I think my pelvis is broken.", true, "pelvis", 4) end
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