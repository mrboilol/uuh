if SERVER then
    CreateConVar("zb_dev", 0, FCVAR_ARCHIVE)
end

if (CLIENT) then
    --sw и sh как глобальные переменные
    sw, sh = ScrW(), ScrH()

    hook.Add( "OnScreenSizeChanged", "sw_sh_globals", function()
        sw, sh = ScrW(), ScrH()
    end)

    --светящийся текст

    local old = surface.CreateFont
    local cache = {}

    local header = "glow_text_"
    surface.madefonts = surface.madefonts or {}
    local made = surface.madefonts


    function surface.CreateFont(name, info)
        made[name] = nil
        cache[name] = info

        old(name, info)
    end

    function ZB_GetFontTable(name)
        return cache[name]
    end

    function draw.GlowingText(text, font, x, y, col, colglow, colglow2, align, align2)
        align = align or TEXT_ALIGN_LEFT
        align2 = align2 or align or TEXT_ALIGN_CENTER

        local bfont1 = header .. font
        local bfont2 = header .. font .. "2"

        if !made[font] then
            local fontdata = ZB_GetFontTable(font)

            fontdata.blursize = 4
            surface.CreateFont(bfont1, fontdata)
            fontdata.blursize = 20
            surface.CreateFont(bfont2, fontdata)
            made[font] = true
        end

        draw.SimpleText( text, bfont1, x, y, colglow or ColorAlpha(col,150), align, align2)
        draw.SimpleText( text, bfont2, x, y, colglow2 or colglow and ColorAlpha(colglow,50) or ColorAlpha(col, 50), align, align2)
        draw.SimpleText( text, font, x, y, col, align, align2)
    end

    local original_draw_simpletext = draw.SimpleText
    local scramble_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}\|;:'\",./<>?"

    local function scramble_text(text, brain_damage)
        if not text or text == '' or brain_damage <= 0 then return text end
        
        local scrambled_text = ""
        local text_len = utf8.len(text)
        local scramble_chance = math.min(brain_damage * 0.75, 0.9)

        for i = 1, text_len do
            local char = utf8.sub(text, i, i)
            if char == ' ' then
                scrambled_text = scrambled_text .. ' '
            elseif math.Rand(0, 1) < scramble_chance then
                scrambled_text = scrambled_text .. string.sub(scramble_chars, math.random(1, #scramble_chars), math.random(1, #scramble_chars))
            else
                scrambled_text = scrambled_text .. char
            end
        end
        return scrambled_text
    end

    draw.SimpleText = function(text, font, x, y, color, xalign, yalign)
        local ply = LocalPlayer()
        local brain_damage = 0
        if IsValid(ply) and ply.organism and ply.organism.brain then
            brain_damage = ply.organism.brain
        end

        local modified_text = scramble_text(text, brain_damage)
        original_draw_simpletext(modified_text, font, x, y, color, xalign, yalign)
    end
end