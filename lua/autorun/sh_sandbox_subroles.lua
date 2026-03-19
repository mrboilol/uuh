if SERVER then
    util.AddNetworkString("Sandbox_Subroles_AddFootstep")
    util.AddNetworkString("Sandbox_Subroles_BreakNeck")
end

local Professions = {
    ["doctor"] = {
        Name = "Doctor",
        Description = "Can heal others and yourself. Spawns with a medkit, bandages, and painkillers. Can inspect player health with Alt+E.",
        SpawnFunction = function(ply)
            ply:Give("weapon_medkit_sh")
            ply:Give("weapon_bandage_sh")
            ply:Give("weapon_painkillers")
        end,
    },
    ["huntsman"] = {
        Name = "Huntsman",
        Description = "An expert tracker and marksman. Spawns with a crossbow. Can see player footsteps.",
        SpawnFunction = function(ply)
            ply:Give("weapon_crossbow")
            ply:GiveAmmo(10, "crossbow_bolt", true)
        end,
    },
    ["engineer"] = {
        Name = "Engineer",
        Description = "Specializes in explosives and fortifications. Spawns with a shotgun and a pipe bomb.",
        SpawnFunction = function(ply)
            ply:Give("weapon_shotgun")
            ply:Give("weapon_hg_pipebomb_tpik")
        end,
    },
    ["cook"] = {
        Name = "Cook",
        Description = "Can create... culinary masterpieces. Spawns with a cleaver and a molotov.",
        SpawnFunction = function(ply)
            ply:Give("weapon_cleaver")
            ply:Give("weapon_hg_molotov_tpik")
        end,
    },
}

