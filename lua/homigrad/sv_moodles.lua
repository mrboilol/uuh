-- sv_moodles.lua
-- Server-side moodle sync template
if not SERVER then return end

util.AddNetworkString("Moodle_Add")
util.AddNetworkString("Moodle_Remove")

local MOODLE_DEBUG = false
local DEBUG_COLOR_SV = Color(255, 150, 0)

if MOODLE_DEBUG then
    print("[Moodles] Server-side system started (DEBUG)")
end

-- Helper for safe numeric reads
local function safeNum(v, fallback)
    if type(v) == "number" then return v end
    if type(v) == "table" and type(v[1]) == "number" then return v[1] end
    return fallback or 0
end

-- Core function to handle state changes and networking
-- Only sends net messages when a state actually changes
local function manageMoodleState(ply, moodleID, isActive, texturePath, count)
    if not IsValid(ply) then return end
    ply.MoodleStates = ply.MoodleStates or {}
    
    if isActive then
        count = count or 1
        if ply.MoodleStates[moodleID] ~= count then
            ply.MoodleStates[moodleID] = count
            net.Start("Moodle_Add")
                net.WriteString(moodleID)
                net.WriteString(texturePath or "")
                net.WriteInt(count, 8)
            net.Send(ply)
            if MOODLE_DEBUG then MsgC(DEBUG_COLOR_SV, "[Moodle] ADD -> "..moodleID.." (x"..tostring(count)..")\n") end
        end
    elseif ply.MoodleStates[moodleID] then
        ply.MoodleStates[moodleID] = nil
        net.Start("Moodle_Remove")
            net.WriteString(moodleID)
        net.Send(ply)
        if MOODLE_DEBUG then MsgC(DEBUG_COLOR_SV, "[Moodle] REMOVE -> "..moodleID.."\n") end
    end
end

