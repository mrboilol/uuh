-- arghahghahaha randgdol tumbel melecity so tuff
local player_GetAll = player.GetAll
local util_TraceLine = util.TraceLine
local util_TraceHull = util.TraceHull
local IsValid = IsValid
local CurTime = CurTime

local TUMBLE_SPEED_THRESHOLD = 230
local TUMBLE_COOLDOWN = 2
local GAP_CHECK_DIST = 50 
local WALL_CHECK_DIST = 20
local WALL_CHECK_HEIGHT = 10 

local BASE_TRIP_CHANCE = 0.25
local MAX_TRIP_CHANCE = 0.9

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

        if speed < effectiveThreshold then continue end


        local speedExcess = math.max(0, speed - effectiveThreshold)
        local tripChance = BASE_TRIP_CHANCE + (speedExcess * 0.005)
        tripChance = tripChance + (1 - consciousness) * 0.5
        tripChance = tripChance + (math.Clamp(fear, 0, 100) / 100) * 0.2
        
        local shouldTrip = false
        local tripType = "none"

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
             if trWall.HitNormal.z < 0.7 then
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

        tripChance = math.Clamp(tripChance, 0, MAX_TRIP_CHANCE)

        if shouldTrip then
            if math.random() < tripChance then
                hg.Fake(ply)
                
                local ragdoll = ply.FakeRagdoll
                if IsValid(ragdoll) then
                    local phys = ragdoll:GetPhysicsObject()
                    if IsValid(phys) then
                        local impulseDir = velocity:GetNormalized()
                        if tripType == "wall" then
                             impulseDir = impulseDir + Vector(0,0,0.5)
                             impulseDir:Normalize()
                        elseif tripType == "gap" then
                            impulseDir = impulseDir + Vector(0,0,-0.5)
                            impulseDir:Normalize()
                        end
                        
                        local forceMag = speed * 5 
                        phys:ApplyForceCenter(impulseDir * forceMag)
                        phys:AddAngleVelocity(Vector(math.random(-100,100), math.random(-100,100), math.random(-100,100)))
                    end
                    local recoveryDelay = 2
                    if consciousness < 0.5 then recoveryDelay = 4 end
                    ply.fakecd = CurTime() + recoveryDelay
                else
                end
                
                ply.nextTumbleCheck = CurTime() + TUMBLE_COOLDOWN
            else
                -- why not
                ply:ViewPunch(Angle(10, 0, 0))
                ply.nextTumbleCheck = CurTime() + 1 
            end
        end
    end
end)

