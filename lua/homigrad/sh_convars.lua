-- This file contains shared convars for the homigrad addon.

if not use_homigrad_hud then
    use_homigrad_hud = CreateConVar("use_homigrad_hud", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Use the Homigrad HUD instead of the hjuyy HUD")
end

if not homigrad_new_otrub then
    homigrad_new_otrub = CreateConVar("homigrad_new_otrub", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Use the new otrub system")
end