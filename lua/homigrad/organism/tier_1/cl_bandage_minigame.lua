
local matWound = Material("vgui/wound.png", "noclamp smooth")
local matBandage = Material("vgui/bandage_roll.png", "noclamp smooth")

local PANEL = {}

function PANEL:Init()
    self:SetSize(ScrW(), ScrH())
    self:MakePopup()
    self:SetAlpha(0)
    self:AlphaTo(255, 0.2)
    
    self.success = false
    self.targetPly = nil
    
    -- Minigame state
    self.woundX = ScrW() * 0.5
    self.woundY = ScrH() * 0.5
    
    self.bandageX = ScrW() * 0.2
    self.bandageY = ScrH() * 0.5
    
    self.isDragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    
    self.shakeIntensity = 0
    self.lastMouseX = gui.MouseX()
    self.lastMouseY = gui.MouseY()
    
    self.bandageWidth = 128
    self.bandageHeight = 128
    
    self.woundWidth = 256
    self.woundHeight = 256
end

function PANEL:SetTarget(ply)
    self.targetPly = ply
end

function PANEL:OnRemove()
    -- Cleanup if needed
end

function PANEL:Paint(w, h)
    -- Background dimmer
    surface.SetDrawColor(0, 0, 0, 200)
    surface.DrawRect(0, 0, w, h)
    
    -- Draw Wound (Target)
    surface.SetDrawColor(255, 255, 255, 180) 
    surface.SetMaterial(matWound)
    surface.DrawTexturedRect(self.woundX - self.woundWidth / 2, self.woundY - self.woundHeight / 2, self.woundWidth, self.woundHeight)
    
    -- Handle Logic
    self:Logic()
    
    -- Draw Movable Bandage
    local drawX, drawY = self.bandageX, self.bandageY
    
    -- Apply shake
    if self.shakeIntensity > 0 then
        drawX = drawX + math.random(-self.shakeIntensity, self.shakeIntensity)
        drawY = drawY + math.random(-self.shakeIntensity, self.shakeIntensity)
    end
    
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(matBandage)
    surface.DrawTexturedRect(drawX - self.bandageWidth / 2, drawY - self.bandageHeight / 2, self.bandageWidth, self.bandageHeight)
end

function PANEL:Logic()
    if not LocalPlayer():Alive() or (LocalPlayer().organism and LocalPlayer().organism.otrub) then
        self:Close()
        return
    end
    
    -- Right click to cancel
    if input.IsMouseDown(MOUSE_RIGHT) then
        self:Close()
        return
    end

    local mx, my = gui.MouseX(), gui.MouseY()
    local dt = FrameTime()
    
    -- Calculate mouse speed
    local mouseSpeed = math.sqrt((mx - self.lastMouseX)^2 + (my - self.lastMouseY)^2) / dt
    self.lastMouseX = mx
    self.lastMouseY = my
    
    local halfW = self.bandageWidth / 2
    local halfH = self.bandageHeight / 2
    local hovering = mx >= (self.bandageX - halfW) and mx <= (self.bandageX + halfW) and
                     my >= (self.bandageY - halfH) and my <= (self.bandageY + halfH)
                     
    if input.IsMouseDown(MOUSE_LEFT) then
        if not self.isDragging and hovering then
            self.isDragging = true
            self.dragOffsetX = self.bandageX - mx
            self.dragOffsetY = self.bandageY - my
        end
    else
        self.isDragging = false
    end
    
    if self.isDragging then
        local targetX = mx + self.dragOffsetX
        local targetY = my + self.dragOffsetY
        
        self.bandageX = Lerp(dt * 10, self.bandageX, targetX)
        self.bandageY = Lerp(dt * 10, self.bandageY, targetY)
        
        if mouseSpeed > 250 then
            self.shakeIntensity = math.min(self.shakeIntensity + dt * 50, 20)
            
            if self.shakeIntensity > 10 and math.random() < 0.1 then
                self:Fail()
            end
        else
            self.shakeIntensity = math.max(self.shakeIntensity - dt * 20, 0)
        end
        
        local dist = math.sqrt((self.bandageX - self.woundX)^2 + (self.bandageY - self.woundY)^2)
        if dist < 50 and self.shakeIntensity < 5 then
            self:Win()
        end
    else
        self.shakeIntensity = 0
    end
end

function PANEL:Fail()
    self.isDragging = false
    
    net.Start("hg_bandage_minigame_fail")
    if IsValid(self.targetPly) then
        net.WriteEntity(self.targetPly)
    else
        net.WriteEntity(LocalPlayer())
    end
    net.SendToServer()
    
    -- Reset bandage position
    self.bandageX = ScrW() * 0.2
    self.bandageY = ScrH() * 0.5
end

function PANEL:Win()
    self.success = true
    net.Start("hg_bandage_minigame_success")
    if IsValid(self.targetPly) then
        net.WriteEntity(self.targetPly)
    else
        net.WriteEntity(LocalPlayer())
    end
    net.WriteBool(true) -- Success
    net.SendToServer()
    
    self:Close()
end

function PANEL:Close()
    if not self.success then
        net.Start("hg_bandage_minigame_success")
        if IsValid(self.targetPly) then
            net.WriteEntity(self.targetPly)
        else
            net.WriteEntity(LocalPlayer())
        end
        net.WriteBool(false) -- Failure
        net.SendToServer()
    end
    self:Remove()
    gui.EnableScreenClicker(false)
end

vgui.Register("HG_BandageMinigame", PANEL, "DPanel")

function hg.StartBandageMinigame(targetPly)
    if IsValid(HG_BANDAGE_PANEL) then HG_BANDAGE_PANEL:Remove() end
    
    HG_BANDAGE_PANEL = vgui.Create("HG_BandageMinigame")
    if targetPly then
        HG_BANDAGE_PANEL:SetTarget(targetPly)
    end
    gui.EnableScreenClicker(true)
end
