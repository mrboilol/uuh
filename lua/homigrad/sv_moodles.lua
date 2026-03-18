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
local function manageMoodleState(ply, moodleID, isActive, texturePath, count, bypassCooldown)
    if not IsValid(ply) then return end
    ply.MoodleStates = ply.MoodleStates or {}
    ply.MoodleCooldowns = ply.MoodleCooldowns or {}

    if ply.organism and (ply.organism.brain or 0) > 0.3 and math.random() < (ply.organism.brain - 0.3) * 0.5 then
        return
    end
    
    if isActive then
        count = count or 1
        if ply.MoodleStates[moodleID] ~= count then
            ply.MoodleStates[moodleID] = count
            ply.MoodleCooldowns[moodleID] = nil -- Remove cooldown when it becomes active again
            net.Start("Moodle_Add")
                net.WriteString(moodleID)
                net.WriteString(texturePath or "")
                net.WriteInt(count, 8)
            net.Send(ply)
            if MOODLE_DEBUG then MsgC(DEBUG_COLOR_SV, "[Moodle] ADD -> "..moodleID.." (x"..tostring(count)..")\n") end
        end
    elseif ply.MoodleStates[moodleID] then
        if not ply.MoodleCooldowns[moodleID] and not bypassCooldown then
            ply.MoodleCooldowns[moodleID] = CurTime() + 2 -- 2 second cooldown
        end

        if bypassCooldown or (ply.MoodleCooldowns[moodleID] and CurTime() >= ply.MoodleCooldowns[moodleID]) then
            ply.MoodleStates[moodleID] = nil
            ply.MoodleCooldowns[moodleID] = nil
            net.Start("Moodle_Remove")
                net.WriteString(moodleID)
            net.Send(ply)
            if MOODLE_DEBUG then MsgC(DEBUG_COLOR_SV, "[Moodle] REMOVE -> "..moodleID.."\n") end
        end
    end
end

local function manageHierarchicalMoodle(ply, baseID, levels, value)
    local active_level = 0
    for i = #levels, 1, -1 do
        local level_info = levels[i]
        if value >= level_info.threshold then
            active_level = i
            break
        end
    end

    for i = 1, #levels do
        local level_info = levels[i]
        local moodleID = baseID .. "_" .. i
        local should_be_active = (i == active_level)
        local should_be_active = (i == active_level)
        -- When a moodle is being deactivated as part of a hierarchy change, bypass the cooldown to prevent flickering.
        local bypass_cooldown = (not should_be_active and active_level > 0)
        manageMoodleState(ply, moodleID, should_be_active, level_info.texture, nil, bypass_cooldown)
    end
end

