-- cl_moodles.lua
-- Client-side moodle rendering template
if not CLIENT then return end

local DEBUG_COLOR_CL_ADD = Color(0, 255, 0)
local DEBUG_COLOR_CL_REMOVE = Color(255, 0, 0)
local color_black = Color(0, 0, 0, 255)

CreateClientConVar("moodle_debug_draw", 0, true, false, "Toggle client-side moodle debug HUD (1=on, 0=off)")
local function IsDebugDrawEnabled() return GetConVar("moodle_debug_draw"):GetInt() == 1 end

local CLIENT_MOODLES = {}

local CRITICAL_MOODLES = {
    ["bleeding_4"] = true,
    ["brain_damage_4"] = true,
    ["cardiac_arrest"] = true,
    ["cold_4"] = true,
    ["heat_4"] = true,
    ["depression_4"] = true,
    ["endurance_4"] = true,
    ["faint_4"] = true,
    ["fractured_neck"] = true,
    ["hemothorax"] = true,
    ["hunger_5"] = true,
    ["internal_bleed"] = true,
    ["overdose_4"] = true,
    ["oxygen_3"] = true,
    ["pain_4"] = true,
    ["respfailure"] = true,
    ["rippedeye_4"] = true,
    ["hypovolemia_4"] = true,
    ["unconscious"] = true,
    ["sepsis"] = true,
    ["horrified"] = true,
    ["deceased"] = true,
}

