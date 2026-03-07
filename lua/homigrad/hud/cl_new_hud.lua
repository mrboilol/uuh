-- Convars for the new HUD
local hud_enabled = CreateClientConVar("homigrad_hud_enabled", "1", true, false, "Enable the new Homigrad HUD")
local hud_open_key = CreateClientConVar("homigrad_hud_open_key", "k", true, false, "Key to open the new Homigrad HUD")

local hud_open = false

local function draw_hud()
    if not hud_enabled:GetBool() then return end
    if not hud_open then return end

    -- Simple HUD for demonstration
    local w, h = ScrW(), ScrH()
    draw.RoundedBox(8, 10, h - 110, 200, 100, Color(0, 0, 0, 150))
    draw.SimpleText("Homigrad HUD", "DermaDefault", 60, h - 90, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end
hook.Add("HUDPaint", "homigrad_new_hud", draw_hud)

local function toggle_hud(ply, bind, pressed)
    if not hud_enabled:GetBool() then return end

    local key_name = hud_open_key:GetString()
    if string.lower(bind) == "gm_showhelp" and key_name == "f1" then
        hud_open = not hud_open
        return true
    end

    if string.lower(bind) == key_name then
        hud_open = not hud_open
        return true
    end
end
hook.Add("PlayerBindPress", "homigrad_new_hud_toggle", toggle_hud)