local SubRoles = {
    ["traitor_default"] = {
        Name = "Defoko",
        Description = [[Default.
    You've prepared for a long time.
    You are equipped with various weapons, poisons and explosives, grenades and your favourite heavy duty knife and a zoraki signal pistol to help you kill.]],
        Objective = "You're geared up with items, poisons, explosives and weapons hidden in your pockets. Murder everyone here.",
        SpawnFunction = function(ply)
            local wep = ply:Give("weapon_zoraki")
            timer.Simple(1, function() if IsValid(wep) then wep:ApplyAmmoChanges(2) end end)
            ply:Give("weapon_buck200knife")
            ply:Give("weapon_hg_rgd_tpik")
            ply:Give("weapon_adrenaline")
            ply:Give("weapon_hg_shuriken")
            ply:Give("weapon_hg_smokenade_tpik")
            ply:Give("weapon_traitor_ied")
            ply:Give("weapon_traitor_poison1")
            ply:Give("weapon_traitor_suit")
            ply:Give("weapon_hg_jam")
            if ply.organism then ply.organism.stamina.max = 220 end
            local inv = ply:GetNetVar("Inventory", {}) inv["Weapons"] = inv["Weapons"] or {} inv["Weapons"]["hg_flashlight"] = true ply:SetNetVar("Inventory", inv)
        end,
    },
    ["traitor_infiltrator"] = {
        Name = "Infiltrator",
        Description = [[Can break people's necks from behind (Alt + E) and disguise as them (Alt + R). Has no weapons or tools except knife, epipen and smoke grenade.]],
        Objective = "You're an expert in diversion. Be discreet and kill one by one",
        SpawnFunction = function(ply)
            ply:Give("weapon_sogknife")
            ply:Give("weapon_adrenaline")
            ply:Give("weapon_hg_smokenade_tpik")
            if ply.organism then ply.organism.stamina.max = 220 end
            local inv = ply:GetNetVar("Inventory", {}) inv["Weapons"] = inv["Weapons"] or {} inv["Weapons"]["hg_flashlight"] = true ply:SetNetVar("Inventory", inv)
        end,
    },
    ["traitor_assasin"] = {
        Name = "Assasin",
        Description = [[Can disarm people and choke them to death (Alt + E). Proficient in shooting from guns. Has additional stamina.]],
        Objective = "You're an expert in guns and in disarmament. Disarm gunman and use his weapon against others",
        SpawnFunction = function(ply)
            if ply.organism then ply.organism.recoilmul = 0.8 ply.organism.stamina.max = 300 end
        end,
    },
    ["traitor_chemist"] = {
        Name = "Chemist",
        Description = [[Has multiple chemical agents and epipen and knife. Resistant to a certain degree to all chemical agents mentioned.]],
        Objective = "You're a chemist who decided to use his knowledge to hurt others. Poison everything.",
        SpawnFunction = function(ply)
            ply:Give("weapon_sogknife")
            ply:Give("weapon_adrenaline")
            ply:Give("weapon_traitor_poison1")
            ply:Give("weapon_traitor_poison2")
            ply:Give("weapon_traitor_poison3")
            ply:Give("weapon_traitor_poison4")
            ply:Give("weapon_traitor_poison_consumable")
            if ply.organism then ply.organism.stamina.max = 220 end
            local inv = ply:GetNetVar("Inventory", {}) inv["Weapons"] = inv["Weapons"] or {} inv["Weapons"]["hg_flashlight"] = true ply:SetNetVar("Inventory", inv)
        end,
    },
}

if SERVER then
    CreateConVar("sandbox_subroles_enabled", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Enable traitor subroles in Sandbox")

    timer.Simple(0, function()
        if not GetConVar("sandbox_subroles_enabled"):GetBool() then
            print("Sandbox Subroles: Disabled by convar.")
            return
        end
        print("Sandbox Subroles: Initializing...")
    end)

    local function find_player(name) for _, p in ipairs(player.GetAll()) do if string.find(string.lower(p:Name()), string.lower(name)) then return p end end return nil end

    concommand.Add("sbox_set_profession", function(ply, cmd, args, argStr)
        if IsValid(ply) and not ply:IsAdmin() then ply:ChatPrint("You are not an admin.") return end
        local target_name = args[1] local prof_name = args[2]
        if not target_name or not prof_name then print("Usage: sbox_set_profession <player_name> <profession_name>") if IsValid(ply) then ply:ChatPrint("Usage: sbox_set_profession <player_name> <profession_name>") end return end
        local target_ply = find_player(target_name)
        if not IsValid(target_ply) then print("Player not found: " .. target_name) if IsValid(ply) then ply:ChatPrint("Player not found: " .. target_name) end return end
        if not Professions[prof_name] then print("Profession not found: " .. prof_name) if IsValid(ply) then ply:ChatPrint("Profession not found: " .. prof_name) end return end
        target_ply.SandboxProfession = prof_name
        target_ply:SetPData("SandboxProfession_SetByCommand", "true")
        target_ply:StripWeapons()
        Professions[prof_name].SpawnFunction(target_ply)
        if target_ply.isSandboxTraitor and target_ply.SandboxSubrole and SubRoles[target_ply.SandboxSubrole] then SubRoles[target_ply.SandboxSubrole].SpawnFunction(target_ply) end
        local msg = "Set " .. target_ply:Name() .. "'s profession to: " .. prof_name print(msg) if IsValid(ply) then ply:ChatPrint(msg) end
        target_ply:ChatPrint("Your profession is now: " .. Professions[prof_name].Name) if Professions[prof_name].Description then target_ply:ChatPrint(Professions[prof_name].Description) end
    end)

    concommand.Add("sbox_set_subrole", function(ply, cmd, args, argStr)
        if IsValid(ply) and not ply:IsAdmin() then ply:ChatPrint("You are not an admin.") return end
        local target_name = args[1] local role_name = args[2]
        if not target_name or not role_name then print("Usage: sbox_set_subrole <player_name> <role_name>") if IsValid(ply) then ply:ChatPrint("Usage: sbox_set_subrole <player_name> <role_name>") end return end
        local target_ply = find_player(target_name)
        if not IsValid(target_ply) then print("Player not found: " .. target_name) if IsValid(ply) then ply:ChatPrint("Player not found: " .. target_name) end return end
        if not SubRoles[role_name] then print("Subrole not found: " .. role_name) if IsValid(ply) then ply:ChatPrint("Subrole not found: " .. role_name) end return end
        target_ply.isSandboxTraitor = true target_ply.SandboxSubrole = role_name
        target_ply:StripWeapons()
        if target_ply.SandboxProfession and Professions[target_ply.SandboxProfession] then Professions[target_ply.SandboxProfession].SpawnFunction(target_ply) end
        SubRoles[role_name].SpawnFunction(target_ply)
        local msg = "Set " .. target_ply:Name() .. " as a traitor with subrole: " .. role_name print(msg) if IsValid(ply) then ply:ChatPrint(msg) end
        target_ply:ChatPrint("You are now a traitor with the " .. SubRoles[role_name].Name .. " subrole.") if SubRoles[role_name].Description then target_ply:ChatPrint(SubRoles[role_name].Description) end
    end)

    concommand.Add("sbox_remove_subrole", function(ply, cmd, args, argStr)
        if IsValid(ply) and not ply:IsAdmin() then ply:ChatPrint("You are not an admin.") return end
        local target_name = args[1] if not target_name then print("Usage: sbox_remove_subrole <player_name>") if IsValid(ply) then ply:ChatPrint("Usage: sbox_remove_subrole <player_name>") end return end
        local target_ply = find_player(target_name)
        if not IsValid(target_ply) then print("Player not found: " .. target_name) if IsValid(ply) then ply:ChatPrint("Player not found: " .. target_name) end return end
        target_ply.isSandboxTraitor = false target_ply.SandboxSubrole = nil target_ply:StripWeapons()
        if target_ply.SandboxProfession and Professions[target_ply.SandboxProfession] then Professions[target_ply.SandboxProfession].SpawnFunction(target_ply) end
        local msg = target_ply:Name() .. " is no longer a traitor." print(msg) if IsValid(ply) then ply:ChatPrint(msg) end
        target_ply:ChatPrint("You are no longer a traitor.")
    end)
    
    concommand.Add("sbox_list_subroles", function(ply, cmd, args, argStr) local msg = "Available subroles:\n" for name, data in pairs(SubRoles) do msg = msg .. "- " .. name .. " (" .. data.Name .. ")\n" end if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end)
    concommand.Add("sbox_list_professions", function(ply, cmd, args, argStr) local msg = "Available professions:\n" for name, data in pairs(Professions) do msg = msg .. "- " .. name .. " (" .. data.Name .. ")\n" end if IsValid(ply) then ply:ChatPrint(msg) else print(msg) end end)

    hook.Add("PlayerSpawn", "SandboxRoles_PlayerSpawn", function(ply)
        if not GetConVar("sandbox_subroles_enabled"):GetBool() then return end
        
        if ply:GetPData("SandboxProfession_SetByCommand", "false") == "false" then
            ply.SandboxProfession = nil
        end
        
        ply.isSandboxTraitor = false
        ply.SandboxSubrole = nil
        
        ply:StripWeapons()

        if not ply.SandboxProfession then 
            local prof_keys = {}
            for k in pairs(Professions) do
                table.insert(prof_keys, k)
            end
            local random_prof = prof_keys[math.random(#prof_keys)]
            ply.SandboxProfession = random_prof
        end
        
        local prof_data = Professions[ply.SandboxProfession]
        if prof_data then
            prof_data.SpawnFunction(ply)
            ply:ChatPrint("You spawned as a " .. prof_data.Name .. ".")
            if prof_data.Description then
                ply:ChatPrint("Profession Info: " .. prof_data.Description)
            end
        end
    end)
    
    local function CanPlayerBreakOtherNeck(ply, aim_ent)
        if(aim_ent:IsRagdoll())then
            local bone_id = aim_ent:LookupBone("ValveBiped.Bip01_Head1")
            if(bone_id)then
                local bone_matrix = aim_ent:GetBoneMatrix(bone_id)
                if(bone_matrix)then
                    local pos, ang = bone_matrix:GetTranslation(), bone_matrix:GetAngles()
                    local other_normal = -ang:Right()
                    local ply_normal = pos - ply:GetShootPos()
                    local dist_z = math.abs(pos.z - ply:GetShootPos().z)
                    if(dist_z < 50) then
                        ply_normal:Normalize()
                        local ang_diff = -(math.deg(math.acos(ply_normal:DotProduct(other_normal))) - 180)
                        if(ang_diff < 100)then return true end
                    end
                end
            end
        elseif(aim_ent:IsPlayer())then
            local other_angle = aim_ent:EyeAngles()[2]
            local ply_angle = (aim_ent:GetPos() - ply:GetPos()):Angle()[2]
            local ang_diff = math.abs(math.AngleDifference(other_angle, ply_angle))
            if(ang_diff < 100)then return true end
        end
        return false
    end

    hook.Add("PlayerPostThink", "Sandbox_SubroleAbilities", function(ply)
        if not GetConVar("sandbox_subroles_enabled"):GetBool() then return end
        if not IsValid(ply) or not ply:Alive() then return end

        if ply:KeyDown(IN_WALK) then -- Alt key
            -- Infiltrator
            if ply.SandboxSubrole == "traitor_infiltrator" then
                if ply:KeyPressed(IN_RELOAD) then
                    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 85, filter = ply })
                    if IsValid(tr.Entity) and tr.Entity:IsRagdoll() then
                        local your_appearance = ply:GetAppearance() or {}
                        local other_appearance = tr.Entity.CurAppearance or {}
                        hg.Appearance.ForceApplyAppearance(ply, other_appearance, true)
                        tr.Entity.CurAppearance = your_appearance
                        hg.Appearance.ForceApplyAppearance(tr.Entity, your_appearance, true)
                        ply:EmitSound("snd_jack_hmcd_disguise.wav", 75, 100)
                    end
                end
                if ply:KeyPressed(IN_USE) then
                    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 85, filter = ply })
                    if IsValid(tr.Entity) and CanPlayerBreakOtherNeck(ply, tr.Entity) then
                        net.Start("Sandbox_Subroles_BreakNeck")
                        net.WriteEntity(tr.Entity)
                        net.SendToServer()
                    end
                end
            end
            -- Assassin
            if ply.SandboxSubrole == "traitor_assasin" then
                local is_choking = ply:GetNetVar("isChoking", false) local choke_target = ply:GetNetVar("chokeTarget", NULL)
                if ply:KeyPressed(IN_USE) and not is_choking then
                    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 85, filter = ply })
                    if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:Alive() then
                        local victim = tr.Entity local wep = victim:GetActiveWeapon()
                        if IsValid(wep) and wep:GetClass() ~= "weapon_hands" then victim:DropWeapon(wep) end
                        victim:SetRagdoll(true, 1.5)
                        timer.Simple(0.1, function()
                            if not IsValid(ply) or not ply:KeyDown(IN_USE) then victim:SetRagdoll(false) return end
                            ply:SetNetVar("isChoking", true) 
                            ply:SetNetVar("chokeTarget", victim) 
                            victim:SetNetVar("chokedBy", ply)
                            if victim.organism then victim.organism.choking = true end
                        end)
                    end
                elseif ply:KeyDown(IN_USE) and is_choking and IsValid(choke_target) then
                    if choke_target:Health() <= 0 then ply:SetNetVar("isChoking", false) if IsValid(choke_target) then choke_target:SetNetVar("chokedBy", NULL) if choke_target.organism then choke_target.organism.choking = false end end return end
                    local attachmentID = choke_target:LookupAttachment("chest")
                    if attachmentID > 0 then local attachment = choke_target:GetAttachment(attachmentID) if attachment then ply:SetPos(attachment.Pos + attachment.Ang:Forward() * -25) ply:SetEyeAngles((choke_target:GetPos() - ply:GetPos()):Angle()) end end
                elseif (ply:KeyReleased(IN_USE) and is_choking) or (is_choking and not IsValid(choke_target)) then 
                    ply:SetNetVar("isChoking", false) 
                    if IsValid(choke_target) then 
                        choke_target:SetNetVar("chokedBy", NULL) 
                        choke_target:SetRagdoll(false)
                        if choke_target.organism then choke_target.organism.choking = false end
                    end 
                end
            end
            -- Doctor
            if ply.SandboxProfession == "doctor" and ply:KeyPressed(IN_USE) then
                 local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 120, filter = ply })
                 if IsValid(tr.Entity) and tr.Entity:IsPlayer() then local p = tr.Entity ply:ChatPrint(p:Name() .. " Health: " .. p:Health()) end
            end
        else
            local is_choking = ply:GetNetVar("isChoking", false) local choke_target = ply:GetNetVar("chokeTarget", NULL)
            if is_choking then ply:SetNetVar("isChoking", false) if IsValid(choke_target) then choke_target:SetNetVar("chokedBy", NULL) choke_target:SetRagdoll(false) if choke_target.organism then choke_target.organism.choking = false end end end
        end
    end)

    hook.Add("HG_PlayerFootstep_Notify", "Sandbox_HuntsmanAbility", function(ply, pos, foot, snd, volume, filter)
        if not GetConVar("sandbox_subroles_enabled"):GetBool() then return end
        for _, p in ipairs(player.GetAll()) do
            if p.SandboxProfession == "huntsman" and p != ply and p:GetPos():DistToSqr(pos) < 250000 then
                net.Start("Sandbox_Subroles_AddFootstep")
                net.WriteVector(pos)
                net.WriteFloat(ply:EyeAngles().y)
                net.WriteBool(foot == 0)
                net.WriteColor(ply:GetPlayerColor() * 255)
                net.Send(p)
            end
        end
    end)

    hook.Add("SetupMove", "Sandbox_ChokeVictim", function(ply, mv, cmd)
        if not IsValid(ply) then return end
        local choker = ply:GetNetVar("chokedBy", NULL) if IsValid(choker) then mv:SetForwardSpeed(0) mv:SetSideSpeed(0) mv:SetButtons(0) local ang = (choker:GetPos() - ply:GetPos()):Angle() ply:SetEyeAngles(ang) end
    end)
    
    net.Receive("Sandbox_Subroles_BreakNeck", function(len, ply)
        local ent = net.ReadEntity()
        if not IsValid(ent) then return end
        ent:TakeDamage(ent:Health() + 20, ply, ply)
        ent:EmitSound("physics/body/body_medium_break2.wav")
    end)

    print("Sandbox Subroles: Loaded successfully.")
