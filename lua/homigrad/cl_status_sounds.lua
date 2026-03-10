-- This file handles the sound effects for low stamina and low consciousness.

local tired_sound
local sleepy_sound

hook.Add("Think", "homigrad_status_sounds", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local org = ply.organism
    if not org then return end

    -- Low stamina sound
    if org.stamina and org.stamina[1] and org.stamina.max then
        local stamina_percent = org.stamina[1] / org.stamina.max
        if stamina_percent < 0.2 then
            if not tired_sound then
                tired_sound = CreateSound(ply, "tired.ogg")
                tired_sound:Play()
                tired_sound:ChangeVolume(0, 0)
            end
            local volume = 1 - (stamina_percent / 0.2)
            tired_sound:ChangeVolume(volume, 0.5)
        elseif tired_sound then
            tired_sound:FadeOut(0.5)
            tired_sound = nil
        end
    end

    -- Low consciousness sound
    if org.consciousness then
        if org.consciousness < 0.5 then
            if not sleepy_sound then
                sleepy_sound = CreateSound(ply, "sleepy.ogg")
                sleepy_sound:Play()
                sleepy_sound:ChangeVolume(0, 0)
            end
            local volume = 1 - (org.consciousness / 0.5)
            sleepy_sound:ChangeVolume(volume, 0.5)
        elseif sleepy_sound then
            sleepy_sound:FadeOut(0.5)
            sleepy_sound = nil
        end
    end

    -- Vomiting sound
    if org.wantToVomit and org.wantToVomit > 0.95 then
        if not bloodvomit_sound then
            bloodvomit_sound = CreateSound(ply, "bloodvomit.ogg")
            bloodvomit_sound:Play()
        end
    elseif bloodvomit_sound then
        bloodvomit_sound:Stop()
        bloodvomit_sound = nil
    end

    -- Critical condition sounds
    if org.critical then
        if org.consciousness > 0.4 then
            if not criticalloop_sound or criticalloop_sound_name ~= "criticalloop.ogg" then
                if criticalloop_sound then criticalloop_sound:Stop() end
                criticalloop_sound = CreateSound(ply, "criticalloop.ogg")
                criticalloop_sound:Play()
                criticalloop_sound_name = "criticalloop.ogg"
            end
        else
            if org.pulse and org.pulse > 0 then
                if not criticalloop_sound or criticalloop_sound_name ~= "criticalloop-unconscious.ogg" then
                    if criticalloop_sound then criticalloop_sound:Stop() end
                    criticalloop_sound = CreateSound(ply, "criticalloop-unconscious.ogg")
                    criticalloop_sound:Play()
                    criticalloop_sound_name = "criticalloop-unconscious.ogg"
                end
            elseif criticalloop_sound then
                criticalloop_sound:FadeOut(1)
                criticalloop_sound = nil
                criticalloop_sound_name = nil
            end
        end
    elseif criticalloop_sound then
        criticalloop_sound:Stop()
        criticalloop_sound = nil
        criticalloop_sound_name = nil
    end
end)
