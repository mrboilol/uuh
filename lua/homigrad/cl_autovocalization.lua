if CLIENT then
    local last_vocalization = 0
    hook.Add("PlayerThink", "AutoVocalization", function(ply, time, dtime)
        if ply ~= lply or not ply:Alive() or (ply.organism and ply.organism.otrub) then return end
        if last_vocalization > time then return end

        local org = ply.organism
        if org then
            local o2_val = org.o2 and org.o2[1]
            local o2_range = org.o2 and org.o2.range
            local o2_pct = (o2_val and o2_range and o2_range > 0) and (o2_val / o2_range) or 1
            
            local speech_affected = o2_pct < 0.2 or (org.pain or 0) > 80 or (org.brain or 0) > 0.05 or (org.jaw or 0) >= 1 or org.jawdislocation
            if not speech_affected then
                return
            end
        else
            return
        end

        local chance = hg.likely_to_phrase(ply)
        if chance > 0 and math.random() < chance / 5 then
            last_vocalization = time + math.random(5, 15) -- Cooldown
            RunConsoleCommand("hg_phrase")
        end
    end)

    hook.Add("PlayerSpawn", "ResetVocalization", function(ply)
        if ply == lply then
            last_vocalization = 0
        end
    end)
end