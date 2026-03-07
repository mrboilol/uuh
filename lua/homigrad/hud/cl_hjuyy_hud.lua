

-- Placeholder functions for hjuyy's API
KiraScripts = KiraScripts or {}
function KiraScripts.RaPD_GetPartDamageStatus(dmg, maxHP) return 0 end
function KiraScripts.RaPD_GetPartDamagePercent(dmg, maxHP) 
    if not dmg or not maxHP or maxHP == 0 then return 100 end
    local total_dmg = 0
    for _, d in pairs(dmg) do
        total_dmg = total_dmg + d
    end
    return 100 - (total_dmg / maxHP) * 100
end
function KiraScripts.RaPD_IsFatalDamage(dmg, maxHP) return false end


local mats = 
{
    Head = Material( "kira_rapd/head.png" ),
    Chest = Material( "kira_rapd/chest.png" ),
    Stomach = Material( "kira_rapd/stom.png" ),
	LeftArm = Material( "kira_rapd/larm.png" ),
    RightArm = Material( "kira_rapd/rarm.png" ),
	LeftLeg = Material( "kira_rapd/lleg.png" ),
    RightLeg = Material( "kira_rapd/rleg.png" ),
}

local matsTwo = {
	fracture = Material( "kira_rapd/fracture.png" ),
	bleeding = Material( "kira_rapd/bleeding.png" ),
}

-- Hardcoded limb positions for the new HUD
local limbPositions = {
    Head = {x = 0, y = -150, w = 80, h = 80},
    Chest = {x = 0, y = -50, w = 100, h = 100},
    Stomach = {x = 0, y = 50, w = 100, h = 80},
    LeftArm = {x = -120, y = 0, w = 60, h = 150},
    RightArm = {x = 120, y = 0, w = 60, h = 150},
    LeftLeg = {x = -70, y = 150, w = 80, h = 200},
    RightLeg = {x = 70, y = 150, w = 80, h = 200},
}

surface.CreateFont( "RaPD_StatusHUD", {
    font = "Arial",
    size = 25,  
} )

surface.CreateFont( "RaPD_StatusHUD_Small", {
    font = "Roboto",
    size = 18,  
} )

surface.CreateFont( "RaPD_StatusHUD_Hud", {
    font = "Roboto-Bold",
    size = 20,  
	extended = false,
	blursize = 0,
	outline = true,
} )

local outlineColor = Color(120,120,120,250)

local function DollPart(mat,color,x,y,w,h)
	surface.SetMaterial( mat )
	surface.SetDrawColor( color )
	surface.DrawTexturedRect( x, y, w, h )
end

local function HealthPainting(percent)
	local r = 255-(255*(percent*0.01))
	local g = 255*(percent*0.01)
	local b = 55
	return r,g,b
end

local RaPDInfo
local RaPD_ShouldUpdateSlots
local RaPD_ShouldUpdateActive
local RaPDInfo_SelectedPlayer

local RaPDInfo_SelectedLimb = "Chest"
local RaPDInfo_HoveredLimb = ""

local function playerByNameNearby(name)
	if isstring(name) then
		for k,v in pairs(player.GetAll()) do
			if v:GetPos():Distance(LocalPlayer():GetPos()) and v:IsPlayer() and isstring(v:Nick()) and string.find(string.lower(v:Nick()), string.lower(name)) then
				return v 
			end
		end
	end
	return false
end

local function DrawDollOfPlayer(ply, panel, x, y, w, h, selected)
	if not GetConVar("use_homigrad_hud"):GetBool() then return end

	draw.RoundedBox( 0, x, y, w, h, ColorAlpha(color_black, 255 ) )
	surface.SetDrawColor(outlineColor)
	surface.DrawOutlinedRect(x, y, w, h, 1)
	
	local damaged = ColorAlpha(Color(55,55,55), 255 )
	
	DollPart(Material( "kira_rapd/body_full2.png" ),damaged,x,y,w,h)
	
	local redLighting = ColorAlpha(Color(105,5,5), 125+(125*math.cos(CurTime()*10)) )
	
	DollPart(Material( "kira_rapd/body_full2.png" ),redLighting,x,y,w,h)
	
	if ply.organism then
        -- Custom implementation for homigrad's organism
		for limb_name, limb_data in pairs(ply.organism) do
			if mats[limb_name] then
				
				local percent = limb_data.health or 100

				local r, g, b = HealthPainting(percent)
				
				if selected and (RaPDInfo_SelectedLimb == limb_name or RaPDInfo_HoveredLimb == limb_name) then
					local add = 150+50*(math.cos(CurTime()*8))
					r, g, b = math.Clamp(r+add, 0, 255), math.Clamp(g+add, 0, 255), math.Clamp(b+add, 0, 255)
				end

				local color = Color(r,g,b)
				
				local health = ColorAlpha(color, 255)
				DollPart(mats[limb_name],health,x,y,w,h)
			end
		end
	end
