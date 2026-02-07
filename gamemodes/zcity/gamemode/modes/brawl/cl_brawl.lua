MODE.name = "brawl"

local currentStage = 1
local stageTotal = 1
local kills = 0
local currentWeapon = ""
local isFinalStage = false
local roundSeconds = 0
local flash = 0
local vignette = false
local graceEnd = 0
local lastMinutePlayed = false

local endPanel
local lastStageStation
local lastStageBannerUntil = 0
local lastStageName = ""


local function CreateEndPanel(winner, list)
    if IsValid(endPanel) then endPanel:Remove() end
    endPanel = vgui.Create("DFrame")
    local sx, sy = ScrW() * 0.5, ScrH() * 0.6
    endPanel:SetSize(sx, sy)
    endPanel:Center()
    endPanel:SetTitle("")
    endPanel:ShowCloseButton(true)
    endPanel:MakePopup()
    function endPanel:Paint(w, h)
        surface.SetDrawColor(30,30,30,220)
        surface.DrawRect(0,0,w,h)
        draw.SimpleText("BRAWL RESULTS", "ZB_InterfaceMediumLarge", w * 0.5, ScreenScale(10), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        local winName = IsValid(winner) and winner:Nick() or "Nobody"
        draw.SimpleText("Winner: " .. winName, "ZB_InterfaceMedium", w * 0.5, ScreenScale(22), Color(255,225,100), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    local scroll = vgui.Create("DScrollPanel", endPanel)
    scroll:SetSize(sx - 20, sy - ScreenScale(40))
    scroll:SetPos(10, ScreenScale(34))
    for i=1, #list do
        local line = vgui.Create("DPanel", scroll)
        line:SetTall(ScreenScale(20))
        line:Dock(TOP)
        line:DockMargin(0,5,0,0)
        local text = string.format("%d. %s — %d Kills", i, list[i].name, list[i].kills)
        function line:Paint(w,h)
            surface.SetDrawColor(50,50,50,200)
            surface.DrawRect(0,0,w,h)
            draw.SimpleText(text, "ZB_InterfaceMedium", 10, h/2, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end
end

net.Receive("brawl_start", function()
    roundSeconds = net.ReadUInt(16)
    kills = 0
    flash = 1
    vignette = false
    lastMinutePlayed = false
    chat.AddText(Color(255,200,120), "Get kills to unlock next weapon.")
    surface.PlaySound("buttons/button15.wav")
end)

net.Receive("brawl_grace", function()
    graceEnd = net.ReadFloat()
end)

net.Receive("brawl_music", function()
    local file = net.ReadString()
    if file and file ~= "" then
        local path = string.StartWith(file, "sound/") and file or ("sound/" .. file)
        sound.PlayFile(path, "noplay", function(station)
            if IsValid(station) then
                station:SetVolume(1)
                station:EnableLooping(false)
                station:Play()
            else
                surface.PlaySound(file)
            end
        end)
    end
end)

net.Receive("brawl_progress", function()
    currentStage = net.ReadUInt(12)
    stageTotal = net.ReadUInt(12)
    kills = net.ReadUInt(16)
    currentWeapon = net.ReadString()
    isFinalStage = net.ReadBool()
    flash = 1
    surface.PlaySound("items/itempickup.wav")
end)

net.Receive("brawl_final", function()
    local ply = net.ReadEntity()
    local finalW = net.ReadString()
    chat.AddText(Color(255,255,255), string.format("[BRAWL] %s reached the FINAL STAGE", IsValid(ply) and ply:Nick() or ""))
    vignette = false
    lastStageName = IsValid(ply) and ply:Nick() or ""
    lastStageBannerUntil = CurTime() + 5
    surface.PlaySound("buttons/button15.wav")
end)

net.Receive("brawl_end", function()
    local winner = net.ReadEntity()
    local count = net.ReadUInt(7)
    local list = {}
    for i=1, count do
        list[i] = { name = net.ReadString(), kills = net.ReadUInt(16) }
    end
    surface.PlaySound("buttons/button15.wav")
    CreateEndPanel(winner, list)
end)

net.Receive("brawl_round_end", function()
    if IsValid(lastStageStation) then lastStageStation:Stop() lastStageStation = nil end
    sound.PlayFile("sound/brawlwin.mp3", "noplay", function(station)
        if IsValid(station) then
            station:SetVolume(1)
            station:EnableLooping(false)
            station:Play()
        else
            surface.PlaySound("brawlwin.mp3")
        end
    end)
end)

function MODE:HUDPaint()
    flash = math.Approach(flash, 0, FrameTime() * 1.5)
    if roundSeconds > 0 then
        local remain = math.max(0, (zb.ROUND_START or 0) + roundSeconds - CurTime())
        if remain <= 60 and not lastMinutePlayed then
            sound.PlayFile("sound/lastminute.mp3", "noplay", function(station)
                if IsValid(station) then
                    station:SetVolume(0.35)
                    station:EnableLooping(false)
                    station:Play()
                else
                    surface.PlaySound("lastminute.mp3")
                end
            end)
            lastMinutePlayed = true
        end
        draw.SimpleText(string.FormattedTime(remain, "%02i:%02i"), "ZB_InterfaceMedium", ScrW()*0.5, ScreenScale(3), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    if CurTime() < graceEnd and graceEnd > 0 then
        local left = math.ceil(math.max(0, graceEnd - CurTime()))
        draw.SimpleText("Prepare to Brawl — "..left.."s", "ZB_InterfaceMediumLarge", ScrW()*0.5, ScrH()*0.45, Color(220,220,220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    if currentStage and stageTotal and currentWeapon ~= nil then
        local w = ScrW()
        local h = ScreenScale(40)
        local bg = Color(0, 0, 0, 150)
        local x = w * 0.3
        local y = ScreenScale(10)
        local outline = Color(255, 140, 0, 200)
        
        -- Draw background
        draw.RoundedBox(8, x, y, w * 0.4, h, bg)
        
        -- Draw border
        surface.SetDrawColor(outline)
        surface.DrawOutlinedRect(x - 2, y - 2, w * 0.4 + 4, h + 4, 2)
        
        draw.SimpleText(string.format("BRAWL - STAGE %d / %d", currentStage, stageTotal), "ZB_InterfaceMediumLarge", w * 0.5, ScreenScale(18), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Current Weapon: " .. (currentWeapon or ""), "ZB_InterfaceMedium", w * 0.5, ScreenScale(28), Color(230,230,230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText("Kills: " .. tostring(kills or 0), "ZB_InterfaceMedium", w * 0.5, ScreenScale(36), Color(230,230,230), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    if (lastStageBannerUntil or 0) > CurTime() and lastStageName ~= "" then
        draw.SimpleText(string.format("%s reached the FINAL STAGE", lastStageName), "ZB_InterfaceMediumLarge", ScrW()*0.5, ScreenScale(52), Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function MODE:RenderScreenspaceEffects()
    if CurTime() < graceEnd and graceEnd > 0 then
        local t = math.Clamp((graceEnd - CurTime()) / 8, 0, 1)
        local params = {
            ["$pp_colour_addr"] = 0,
            ["$pp_colour_addg"] = 0,
            ["$pp_colour_addb"] = 0,
            ["$pp_colour_brightness"] = -0.05 * t,
            ["$pp_colour_contrast"] = 1 - 0.5 * t,
            ["$pp_colour_colour"] = 1 - t,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0,
            ["$pp_colour_mulb"] = 0,
        }
        DrawColorModify(params)
    end
    -- removed red vignette effect
end


function MODE:RoundStart()
    if IsValid(endPanel) then endPanel:Remove() end
    vignette = false
end

hook.Add("radialOptions", "brawl_disable_drop", function()
    local rnd = CurrentRound and CurrentRound()
    if not rnd or rnd.name ~= "brawl" then return end
    if not hg or not hg.radialOptions then return end
    local filtered = {}
    for i = 1, #hg.radialOptions do
        local opt = hg.radialOptions[i]
        if istable(opt) and opt[2] == "Drop Weapon" then
        else
            filtered[#filtered + 1] = opt
        end
    end
    hg.radialOptions = filtered
end)

net.Receive("brawl_laststage_start", function()
    if IsValid(lastStageStation) then lastStageStation:Stop() lastStageStation = nil end
    sound.PlayFile("sound/laststage.mp3", "noplay", function(station)
        if IsValid(station) then
            station:SetVolume(1)
            station:EnableLooping(true)
            station:Play()
            lastStageStation = station
        end
    end)
end)

net.Receive("brawl_laststage_stop", function()
    local st = lastStageStation
    if not IsValid(st) then return end
    local startVol = st:GetVolume()
    local steps = 10
    for i=1,steps do
        timer.Simple(i * 0.1, function()
            if not IsValid(st) then return end
            st:SetVolume(math.max(0, startVol - (i/steps)*startVol))
            if i == steps then st:Stop() lastStageStation = nil end
        end)
    end
end)