-- =======================================================
-- TOOLTIP DATA
-- =======================================================
local MOODLE_INFO = {
    ["amputation"] = { title = "Amputation", desc = "One of your limbs is missing!" },
    ["bleeding_1"] = { title = "Minor Bleeding", desc = "Blood is leaking out of you, but it should be alright." },
    ["bleeding_2"] = { title = "Moderate Bleeding", desc = "You are losing blood, But if you are healthy then its ok." },
    ["bleeding_3"] = { title = "Severe Bleeding", desc = "Blood is leaking out of you, patch it up!" },
    ["bleeding_4"] = { title = "Catastrophic Bleeding", desc = "Why are you looking at this? Go find a bandage!" },
    ["bradycardia"] = { title = "Bradycardia", desc = "Your heart rate is low, something might be wrong..." },
    ["brain_damage_1"] = { title = "Minor Brain Damage", desc = "Huh?." },
    ["brain_damage_2"] = { title = "Moderate Brain Damage", desc = "I smell something very weird..." },
    ["brain_damage_3"] = { title = "Severe Brain Damage", desc = "Aug.h.. Whuat.?" },
    ["brain_damage_4"] = { title = "Critical Brain Damage", desc = "..." },
    ["cardiac_arrest"] = { title = "Cardiac Arrest", desc = "You will soon go to sleep for a very long time." },
    ["cold_1"] = { title = "Chilly", desc = "Its a little cold for comfort." },
    ["cold_2"] = { title = "Cold", desc = "Is it that cold outside?" },
    ["cold_3"] = { title = "Very Cold", desc = "Its really, REALLY cold." },
    ["cold_4"] = { title = "Hypothermia", desc = "Its... So... Cold..." },
    ["concussion"] = { title = "Incapacitated", desc = "You need help to get up." },
    ["deaf_1"] = { title = "Tinnitus", desc = "Your sensitive ears are ringing." },
    ["deaf_2"] = { title = "Partial Deafness", desc = "You barely can hear." },
    ["deaf_3"] = { title = "Deaf", desc = "You cannot hear anything." },
    ["deceased"] = { title = "Critical", desc = "This is the end of you. Goodbye." },
    ["depression_1"] = { title = "Sad", desc = "Find things that are good for you!" },
    ["depression_2"] = { title = "Depressed", desc = "Maybe you didnt eat enough?" },
    ["depression_3"] = { title = "Severely Depressed", desc = "Life stopped making sense." },
    ["depression_4"] = { title = "Suicidal", desc = "You will soon leave this world without a care." },
    ["dislocated_spine"] = { title = "Damaged Spine", desc = "For some reason you cant move your legs." },
    ["dislocated_jaw"] = { title = "Dislocated Jaw", desc = "Your jaw is out of place, put it back in!" },
    ["dislocation"] = { title = "Dislocation", desc = "Its not really that bad, but its recommened to place it back." },
    ["encumbered"] = { title = "Encumbered", desc = "You are severely immobilized." },
    ["endurance_1"] = { title = "Tired", desc = "Lets take a break..." },
    ["endurance_2"] = { title = "Exhausted", desc = "Lets REALLY take a break..." },
    ["endurance_3"] = { title = "Severely Exhausted", desc = "I can barely go on..." },
    ["endurance_4"] = { title = "Out of Breath", desc = "Too much... TOO MUCH..." },
    ["energized"] = { title = "Energized", desc = "Feeling great! You are full of energy." },
    ["faint_1"] = { title = "Dizzy", desc = "Feeling a litle sleepy..." },
    ["faint_2"] = { title = "Disoriented", desc = "My eyes are starting to close..." },
    ["faint_3"] = { title = "Faint", desc = "Its hard to stay balanced..." },
    ["faint_4"] = { title = "Low Consciousness", desc = "I think im about to fall asleep right about now..." },
    ["fight_or_flight"] = { title = "Fight or Flight", desc = "Alert, Pain is numbed for now..." },
    ["fracture"] = { title = "Fracture", desc = "One of your limbs is broken, you should get it fixed..." },
    ["fractured_neck"] = { title = "Fractured Neck", desc = "I cant move..." },
    ["fractured_ribs"] = { title = "Fractured Ribs", desc = "Better hope none of them are poking at your lungs..." },
    ["happy_1"] = { title = "Happy", desc = "Satisfied with what you have right now." },
    ["happy_2"] = { title = "Joyful", desc = "Life feels nice." },
    ["happy_3"] = { title = "Ecstatic", desc = "Im loving life right now!" },
    ["happy_4"] = { title = "Euphoric", desc = "Nothing can stop me!" },
    ["heat_1"] = { title = "Warm", desc = "Bit too warm for comfort" },
    ["heat_2"] = { title = "Hot", desc = "Is it summer season already?" },
    ["heat_3"] = { title = "Very Hot", desc = "Its WAY too hot..." },
    ["heat_4"] = { title = "Hyperthermia", desc = "I CANT TAKE THIS HEAT ANYMORE!" },
    ["hemothorax"] = { title = "Pneumothorax", desc = "Its like breathing does nothing..." },
    ["hypovolemia_1"] = { title = "Mild Hypovolemia", desc = "You've lost some blood. You feel a bit weak." },
    ["hypovolemia_2"] = { title = "Moderate Hypovolemia", desc = "Significant blood loss. You feel weak and dizzy." },
    ["hypovolemia_3"] = { title = "Severe Hypovolemia", desc = "You are on the verge of collapsing from blood loss." },
    ["hypovolemia_4"] = { title = "Critical Hypovolemia", desc = "Your body is shutting down from a lack of blood." },
    ["hunger_1"] = { title = "Peckish", desc = "I could go for a bite." },
    ["hunger_2"] = { title = "Hungry", desc = "I could eat a horse right now." },
    ["hunger_3"] = { title = "Very Hungry", desc = "Now im hungry..." },
    ["hunger_4"] = { title = "Starving", desc = "Im REALLY hungry..." },
    ["hunger_5"] = { title = "REALLY Hungry", desc = "Food..." },
    ["internal_bleed"] = { title = "Internal Bleeding", desc = "Your guts are bleeding!" },
    ["overdose_1"] = { title = "Minor Overdose", desc = "This feels good..." },
    ["overdose_2"] = { title = "Overdose", desc = "This feels REALLY good..." },
    ["overdose_3"] = { title = "Severe Overdose", desc = "I see sounds and hear colors..." },
    ["overdose_4"] = { title = "Critical Overdose", desc = "Okay, i think i took too much..." },
    ["oxygen"] = { title = "Low Oxygen", desc = "My skin is all weird and rubbery..." },
    ["oxygen_2"] = { title = "Very Low Oxygen", desc = "Air.. I need air..." },
    ["oxygen_3"] = { title = "Critical Oxygen", desc = "Brain damage is starting to set in." },
    ["pain_1"] = { title = "Minor Pain", desc = "Just some discomfort." },
    ["pain_2"] = { title = "Moderate Pain", desc = "Something might be wrong..." },
    ["pain_3"] = { title = "Severe Pain", desc = "Something is wrong..." },
    ["pain_4"] = { title = "Excruciating Pain", desc = "AAAAAAAAAAAAAAAAAAAAAAAAAAAA" },
    ["respfailure"] = { title = "Respiratory Failure", desc = "I cant breathe..." },
    ["rippedeye_3"] = { title = "Missing Eye", desc = "I cant see out of my eye." },
    ["rippedeye_4"] = { title = "Blind", desc = "Who turned the lights off?" },
    ["rippedjaw"] = { title = "Fractured Jaw", desc = "Wheres yo head at?" },
    ["shock"] = { title = "Shock", desc = "Hurts so much i cant move..." },
    ["speechless"] = { title = "Speechless", desc = "I dont know about people understanding your gibberish." },
    ["stimulated"] = { title = "Stimulated", desc = "NOW nothing cant stop me!" },
    ["tachycardia"] = { title = "Tachycardia", desc = "Something is probably wrong, or not." },
    ["thoraxdestroyed"] = { title = "Skull Fracture", desc = "Your skull is poking at your brain as you read this!" },
    ["trauma_1"] = { title = "Anxious", desc = "You are feeling a bit on edge." },
    ["trauma_2"] = { title = "Scared", desc = "You dont want to continue experiencing this." },
    ["trauma_3"] = { title = "Terrified", desc = "You are REALLY scared." },
    ["trauma_4"] = { title = "Really fucking scared", desc = "You cant even comprehend your emotions." },
    ["unconscious"] = { title = "Unconscious", desc = "Or sleeping, but probably knocked out." },
    ["sepsis"] = { title = "Sepsis", desc = "Not so fun now is it?" },
    ["horrified"] = { title = "Critically Injured", desc = "You cant be saved." },
}

