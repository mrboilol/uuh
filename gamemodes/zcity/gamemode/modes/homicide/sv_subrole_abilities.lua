local MODE = MODE

util.AddNetworkString("HMCD_BeingVictimOfNeckBreak")	--; А тут я значит рещил без скобок да крутой кодинг стиль вопросы?
util.AddNetworkString("HMCD_BreakingOtherNeck")
util.AddNetworkString("HMCD_BeingVictimOfDisarmament")
util.AddNetworkString("HMCD_DisarmingOther")
util.AddNetworkString("HMCD_UpdateChemicalResistance")

--\\Chemical resistance
	function MODE.NetworkChemicalResistanceOfPlayer(ply)
		ply.PassiveAbility_ChemicalAccumulation = ply.PassiveAbility_ChemicalAccumulation or {}
		
		net.Start("HMCD_UpdateChemicalResistance")
		
		for chemical_name, amt in pairs(ply.PassiveAbility_ChemicalAccumulation) do
			net.WriteString(chemical_name)
			net.WriteUInt(math.Round(amt), MODE.NetSize_ChemicalResistanceBits)
		end
		
		net.WriteString("")
		net.Send(ply)
	end
--//

hook.Add("PlayerPostThink", "HMCD_SubRoles_Abilities", function(ply)
	if(MODE.RoleChooseRoundTypes[MODE.Type])then
		if(ply:Alive() and ply.organism and not ply.organism.otrub)then
			if(ply.SubRole == "traitor_infiltrator" or ply.SubRole == "traitor_infiltrator_soe")then
				if(ply:KeyDown(IN_WALK))then
					if(ply:KeyPressed(IN_RELOAD))then
						local aim_ent, other_ply = hg.eyeTrace(ply,85).Entity
						other_ply = hg.RagdollOwner(aim_ent) or aim_ent
						
						if(IsValid(aim_ent) and aim_ent:IsRagdoll())then	--; REDO
							local other_appearance = aim_ent.CurAppearance
							local your_appearance = ply.CurAppearance

							local aMdl1,aMdl2 = your_appearance.AModel,other_appearance.AModel
							
							other_appearance.AModel = aMdl1
							your_appearance.AModel = aMdl2

							local aFace1,aFace2 = your_appearance.AFacemaps,other_appearance.AFacemaps

							other_appearance.AFacemaps = aFace1
							your_appearance.AFacemaps = aFace2

							hg.Appearance.ForceApplyAppearance(ply, other_appearance, true)
							local char = hg.GetCurrentCharacter(ply)
							if char:IsRagdoll() then
								hg.Appearance.ForceApplyAppearance(char, other_appearance, true)
							end
							ply:EmitSound("snd_jack_hmcd_disguise.wav",35,math.random(90,110),0.5)

							--local duplicator_data = duplicator.CopyEntTable(ply)
							--duplicator.DoGeneric(aim_ent, duplicator_data)
							aim_ent.CurAppearance = your_appearance

							hg.Appearance.ForceApplyAppearance(aim_ent, your_appearance, true)
							
							if other_ply:IsPlayer() and other_ply:Alive() then
								hg.Appearance.ForceApplyAppearance(other_ply, your_appearance, true)
							end
						end
					end
					
					if(ply:KeyPressed(IN_USE))then
						local aim_ent, other_ply = MODE.GetPlayerTraceToOther(ply)
						
						if(IsValid(aim_ent))then
							if(other_ply and MODE.CanPlayerBreakOtherNeck(ply, aim_ent))then
								MODE.StartBreakingOtherNeck(ply, other_ply)
							end
						end
					elseif(ply:KeyDown(IN_USE))then
						if(ply.Ability_NeckBreak)then
							MODE.ContinueBreakingOtherNeck(ply)
						end
					end
					
					if(ply:KeyReleased(IN_USE))then
						MODE.StopBreakingOtherNeck(ply)
					end
				else
					MODE.StopBreakingOtherNeck(ply)
				end
			end
			
			if(ply.SubRole == "traitor_assasin" or ply.SubRole == "traitor_assasin_soe")then
				local is_choking = ply:GetNetVar("isChoking", false)
                local choke_target = ply:GetNetVar("chokeTarget", NULL)

                if ply:KeyDown(IN_WALK) then -- Alt key
                    if ply:KeyPressed(IN_USE) and not is_choking then
                        local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * 85, filter = ply })
                        if IsValid(tr.Entity) and tr.Entity:IsPlayer() and tr.Entity:Alive() then
                            local victim = tr.Entity
                            local wep = victim:GetActiveWeapon()
                            if IsValid(wep) and wep:GetClass() ~= "weapon_hands" then victim:DropWeapon(wep) end
                            
                            victim:SetRagdoll(true, 1.5)

                            timer.Simple(0.1, function()
                                if not IsValid(ply) or not ply:KeyDown(IN_USE) then 
                                    victim:SetRagdoll(false)
                                    return 
                                end
                                ply:SetNetVar("isChoking", true) 
                                ply:SetNetVar("chokeTarget", victim) 
                                victim:SetNetVar("chokedBy", ply) 
                                if victim.organism then victim.organism.choking = true end
                            end)
                        end
                    elseif ply:KeyDown(IN_USE) and is_choking and IsValid(choke_target) then
                        if choke_target:Health() <= 0 then 
                            ply:SetNetVar("isChoking", false) 
                            if IsValid(choke_target) then 
                                choke_target:SetNetVar("chokedBy", NULL) 
                                if choke_target.organism then choke_target.organism.choking = false end
                            end 
                            return 
                        end
                        local attachmentID = choke_target:LookupAttachment("chest")
                        if attachmentID > 0 then 
                            local attachment = choke_target:GetAttachment(attachmentID) 
                            if attachment then 
                                ply:SetPos(attachment.Pos + attachment.Ang:Forward() * -25) 
                                ply:SetEyeAngles((choke_target:GetPos() - ply:GetPos()):Angle()) 
                            end 
                        end
                    elseif (ply:KeyReleased(IN_USE) and is_choking) or (is_choking and not IsValid(choke_target)) then 
                        ply:SetNetVar("isChoking", false) 
                        if IsValid(choke_target) then 
                            choke_target:SetNetVar("chokedBy", NULL) 
                            choke_target:SetRagdoll(false)
                            if choke_target.organism then choke_target.organism.choking = false end
                        end 
                    end
                else
                    if is_choking then 
                        ply:SetNetVar("isChoking", false) 
                        if IsValid(choke_target) then 
                            choke_target:SetNetVar("chokedBy", NULL) 
                            choke_target:SetRagdoll(false)
                            if choke_target.organism then choke_target.organism.choking = false end
                        end 
                    end
                end
			end
			
			if(ply.SubRole == "traitor_zombie")then
				if(ply:KeyDown(IN_WALK))then
					
				end
			end

			if(ply.SubRole == "traitor_chemist")then
				DegradeChemicalsOfPlayer(ply)
				
				if(!ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime or ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime <= CurTime())then
					MODE.NetworkChemicalResistanceOfPlayer(ply)

					ply.PassiveAbility_ChemicalAccumulation_NextNetworkTime = CurTime() + 1
				end
			end
		end
	end
end)

hook.Add("SetupMove", "Sandbox_ChokeVictim", function(ply, mv, cmd)
    if not IsValid(ply) then return end
    local choker = ply:GetNetVar("chokedBy", NULL)
    if IsValid(choker) then
        mv:SetForwardSpeed(0)
        mv:SetSideSpeed(0)
        mv:SetButtons(0)
        
        local ang = (choker:GetPos() - ply:GetPos()):Angle()
        ply:SetEyeAngles(ang)
    end
end)