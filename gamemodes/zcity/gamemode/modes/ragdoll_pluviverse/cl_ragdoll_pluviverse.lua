local MODE = MODE

MODE.name = "ragdoll_pluviverse"

local ragdollPluviverseMusic
local ragdollPluviverseActive = false
local ragdollPluviverseSongList = {
    "RAGDOLL.wav",
    "CHARGE.wav",
    "UNIVERSE.wav"
}
local ragdollPluviverseSongTimer = "RagdollPluviverseNextSong"

local function StopRagdollPluviverseMusic()
    if IsValid(ragdollPluviverseMusic) then
        ragdollPluviverseMusic:Stop()
    end
    ragdollPluviverseMusic = nil
    timer.Remove(ragdollPluviverseSongTimer)
end

local function PickNextRagdollPluviverseSong(current)
    if #ragdollPluviverseSongList <= 1 then
        return ragdollPluviverseSongList[1]
    end
    local nextSong = ragdollPluviverseSongList[math.random(#ragdollPluviverseSongList)]
    if current and #ragdollPluviverseSongList > 1 then
        while nextSong == current do
            nextSong = ragdollPluviverseSongList[math.random(#ragdollPluviverseSongList)]
        end
    end
    return nextSong
end

local function PlayRagdollPluviverseMusic(fileName)
    StopRagdollPluviverseMusic()
    sound.PlayFile("sound/" .. fileName, "noplay", function(station)
        if IsValid(station) then
            ragdollPluviverseMusic = station
            local musicVolume = GetConVar("snd_musicvolume"):GetFloat()
            ragdollPluviverseMusic:SetVolume(math.Clamp(musicVolume * 1.0, 0, 1))
            station:Play()
            station:EnableLooping(false)
            local length = station:GetLength()
            if length and length > 0 then
                timer.Create(ragdollPluviverseSongTimer, length + 0.05, 1, function()
                    if not ragdollPluviverseActive then return end
                    local nextSong = PickNextRagdollPluviverseSong(fileName)
                    if nextSong then
                        PlayRagdollPluviverseMusic(nextSong)
                    end
                end)
            end
        end
    end)
end

net.Receive("ragdoll_pluviverse_start", function()
    zb.RemoveFade()
    ragdollPluviverseActive = true
    PlayRagdollPluviverseMusic(net.ReadString())
end)

net.Receive("ragdoll_pluviverse_end", function()
    ragdollPluviverseActive = false
    StopRagdollPluviverseMusic()
end)

local fighter = {
    objective = "Survive the fall. Kill everyone.",
    name = "Ragdoll Fighter",
    color1 = Color(0,120,190)
}

surface.CreateFont("PluviverseHUD_Large", {
    font = "Roboto",
    size = 32,
    weight = 800,
    shadow = true,
})

surface.CreateFont("PluviverseHUD_Medium", {
    font = "Roboto",
    size = 24,
    weight = 600,
    shadow = true,
})

surface.CreateFont("PluviverseHUD_Small", {
    font = "Roboto",
    size = 16,
    weight = 500,
    shadow = true,
})

surface.CreateFont("PluviverseHUD_BarText", {
    font = "Roboto",
    size = 22,
    weight = 700,
    shadow = true,
})

surface.CreateFont("PluviverseHUD_Kill", {
    font = "Roboto",
    size = 22,
    weight = 800,
    shadow = true,
})

surface.CreateFont("PluviverseHUD_KillSmall", {
    font = "Roboto",
    size = 18,
    weight = 700,
    shadow = true,
})

local function DarkenColor(col, mul)
    return Color(
        math.Clamp(col.r * mul, 0, 255),
        math.Clamp(col.g * mul, 0, 255),
        math.Clamp(col.b * mul, 0, 255),
        255
    )
end

local function DrawStatBar(x, y, w, h, value, max, fillColor, iconChar)
    local fraction = math.Clamp(value / max, 0, 1)
    local radius = math.floor(h * 0.35)
    local iconW = h
    draw.RoundedBox(radius, x, y, w, h, Color(18, 18, 18, 230))
    draw.RoundedBox(radius, x + 1, y + 1, w - 2, h - 2, Color(35, 35, 35, 230))
    local fillW = math.floor((w - 2) * fraction)
    if fillW > 0 then
        draw.RoundedBox(radius - 1, x + 1, y + 1, fillW, h - 2, fillColor)
    end
    local iconColor = DarkenColor(fillColor, 0.85)
    draw.RoundedBoxEx(radius - 1, x + 1, y + 1, iconW - 2, h - 2, iconColor, true, false, true, false)
    draw.SimpleText(iconChar, "PluviverseHUD_BarText", x + iconW / 2, y + h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local text = math.floor(value) .. " | " .. math.floor(max)
    draw.SimpleText(text, "PluviverseHUD_BarText", x + w / 2, y + h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local function WrapText(text, font, maxWidth)
    if text == "" then return {}, 0 end
    surface.SetFont(font)
    local words = string.Explode(" ", text)
    local lines = {}
    local line = ""
    for i = 1, #words do
        local word = words[i]
        local test = line == "" and word or (line .. " " .. word)
        local testW = surface.GetTextSize(test)
        if testW > maxWidth and line ~= "" then
            lines[#lines + 1] = line
            line = word
        else
            line = test
        end
    end
    if line ~= "" then
        lines[#lines + 1] = line
    end
    return lines, #lines
end

local function OrganismCondition(ply)
    local org = ply.new_organism or ply.organism
    if not org or not org.blood then
        local hp = ply:Health()
        local maxHp = ply:GetMaxHealth()
        return hp, maxHp
    end
    local blood = math.Clamp(org.blood or 0, 0, 5000) / 5000
    local pain = 1 - math.Clamp((org.pain or 0) / 100, 0, 1)
    local brain = 1 - math.Clamp(org.brain or 0, 0, 1)
    local o2 = 1
    if org.o2 and org.o2[1] and org.o2.range then
        o2 = math.Clamp(org.o2[1] / org.o2.range, 0, 1)
    end
    local condition = (blood * 0.5) + (pain * 0.2) + (brain * 0.2) + (o2 * 0.1)
    if org.otrub then
        condition = condition * 0.2
    end
    return math.floor(condition * 100), 100
end

local killNotifications = {}
local killStreakCount = 0
local lastKillTime = 0

net.Receive("ragdoll_pluviverse_kill", function()
    local name = net.ReadString()
    local weapon = net.ReadString()
    local now = CurTime()
    if now <= lastKillTime + 3 then
        killStreakCount = killStreakCount + 1
    else
        killStreakCount = 1
    end
    lastKillTime = now
    local multiText
    if killStreakCount == 2 then
        multiText = "DOUBLE KILL!"
    elseif killStreakCount == 3 then
        multiText = "TRIPLE KILL!"
    elseif killStreakCount > 3 then
        multiText = "MULTI KILL!"
    end
    table.insert(killNotifications, {
        name = name,
        weapon = weapon,
        time = CurTime() + 3,
        anim = 0,
        multiText = multiText,
        multiTime = multiText and (CurTime() + 2.2) or 0
    })
end)


function MODE:HUDPaint()
    local sw, sh = ScrW(), ScrH()
    local ply = LocalPlayer()

    -- Start Screen / Immunity Logic
    if zb.ROUND_START + 15 > CurTime() then
        draw.SimpleText("IMMUNITY ENDS IN: " .. string.FormattedTime(zb.ROUND_START + 15 - CurTime(), "%02i:%02i:%02i"), "ZB_HomicideMedium", sw * 0.5, sh * 0.75, Color(255,55,55), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    if not ply:Alive() then return end
    
    -- Start Screen Fade
    if zb.ROUND_START + 8.5 > CurTime() then
        local fade = math.Clamp(zb.ROUND_START + 8 - CurTime(),0,1)
        draw.SimpleText("Homicide | Ragdoll Pluviverse", "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.1, Color(0,162,255, 255 * fade), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local Rolename = fighter.name
        local ColorRole = fighter.color1
        ColorRole.a = 255 * fade
        draw.SimpleText("You are a "..Rolename , "ZB_HomicideMediumLarge", sw * 0.5, sh * 0.5, ColorRole, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local Objective = fighter.objective
        local ColorObj = fighter.color1
        ColorObj.a = 255 * fade
        draw.SimpleText( Objective, "ZB_HomicideMedium", sw * 0.5, sh * 0.9, ColorObj, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        return
    end

    local slotCount = 5
    local slotSize = 66
    local spacing = 6
    local totalW = (slotCount * slotSize) + ((slotCount - 1) * spacing)
    local startXInv = (sw - totalW) / 2
    local startYInv = sh - slotSize - 18

    -- Kill Notifications (Center Screen)
    for i = #killNotifications, 1, -1 do
        local notif = killNotifications[i]
        if notif.time < CurTime() then
            table.remove(killNotifications, i)
        else
            notif.anim = math.Clamp(notif.anim + FrameTime() * 6, 0, 1)
            local alpha = 255
            if notif.time - CurTime() < 0.4 then
                alpha = (notif.time - CurTime()) / 0.4 * 255
            end
            local nameText = "KILLED " .. string.upper(notif.name)
            local weaponText = string.upper(notif.weapon or "")
            surface.SetFont("PluviverseHUD_Kill")
            local nameW, nameH = surface.GetTextSize(nameText)
            surface.SetFont("PluviverseHUD_KillSmall")
            local weaponW, weaponH = surface.GetTextSize(weaponText)
            local padding = 12
            local barH = 28
            local subH = 24
            local barW = math.max(320, nameW + weaponW + padding * 3)
            local x = (sw - barW) * 0.5
            local y = startYInv - (barH + 10) - ((i - 1) * (barH + 8 + (notif.multiText and subH + 6 or 0))) - (notif.multiText and (subH + 6) or 0)
            local slide = math.floor((1 - notif.anim) * 40)
            local drawX = x - slide
            draw.RoundedBox(6, drawX, y, barW, barH, Color(150, 35, 35, alpha))
            draw.RoundedBox(6, drawX + 1, y + 1, barW - 2, barH - 2, Color(220, 70, 70, alpha))
            draw.SimpleText(nameText, "PluviverseHUD_Kill", drawX + padding, y + barH * 0.5, Color(255, 255, 255, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(weaponText, "PluviverseHUD_KillSmall", drawX + barW - padding, y + barH * 0.5, Color(255, 255, 255, alpha), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            if notif.multiText and notif.multiTime > CurTime() then
                local subY = y + barH + 6
                draw.RoundedBox(6, drawX + 10, subY, barW - 20, subH, Color(255, 120, 20, alpha))
                draw.SimpleText(notif.multiText, "PluviverseHUD_Kill", drawX + barW * 0.5, subY + subH * 0.5, Color(255, 255, 255, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end

    -- Custom HUD
    local health, maxHealth = OrganismCondition(ply)

    -- Health & Armor (Bottom Left)
    local barW, barH = 460, 42
    local startX = 20
    local startY = startYInv + (slotSize - barH) * 0.5

    DrawStatBar(startX, startY, barW, barH, health, maxHealth, Color(90, 235, 120), "♥")

    -- Weapon Info (Bottom Right)
    local wep = ply:GetActiveWeapon()
    if IsValid(wep) then
        local name = wep.PrintName or wep:GetClass()
        local desc = wep.Instructions or wep.Description or ""
        local rarity = wep.RarityName or wep.Rarity or wep.rarity or "RARE"
        local stars = tonumber(wep.RarityStars or wep.stars or wep.rarityStars) or 2
        stars = math.Clamp(stars, 1, 5)

        local clip = wep:Clip1()
        local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())
        local ammoValue = clip >= 0 and clip or reserve

        local infoW = 460
        local infoX = sw - infoW - 20
        local headerH = 24
        local padding = 12
        local descMaxW = infoW - padding * 2 - 60
        local descLines, descCount = WrapText(tostring(desc), "PluviverseHUD_Small", descMaxW)
        local _, nameH = surface.GetTextSize("Hg")
        surface.SetFont("PluviverseHUD_Small")
        local _, lineH = surface.GetTextSize("Hg")
        local infoH = headerH + padding + nameH + (descCount > 0 and (descCount * lineH + 6) or 0) + padding
        local infoY = startYInv + (slotSize - infoH) * 0.5
        draw.RoundedBox(10, infoX, infoY, infoW, infoH, Color(70, 20, 20, 230))
        draw.RoundedBoxEx(10, infoX, infoY, infoW, headerH, Color(205, 60, 60, 255), true, true, false, false)

        local starText = string.rep("★", stars)
        draw.SimpleText(string.upper(tostring(rarity)), "PluviverseHUD_Small", infoX + 10, infoY + 3, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(starText, "PluviverseHUD_Small", infoX + infoW - 10, infoY + 3, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        local nameX = infoX + padding
        local nameY = infoY + headerH + padding - 2
        draw.SimpleText(tostring(name), "PluviverseHUD_Medium", nameX, nameY, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local descY = nameY + nameH + 6
        for i = 1, descCount do
            draw.SimpleText(descLines[i], "PluviverseHUD_Small", nameX, descY + (i - 1) * lineH, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end
        draw.SimpleText(tostring(ammoValue), "PluviverseHUD_Large", infoX + infoW - padding, infoY + headerH + padding + nameH * 0.5, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
    end

    -- Top Right Stats (Players & Kills)
    local aliveCount = 0
    for _, p in player.Iterator() do
        if p:Alive() then aliveCount = aliveCount + 1 end
    end
    
    local kills = ply:Frags()
    
    local statX = sw - 20
    local statY = 20
    local statSpacing = 30
    
    -- Add shadow to text for readability
    draw.SimpleText("ALIVE: " .. aliveCount, "PluviverseHUD_Medium", statX, statY, Color(255, 255, 255), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    draw.SimpleText("KILLS: " .. kills, "PluviverseHUD_Medium", statX, statY + statSpacing, Color(255, 100, 100), TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    -- Inventory (Bottom Center)
    local weps = ply:GetWeapons()
    local slotWeapons = {}

    for _, w in ipairs(weps) do
        local slot = (w:GetSlot() or 0) + 1
        if slot >= 1 and slot <= slotCount then
            slotWeapons[slot] = w
        end
    end

    for slot = 1, slotCount do
        local x = startXInv + (slot - 1) * (slotSize + spacing)
        local w = slotWeapons[slot]
        local isActive = IsValid(wep) and w == wep
        local borderColor = isActive and Color(200, 40, 40, 255) or Color(90, 20, 20, 255)
        local innerColor = Color(12, 12, 12, 235)
        local headerH = 16
        draw.RoundedBox(6, x, startYInv, slotSize, slotSize, borderColor)
        draw.RoundedBox(5, x + 2, startYInv + 2, slotSize - 4, slotSize - 4, innerColor)
        draw.RoundedBoxEx(5, x + 2, startYInv + 2, slotSize - 4, headerH, Color(110, 25, 25, 255), true, true, false, false)
        draw.SimpleText(slot, "PluviverseHUD_Small", x + slotSize / 2, startYInv + 4, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        if IsValid(w) then
            local iconX = x + 6
            local iconY = startYInv + headerH + 4
            local iconW = slotSize - 12
            local iconH = slotSize - headerH - 18
            if w.DrawWeaponSelection then
                w:DrawWeaponSelection(iconX, iconY - 2, iconW, iconH + 4, 255)
            else
                local wepName = w.PrintName or w:GetClass()
                local shortName = string.upper(string.sub(wepName, 1, 6))
                draw.SimpleText(shortName, "PluviverseHUD_Small", x + slotSize / 2, iconY + iconH * 0.5, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            local clip = w:Clip1()
            local reserve = ply:GetAmmoCount(w:GetPrimaryAmmoType())
            if clip >= 0 then
                local ammoText = clip .. " | " .. reserve
                draw.SimpleText(ammoText, "PluviverseHUD_Small", x + slotSize / 2, startYInv + slotSize - 6, Color(225, 235, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            end
        end
    end
end

function MODE:RenderScreenspaceEffects()
    if zb.ROUND_START + 7.5 < CurTime() then return end
    
    local fade = math.Clamp(zb.ROUND_START + 7.5 - CurTime(),0,1)

    surface.SetDrawColor(0,0,0,255 * fade)
    surface.DrawRect(-1,-1,ScrW() + 1,ScrH() + 1)
end