-- Networking
net.Receive("Moodle_Add", function()
    local id = net.ReadString()
    local tex = net.ReadString()
    local cnt = net.ReadInt(8)
    
    local existing = CLIENT_MOODLES[id]
    CLIENT_MOODLES[id] = existing or { texture = tex, count = cnt, mat = Material(tex) }
    CLIENT_MOODLES[id].texture = tex
    CLIENT_MOODLES[id].count = cnt
    CLIENT_MOODLES[id].mat = CLIENT_MOODLES[id].mat or Material(tex)
    CLIENT_MOODLES[id].spawn = CurTime() -- Mark for popup animation
    
    if IsDebugDrawEnabled() then MsgC(DEBUG_COLOR_CL_ADD, "[M] + "..id.."\n") end
end)

net.Receive("Moodle_Remove", function()
    local id = net.ReadString()
    if id == "*" then 
        CLIENT_MOODLES = {} 
        return 
    end
    
    CLIENT_MOODLES[id] = nil
    if IsDebugDrawEnabled() then MsgC(DEBUG_COLOR_CL_REMOVE, "[MM] - "..id.."\n") end
end)

-- HUD paint
hook.Add("HUDPaint", "Moodle_Draw", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then 
        CLIENT_MOODLES = {} 
        return 
    end
    if table.IsEmpty(CLIENT_MOODLES) then return end
    
    -- Layout settings
    local iconSize, pad = 48, 6
    local baseX = 16 
    local baseY = ScrH() - iconSize - 16
    local screenW = ScrW() > 0 and ScrW() or 1920
    
    local mx, my = gui.MousePos()
    local hovered = nil
    local x = baseX
    local yRowOffset = 0

    -- Animation helper
    local function easeOutBack(t)
        local c1 = 1.70158
        local c3 = c1 + 1
        return 1 + c3 * (t - 1)^3 + c1 * (t - 1)^2
    end

    -- Draw Icons
    for id, data in pairs(CLIENT_MOODLES) do
        local spawn = data.spawn or CurTime()
        local dt = CurTime() - spawn
        
        -- Animations
        local animT = math.Clamp(dt / 0.55, 0, 1)
        local scale = 0.2 + easeOutBack(animT) * 0.8
        local alpha = math.Clamp(dt / 0.25, 0, 1) * 255

        local drawW, drawH = iconSize * scale, iconSize * scale
        
        -- Wrap to new row if hitting right edge
        if (x + iconSize) > (screenW - 16) then
            x = baseX
            yRowOffset = yRowOffset + (iconSize + pad)
        end

        local drawY = baseY - yRowOffset + (iconSize - drawH)
        local drawX = x

        -- Flashing border for critical moodles
        -- if CRITICAL_MOODLES[id] then
        --     local flash = (math.sin(CurTime() * 8) + 1) / 2
        --     local flashAlpha = 50 + flash * 150
        --     surface.SetDrawColor(255, 0, 0, flashAlpha)
        --     surface.DrawOutlinedRect(drawX - 1, drawY - 1, drawW + 2, drawH + 2)
        --     surface.DrawOutlinedRect(drawX - 2, drawY - 2, drawW + 4, drawH + 4)
        -- end

        -- Draw texture or fallback box
        if data.mat and not data.mat:IsError() then
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.SetMaterial(data.mat)
            surface.DrawTexturedRect(drawX, drawY, drawW, drawH)
        else
            surface.SetDrawColor(255, 0, 255, alpha)
            surface.DrawRect(drawX, drawY, drawW, drawH)
        end

        -- Draw stack count if > 1
        if data.count and data.count > 1 then
            draw.SimpleText(tostring(data.count), "DermaDefaultBold", drawX + drawW - 4, drawY + drawH - 4, color_black, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        end

        -- Hover detection (uses unscaled area for easier targeting)
        if mx >= drawX and mx <= drawX + drawW and my >= drawY and my <= drawY + drawH then
            hovered = id
        end
        
        x = x + iconSize + pad
    end

    -- Draw Tooltip
    if hovered and MOODLE_INFO[hovered] then
        local info = MOODLE_INFO[hovered]
        local tw = 360
        local tx = math.min(mx + 12, ScrW() - tw - 12)
        local ty = my - 72
        
        draw.RoundedBox(6, tx - 6, ty - 6, tw, 68, Color(0, 0, 0, 200))
        draw.SimpleText(info.title, "DermaDefaultBold", tx, ty, color_white)
        draw.SimpleText(info.desc, "DermaDefault", tx, ty + 22, Color(200, 200, 200))
    end
end)