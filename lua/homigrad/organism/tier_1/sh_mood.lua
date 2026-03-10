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

    if org.sad_time > sadness_duration_for_suicide and not ply.IsSuiciding then
		local suicide_weapon = nil
		for _, wep in ipairs(ply:GetWeapons()) do
			if sharp_weapons[wep:GetClass()] then
				suicide_weapon = wep
				break
			end
		end

		if suicide_weapon then
			ply:SelectWeapon(suicide_weapon:GetClass())
			org.suicidal = true
			ply.IsSuiciding = true
			ply:Notify("Do it.", 10, "suicide_imminent", 0, nil, Color(255, 0, 0, 255))

			ply.canSuicide = false
			timer.Simple(3, function()
				if not IsValid(ply) then return end
				ply.canSuicide = true
			end)
		else
			org.heartstop = true
			ply:Notify("I dont feel so good...", 10, "heart_attack", 0, nil, Color(255, 0, 0, 255))
		end

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
			ply.suiciding = !ply.suiciding
		end)
	end
    if not IsValid(ply) or not ply:Alive() or ply:IsSuiciding() then return end

    if ply.organism.mood > 70 and GetConVar("hg_mood_enabled"):GetBool() then
        ply:Notify("I cant...")
        return
    end

    local suicide_weapon = nil
    for _, wep in ipairs(ply:GetWeapons()) do
        if sharp_weapons[wep:GetClass()] then
            suicide_weapon = wep
            break
        end
    end

    if suicide_weapon then
        ply:SelectWeapon(suicide_weapon:GetClass())
        ply.IsSuiciding = true
		ply:Notify(suicide_phrases[math.random(#suicide_phrases)], 10, "suicide_imminent", 0, nil, Color(255, 0, 0, 255))

		ply.canSuicide = false
		timer.Simple(3, function()
			if not IsValid(ply) then return end
			ply.canSuicide = true
		end)
    else
        ply.organism.heartstop = true
        ply:Notify("You are having a heart attack.", 10, "heart_attack", 0, nil, Color(255, 0, 0, 255))
    end
end)

hook.Add("HG_MovementCalc_2", "MoodInertia", function(mul, ply)
    if not IsValid(ply) or not ply:IsPlayer() or not ply.organism then return end

    local multiplier = hg.organism.GetMoodInertiaMultiplier(ply)
    mul[1] = mul[1] * (1 / multiplier) -- Inverse because it's a multiplier on speed
end)
