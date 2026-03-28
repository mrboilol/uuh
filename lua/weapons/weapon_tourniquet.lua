if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_bandage_sh"
SWEP.PrintName = "Tourniquet"
SWEP.Instructions = "An esmarch tourniquet designed to stop large (arterial) bleedings. Can also be used to stop light bleedings, although it makes the limb ineffective."
SWEP.Category = "ZCity Medicine"
SWEP.Spawnable = true
SWEP.Primary.Wait = 1
SWEP.Primary.Next = 0
SWEP.HoldType = "slam"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/tourniquet/tourniquet.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("scrappers/jgut.png")
	SWEP.IconOverride = "scrappers/jgut.png"
	SWEP.BounceWeaponIcon = false

	SWEP.WepSelectIcon2 = Material("scrappers/jgut.png")

	function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
--
--
		surface.SetDrawColor( 255, 255, 255, alpha )
		surface.SetMaterial( self.WepSelectIcon2 )
	
		surface.DrawTexturedRect( x, y + 10,  wide, wide/2 )
	
		self:PrintWeaponInfo( x + wide + 20, y + tall * 0.95, alpha )
	
	end
end

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 3
SWEP.SlotPos = 1
SWEP.WorkWithFake = true
SWEP.offsetVec = Vector(4, -1.5, 0)
SWEP.offsetAng = Angle(-30, 20, -90)
SWEP.ModelScale = 1
SWEP.modeNames = {
	[1] = "tourniquet"
}

function SWEP:InitializeAdd()
	self:SetHold(self.HoldType)

	self.modeValues = {
		[1] = 1,
	}
end

SWEP.showstats = false

SWEP.modeValuesdef = {
	[1] = 1,
}


local hg_healanims = ConVarExists("hg_healanims") and GetConVar("hg_healanims") or CreateConVar("hg_healanims", 0, FCVAR_REPLICATED + FCVAR_ARCHIVE, "Toggle heal/food animations", 0, 1)

function SWEP:Think()
	if not self:GetOwner():KeyDown(IN_ATTACK) and hg_healanims:GetBool() then
		self:SetHolding(math.max(self:GetHolding() - 12, 0))
	end
end

local lang1, lang2 = Angle(0, -10, 0), Angle(0, 10, 0)
function SWEP:Animation()
	local owner = self:GetOwner()
	local aimvec = self:GetOwner():GetAimVector()
	local hold = self:GetHolding()
	if (owner.zmanipstart ~= nil and not owner.organism.larmamputated) then return end
	self:BoneSet("r_upperarm", vector_origin, Angle(30 - hold / 4, -30 + hold / 2 + 20 * aimvec[3], 5 - hold / 3.5))
    self:BoneSet("r_forearm", vector_origin, Angle(hold / 10, -hold / 2.5, 35 -hold/1.5))
end

function SWEP:OwnerChanged()
	local owner = self:GetOwner()
	if IsValid(owner) and owner:IsNPC() then
		self:NPCHeal(owner, 0.25, "snd_jack_hmcd_bandage.wav")
	end
end

function SWEP:Heal(ent, mode, bone)
    local org = ent.organism
    if not org then return false end

    if self:Tourniquet(ent, bone) or self:HealVeins(ent, bone) then
        self.modeValues[1] = 0
        self:GetOwner():SelectWeapon("weapon_hands_sh")
        self:Remove()
        return true
    end

    return false
end


