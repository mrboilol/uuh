--
local hg_hungersystem = CreateConVar("hg_hungersystem", 0, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY, "Enables/disabled hunger system", 0, 1)
local max, min, Round, Lerp, halfValue2 = math.max, math.min, math.Round, Lerp, util.halfValue2
--local Organism = hg.organism
hg.organism.module.metabolism = {}
local module = hg.organism.module.metabolism
module[1] = function(org)
	org.satiety = 0
    org.hungry = 0
    org.hungryDmgCd = 0
end

local colorRed = Color(125,25,25)
module[2] = function(owner, org, timeValue)
    local mood = hg.Abnormalties.GetPlayerStat(owner, "mood")

    if org.satiety <= 0 and hg_hungersystem:GetBool() then 
        org.hungry = min(max(org.hungry + timeValue * 0.01, 0),100)
        //if org.isPly and not org.otrub and org.hungry > 25 and org.hungry < 45 then org.owner:Notify(table.Random(pharse),60,"hungry",6) end
        org.hungryDmgCd = org.hungryDmgCd or 0
        if org.alive and org.hungryDmgCd < CurTime() and org.hungry > 45 then
            //org.owner:Notify(table.Random(veryPharse),20,"hungry",6,nil,colorRed)
            org.painadd = org.painadd + 25 * (org.hungry/45)
            org.hungryDmgCd = CurTime() + (math.random(40,55) - (org.hungry/5.5))
            //owner:TakeDamage(5,owner,owner)
            if org.hungry > 80 then
                org.stomach = math.min(org.stomach + 0.1,1)
                if org.stomach > 0.85 and org.heart < 0.3 then
                    org.heart = org.heart + 0.1
                end
                if org.heart > 0.3 then
                    org.o2.regen = 0
                end
                //owner:TakeDamage(15,owner,owner)
            end
        end
    else
        org.hungry = min(max(org.hungry - timeValue * 2, 0),100)
    end
    org.hungry = Round(org.hungry or 0,3)

    if (org.intestines > 0.5 or org.stomach > 0.5) and not org.otrub and owner:IsPlayer() and org.satiety > 1 then
        if not org.randomPainSound or org.randomPainSound < CurTime() then
            org.randomPainSound = CurTime() + math.random(20,45)
            owner:EmitSound("zcitysnd/"..(ThatPlyIsFemale(owner) and "female" or "male").."/pain_"..math.random(1,8)..".mp3")
            org.painadd = org.painadd + 20
            //owner:TakeDamage(5,owner,owner)
        end
    end

    if org.satiety == 0 then return end

    org.satiety = min(max(org.satiety - timeValue * 0.5, 0), 100)

    local mood_blood_bonus = 1
    if mood and mood >= 80 then
        mood_blood_bonus = 1.1 -- 10% bonus to blood regeneration
    end
    org.blood = min(org.blood + timeValue * (org.satiety/10) * mood_blood_bonus, 5000)

    if mood and mood > 70 then
        local mood_bonus = (mood - 70) / 30 * 0.2 -- Up to 20% bonus healing
        org.regeneratehp = (!((org.regeneratehp or 0) >= 1) and min( (org.regeneratehp or 0) + timeValue * (org.satiety/100) * (1 + mood_bonus), 1)) or 0
    else
        org.regeneratehp = (!((org.regeneratehp or 0) >= 1) and min( (org.regeneratehp or 0) + timeValue * (org.satiety/100), 1)) or 0
    end
    owner:SetHealth(min(owner:Health() + org.regeneratehp,100))

    if mood then
        local new_mood = mood
        if org.hungry > 50 then
            local mood_loss = (org.hungry - 50) / 50 * timeValue * 0.5 -- Mood loss starts when hunger is over 50
            new_mood = new_mood - mood_loss * hg.Abnormalties:GetMoodInertiaMultiplier(owner)
        end

        if org.satiety > 80 then
            local mood_gain = (org.satiety - 80) / 20 * timeValue * 0.2 -- Mood gain starts when satiety is over 80
            new_mood = new_mood + mood_gain
        end

        new_mood = math.Clamp(new_mood, 0, 100)
        if new_mood != mood then
            hg.Abnormalties.SetPlayerStat(owner, "mood", new_mood)
        end
    end
end