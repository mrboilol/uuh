-- arghahghahaha randgdol tumbel melecity so tuff
local player_GetAll = player.GetAll
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local IsValid = IsValid
local CurTime = CurTime

local TUMBLE_SPEED_THRESHOLD = 250
local TUMBLE_COOLDOWN = 2
local GAP_CHECK_DIST = 50 
local WALL_CHECK_DIST = 20
local WALL_CHECK_HEIGHT = 10 

local BASE_TRIP_CHANCE = 0.1
local MAX_TRIP_CHANCE = 0.8

hook.Add("Think", "stanleytumbler", function()
    for _, ply in ipairs(player_GetAll()) do
        if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then continue end
        
        if IsValid(ply.FakeRagdoll) then continue end
        
        if ply:GetMoveType() == MOVETYPE_NOCLIP or not ply:IsOnGround() then continue end

        if (ply.nextTumbleCheck or 0) > CurTime() then continue end
        ply.nextTumbleCheck = CurTime() + 0.1
        local velocity = ply:GetVelocity()
        local speed = velocity:Length2D()
        local org = ply.organism or {}
        local consciousness = org.consciousness or 1
        local fear = org.fear or 0
        local stamina = org.stamina and org.stamina[1] or 100
        local effectiveThreshold = TUMBLE_SPEED_THRESHOLD
        effectiveThreshold = effectiveThreshold * math.Clamp(consciousness, 0.5, 1.0)
        
        if stamina < 20 then
            effectiveThreshold = effectiveThreshold * 0.8
        end

        ply.eyeAnglesOld = ply.eyeAnglesOld or ply:EyeAngles()
        local cosine = ply:EyeAngles():Forward():Dot(ply.eyeAnglesOld:Forward())
        ply.eyeAnglesOld = ply:EyeAngles()

        local isSlipping = false
        local tr = util.TraceLine({
            start = ply:GetPos(),
            endpos = ply:GetPos() - Vector(0,0,1),
            filter = ply
        })
        if tr.Hit and tr.SurfaceProps and util.GetSurfaceData(tr.SurfaceProps) and util.GetSurfaceData(tr.SurfaceProps).friction < 0.2 then
            isSlipping = true
        end

        if speed < effectiveThreshold and not isSlipping then continue end


        local speedExcess = math.max(0, speed - effectiveThreshold)
        local tripChance = BASE_TRIP_CHANCE + (speedExcess * 0.005)
        tripChance = tripChance + (1 - consciousness) * 0.5
        tripChance = tripChance + (math.Clamp(fear, 0, 100) / 100) * 0.2
        
        local shouldTrip = false
        local tripType = "none"
        local trHighHit = false

        if isSlipping or (speed > 200 and cosine <= 0.99) then
            shouldTrip = true
            tripType = "slip"
            tripChance = tripChance + 0.5
        end

        local forward = ply:GetAimVector()
        forward.z = 0
        forward:Normalize()

        local pos = ply:GetPos()

        local trWall = util_TraceHull({
            start = pos + Vector(0,0,5),
            endpos = pos + Vector(0,0,5) + forward * 20,
            mins = ply:OBBMins(),
            maxs = ply:OBBMaxs(),
            filter = ply,
            mask = MASK_PLAYERSOLID
        })

        if trWall.Hit then
             if trWall.HitNormal.z < 0.3 then
                 local ent = trWall.Entity
                 local isEntity = IsValid(ent) and (ent:IsPlayer() or ent:IsNPC() or ent:IsRagdoll())
                 
                 if isEntity then
                     tripType = "ragdoll"
                     shouldTrip = true
                     tripChance = tripChance + 0.5 
                 else
                     local highTraceHeight = 35
                     local trHigh = util_TraceLine({
                         start = pos + Vector(0,0,highTraceHeight),
                         endpos = pos + Vector(0,0,highTraceHeight) + forward * 30,
                         filter = ply,
                         mask = MASK_PLAYERSOLID
                     })
                     trHighHit = trHigh.Hit
                     
                     local speedFactor = math.Clamp((speed - 250) / 300, 0, 1)
                     
                     local wallChance = speedFactor
                     if not trHigh.Hit then
                         wallChance = wallChance * 0.1
                     end
                     
                     if wallChance > 0 then
                         shouldTrip = true
                         tripType = "wall"
                         tripChance = tripChance + wallChance
                     end
                 end
             end
        end

        if not shouldTrip then
            local checkPos = pos + forward * 30
            local trGround = util_TraceLine({
                start = checkPos + Vector(0,0,10),
                endpos = checkPos - Vector(0,0,GAP_CHECK_DIST),
                filter = ply,
                mask = MASK_SOLID
            })

            if not trGround.Hit then
                shouldTrip = true
                tripType = "gap"
                tripChance = tripChance + 0.2
            end
        end

        if org.superfighter then
            tripChance = tripChance * 0.1
        end

        if org.noradrenaline and org.noradrenaline > 0 then
            tripChance = tripChance * 0.1
        end
        if org.berserk and org.berserk > 0 then
            tripChance = tripChance * 0.1
        end
        if org.adrenaline and org.adrenaline > 0 then
            tripChance = tripChance * 0.75
        end

        tripChance = math.Clamp(tripChance, 0, MAX_TRIP_CHANCE)

        if shouldTrip then
            if math.random() < tripChance then
                hg.Fake(ply)
                --mcity reference?
                if not org.superfighter then
                    local breakChance = 0.05
                    local dislocationChance = 0.2

                    if math.random() < breakChance then
                        -- Limb break
                        ply:EmitSound("owfuck"..math.random(1, 4)..".ogg")
                        org.painadd = (org.painadd or 0) + 70 -- More pain for a break

                        if tripType == "wall" then
                            if trHighHit then
                                org.jaw = 1 -- Break jaw
                            else
                                if math.random(1, 2) == 1 then
                                    org.rleg = 1 -- Break right leg
                                else
                                    org.lleg = 1 -- Break left leg
                                end
                            end
                        elseif tripType == "ragdoll" then
                            if math.random(1, 2) == 1 then
                                org.rarm = 1 -- Break right arm
                            else
                                org.larm = 1 -- Break left arm
                            end
                        end
                    elseif math.random() < dislocationChance then
                        -- Limb dislocation
                        ply:EmitSound("disloc"..math.random(1, 2)..".wav")
                        org.painadd = (org.painadd or 0) + 35

                        if tripType == "wall" then
                            if trHighHit then
                                org.jawdislocation = true
                            else
                                if math.random(1, 2) == 1 then
                                    org.rlegdislocation = true
                                else
                                    org.llegdislocation = true
                                end
                            end
                        elseif tripType == "ragdoll" then
                            if math.random(1, 2) == 1 then
                                org.rarmdislocation = true
                            else
                                org.larmdislocation = true
                            end
                        end
                    end
                end
                
                local ragdoll = ply.FakeRagdoll
                if IsValid(ragdoll) then
                    local b1 = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_L_Calf"))
                    local phys1 = (hg.IdealMassPlayer and hg.IdealMassPlayer["ValveBiped.Bip01_L_Calf"]) or 7
                    local b2 = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_R_Calf"))
                    local phys2 = (hg.IdealMassPlayer and hg.IdealMassPlayer["ValveBiped.Bip01_R_Calf"]) or 7
                    local torso = ply:TranslateBoneToPhysBone(ply:LookupBone("ValveBiped.Bip01_Spine2"))
                    local phystorso = (hg.IdealMassPlayer and hg.IdealMassPlayer["ValveBiped.Bip01_Spine2"]) or 20

                    local force = velocity:GetNormalized() * 150
                    
                    local torsoForce = -force * 5 * phystorso
                    local legForce = (force * 5 - Vector(0,0,2)) * phys1

                    if tripType == "wall" then
                        torsoForce = torsoForce * 1.2
                        legForce = legForce * 0.8 
                    elseif tripType == "gap" then
                        legForce = legForce * 1.5
                    elseif tripType == "ragdoll" then
                         torsoForce = torsoForce * 0.5
                    end

                    hg.AddForceRag(ply, torso, torsoForce, 0.5)
                    hg.AddForceRag(ply, b1, legForce, 0.5)
                    hg.AddForceRag(ply, b2, legForce, 0.5)

                    timer.Simple(0, function()
                        if IsValid(ply) then hg.StunPlayer(ply) end
                    end)

                    local recoveryDelay = 2
                    if consciousness < 0.5 then recoveryDelay = 4 end
                    ply.fakecd = CurTime() + recoveryDelay
                end
                
                ply.nextTumbleCheck = CurTime() + TUMBLE_COOLDOWN
            else
                -- why not
                ply:ViewPunch(Angle(2, 0, 0))
                ply.nextTumbleCheck = CurTime() + 1 
            end
        end
    end
end)