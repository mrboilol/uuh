surface.CreateFont( "dead font", {
	font = "Arial", -- On Windows/macOS, use the font-name which is shown to you by your operating system Font Viewer. On Linux, the font-name *may* work, but using the file name is more reliable
	extended = false,
	size = 45,
	weight = 3000,
	antialias = false ,
	shadow = true,
} )

surface.CreateFont( "dead font2", {
	font = "Arial", -- On Windows/macOS, use the font-name which is shown to you by your operating system Font Viewer. On Linux, the font-name *may* work, but using the file name is more reliable
	extended = false,
	size = 25,
	weight = 650,
	antialias = false ,
	shadow = true,
} )

local tips = {
    "Mattresses can save your life when falling",
    "skill issue",
    "go play roblox",
    "buy ardor",
    "sharick is a son of a dog",
    "Also try JBMod!",
    "Also try Homifork!",
    "Also try Rads Ragdoll!",
    "Also try Trauma Health System!",
    "Kick - hg_kick",
    "Leaning - +alt1/+alt2",
    "update tomorrow if it's not out - reread",
    "inventory theory",
    "Well, sometimes the opponents are just very lucky.",
    "lmfao how tf do you die",
    "lshell",
    "Something terrible happened on October 1st..",
    "translation theory",
    "a cat has caught you",
    "a terrible spirit lives on hmcd_mansion..",
    "but the game is under development",
    "crow's z city is for pussies",
    "zgradians are dumb retards",
    "Dont run into walls.",
    "Watch the floor! Running over bumps will sometimes trip you.",
    "Hitting the chest is sometimes a better idea than hitting the face.",
    "Lungs and heart have an 80% chance to be protected by ribs.",
    "Wheres your head at???",
    "Go get yo knife go get yo knife...",
    "sometimes i dream about cheese.",
    "RDM RDM RDM RDM RDM RDM RDM RDM",
    "go play terraria",
    "Mannitol can bring back braindead people, unless their brains were blown out."
}



net.Receive("death",function()
local kiler = net.ReadString()//LocalPlayer():GetNWString("killer")
local wep = net.ReadString()//LocalPlayer():GetNWString("killwep")
local bone = net.ReadString()//LocalPlayer():GetNWString("killbone")
hook.Remove("PostDrawHUD","homigdea")
timer.Simple(0.5,function()
LocalPlayer():EmitSound("homigrad/vgui/csgo_ui_crate_open.wav")
local tip = tips[math.random(1,#tips)]
local dead = 0
if bone == "ValveBiped.Bip01_R_Forearm" then bone = "head" end
hook.Add("PostDrawHUD", "homigdea", function()
    local ply = LocalPlayer()
    local w,h = ScrW(),ScrH()
    if not ply:Alive() then
        if dead == 0 then dead = CurTime() end
        
        local elapsed = CurTime() - dead
        local centerX, centerY = ScrW() / 2, ScrH() / 2
        local x, y = centerX, centerY

        if elapsed < 1.5 then
            local step = math.floor(elapsed * 60)
            math.randomseed(step)
            local dampening = math.exp(-elapsed * 6)
            
            x = centerX + math.random(-10000, 10000) * dampening
            y = centerY + math.random(-10000, 10000) * dampening
        end

local scaleX = w / 30
local scaleY = h / 30
surface.SetDrawColor( 255, 255, 255, math.max(15,0.5 * elapsed) )
surface.SetMaterial( Material("bg/points30.png", "noclamp") )
surface.DrawTexturedRectUV(0, 0, w, h, RealTime() * 1,RealTime() * 1,scaleX + RealTime() * 1,scaleY + RealTime() * 1)
surface.SetDrawColor( 10, 10, 10, math.max(200,15 * elapsed) )
surface.SetMaterial( Material("vgui/gradient_down", "noclamp") )
surface.DrawTexturedRect(0,0,w,h / 1.5)
        draw.SimpleText("DEATH", "dead font", x + math.Rand(-2,2), y + math.Rand(-2,2), Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        draw.SimpleText("Hint: " .. tip,"dead font2", x, y * 1.14, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    else
        dead = 0
    end
end)
end)

end)
