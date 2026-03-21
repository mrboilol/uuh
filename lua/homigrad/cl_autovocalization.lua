if CLIENT then
    local last_vocalization = 0
    hook.Add("Player Think", "AutoVocalization", function(ply, time, dtime)
        if ply ~= lply or not ply:Alive() or (ply.organism and ply.organism.otrub) then return end
        if last_vocalization > time then return end

        local chance = hg.likely_to_phrase(ply)
        if chance > 0 and math.random() < chance / 5 then
            last_vocalization = time + math.random(5, 15) -- Cooldown
            RunConsoleCommand("hg_phrase")
        end
    end)
end