end

local function PaintDoll(panel, ply)
	function panel:Paint( w, h )
		DrawDollOfPlayer(ply or LocalPlayer(), panel, 0, 0, w, h, true)
	end
end

function RaPD_ShowInformation( pl, cmd, args, otherPly )
    if not GetConVar("use_homigrad_hud"):GetBool() then return end
	
	if !args then args = {} end
	
	if IsValid(RaPDInfo) then
		RaPDInfo:Remove()
		return 
	end
	
	RaPD_ShouldUpdateSlots = true
	RaPD_ShouldUpdateActive = true
	
	local otherPlyAnalyse = IsValid(otherPly) and otherPly:IsPlayer()
	
	local ply = otherPlyAnalyse and otherPly or playerByNameNearby(args[1]) or LocalPlayer()
	
	RaPDInfo_SelectedPlayer = ply
	
	-- Create the main frame
	RaPDInfo = vgui.Create( "DFrame" )
	RaPDInfo:SetSize( 760, 549 )
	RaPDInfo:Center()
	RaPDInfo:MakePopup()
	RaPDInfo:SetTitle("Homigrad HUD: "..ply:Nick())

    -- Add the doll panel
	RaPDInfo_StatusPanel = vgui.Create( "DPanel", RaPDInfo )
	RaPDInfo_StatusPanel:SetSize( 220, 503 )
	RaPDInfo_StatusPanel:CenterVertical()
	RaPDInfo_StatusPanel:CenterHorizontal()
	
	PaintDoll(RaPDInfo_StatusPanel, ply)

    -- Add limb selectors
	for k,v in pairs(limbPositions) do
		local x = v.x or 0
		local y = v.y or 0
		local w = v.w or 50
		local h = v.h or 50
		
		local limbSelector = vgui.Create( "DButton", RaPDInfo_StatusPanel )
		limbSelector:SetSize( w, h )
		limbSelector:SetPos( (x + RaPDInfo_StatusPanel:GetWide()/2)-(w/2), y + RaPDInfo_StatusPanel:GetTall()/2 - h/2 )
		limbSelector:SetText("")
		
		function limbSelector:Paint( w, h )
			if limbSelector:IsHovered() then
				RaPDInfo_HoveredLimb = k
			elseif RaPDInfo_HoveredLimb == k then
				RaPDInfo_HoveredLimb = ""
			end
		end
		
		function limbSelector:DoClick()
            local wep = ply:GetActiveWeapon()
            if not IsValid(wep) then return end

            net.Start("homigrad_use_item")
            net.WriteString(wep:GetClass())
            net.WriteString(k)
            net.WriteEntity(ply)
            net.SendToServer()

            RaPDInfo:Close()
		end
	end

    -- Add limb status panel
    local RaPDInfo_StatusLimb = vgui.Create( "DPanel", RaPDInfo )
	RaPDInfo_StatusLimb:SetSize( 260, 503 )
	RaPDInfo_StatusLimb:SetPos( 2, 24)
    function RaPDInfo_StatusLimb:Paint(w, h)
        draw.SimpleText( RaPDInfo_SelectedLimb, "RaPD_StatusHUD", w/2, 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

        local limb_data = ply.organism and ply.organism[RaPDInfo_SelectedLimb]
        if limb_data then
            local percent = limb_data.health or 100
            local r,g,b = HealthPainting(percent)
		    local color = Color( r+130, g+130, b+130, 255 )
            draw.SimpleText( "Health: "..percent.."%", "RaPD_StatusHUD_Small", w/2, 50, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )

            local y_offset = 80
            if limb_data.bleeding then
                surface.SetMaterial(matsTwo.bleeding)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(w/2 - 16, y_offset, 32, 32)
                y_offset = y_offset + 40
            end

            if limb_data.fracture then
                surface.SetMaterial(matsTwo.fracture)
                surface.SetDrawColor(color_white)
                surface.DrawTexturedRect(w/2 - 16, y_offset, 32, 32)
            end
        end
    end
end

concommand.Add("homigrad_show_hud", function(ply) RaPD_ShowInformation(ply) end)

