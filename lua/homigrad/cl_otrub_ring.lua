local was_otrub = false
local otrub_effect_start_time = 0

function draw.OutlinedArc(x, y, radius, start_angle, end_angle, num_segments, thickness)
    local poly = {}
    for i = 0, num_segments do
        local angle = start_angle + (end_angle - start_angle) * (i / num_segments)
        local rad = math.rad(angle)
        local x1 = x + math.cos(rad) * radius
        local y1 = y + math.sin(rad) * radius
        local x2 = x + math.cos(rad) * (radius - thickness)
        local y2 = y + math.sin(rad) * (radius - thickness)
        poly[#poly + 1] = {x = x1, y = y1}
        poly[#poly + 1] = {x = x2, y = y2}
    end
    surface.DrawPoly(poly)
end

hook.Add("HUDPaint", "homigrad_otrub_ring", function()
    if not GetConVar("homigrad_new_otrub"):GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local org = ply.organism
    if not org then return end

    if CurTime() < otrub_effect_start_time and org.otrub then return end

    local shock = org.shock or 0
    local radius = ScrH() / 2 - 10

    local color = color_white
    if org.otrub then
        color = Color(255, 0, 0)
    end

    surface.SetDrawColor(color)
    draw.OutlinedArc(ScrW() / 2, ScrH() / 2, radius, 0, 360 * (1 - shock), 64, 2)
end)

hook.Add("Think", "homigrad_otrub_handler", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local org = ply.organism
    if not org then return end

    if org.otrub and not was_otrub then
        ply:ScreenFade(SCREENFADE.IN, color_black, 0.2, 0.5)
        otrub_effect_start_time = CurTime() + 0.7
        
        RunConsoleCommand("stopsound")
        RunConsoleCommand("dsp_room", "27")
        
    elseif not org.otrub and was_otrub then
        RunConsoleCommand("dsp_room", "0")
    end
    
    was_otrub = org.otrub
end)