local function ApplyBrainDamageEffects(ply, org)
    local brain_damage = org.brain or 0
    if brain_damage < 0.1 then return end

    -- Fake moodles
    -- The chance of a fake moodle appearing increases with brain damage.
    local chance = (brain_damage - 0.1) * 0.5 -- Increased from 0.2
    if math.random() < chance then
        local fake_moodles = {
            { id = "happy_4", texture = "materials/moodels/Happy_4.png" },
            { id = "energized", texture = "materials/moodels/Energized.png" },
            { id = "pain_4", texture = "materials/moodels/Pain_4.png" },
            { id = "hunger_5", texture = "materials/moodels/Hunger_5.png" },
            { id = "cold_4", texture = "materials/moodels/Cold_4.png" },
            { id = "heat_4", texture = "materials/moodels/Heat_4.png" },
        }
        local chosen_moodle = fake_moodles[math.random(1, #fake_moodles)]
        
        -- A fake moodle should not have a real counterpart active
        if ply.MoodleStates[chosen_moodle.id] then return end

        local fake_id = chosen_moodle.id .. "_fake"
        
        -- Don't stack fake moodles
        if ply.MoodleStates[fake_id] then return end

        manageMoodleState(ply, fake_id, true, chosen_moodle.texture)

        -- Remove after a short, random duration
        local duration = math.Rand(5, 15) -- Increased from 3-7
        timer.Simple(duration, function()
            if not IsValid(ply) then return end
            manageMoodleState(ply, fake_id, false, nil, nil, true) -- Bypass cooldown
        end)
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
    local isArterial = ((org.arteria or 0) + (org.rarmartery or 0) + (org.larmartery or 0) + (org.rlegartery or 0) + (org.llegartery or 0)) > 0
    if isArterial then
        manageMoodleState(ply, "bleeding_4", true, "materials/moodels/Bleeding_4.png")
    else
        manageHierarchicalMoodle(ply, "bleeding", {
            { threshold = 0.1, texture = "materials/moodels/Bleeding_1.png" },
            { threshold = 1, texture = "materials/moodels/Bleeding_2.png" },
            { threshold = 5, texture = "materials/moodels/Bleeding_3.png" },
            { threshold = 15, texture = "materials/moodels/Bleeding_4.png" },
        }, bleedRate)
    end

    -- Hypovolemia (Low Blood Volume)
    local blood = org.blood or 5000
    local blood_loss = 1 - (blood / 5000)
    if blood_loss < 0 then blood_loss = 0 end
    manageHierarchicalMoodle(ply, "hypovolemia", {
        { threshold = 0.05, texture = "materials/moodels/Blood_loss_1.png" },
        { threshold = 0.25, texture = "materials/moodels/Blood_loss_2.png" },
        { threshold = 0.40, texture = "materials/moodels/Blood_loss_3.png" },
        { threshold = 0.55, texture = "materials/moodels/Blood_loss_4.png" },
    }, blood_loss)

    -- Bradycardia & Tachycardia
    local pulse = org.pulse or 70
    manageMoodleState(ply, "bradycardia", pulse < 40, "materials/moodels/Bradycardia_Moodle_Animated.png")
    manageMoodleState(ply, "tachycardia", pulse > 120, "materials/moodels/Tachycardia_Moodle.png")

    -- Brain Damage
    manageHierarchicalMoodle(ply, "brain_damage", {
        { threshold = 0.05, texture = "materials/moodels/Braindamage_Moodle_1.png" },
        { threshold = 0.10, texture = "materials/moodels/Braindamage_Moodle_2.png" },
        { threshold = 0.20, texture = "materials/moodels/Braindamage_Moodle_3.png" },
        { threshold = 0.30, texture = "materials/moodels/Braindamage_Moodle_4_Crit.png" },
    }, org.brain or 0)

    -- Cardiac Arrest
    manageMoodleState(ply, "cardiac_arrest", org.heartstop, "materials/moodels/Cardiacarrest_Moodle.png")

    -- Cold / Heat
    local temperature = org.temperature or 36.7
    manageHierarchicalMoodle(ply, "cold", {
        { threshold = 35, texture = "materials/moodels/Cold_1.png" },
        { threshold = 32, texture = "materials/moodels/Cold_2.png" },
        { threshold = 30, texture = "materials/moodels/Cold_3.png" },
        { threshold = -100, texture = "materials/moodels/Cold_4.png" }, -- Using a low number for the last threshold
    }, 36.5 - temperature) -- Invert temperature for cold

    manageHierarchicalMoodle(ply, "heat", {
        { threshold = 37.5, texture = "materials/moodels/Heat_1.png" },
        { threshold = 38.5, texture = "materials/moodels/Heat_2.png" },
        { threshold = 40.0, texture = "materials/moodels/Heat_3.png" },
        { threshold = 42.0, texture = "materials/moodels/Heat_4.png" },
    }, temperature)

    -- Concussion / Critical
    manageMoodleState(ply, "thoraxdestroyed", org.incapacitated, "materials/moodels/Thoraxdestroyed_Moodle.png")
    manageMoodleState(ply, "horrified", org.critical, "materials/moodels/HorrifiedMoodle.png")

    -- Tinnitus
    local tinnitus_active = (org.tinnitus_end_time or 0) > CurTime()
    manageMoodleState(ply, "deaf_1", tinnitus_active, "materials/moodels/Deaf_2.png")

    -- Depression / Happy
    if GetConVar("hg_mood_enabled"):GetBool() then
        local mood = org.mood or 50
        manageHierarchicalMoodle(ply, "depression", {
            { threshold = 30, texture = "materials/moodels/Depression_1.png" },
            { threshold = 20, texture = "materials/moodels/Depression_2.png" },
            { threshold = 10, texture = "materials/moodels/Depression_3.png" },
            { threshold = 0, texture = "materials/moodels/Depression_4.png" },
        }, 40 - mood) -- Inverted for depression

        manageHierarchicalMoodle(ply, "happy", {
            { threshold = 60, texture = "materials/moodels/Happy_1.png" },
            { threshold = 70, texture = "materials/moodels/Happy_2.png" },
            { threshold = 80, texture = "materials/moodels/Happy_3.png" },
            { threshold = 90, texture = "materials/moodels/Happy_4.png" },
        }, mood)
    else
        manageMoodleState(ply, "depression_1", false, nil, nil, true)
        manageMoodleState(ply, "depression_2", false, nil, nil, true)
        manageMoodleState(ply, "depression_3", false, nil, nil, true)
        manageMoodleState(ply, "depression_4", false, nil, nil, true)
        manageMoodleState(ply, "happy_1", false, nil, nil, true)
        manageMoodleState(ply, "happy_2", false, nil, nil, true)
        manageMoodleState(ply, "happy_3", false, nil, nil, true)
        manageMoodleState(ply, "happy_4", false, nil, nil, true)
    end

    -- Dislocated Spine
    local dislocated_spine_1_2 = (org.spine1dislocation or org.spine2dislocation) or ((org.spine1 > 0.75 and org.spine1 < 1) or (org.spine2 > 0.75 and org.spine2 < 1))
    local dislocated_spine_3 = org.spine3dislocation and (org.spine3 > 0.5 and org.spine3 < 0.75)
    local dislocated_spine = dislocated_spine_1_2 or dislocated_spine_3
    manageMoodleState(ply, "dislocated_spine", dislocated_spine, "materials/moodels/Dislocated_spine.png")

    -- Broken Neck
    local broken_neck = (org.spine1 == 1) or (org.spine2 == 1) or (org.spine3 > 0.75)
    manageMoodleState(ply, "broken_neck", broken_neck, "materials/moodels/Fractured_neck.png")

    manageMoodleState(ply, "dislocated_jaw", org.jawdislocation, "materials/moodels/Dislocated_jaw.png")

    -- Dislocation
    local dislocCount = 0
    if org.llegdislocation then dislocCount = dislocCount + 1 end
    if org.rlegdislocation then dislocCount = dislocCount + 1 end
    if org.larmdislocation then dislocCount = dislocCount + 1 end
    if org.rarmdislocation then dislocCount = dislocCount + 1 end
    manageMoodleState(ply, "dislocation", dislocCount > 0, "materials/moodels/Dislocation_4.png", dislocCount)

    -- Encumbered
    local maxweight = 30 -- You might want to configure this value
    local weightmul = hg.CalculateWeight(ply, maxweight)
    manageHierarchicalMoodle(ply, "encumbered", {
        { threshold = 0.6, texture = "materials/moodels/Encumbered_Moodle_1.png" },
        { threshold = 0.4, texture = "materials/moodels/Encumbered_Moodle_2.png" },
        { threshold = 0.2, texture = "materials/moodels/Encumbered_Moodle_3.png" },
        { threshold = 0, texture = "materials/moodels/Encumbered_Moodle_4.png" },
    }, 0.8 - weightmul) -- Inverted

    -- Endurance
    local stamina = (org.stamina and org.stamina[1]) or 100
    local maxStamina = (org.stamina and org.stamina.max) or 100
    local stPct = stamina / maxStamina
    manageHierarchicalMoodle(ply, "endurance", {
        { threshold = 0.25, texture = "materials/moodels/Endurance_1.png" },
        { threshold = 0.1, texture = "materials/moodels/Endurance_2.png" },
        { threshold = 0.0, texture = "materials/moodels/Endurance_3.png" },
        { threshold = -1, texture = "materials/moodels/Endurance_4.png" },
    }, 0.5 - stPct) -- Inverted
    manageMoodleState(ply, "energized", stamina > maxStamina * 1.5, "materials/moodels/Energized.png")

    -- Faint (Scaling based on Low Consciousness + Disorientation)
    local consciousness = org.consciousness or 1
    local disorientation = org.disorientation or 0
    local faint_level = 0
    if consciousness < 0.8 or disorientation > 0.1 then faint_level = 1 end
    if consciousness < 0.6 or disorientation > 1 then faint_level = 2 end
    if consciousness < 0.4 or disorientation > 2 then faint_level = 3 end
    if org.otrub and disorientation > 3 then faint_level = 4 end
    manageHierarchicalMoodle(ply, "faint", {
        { threshold = 1, texture = "materials/moodels/Faint_1.png" },
        { threshold = 2, texture = "materials/moodels/Faint_2.png" },
        { threshold = 3, texture = "materials/moodels/Faint_3.png" },
        { threshold = 4, texture = "materials/moodels/Faint_4.png" },
    }, faint_level)

    -- Fight or Flight
    manageMoodleState(ply, "fight_or_flight", (org.adrenaline or 0) > 1, "materials/moodels/FightOrFlight_Moodle.png")

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
    manageMoodleState(ply, "fractured_ribs", (org.chest or 0) >= 0.3, "materials/moodels/Fractured_ribs.png")

    -- Hemothorax
    manageMoodleState(ply, "hemothorax", (org.pneumothorax or 0) > 0, "materials/moodels/Hemothorax_Moodle_Animated_Crit.png")

    -- Hunger
    local hunger = org.hungry or 0
    manageHierarchicalMoodle(ply, "hunger", {
        { threshold = 60, texture = "materials/moodels/Hunger_3.png" },
        { threshold = 80, texture = "materials/moodels/Hunger_4.png" },
        { threshold = 100, texture = "materials/moodels/Hunger_5.png" },
    }, hunger)

    -- Internal Bleed
    manageMoodleState(ply, "internal_bleed", (org.internalBleed or 0) > 0.1, "materials/moodels/InternalBleed_Moodle_Animated_Crit.png")

    -- Overdose (Using Analgesia/Painkillers as threshold mapping)
    local overdose = org.analgesia or 0
    manageHierarchicalMoodle(ply, "overdose", {
        { threshold = 0.50, texture = "materials/moodels/Overdose_Moodle_1.png" },
        { threshold = 0.75, texture = "materials/moodels/Overdose_Moodle_2.png" },
        { threshold = 0.90, texture = "materials/moodels/Overdose_Moodle_3.png" },
        { threshold = 1.25, texture = "materials/moodels/Overdose_Moodle_4.png" },
    }, overdose)

    -- Oxygen
    local o2_val = org.o2 and org.o2[1]
    local o2_range = org.o2 and org.o2.range
    if o2_val and o2_range and o2_range > 0 then
        local o2_pct = o2_val / o2_range
        manageHierarchicalMoodle(ply, "oxygen", {
            { threshold = 0.3, texture = "materials/moodels/Oxygen_Moodle_1.png" },
            { threshold = 0.15, texture = "materials/moodels/Oxygen_Moodle_2.png" },
            { threshold = 0, texture = "materials/moodels/Oxygen_Moodle_3.png" },
        }, 0.5 - o2_pct) -- Inverted
    end

    -- Pain
    local pain = org.pain or 0
    manageHierarchicalMoodle(ply, "pain", {
        { threshold = 25, texture = "materials/moodels/Pain_1.png" },
        { threshold = 50, texture = "materials/moodels/Pain_2.png" },
        { threshold = 75, texture = "materials/moodels/Pain_3.png" },
        { threshold = 100, texture = "materials/moodels/Pain_4.png" },
    }, pain)

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
    manageMoodleState(ply, "speechless", (org.pain or 0) > 80 or (org.brain or 0) > 0.05 or (org.jaw or 0) >= 1, "materials/moodels/Speechless.png")

    -- Thorax Destroyed (Skull Fracture)
    manageMoodleState(ply, "concussion", (org.skull or 0) >= 1, "materials/moodels/Concussion_moodle.png")

    -- Fear
    local fear = org.fear or 0
    manageHierarchicalMoodle(ply, "trauma", {
        { threshold = 0.1, texture = "materials/moodels/Trauma_Moodle_1.png" },
        { threshold = 0.25, texture = "materials/moodels/Trauma_Moodle_2.png" },
        { threshold = 0.5, texture = "materials/moodels/Trauma_Moodle_3.png" },
        { threshold = 0.8, texture = "materials/moodels/Trauma_Moodle_4.png" },
    }, fear)

    if fear > 0.25 then
        org.adrenalineAdd = (org.adrenalineAdd or 0) + (fear * 0.5)
    end

    -- Unconscious
    manageMoodleState(ply, "unconscious", org.otrub or false, "materials/moodels/Unconscious_Moodle.png")

    -- Sepsis
    manageMoodleState(ply, "sepsis", (org.hemotransfusionshock and (type(org.hemotransfusionshock) == "boolean" or org.hemotransfusionshock > 0)), "materials/moodels/Sepsis_2.png")

    -- Horrified (Noradrenaline/Berserk)
    manageMoodleState(ply, "stimulated", (org.berserk or 0) > 0 or (org.noradrenaline or 0) > 0, "materials/moodels/Stimulated.png")

    if (org.brain or 0) > 0.01 then
        ApplyBrainDamageEffects(ply, org)
    end
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