-- Main sync function where your custom logic goes
local function SyncMoodles(ply)
    if not IsValid(ply) or not ply:Alive() then return end
    
    ply.MoodleStates = ply.MoodleStates or {}

    -- =======================================================
    -- ACTUAL HOMIGRAD ORGANISM LOGIC
    -- =======================================================
    local org = ply.organism
    if not org then return end

    -- Amputation
    local ampCount = 0
    if org.llegamputated then ampCount = ampCount + 1 end
    if org.rlegamputated then ampCount = ampCount + 1 end
    if org.larmamputated then ampCount = ampCount + 1 end
    if org.rarmamputated then ampCount = ampCount + 1 end
    manageMoodleState(ply, "amputation", ampCount > 0, "materials/moodels/Amputation_Moodle.png", ampCount)

    -- Bleeding
    local bleedRate = org.bleed or 0
    local isArterial = org.arteria or org.rarmartery or org.larmartery or org.rlegartery or org.llegartery
    manageMoodleState(ply, "bleeding_1", bleedRate > 0.1 and bleedRate <= 1 and not isArterial, "materials/moodels/Bleeding_1.png")
    manageMoodleState(ply, "bleeding_2", bleedRate > 1 and bleedRate <= 5 and not isArterial, "materials/moodels/Bleeding_2.png")
    manageMoodleState(ply, "bleeding_3", bleedRate > 5 and bleedRate <= 15 and not isArterial, "materials/moodels/Bleeding_3.png")
    manageMoodleState(ply, "bleeding_4", bleedRate > 15 or isArterial, "materials/moodels/Bleeding_4.png")

    -- Bradycardia & Tachycardia
    local pulse = org.pulse or 70
    manageMoodleState(ply, "bradycardia", pulse < 40, "materials/moodels/Bradycardia_Moodle_Animated.png")
    manageMoodleState(ply, "tachycardia", pulse > 120, "materials/moodels/Tachycardia_Moodle.png")

    -- Brain Damage
    local brainDamage = org.brain or 0
    manageMoodleState(ply, "brain_damage_1", brainDamage > 0.05 and brainDamage <= 0.10, "materials/moodels/Braindamage_Moodle_1.png")
    manageMoodleState(ply, "brain_damage_2", brainDamage > 0.10 and brainDamage <= 0.20, "materials/moodels/Braindamage_Moodle_2.png")
    manageMoodleState(ply, "brain_damage_3", brainDamage > 0.20 and brainDamage <= 0.40, "materials/moodels/Braindamage_Moodle_3.png")
    manageMoodleState(ply, "brain_damage_4", brainDamage > 0.40, "materials/moodels/Braindamage_Moodle_4_Crit.png")

    -- Cardiac Arrest
    manageMoodleState(ply, "cardiac_arrest", org.heartstop, "materials/moodels/Cardiacarrest_Moodle.png")

    -- Cold / Heat
    local temperature = org.temperature or 36.7
    manageMoodleState(ply, "cold_1", temperature < 36.5 and temperature >= 35, "materials/moodels/Cold_1.png")
    manageMoodleState(ply, "cold_2", temperature < 35 and temperature >= 32, "materials/moodels/Cold_2.png")
    manageMoodleState(ply, "cold_3", temperature < 32 and temperature >= 30, "materials/moodels/Cold_3.png")
    manageMoodleState(ply, "cold_4", temperature < 30, "materials/moodels/Cold_4.png")

    manageMoodleState(ply, "heat_1", temperature > 37.5 and temperature <= 38.5, "materials/moodels/Heat_1.png")
    manageMoodleState(ply, "heat_2", temperature > 38.5 and temperature <= 40.0, "materials/moodels/Heat_2.png")
    manageMoodleState(ply, "heat_3", temperature > 40.0 and temperature <= 42.0, "materials/moodels/Heat_3.png")
    manageMoodleState(ply, "heat_4", temperature > 42.0, "materials/moodels/Heat_4.png")

    -- Concussion / Critical
    manageMoodleState(ply, "thoraxdestroyed", org.incapacitated, "materials/moodels/Thoraxdestroyed_Moodle.png")
    manageMoodleState(ply, "horrified", org.critical, "materials/moodels/HorrifiedMoodle.png")

    -- Tinnitus
    local tinnitus_active = (org.tinnitus_end_time or 0) > CurTime()
    manageMoodleState(ply, "deaf_1", tinnitus_active, "materials/moodels/Deaf_1.png")



    -- Depression / Happy
    local mood = org.mood or 50
    manageMoodleState(ply, "depression_1", mood < 40 and mood >= 30, "materials/moodels/Depression_1.png")
    manageMoodleState(ply, "depression_2", mood < 30 and mood >= 20, "materials/moodels/Depression_2.png")
    manageMoodleState(ply, "depression_3", mood < 20 and mood >= 10, "materials/moodels/Depression_3.png")
    manageMoodleState(ply, "depression_4", mood < 10, "materials/moodels/Depression_4.png")

    manageMoodleState(ply, "happy_1", mood >= 60 and mood < 70, "materials/moodels/Happy_1.png")
    manageMoodleState(ply, "happy_2", mood >= 70 and mood < 80, "materials/moodels/Happy_2.png")
    manageMoodleState(ply, "happy_3", mood >= 80 and mood < 90, "materials/moodels/Happy_3.png")
    manageMoodleState(ply, "happy_4", mood >= 90, "materials/moodels/Happy_4.png")

    -- Dislocated Spine & Jaw
    local spineDislocated = (org.spine1 or 0) > 0 or (org.spine2 or 0) > 0
    manageMoodleState(ply, "dislocated_spine", spineDislocated, "materials/moodels/Dislocated_spine.png")
    manageMoodleState(ply, "dislocated_jaw", org.jawdislocation, "materials/moodels/Dislocated_jaw.png")

    -- Dislocation
    local dislocCount = 0
    if org.llegdislocation then dislocCount = dislocCount + 1 end
    if org.rlegdislocation then dislocCount = dislocCount + 1 end
    if org.larmdislocation then dislocCount = dislocCount + 1 end
    if org.rarmdislocation then dislocCount = dislocCount + 1 end
    manageMoodleState(ply, "dislocation", dislocCount > 0, "materials/moodels/Dislocation_4.png", dislocCount)

    -- Encumbered
    local maxweight = 25 -- You might want to configure this value
    local weightmul = hg.CalculateWeight(ply, maxweight)

    manageMoodleState(ply, "encumbered_1", weightmul < 0.8 and weightmul >= 0.6, "materials/moodels/Encumbered_Moodle_1.png")
    manageMoodleState(ply, "encumbered_2", weightmul < 0.6 and weightmul >= 0.4, "materials/moodels/Encumbered_Moodle_2.png")
    manageMoodleState(ply, "encumbered_3", weightmul < 0.4 and weightmul >= 0.2, "materials/moodels/Encumbered_Moodle_3.png")
    manageMoodleState(ply, "encumbered_4", weightmul < 0.2, "materials/moodels/Encumbered_Moodle_4.png")

    -- Endurance
    local stamina = (org.stamina and org.stamina[1]) or 100
    local maxStamina = (org.stamina and org.stamina.max) or 100
    local stPct = stamina / maxStamina
    manageMoodleState(ply, "endurance_1", stPct < 0.5 and stPct >= 0.25, "materials/moodels/Endurance_1.png")
    manageMoodleState(ply, "endurance_2", stPct < 0.25 and stPct >= 0.1, "materials/moodels/Endurance_2.png")
    manageMoodleState(ply, "endurance_3", stPct < 0.1 and stPct > 0, "materials/moodels/Endurance_3.png")
    manageMoodleState(ply, "endurance_4", stPct <= 0, "materials/moodels/Endurance_4.png")
    manageMoodleState(ply, "energized", stamina > maxStamina * 1.5, "materials/moodels/Energized.png")

    -- Faint (Scaling based on Low Consciousness + Disorientation)
    local consciousness = org.consciousness or 1
    local disorientation = org.disorientation or 0
    manageMoodleState(ply, "faint_1", consciousness < 0.8 and consciousness >= 0.6 or disorientation > 0.1, "materials/moodels/Faint_1.png")
    manageMoodleState(ply, "faint_2", consciousness < 0.6 and consciousness >= 0.4 or disorientation > 1, "materials/moodels/Faint_2.png")
    manageMoodleState(ply, "faint_3", consciousness < 0.4 and consciousness >= 0.2 or disorientation > 2, "materials/moodels/Faint_3.png")
    manageMoodleState(ply, "faint_4", consciousness < 0.2 or disorientation > 3, "materials/moodels/Faint_4.png")

    -- Fight or Flight
    manageMoodleState(ply, "fight_or_flight", (org.adrenaline or 0) > 5, "materials/moodels/FightOrFlight_Moodle.png")

    -- Fractures
    local fracCount = 0
    if (org.lleg or 0) >= 1 then fracCount = fracCount + 1 end
    if (org.rleg or 0) >= 1 then fracCount = fracCount + 1 end
    if (org.larm or 0) >= 1 then fracCount = fracCount + 1 end
    if (org.rarm or 0) >= 1 then fracCount = fracCount + 1 end
    if (org.pelvis or 0) >= 1 then fracCount = fracCount + 1 end
    manageMoodleState(ply, "fracture", fracCount > 0, "materials/moodels/Fracture_4.png", fracCount)
    
    local spine3_thresh = hg and hg.organism and hg.organism.fake_spine3 or 0.8
    manageMoodleState(ply, "fractured_neck", (org.spine3 or 0) >= spine3_thresh, "materials/moodels/Fractured_neck.png")
    manageMoodleState(ply, "fractured_ribs", (org.chest or 0) >= 1, "materials/moodels/Fractured_ribs.png")

    -- Hemothorax
    manageMoodleState(ply, "hemothorax", (org.pneumothorax or 0) > 0, "materials/moodels/Hemothorax_Moodle_Animated_Crit.png")

    -- Hunger
    local hunger = org.hungry or 0
    manageMoodleState(ply, "hunger_1", hunger > 20 and hunger <= 40, "materials/moodels/Hunger_1.png")
    manageMoodleState(ply, "hunger_2", hunger > 40 and hunger <= 60, "materials/moodels/Hunger_2.png")
    manageMoodleState(ply, "hunger_3", hunger > 60 and hunger <= 80, "materials/moodels/Hunger_3.png")
    manageMoodleState(ply, "hunger_4", hunger > 80 and hunger < 100, "materials/moodels/Hunger_4.png")
    manageMoodleState(ply, "hunger_5", hunger >= 100, "materials/moodels/Hunger_5.png")

    -- Internal Bleed
    manageMoodleState(ply, "internal_bleed", (org.internalBleed or 0) > 0.1, "materials/moodels/InternalBleed_Moodle_Animated_Crit.png")

    -- Overdose (Using Analgesia/Painkillers as threshold mapping)
    local overdose = org.analgesia or 0
    manageMoodleState(ply, "overdose_1", overdose > 0.50 and overdose <= 0.75, "materials/moodels/Overdose_Moodle_1.png")
    manageMoodleState(ply, "overdose_2", overdose > 0.75 and overdose <= 0.90, "materials/moodels/Overdose_Moodle_2.png")
    manageMoodleState(ply, "overdose_3", overdose > 0.90 and overdose <= 1.25, "materials/moodels/Overdose_Moodle_3.png")
    manageMoodleState(ply, "overdose_4", overdose > 1.25, "materials/moodels/Overdose_Moodle_4.png")

    -- Oxygen
    local oxy = (org.o2 and org.o2[1]) or 100
    manageMoodleState(ply, "oxygen", oxy < 50 and oxy >= 30, "materials/moodels/Oxygen_Moodle_1.png")
    manageMoodleState(ply, "oxygen_2", oxy < 30 and oxy >= 10, "materials/moodels/Oxygen_Moodle_2.png")
    manageMoodleState(ply, "oxygen_3", oxy < 10, "materials/moodels/Oxygen_Moodle_3.png")

    -- Pain
    local pain = org.pain or 0
    manageMoodleState(ply, "pain_1", pain > 25 and pain <= 50, "materials/moodels/Pain_1.png")
    manageMoodleState(ply, "pain_2", pain > 50 and pain <= 75, "materials/moodels/Pain_2.png")
    manageMoodleState(ply, "pain_3", pain > 75 and pain < 100, "materials/moodels/Pain_3.png")
    manageMoodleState(ply, "pain_4", pain >= 100, "materials/moodels/Pain_4.png")

    -- Respiratory Failure
    manageMoodleState(ply, "respfailure", (org.trachea or 0) >= 0.5 or org.lungsfunction == false, "materials/moodels/Respfailure.png")

    -- Ripped Eye and Blindness
    local missingEyes = 0
    if org.righteyedestroyed or (org.righteye or 0) >= 1 then missingEyes = missingEyes + 1 end
    if org.lefteyedestroyed or (org.lefteye or 0) >= 1 then missingEyes = missingEyes + 1 end
    local isBlinded = (org.blindness_end_time or 0) > CurTime()
    manageMoodleState(ply, "rippedeye_3", missingEyes == 1, "materials/moodels/Rippedeye_Moodle_3.png")
    manageMoodleState(ply, "rippedeye_4", missingEyes == 2 or isBlinded, "materials/moodels/Rippedeye_Moodle_4.png")

    -- Ripped Jaw
    manageMoodleState(ply, "rippedjaw", (org.jaw or 0) >= 1 or org.jawdislocation, "materials/moodels/Rippedjaw_Moodle.png")

    -- Shock
    manageMoodleState(ply, "shock", (org.shock or 0) > 25, "materials/moodels/Shock.png")

    -- Speechless
    manageMoodleState(ply, "speechless", pain > 80 or brainDamage > 0.2 or (org.jaw or 0) >= 1, "materials/moodels/Speechless.png")

    -- Thorax Destroyed (Skull Fracture)
    manageMoodleState(ply, "concussion", (org.skull or 0) >= 1, "materials/moodels/Concussion_moodle.png")

    -- Trauma (Fear)
    local fear = org.fear or 0
    manageMoodleState(ply, "trauma_2", fear > 0.25 and fear <= 0.5, "materials/moodels/Trauma_Moodle_2.png")
    manageMoodleState(ply, "trauma_3", fear > 0.5 and fear <= 0.75, "materials/moodels/Trauma_Moodle_3.png")
    manageMoodleState(ply, "trauma_4", fear > 0.75, "materials/moodels/Trauma_Moodle_4.png")

    -- Unconscious
    manageMoodleState(ply, "unconscious", org.otrub or false, "materials/moodels/Unconscious_Moodle.png")

    -- Sepsis
    manageMoodleState(ply, "sepsis", (org.hemotransfusionshock and (type(org.hemotransfusionshock) == "boolean" or org.hemotransfusionshock > 0)), "materials/moodels/Sepsis_2.png")

    -- Horrified (Noradrenaline/Berserk)
    manageMoodleState(ply, "stimulated", (org.noradrenalineActive or org.berserkActive2 or (org.berserk or 0) > 0 or (org.noradrenaline or 0) > 0), "materials/moodels/Stimulated.png")

end

-- Think loop for periodic syncing
hook.Add("Think", "Moodle_ThinkSync", function()
    local curTime = CurTime()
    local syncInterval = 0.5 -- How often to check states (seconds)
    
    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        
        ply.moodle_last_sync = ply.moodle_last_sync or 0
        if curTime >= ply.moodle_last_sync + syncInterval then
            ply.moodle_last_sync = curTime
            
            local ok, err = pcall(SyncMoodles, ply)
            if not ok and MOODLE_DEBUG then 
                MsgC(DEBUG_COLOR_SV, "[Moodle] Sync error: "..tostring(err).."\n") 
            end
        end
    end
end)

-- Clear moodles on spawn and death
local function ClearMoodles(ply)
    if not IsValid(ply) then return end
    ply.MoodleStates = {}
    net.Start("Moodle_Remove") 
    net.WriteString("*") -- "*" acts as a wildcard to clear all client-side
    net.Send(ply)
end

hook.Add("PlayerSpawn", "Moodle_ClearSpawn", function(ply)
    timer.Simple(0.05, function() ClearMoodles(ply) end)
end)

hook.Add("PlayerDeath", "Moodle_ClearDeath", function(ply)
    ClearMoodles(ply)
end)