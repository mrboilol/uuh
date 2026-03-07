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
end)
