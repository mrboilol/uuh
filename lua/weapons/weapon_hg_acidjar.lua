if SERVER then AddCSLuaFile() end
SWEP.Base = "weapon_hg_grenade"
SWEP.PrintName = "Sulfuric Acid Jar"
SWEP.Instructions = "A glass jar filled with highly corrosive sulfuric acid. When thrown, it shatters and spreads acid that causes severe chemical burns and intense pain."
SWEP.Category = "Weapons - Explosive"
SWEP.Spawnable = true
SWEP.HoldType = "grenade"
SWEP.ViewModel = ""
SWEP.WorldModel = "models/props_lab/jar01b.mdl"
if CLIENT then
	SWEP.WepSelectIcon = Material("vgui/acid.png")
	SWEP.IconOverride = "vgui/acid.png"
	SWEP.BounceWeaponIcon = false
end

SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.Slot = 4
SWEP.SlotPos = 1
SWEP.ENT = "ent_hg_acidjar"

SWEP.nofunnyfunctions = true
SWEP.timetothrow = 0.5

SWEP.throwsound = "sulfuricacid/bottle_throw.wav"

SWEP.offsetVec = Vector(3, -2, -1)
SWEP.offsetAng = Angle(145, 0, 0)
SWEP.NoTrap = true