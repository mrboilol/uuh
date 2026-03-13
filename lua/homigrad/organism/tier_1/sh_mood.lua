CreateConVar("hg_mood_enabled", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable/disable the mood system")
CreateConVar("hg_mood_always_happy", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Everyone is always happy")

local suicide_phrases = {
	"FUCK YOU, I FUCKING TOLD YOU I TOLD YOU!",
	"Finally, Sweet release.",
	"Goodbye, cruel world.",
}

sharp_weapons = {
    ["weapon_hg_machete"] = true,
    ["weapon_hg_glassshard"] = true,
    ["weapon_hg_glassshard_taped"] = true,
    ["weapon_hg_bottlebroken"] = true,
    ["weapon_hg_razor"] = true,
    ["weapon_sogknife"] = true,
    ["weapon_pocketknife"] = true,
    ["weapon_buck200knife"] = true,
}

hg.organism.mood = hg.organism.mood or {}

function hg.organism.GetMoodInertiaMultiplier(ply)
    local org = ply.organism
    if not org or not org.mood then return 1 end

    local mood = org.mood
    local distance_from_neutral = math.abs(mood - 50)
    local inertia = 1 + (distance_from_neutral / 50) * 0.5 -- At most 50% inertia

    return inertia
end

function hg.organism.UpdateSuicidalTendencies(ply, timeValue)
    if not GetConVar("hg_mood_enabled"):GetBool() then return end
    local org = ply.organism
    if not org or not org.mood then return end

    if org.mood < 20 then
        org.sad_time = (org.sad_time or 0) + timeValue
    else
        org.sad_time = 0
    end

    local sadness_duration_for_suicide = math.max(30, 120 - (20 - org.mood) * 5)

    if org.sad_time > sadness_duration_for_suicide and not org.suicidal then
        org.suicidal = true
        ply:Notify("I can't take this anymore.", 10, "suicide_thoughts", 0, nil, Color(255, 0, 0, 255))
    elseif org.sad_time <= sadness_duration_for_suicide then
        org.suicidal = false
    end
end

if SERVER then
    concommand.Add("hg_induce_suicide", function(ply, cmd, args)
        if not ply:IsAdmin() then return end

        local target = ply
        if args[1] then
            target = player.GetByName(args[1])[1]
        end

        if not IsValid(target) or not target:IsPlayer() then
            ply:ChatPrint("Invalid target.")
            return
        end

        if not target.organism then
            ply:ChatPrint("Target does not have an organism.")
            return
        end

        target.organism.suicidal = true
        ply:ChatPrint("Induced suicidal tendencies in " .. target:Name())
    end)
end

if SERVER then
    concommand.Add("suicide", function(ply)
        if not IsValid(ply) or not ply:Alive() then return end
        
        if not ply.organism or not ply.organism.suicidal then
            ply:Notify("I cant do that...")
            return
        end

        ply.suiciding = not ply.suiciding
    end)
end

hook.Add("HG_MovementCalc_2", "MoodInertia", function(mul, ply)
    if not GetConVar("hg_mood_enabled"):GetBool() then return end
    if not IsValid(ply) or not ply:IsPlayer() or not ply.organism then return end

    local multiplier = hg.organism.GetMoodInertiaMultiplier(ply)
    mul[1] = mul[1] * (1 / multiplier) -- Inverse because it's a multiplier on speed
end)
