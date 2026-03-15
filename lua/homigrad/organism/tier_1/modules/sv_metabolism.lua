--
local hg_hungersystem = CreateConVar("hg_hungersystem", 1, FCVAR_ARCHIVE + FCVAR_REPLICATED + FCVAR_NOTIFY, "Enables/disabled hunger system", 0, 1)
local max, min, Round, Lerp, halfValue2 = math.max, math.min, math.Round, Lerp, util.halfValue2
--local Organism = hg.organism
hg.organism.module.metabolism = {}
local module = hg.organism.module.metabolism
module[1] = function(org)
	org.satiety = 100
    org.hungry = 0
    org.hungryDmgCd = 0
end

local colorRed = Color(125,25,25)

local hunger_messages_1 = {
    "I'm starting to get really hungry...",
    "My stomach is starting to rumble.",
    "I could use a snack."
}

local hunger_messages_2 = {
    "My stomach is eating itself... I need to eat.",
    "I'm so hungry, I could eat a horse.",
    "I need to find some food, and soon."
}

local hunger_messages_3 = {
    "I'm so, SO HUNGRY... I NEED FOOD",
    "I feel like I'm going to starve to death.",
    "If I don't eat something now, I'm not sure what will happen."
}

local hungerMessageCooldown = 30 -- 30 seconds

module[2] = function(owner, org, timeValue)
    local mood = org.mood

    -- Satiety decrease
    local satiety_decrease_rate = 0.25 -- Base rate
    if mood and mood < 30 then
        satiety_decrease_rate = satiety_decrease_rate * (1 + (30 - mood) / 30 * 0.5) -- Up to 50% more satiety loss
    end
    org.satiety = math.max(org.satiety - timeValue * satiety_decrease_rate, 0)

    -- Hunger logic based on satiety
    local hunger_change_rate = 0
    if org.satiety > 80 then
        -- Satiated, hunger decreases
        hunger_change_rate = -2.0 -- Faster decrease when very full
    elseif org.satiety > 20 then
        -- Neutral zone, slow hunger decrease
        hunger_change_rate = -0.5
    else
        -- Low satiety, hunger increases
        hunger_change_rate = 3.0 -- Base hunger increase
        if org.satiety <= 10 then
            hunger_change_rate = 5.0 -- Faster increase
        end
        if org.satiety == 0 then
            hunger_change_rate = 7.0 -- Fastest increase when empty
        end
    end

    local oldHunger = org.hungry
    org.hungry = math.Clamp(org.hungry + timeValue * hunger_change_rate * 0.1, 0, 100)
    org.hungry = Round(org.hungry or 0,3)


    -- Debuffs and messages based on hunger
    if hg_hungersystem:GetBool() then
        if org.hungry > oldHunger then -- Only show messages if hunger is increasing
            if org.hungry > 95 then
                if org.isPly and not org.otrub and (org.lastHungerMessageTime or 0) < CurTime() then
                    org.lastHungerMessageTime = CurTime() + hungerMessageCooldown
                    local message = hunger_messages_3[math.random(#hunger_messages_3)]
                    owner:Notify(message, 15, "starvation_critical", 0, nil, Color(255, 0, 0))
                end
                org.o2[1] = math.max(org.o2[1] - timeValue * 0.1, 0)
            elseif org.hungry > 75 then
                if org.isPly and not org.otrub and (org.lastHungerMessageTime or 0) < CurTime() then
                    org.lastHungerMessageTime = CurTime() + hungerMessageCooldown
                    local message = hunger_messages_2[math.random(#hunger_messages_2)]
                    owner:Notify(message, 15, "starvation_warning_2", 0, nil, Color(255, 100, 100))
                end
                org.stomach = math.min(org.stomach + timeValue * 0.01, 1)
                org.intestines = math.min(org.intestines + timeValue * 0.01, 1)
            elseif org.hungry > 50 then
                if org.isPly and not org.otrub and (org.lastHungerMessageTime or 0) < CurTime() then
                    org.lastHungerMessageTime = CurTime() + hungerMessageCooldown
                    local message = hunger_messages_1[math.random(#hunger_messages_1)]
                    owner:Notify(message, 15, "starvation_warning_1")
                end
            end
        else
             if org.isPly then
                owner:ResetNotification("starvation_warning_1")
                owner:ResetNotification("starvation_warning_2")
                owner:ResetNotification("starvation_critical")
            end
        end

        if org.hungry > 60 then
            local pain_multiplier = math.Clamp(math.Remap(org.hungry, 60, 100, 0.1, 2), 0.1, 2)
            org.painadd = (org.painadd or 0) + timeValue * pain_multiplier
        end
    end


    if (org.intestines > 0.5 or org.stomach > 0.5) and not org.otrub and owner:IsPlayer() and org.satiety > 1 then
        if not org.randomPainSound or org.randomPainSound < CurTime() then
            org.randomPainSound = CurTime() + math.random(20,45)
            owner:EmitSound("zcitysnd/"..(ThatPlyIsFemale(owner) and "female" or "male").."/pain_"..math.random(1,8)..".mp3")
            org.painadd = (org.painadd or 0) + 20
        end
    end

    -- Benefits from satiety (not hunger)
    local mood_blood_bonus = 1
    if mood and mood >= 80 then
        mood_blood_bonus = 1.1 -- 10% bonus to blood regeneration
    end
    -- Blood and HP regen still rely on satiety, as you need substance to regenerate.
    org.blood = min(org.blood + timeValue * (org.satiety/10) * mood_blood_bonus, 5000)

    if mood and mood > 70 then
        local mood_bonus = (mood - 70) / 30 * 0.2 -- Up to 20% bonus healing
        org.regeneratehp = (!((org.regeneratehp or 0) >= 1) and min( (org.regeneratehp or 0) + timeValue * (org.satiety/100) * (1 + mood_bonus), 1)) or 0
    else
        org.regeneratehp = (!((org.regeneratehp or 0) >= 1) and min( (org.regeneratehp or 0) + timeValue * (org.satiety/100), 1)) or 0
    end
    owner:SetHealth(min(owner:Health() + (org.regeneratehp or 0),100))

    -- Mood effects
    if mood then
        local new_mood = mood
        if org.hungry > 50 then
            local mood_loss = (org.hungry - 50) / 50 * timeValue * 0.5 -- Mood loss starts when hunger is over 50
            new_mood = new_mood - mood_loss * (hg.organism.GetMoodInertiaMultiplier and hg.organism.GetMoodInertiaMultiplier(owner) or 1)
        end

        if org.satiety > 80 then
            local mood_gain = (org.satiety - 80) / 20 * timeValue * 0.2 -- Mood gain starts when satiety is over 80
            new_mood = new_mood + mood_gain
        end

        new_mood = math.Clamp(new_mood, 0, 100)
        if new_mood != mood then
            org.mood = new_mood
        end
    end
end