if SERVER then
    local tourniquet_bones = {
        ["ValveBiped.Bip01_L_UpperArm"] = {
            ["ValveBiped.Bip01_L_Forearm"] = true,
            ["ValveBiped.Bip01_L_Hand"] = true
        },
        ["ValveBiped.Bip01_L_Forearm"] = {
            ["ValveBiped.Bip01_L_Hand"] = true
        },
        ["ValveBiped.Bip01_R_UpperArm"] = {
            ["ValveBiped.Bip01_R_Forearm"] = true,
            ["ValveBiped.Bip01_R_Hand"] = true
        },
        ["ValveBiped.Bip01_R_Forearm"] = {
            ["ValveBiped.Bip01_R_Hand"] = true
        },
        ["ValveBiped.Bip01_L_Thigh"] = {
            ["ValveBiped.Bip01_L_Calf"] = true,
            ["ValveBiped.Bip01_L_Foot"] = true
        },
        ["ValveBiped.Bip01_L_Calf"] = {
            ["ValveBiped.Bip01_L_Foot"] = true
        },
        ["ValveBiped.Bip01_R_Thigh"] = {
            ["ValveBiped.Bip01_R_Calf"] = true,
            ["ValveBiped.Bip01_R_Foot"] = true
        },
        ["ValveBiped.Bip01_R_Calf"] = {
            ["ValveBiped.Bip01_R_Foot"] = true
        },
    }

    function SWEP:Tourniquet(ent, bone)
        local org = ent.organism
        if not org then return end
        if #org.arterialwounds > 0 then
            local ent = org.isPly and org.owner or ent
            ent.tourniquets = ent.tourniquets or {}

            local pw
            local bonewounds = {}
            if not bone then
                for i,wound in pairs(org.arterialwounds) do
                    if wound[7] ~= "arteria" and wound[7] ~= "spineartery" then 
                        pw = i 
                        for i1,tbl in pairs(org.wounds) do
                            if !tbl or !tbl[4] or !ent:LookupBone(tbl[4]) then continue end
                            local bonename = ent:GetBoneName(ent:LookupBone(tbl[4]))
                            local sec_bonename = ent:GetBoneName(ent:LookupBone(wound[4]))
                            if bonename == sec_bonename or (tourniquet_bones[sec_bonename] and tourniquet_bones[sec_bonename][bonename]) then
                                table.insert(bonewounds,i1)
                            end
                        end
                    break end
                end
            else
                for i,wound in pairs(org.arterialwounds) do
                    if ent:GetBoneName(ent:LookupBone(wound[4])) == bone then pw = i break end
                end
                for i,tbl in pairs(org.wounds) do
                    local bonename = ent:GetBoneName(ent:LookupBone(tbl[4]))
                    if bonename == bone or (tourniquet_bones[bone] and tourniquet_bones[bone][bonename]) then
                        table.insert(bonewounds,i)
                    end
                end
            end		
            pw = pw or math.random(#org.arterialwounds)

            local wound = org.arterialwounds[pw]
            if not wound then return false end

            if wound[7] == "spineartery" or wound[7] == "arteria" then
                self:GetOwner():Notify("You cannot apply a tourniquet here!", 1)
                return false
            end

            ent.tourniquets[#ent.tourniquets + 1] = {wound[2], wound[3], wound[4]}
            org[wound[7]] = 0

            if wound[7] == "arteria" then org.o2.regen = 0 end

            table.remove(org.arterialwounds,pw)

            org.owner:SetNetVar("arterialwounds",org.arterialwounds)

            for i = 1, #bonewounds do
                if org.wounds[bonewounds[i]] then
                    org.wounds[bonewounds[i]][1] = 0
                end
            end
            for i = 1, #bonewounds do
                if org.wounds[bonewounds[i]] then
                    table.remove(org.wounds, bonewounds[i])
                end
            end

            org.owner:SetNetVar("wounds",org.wounds)

            ent:SetNetVar("Tourniquets",ent.tourniquets)
            if IsValid(ent.FakeRagdoll) then
                ent.FakeRagdoll:SetNetVar("Tourniquets",ent.tourniquets)
            end
            
            if not table.HasValue(hg.TourniquetGuys,ent) then
                table.insert(hg.TourniquetGuys,ent)
            end

            for i,ent in ipairs(hg.TourniquetGuys) do
                if not IsValid(ent) or not ent.tourniquets or table.IsEmpty(ent.tourniquets) then table.remove(hg.TourniquetGuys,i) end
            end

            SetNetVar("TourniquetGuys",hg.TourniquetGuys)

            self:GetOwner():EmitSound("snd_jack_hmcd_bandage.wav", 65, math.random(95, 105))
            return true
        end
    end
end


function SWEP:PrimaryAttack()
    if GetConVar("use_homigrad_hud"):GetBool() then
        if CLIENT then
            RunConsoleCommand("homigrad_show_hud")
        end
        return
    end

	if SERVER then
		local trace = hg.eyeTrace(self:GetOwner())
		self.healbuddy = self:GetOwner()
		local done = self:Heal(self.healbuddy, self.mode, trace.PhysicsBone)
		
		if(done and self.PostHeal)then
			self:PostHeal(self.healbuddy, self.mode)
		end

		if self.net_cooldown2 < CurTime() then
			self:SetNetVar("modeValues",self.modeValues)
			--self.net_cooldown2 = CurTime() + 0.1
		end
	end
end