end

if CLIENT then
    local FootSteps = {}
    local ArrangedFootSteps = {}
    local FootStepsAmt = 0
    
    net.Receive("Sandbox_Subroles_AddFootstep", function()
        local pos, ang, left, color = net.ReadVector(), net.ReadFloat(), net.ReadBool(), net.ReadColor()
        local step = {pos, ang, left, color, CurTime()}
        table.insert(FootSteps, step)
        FootStepsAmt = FootStepsAmt + 1
    end)
    
    hook.Add("PostDrawTranslucentRenderables", "Sandbox_Huntsman_DrawFootsteps", function()
        if not GetConVar("sandbox_subroles_enabled"):GetBool() or game.GetGamemode().Id ~= "sandbox" then return end
        local ply = LocalPlayer()
        if not IsValid(ply) or ply.SandboxProfession ~= "huntsman" then return end

        for k, v in pairs(ArrangedFootSteps) do
            local pos, ang, left, color, time = v[1], v[2], v[3], v[4], v[5]
            local alpha = math.Clamp(255 - (CurTime() - time) * 15, 0, 255)
            if alpha == 0 then table.remove(ArrangedFootSteps, k) continue end
            
            cam.Start3D(EyePos(), EyeAngles())
                render.SetMaterial(Material("models/props_forest/leaves_dead01"))
                render.DrawQuadEasy(pos, Vector(0,0,1), 20, 20, color, ang)
            cam.End3D()
        end
    end)
    
    hook.Add("Think", "Sandbox_Huntsman_ArrangeFootsteps", function()
        if FootStepsAmt == 0 then return end
        for i=1, FootStepsAmt do
            table.insert(ArrangedFootSteps, table.remove(FootSteps, 1))
        end
        FootStepsAmt = 0
    end)
end