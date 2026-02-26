if CLIENT then
    local Heartbeat = {}
    Heartbeat.Enabled = CreateClientConVar("hg_heartbeat_enabled", "1", true, false)
    Heartbeat.Monitor = CreateClientConVar("hg_monitor", "1", true, false)
    Heartbeat.PositionX = CreateClientConVar("hg_heartbeat_x", "50", true, false)
    Heartbeat.PositionY = CreateClientConVar("hg_heartbeat_y", "50", true, false)
    Heartbeat.Width = 450
    Heartbeat.Height = 170
    Heartbeat.TraumaHeight = 40
    Heartbeat.StatsWidth = 200  
    
    Heartbeat.Conditions = {
        { name = "Asystolic", priority = 100, color = Color(255, 0, 0), check = function(m, s) return s.isCardiacArrest end },
        { name = "Critically Injured", priority = 90, color = Color(255, 0, 0), check = function(m, s) return s.isCritical end },
        { name = "Arterial Rupture", priority = 85, color = Color(255, 0, 0), check = function(m, s) return table.Count(m.arterialwounds) > 0 end },
        { name = "Severe Hypovolemia", priority = 80, color = Color(255, 100, 0), check = function(m, s) return s.isHemorrhagic and m.blood < 2500 end },
        { name = "Severe Hypoxemia", priority = 75, color = Color(255, 100, 0), check = function(m, s) return s.isHypoxic and m.o2 < 15 end },
        { name = "Brain Damaged", priority = 70, color = Color(255, 100, 100), check = function(m, s) return s.isBrainDamaged end },
        { name = "Arrythmic", priority = 60, color = Color(255, 150, 0), check = function(m, s) return s.isArrhythmia end },
        { name = "Pneumothorax", priority = 65, color = Color(255, 120, 0), check = function(m, s) return m.pneumothorax > 0.3 end },
        { name = "Spinal Fracture", priority = 55, color = Color(255, 200, 0), check = function(m, s) return m.spine2 > 0.5 or m.spine3 > 0.5 end },
        { name = "Arm Fracture", priority = 54, color = Color(255, 200, 0), check = function(m, s) return m.larm >= 1 or m.rarm >= 1 end },
        { name = "Leg Fracture", priority = 53, color = Color(255, 200, 0), check = function(m, s) return m.lleg >= 1 or m.rleg >= 1 end },
        { name = "Cranial Fracture", priority = 55, color = Color(255, 200, 0), check = function(m, s) return m.skull > 0.5 end },
        { name = "Hypovolemic", priority = 50, color = Color(255, 255, 0), check = function(m, s) return s.isHemorrhagic end },
        { name = "Internal Bleeding", priority = 45, color = Color(255, 255, 0), check = function(m, s) return m.internalBleed > 0 end },
        { name = "Hypoxemic", priority = 40, color = Color(0, 150, 255), check = function(m, s) return s.isHypoxic and m.o2 >= 15 end },
        { name = "Bleeding", priority = 35, color = Color(255, 255, 100), check = function(m, s) return m.bleed > 0 end },
        { name = "Tachycardic", priority = 30, color = Color(255, 255, 0), check = function(m, s) return s.isTachycardia end },
        { name = "Bradycardic", priority = 20, color = Color(0, 200, 255), check = function(m, s) return s.isBradycardia end },
        { name = "Panicked", priority = 25, color = Color(255, 100, 255), check = function(m, s) return m.adrenaline > 1.5 and m.pain > 40 end },
        { name = "Fainting", priority = 18, color = Color(180, 180, 180), check = function(m, s) return m.unconscious and not s.isCritical end },
        { name = "Unresponsive", priority = 15, color = Color(200, 200, 200), check = function(m, s) return s.isUnconscious end },
        { name = "Systemic Organ Failure", priority = 88, color = Color(255, 20, 20), check = function(m, s) return m.heart > 0.8 or m.liver > 0.8 or m.kidneys > 0.8 or m.stomach > 0.8 end },
        { name = "Heart Failure", priority = 86, color = Color(255, 50, 50), check = function(m, s) return m.heart > 0.6 end },
        { name = "Liver Failure", priority = 68, color = Color(255, 120, 50), check = function(m, s) return m.liver > 0.6 end },
        { name = "Kidney Failure", priority = 67, color = Color(255, 120, 50), check = function(m, s) return m.kidneys > 0.6 end },
        { name = "Stomach Rupture", priority = 66, color = Color(255, 120, 50), check = function(m, s) return m.stomach > 0.6 end },
    }
    
    Heartbeat.Afflictions = CreateClientConVar("hg_afflictions", "1", true, false)

    Heartbeat.LastHeartStopState = false
    Heartbeat.HeartStopSoundPlayed = false

    function Heartbeat:GetActiveConditions(metrics, state)
        local activeConditions = {}
        if not metrics or not state then return activeConditions end

        for _, condition in ipairs(self.Conditions) do
            if condition.check(metrics, state) then
                table.insert(activeConditions, condition)
            end
        end

        table.sort(activeConditions, function(a, b)
            return a.priority > b.priority
        end)

        return activeConditions
    end
    Heartbeat.LastHighPulseState = false
    Heartbeat.HighPulseSound = nil
    Heartbeat.HighPulseVolume = 0
    Heartbeat.TargetHighPulseVolume = 0
    
    surface.CreateFont("Heartbeat_Small", {
        font = "Bender",
        size = 11,
        weight = 400
    })
    
    surface.CreateFont("Heartbeat_Medium", {
        font = "Bender",
        size = 14,
        weight = 600
    })
    
    surface.CreateFont("Heartbeat_Large", {
        font = "Bender",
        size = 16,
        weight = 800
    })
    
    surface.CreateFont("Heartbeat_Status", {
        font = "Bender",
        size = 14,
        weight = 900
    })
    
    Heartbeat.ECGData = {}
    Heartbeat.DataPoints = 300
    Heartbeat.DataIndex = 1
    Heartbeat.LastUpdateTime = 0
    Heartbeat.UpdateInterval = 0.05
    Heartbeat.LastPulse = 70
    Heartbeat.CardiacArrestTimer = 0
    Heartbeat.ArrhythmiaTimer = 0
    Heartbeat.PainEffect = 0
    Heartbeat.BloodEffect = 0
    Heartbeat.O2Effect = 0
    Heartbeat.WaveTime = 0
    
    for i = 1, Heartbeat.DataPoints do
        Heartbeat.ECGData[i] = 0
    end
    
    function Heartbeat:IsPlayerHurt(metrics)
        if not metrics then return false end
        
        if metrics.blood < 5000 then return true end
        if metrics.o2 < 30 then return true end
        if metrics.pain > 0 then return true end
        if metrics.heartDamage > 0 then return true end
        if metrics.brain > 0 then return true end
        if metrics.shock > 0 then return true end
        if metrics.pneumothorax > 0 then return true end
        if metrics.lungsL > 0 then return true end
        if metrics.lungsR > 0 then return true end
        if metrics.trachea > 0 then return true end
        if metrics.chest > 0 then return true end
        if metrics.skull > 0 then return true end
        if metrics.spine2 > 0 then return true end
        if metrics.spine3 > 0 then return true end
        if metrics.bleed > 0 then return true end
        if metrics.internalBleed > 0 then return true end
        
        return false
    end

    
    
    function Heartbeat:CheckPlayerState()
        local ply = LocalPlayer()
        if not IsValid(ply) then 
            self.IsActive = false
            return false
        end
        
        
        if not ply:Alive() then
            if self.IsActive then
                self:OnPlayerDied()
            end
            self.IsActive = false
            self.WasDead = true
            return false
        end
        
        
        if self.WasDead and ply:Alive() then
            self.WasDead = false
            if not self.IsActive then
                self:OnPlayerRespawned()
            end
            self.IsActive = true
        end
        
        return true
    end
    
    
    function Heartbeat:OnPlayerDied()
        
        if self.HighPulseSound and self.HighPulseSound:IsValid() then
            self.HighPulseSound:Stop()
            self.HighPulseSound = nil
        end
        
        self:StopHeartStopSound()
        
       
        for i = 1, self.DataPoints do
            self.ECGData[i] = 0
        end
        
        
        self.CardiacArrestTimer = 0
        self.ArrhythmiaTimer = 0
        self.PainEffect = 0
        self.BloodEffect = 0
        self.O2Effect = 0
        self.WaveTime = 0
        
        print("[Heartbeat Monitor] Player died - monitor deactivated")
    end
    
    
    function Heartbeat:OnPlayerRespawned()
        
        self.LastHeartStopState = false
        self.HeartStopSoundPlayed = false
        self.LastHighPulseState = false
        self.HighPulseVolume = 0
        self.TargetHighPulseVolume = 0
        
        self.LastUpdateTime = 0
        self.LastPulse = 70
        
        print("[Heartbeat Monitor] Player respawned - monitor activated")
    end
    
    function Heartbeat:GetPlayerOrganism()
        local ply = LocalPlayer()
        if not IsValid(ply) then return nil end
        if not ply:Alive() then return nil end
        
        if ply.organism then return ply.organism end
        if ply.new_organism then return ply.new_organism end
        
        return nil
    end
    
    function Heartbeat:GetMedicalMetrics(org)
        if not org then
            return {
                pulse = 70,
                heartDamage = 0,
                heartStop = false,
                blood = 5000,
                o2 = 30,
                brain = 0,
                unconscious = false,
                critical = false,
                pain = 0,
                adrenaline = 0,
                shock = 0,
                bleed = 0,
                internalBleed = 0,
                stamina = 180,
                pneumothorax = 0,
                spine2 = 0,
            spine3 = 0,
            larm = 0,
            rarm = 0,
            lleg = 0,
            rleg = 0,
            arterialwounds = {}
            }
        end
        
        return {
            pulse = tonumber(org.pulse) or 70,
            heartDamage = tonumber(org.heart) or 0,
            heartStop = org.heartstop or false,
            blood = tonumber(org.blood) or 5000,
            o2 = (org.o2 and tonumber(org.o2[1])) or 30,
            brain = tonumber(org.brain) or 0,
            unconscious = org.otrub or false,
            critical = org.critical or false,
            pain = tonumber(org.pain) or 0,
            adrenaline = tonumber(org.adrenaline) or 0,
            shock = tonumber(org.shock) or 0,
            bleed = tonumber(org.bleed) or 0,
            internalBleed = tonumber(org.internalBleed) or 0,
            stamina = (org.stamina and tonumber(org.stamina[1])) or 180,
            pneumothorax = tonumber(org.pneumothorax) or 0,
            lungsL = (org.lungsL and tonumber(org.lungsL[1])) or 0,
            lungsR = (org.lungsR and tonumber(org.lungsR[1])) or 0,
            trachea = tonumber(org.trachea) or 0,
            chest = tonumber(org.chest) or 0,
            skull = tonumber(org.skull) or 0,
            spine2 = tonumber(org.spine2) or 0,
            spine3 = tonumber(org.spine3) or 0,
            incapacitated = org.incapacitated or false,
            larm = tonumber(org.larm) or 0,
            rarm = tonumber(org.rarm) or 0,
            lleg = tonumber(org.lleg) or 0,
            rleg = tonumber(org.rleg) or 0,
            arterialwounds = org.arterialwounds or {},
            heart = tonumber(org.heart) or 0,
            liver = tonumber(org.liver) or 0,
            kidneys = tonumber(org.kidneys) or 0,
            stomach = tonumber(org.stomach) or 0
        }
    end
    
    function Heartbeat:GetTraumaList(metrics)
        local traumas = {}
        
        if metrics.chest > 0.5 then table.insert(traumas, "CHEST FRACTURE") end
        if metrics.skull > 0.5 then table.insert(traumas, "SKULL FRACTURE") end
        if metrics.spine2 > 0.5 or metrics.spine3 > 0.5 then table.insert(traumas, "SPINE FRACTURE") end
        if metrics.lungsL > 0.5 then table.insert(traumas, "LEFT LUNG DAMAGE") end
        if metrics.lungsR > 0.5 then table.insert(traumas, "RIGHT LUNG DAMAGE") end
        if metrics.trachea > 0.5 then table.insert(traumas, "TRACHEA DAMAGE") end
        if metrics.pneumothorax > 0.3 then table.insert(traumas, "PNEUMOTHORAX") end
        if metrics.bleed > 0 then table.insert(traumas, "BLEEDING") end
        if metrics.internalBleed > 0 then table.insert(traumas, "INTERNAL BLEEDING") end
        if metrics.unconscious then table.insert(traumas, "UNCONSCIOUS") end
        if metrics.incapacitated then table.insert(traumas, "INCAPACITATED") end
        
        return traumas
    end
    
    function Heartbeat:DetermineMedicalState(metrics)
        local state = {
            isCardiacArrest = false,
            isArrhythmia = false,
            isTachycardia = false,
            isBradycardia = false,
            isCritical = false,
            isHypoxic = false,
            isHemorrhagic = false,
            isBrainDamaged = false,
            isUnconscious = false,
            severity = 0
        }
        
        state.isCardiacArrest = metrics.heartStop or metrics.pulse <= 0
        state.isArrhythmia = metrics.heartDamage > 0.3
        state.isTachycardia = metrics.pulse > 120
        state.isBradycardia = metrics.pulse < 50 and metrics.pulse > 0
        state.isCritical = metrics.critical or metrics.blood < 2000 or metrics.o2 < 10 or metrics.brain > 0.5
        state.isHypoxic = metrics.o2 < 20
        state.isHemorrhagic = metrics.blood < 3500
        state.isBrainDamaged = metrics.brain > 0.2
        state.isUnconscious = metrics.unconscious
        
        local severity = 0
        if state.isCardiacArrest then severity = severity + 0.3 end
        if state.isCritical then severity = severity + 0.2 end
        if state.isHemorrhagic then severity = severity + 0.15 end
        if state.isHypoxic then severity = severity + 0.15 end
        if state.isBrainDamaged then severity = severity + 0.1 end
        if metrics.pain > 50 then severity = severity + 0.1 end
        
        state.severity = math.min(severity, 1)
        
        return state
    end
    
    function Heartbeat:PlayHeartStopSound()
        --sound.Play("ambient/alarms/apc_alarm_loop1.wav", LocalPlayer():GetPos(), 38, 100, 1)
    end
    
    function Heartbeat:StopHeartStopSound()
        LocalPlayer():StopSound("ambient/alarms/apc_alarm_loop1.wav")
    end
    
    function Heartbeat:UpdateHighPulseSound(metrics, state)
        local isHighPulse = metrics.pulse > 120 and not state.isCardiacArrest
        local pulseFactor = math.max(0, (metrics.pulse - 120) / 80)
        
        if isHighPulse then
            self.TargetHighPulseVolume = 0.3 + pulseFactor * 0.5
        else
            self.TargetHighPulseVolume = 0
        end
        
        self.HighPulseVolume = Lerp(FrameTime() * 3, self.HighPulseVolume, self.TargetHighPulseVolume)
        
        if self.HighPulseVolume > 0.01 then
            if not self.HighPulseSound or not self.HighPulseSound:IsValid() then
                self.HighPulseSound = CreateSound(LocalPlayer(), "sound/pyls.wav")
                if self.HighPulseSound then
                    self.HighPulseSound:PlayEx(0, 100)
                end
            end
            
            if self.HighPulseSound then
                self.HighPulseSound:ChangeVolume(self.HighPulseVolume, 0.1)
                
                local pitch = 100 + pulseFactor * 20
                self.HighPulseSound:ChangePitch(pitch, 0.1)
            end
        elseif self.HighPulseSound and self.HighPulseSound:IsValid() then
            if self.HighPulseVolume <= 0.01 then
                self.HighPulseSound:Stop()
                self.HighPulseSound = nil
            end
        end
    end
    
    function Heartbeat:GenerateECGWave(phase, metrics, state)
        local wave = 0
        
        if state.isCardiacArrest then
            return 0
        end
        
        local baseFrequency = 2 * math.pi * 1
        local baseWave = math.sin(phase * baseFrequency) * 0.3
        
        local pWave, qrsComplex, tWave = 0, 0, 0
        
        if phase > 0.1 and phase < 0.15 then
            pWave = math.sin((phase - 0.1) * 40) * 0.4
        end
        
        if phase > 0.3 and phase < 0.35 then
            qrsComplex = math.sin((phase - 0.3) * 60) * 0.8
        end
        if phase > 0.35 and phase < 0.45 then
            qrsComplex = qrsComplex + math.sin((phase - 0.35) * 50) * 1.2
        end
        if phase > 0.45 and phase < 0.5 then
            qrsComplex = qrsComplex - math.sin((phase - 0.45) * 40) * 0.6
        end
        
        if phase > 0.6 and phase < 0.7 then
            tWave = math.sin((phase - 0.6) * 30) * 0.5
        end
        
        wave = baseWave + pWave + qrsComplex + tWave
        
        if state.isArrhythmia and metrics.heartDamage then
            local arrhythmiaStrength = metrics.heartDamage * 0.5
            local arrhythmiaFreq = 15 + math.sin(CurTime() * 2) * 5
            local arrhythmiaWave = math.sin(phase * arrhythmiaFreq) * 0.3 * arrhythmiaStrength
            
            if math.random(100) < metrics.heartDamage * 20 then
                arrhythmiaWave = arrhythmiaWave + math.sin(phase * 100) * 0.5 * arrhythmiaStrength
            end
            
            wave = wave + arrhythmiaWave
        end
        
        if state.isTachycardia then
            wave = wave * 0.9
            wave = wave + math.sin(phase * 35) * 0.15
        end
        
        if state.isBradycardia then
            wave = wave * 1.1
            wave = wave + math.sin(phase * 8) * 0.1
        end
        
        if state.isHypoxic then
            local hypoxicEffect = (30 - metrics.o2) / 30
            wave = wave * (1 - hypoxicEffect * 0.3)
            wave = wave + math.sin(phase * 20) * 0.1 * hypoxicEffect
        end
        
        if state.isHemorrhagic then
            if type(metrics.blood) ~= "number" then
                metrics.blood = 5000
            end
            local bloodEffect = (5000 - metrics.blood) / 3000
            wave = wave * (1 - bloodEffect * 0.4)
            
            if metrics.blood < 2500 then
                if math.sin(CurTime() * 2) > 0.7 then
                    wave = wave * 0.3
                end
            end
        end
        
        if state.isBrainDamaged then
            local brainEffect = metrics.brain * 0.3
            wave = wave + (math.sin(phase * 12 + CurTime() * 3) * 0.2 * brainEffect)
            wave = wave * (0.8 + math.sin(CurTime() * 0.5) * 0.2)
        end
        
        if metrics.pain > 30 then
            local painEffect = math.min(metrics.pain / 100, 0.4)
            wave = wave + math.sin(phase * 25) * 0.2 * painEffect
        end
        
        if metrics.adrenaline > 0 then
            local adrenEffect = math.min(metrics.adrenaline, 2) * 0.15
            wave = wave + math.abs(math.sin(phase * 35)) * 0.25 * adrenEffect
        end
        
        if metrics.shock > 20 then
            local shockEffect = math.min(metrics.shock / 100, 0.3)
            wave = wave * (1 - shockEffect * 0.2)
        end
        
        if metrics.pneumothorax > 0.3 then
            wave = wave * (1 - metrics.pneumothorax * 0.5)
        end
        
        if metrics.lungsL > 0.5 or metrics.lungsR > 0.5 then
            local lungDamage = (metrics.lungsL + metrics.lungsR) / 2
            wave = wave * (1 - lungDamage * 0.3)
        end
        
        if metrics.spine2 > 0.5 or metrics.spine3 > 0.5 then
            wave = wave * 0.7
        end
        
        if state.isUnconscious then
            wave = wave * 0.6
            wave = wave + math.sin(phase * 6) * 0.1
        end
        
        if state.isCritical then
            wave = wave + (math.random() - 0.5) * 0.3
            
            if math.sin(CurTime() * 0.3) > 0.8 then
                wave = wave * 0.2
            end
        end
        
        wave = wave + (math.random() - 0.5) * 0.05
        
        return wave
    end
    
    function Heartbeat:Update()
        
        if not self.Enabled:GetBool() then return end
        if not self:CheckPlayerState() then return end
        if not self.IsActive then return end
        
        
        if not GetGlobalBool("HG_Heartbeat_Active", true) then return end
        
        local currentTime = CurTime()
        if currentTime - self.LastUpdateTime < self.UpdateInterval then return end
        self.LastUpdateTime = currentTime
        
        local org = self:GetPlayerOrganism()
        local metrics = self:GetMedicalMetrics(org)
        local state = self:DetermineMedicalState(metrics)
        
        local heartStop = state.isCardiacArrest
        
        if heartStop and not self.LastHeartStopState then
            self:PlayHeartStopSound()
            self.HeartStopSoundPlayed = true
        elseif not heartStop and self.LastHeartStopState then
            self:StopHeartStopSound()
            self.HeartStopSoundPlayed = false
        end
        
        self.LastHeartStopState = heartStop
        
        self:UpdateHighPulseSound(metrics, state)
        
        if state.isCardiacArrest then
            self.CardiacArrestTimer = self.CardiacArrestTimer + FrameTime()
        else
            self.CardiacArrestTimer = math.max(self.CardiacArrestTimer - FrameTime() * 0.5, 0)
        end
        
        if state.isArrhythmia then
            self.ArrhythmiaTimer = self.ArrhythmiaTimer + FrameTime()
        else
            self.ArrhythmiaTimer = math.max(self.ArrhythmiaTimer - FrameTime() * 0.3, 0)
        end
        
        self.PainEffect = Lerp(FrameTime() * 2, self.PainEffect, metrics.pain / 100)
        self.BloodEffect = Lerp(FrameTime() * 2, self.BloodEffect, (5000 - metrics.blood) / 3000)
        self.O2Effect = Lerp(FrameTime() * 2, self.O2Effect, (30 - metrics.o2) / 30)
        
        if metrics.pulse > 0 and not state.isCardiacArrest then
            local timeScale = metrics.pulse / 60
            self.WaveTime = self.WaveTime + (FrameTime() * timeScale)
        end
        
        local phase = self.WaveTime % 1
        
        local waveValue = self:GenerateECGWave(phase, metrics, state)
        
        self.ECGData[self.DataIndex] = waveValue
        self.DataIndex = self.DataIndex + 1
        if self.DataIndex > self.DataPoints then
            self.DataIndex = 1
        end
        
        self.LastPulse = metrics.pulse
    end
    
    function Heartbeat:DrawTraumaWindow(x, y, org, metrics, state)
        if not org then return end

        local activeConditions = self:GetActiveConditions(metrics, state)
        if #activeConditions == 0 then return end

        surface.SetDrawColor(10, 20, 10, 240)
        surface.DrawRect(x, y, self.Width, self.TraumaHeight)

        local mostSevereCondition = activeConditions[1]

        surface.SetDrawColor(mostSevereCondition.color.r, mostSevereCondition.color.g, mostSevereCondition.color.b, 150)
        surface.DrawOutlinedRect(x, y, self.Width, self.TraumaHeight)
        surface.DrawOutlinedRect(x + 1, y + 1, self.Width - 2, self.TraumaHeight - 2)

        local conditionsToDisplay = {}
        for i = 1, math.min(#activeConditions, 3) do
            table.insert(conditionsToDisplay, activeConditions[i].name)
        end
        local conditionsText = table.concat(conditionsToDisplay, " | ")

        draw.SimpleText("ALERT: " .. conditionsText, "Heartbeat_Small",
            x + self.Width / 2, y + self.TraumaHeight / 2,
            mostSevereCondition.color,
            TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER)
    end
    
    function Heartbeat:DrawStatsWindow(x, y, metrics, state)
        if not metrics then return end

        local statsX = x - self.StatsWidth - 10
        local statsY = y

        surface.SetDrawColor(10, 20, 10, 240)
        surface.DrawRect(statsX, statsY, self.StatsWidth, self.Height)

        surface.SetDrawColor(0, 150, 0, 255)
        surface.DrawOutlinedRect(statsX, statsY, self.StatsWidth, self.Height)
        surface.DrawOutlinedRect(statsX + 1, statsY + 1, self.StatsWidth - 2, self.Height - 2)

        draw.SimpleText("VITAL STATISTICS", "Heartbeat_Small", statsX + self.StatsWidth/2, statsY + 15, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        surface.SetDrawColor(0, 150, 0, 100)
        surface.DrawLine(statsX + 10, statsY + 30, statsX + self.StatsWidth - 10, statsY + 30)

        if not self:IsPlayerHurt(metrics) then
            draw.SimpleText("ALL OK", "Heartbeat_Large", statsX + self.StatsWidth/2, statsY + self.Height/2, Color(0, 255, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        local activeConditions = self:GetActiveConditions(metrics, state)
        local startY = statsY + 40
        for i, condition in ipairs(activeConditions) do
            draw.SimpleText(condition.name, "Heartbeat_Small", statsX + 15, startY, condition.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            startY = startY + 15
        end
    end
    
    function Heartbeat:Draw()
        if not self.Enabled:GetBool() then return end
        if not GetGlobalBool("HG_Heartbeat_Active", true) then return end
        if not self:CheckPlayerState() then return end
        if not self.IsActive then return end
        
        
        if not GetGlobalBool("HG_Heartbeat_Active", true) then return end
        
        local x = self.PositionX:GetInt()
        local y = self.PositionY:GetInt()
        
        local org = self:GetPlayerOrganism()
        local metrics = self:GetMedicalMetrics(org)
        local state = self:DetermineMedicalState(metrics)
        
        local mainY = y + self.TraumaHeight
        
       
        self:DrawTraumaWindow(x, y, org, metrics, state)
        -- if self.Monitor:GetBool() then
        --     self:DrawStatsWindow(x, y, metrics, state)
        -- end  
        
        
        local frameColor = Color(0, 150, 0, 255)
        local statusText = "NORMAL"
        local statusColor = Color(0, 255, 0, 255)
        local bpmColor = Color(0, 255, 0, 255)
        
        if state.isCardiacArrest then
            frameColor = Color(255, 0, 0, 255)
            statusText = "CARDIAC ARREST"
            statusColor = Color(255, 0, 0, 255)
            bpmColor = Color(255, 0, 0, 255)
        elseif state.isCritical then
            frameColor = Color(255, 100, 0, 255)
            statusText = "CRITICAL"
            statusColor = Color(255, 100, 0, 255)
            bpmColor = Color(255, 100, 0, 255)
        elseif state.isUnconscious then
            frameColor = Color(200, 200, 0, 255)
            statusText = "UNCONSCIOUS"
            statusColor = Color(200, 200, 0, 255)
            bpmColor = Color(200, 200, 0, 255)
        elseif state.isArrhythmia then
            frameColor = Color(255, 150, 0, 255)
            statusText = "ARRHYTHMIA"
            statusColor = Color(255, 150, 0, 255)
            bpmColor = Color(255, 150, 0, 255)
        elseif state.isTachycardia then
            frameColor = Color(255, 255, 0, 255)
            statusText = "TACHYCARDIA"
            statusColor = Color(255, 255, 0, 255)
            bpmColor = Color(255, 255, 0, 255)
        elseif state.isBradycardia then
            frameColor = Color(255, 150, 0, 255)
            statusText = "BRADYCARDIA"
            statusColor = Color(255, 150, 0, 255)
            bpmColor = Color(255, 150, 0, 255)
        elseif state.isHypoxic then
            frameColor = Color(0, 150, 255, 255)
            statusText = "HYPOXIA"
            statusColor = Color(0, 150, 255, 255)
            bpmColor = Color(0, 150, 255, 255)
        elseif state.isHemorrhagic then
            frameColor = Color(255, 0, 100, 255)
            statusText = "HEMORRHAGE"
            statusColor = Color(255, 0, 100, 255)
            bpmColor = Color(255, 0, 100, 255)
        end
        
        
        surface.SetDrawColor(10, 20, 10, 240)
        surface.DrawRect(x, mainY, self.Width, self.Height)
        
        
        surface.SetDrawColor(frameColor.r, frameColor.g, frameColor.b, 255)
        surface.DrawOutlinedRect(x, mainY, self.Width, self.Height)
        surface.DrawOutlinedRect(x + 1, mainY + 1, self.Width - 2, self.Height - 2)
        
        
        surface.SetDrawColor(0, 60, 0, 40)
        local gridSize = 20
        
        for i = 0, math.floor(self.Width / gridSize) do
            surface.DrawLine(x + i * gridSize, mainY, x + i * gridSize, mainY + self.Height)
        end
        
        for i = 0, math.floor(self.Height / gridSize) do
            surface.DrawLine(x, mainY + i * gridSize, x + self.Width, mainY + i * gridSize)
        end
        
        
        local lineColor = Color(0, 255, 0, 255)
        
        if state.isCardiacArrest then
            local pulse = math.sin(CurTime() * 3) * 0.5 + 0.5
            lineColor = Color(255 * pulse, 0, 0, 255)
        elseif state.isCritical then
            local pulse = math.sin(CurTime() * 5) * 0.5 + 0.5
            lineColor = Color(255 * pulse, 100 * pulse, 0, 255)
        elseif state.isArrhythmia then
            local pulse = math.sin(CurTime() * 7) * 0.5 + 0.5
            lineColor = Color(255 * pulse, 150 * pulse, 0, 255)
        end
        
        
        local points = {}
        for i = 0, self.DataPoints - 1 do
            local idx = (self.DataIndex + i - 1) % self.DataPoints + 1
            local x_pos = x + i * (self.Width / self.DataPoints)
            local y_pos = mainY + self.Height/2 - self.ECGData[idx] * (self.Height * 0.35)
            table.insert(points, {x = x_pos, y = y_pos})
        end
        
        if #points >= 2 then
            surface.SetDrawColor(lineColor.r, lineColor.g, lineColor.b, 255)
            for i = 1, #points - 1 do
                surface.DrawLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y)
            end
            
            surface.SetDrawColor(lineColor.r, lineColor.g, lineColor.b, 80)
            for i = 1, #points - 1 do
                surface.DrawLine(points[i].x, points[i].y + 1, points[i + 1].x, points[i + 1].y + 1)
            end
        end
        
        
        local bpmText = "BPM: "
        if state.isCardiacArrest then
            bpmText = bpmText .. "0"
        else
            bpmText = bpmText .. math.Round(metrics.pulse)
        end
        
        draw.SimpleText(bpmText, "Heartbeat_Large", x + 12, mainY + 12, bpmColor)
        
        
        local alpha = 150 + math.sin(CurTime() * 3) * 100
        statusColor.a = alpha
        draw.SimpleText(statusText, "Heartbeat_Status", 
            x + self.Width/2, 
            mainY + self.Height - 22, 
            statusColor, 
            TEXT_ALIGN_CENTER)
    end


    function Heartbeat:DrawAfflictions()
        if not self.Enabled:GetBool() then return end
        if not self.Afflictions:GetBool() then return end
        if not self:CheckPlayerState() then return end
        if not self.IsActive then return end

        local org = self:GetPlayerOrganism()
        if not org then return end

        local metrics = self:GetMedicalMetrics(org)
        local state = self:DetermineMedicalState(metrics)
        local activeConditions = self:GetActiveConditions(metrics, state)

        if #activeConditions == 0 then return end

        local conditionsToHide = {
            ["Asystolic"] = state.isCardiacArrest,
            ["Critically Injured"] = state.isCritical,
            ["Arrythmic"] = state.isArrhythmia,
            ["Tachycardic"] = state.isTachycardia,
            ["Bradycardic"] = state.isBradycardia,
            ["Hypoxemic"] = state.isHypoxic,
            ["Hypovolemic"] = state.isHemorrhagic,
            ["Unresponsive"] = state.isUnconscious
        }

        local filteredConditions = {}
        for _, condition in ipairs(activeConditions) do
            if not conditionsToHide[condition.name] then
                table.insert(filteredConditions, condition)
            end
        end

        if #filteredConditions == 0 then return end

        local width = 250
        local padding = 10
        local lineHeight = 30
        local headerHeight = 25
        local height = headerHeight + (#filteredConditions * lineHeight) + padding

        local x = ScrW() - width - 20
        local y = 20

        -- Draw background
        surface.SetDrawColor(10, 15, 10, 220)
        surface.DrawRect(x, y, width, height)

        -- Draw border
        local isUnconscious = state.isUnconscious

        if isUnconscious then
            local grayColor = Color(100, 100, 100, 150)
            surface.SetDrawColor(grayColor.r, grayColor.g, grayColor.b, 180)
            surface.DrawOutlinedRect(x, y, width, height)
            surface.DrawOutlinedRect(x + 1, y + 1, width - 2, height - 2)
            draw.SimpleText("UNRESPONSIVE", "Heartbeat_Medium", x + width / 2, y + headerHeight / 2, grayColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(grayColor.r, grayColor.g, grayColor.b, 100)
            surface.DrawLine(x + padding, y + headerHeight, x + width - padding, y + headerHeight)
        else
            local mostSevereColor = activeConditions[1].color
            surface.SetDrawColor(mostSevereColor.r, mostSevereColor.g, mostSevereColor.b, 180)
            surface.DrawOutlinedRect(x, y, width, height)
            surface.DrawOutlinedRect(x + 1, y + 1, width - 2, height - 2)
            draw.SimpleText("CONDITIONS", "Heartbeat_Medium", x + width / 2, y + headerHeight / 2, mostSevereColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(mostSevereColor.r, mostSevereColor.g, mostSevereColor.b, 100)
            surface.DrawLine(x + padding, y + headerHeight, x + width - padding, y + headerHeight)
        end

        -- Draw conditions
        local currentY = y + headerHeight + (padding / 2)
        for i, condition in ipairs(filteredConditions) do
            local alpha = 255
            if i > 1 then
                alpha = 180 - (i * 20)
            end

            if isUnconscious then
                local textColor = Color(120, 120, 120, alpha)
                draw.SimpleText(condition.name, "Heartbeat_Small", x + padding, currentY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                if condition.name == "Asystolic" or condition.name == "Severe Hypoxemia" or condition.name == "Hypoxemic" then
                    local details = self:GetAfflictionDetails(condition, metrics, state)
                    if details then
                        draw.SimpleText(details, "Heartbeat_Small", x + padding, currentY + 12, Color(150, 150, 150, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    end
                end
            else
                local textColor = Color(condition.color.r, condition.color.g, condition.color.b, alpha)
                draw.SimpleText(condition.name, "Heartbeat_Small", x + padding, currentY, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                local details = self:GetAfflictionDetails(condition, metrics, state)
                if details then
                    draw.SimpleText(details, "Heartbeat_Small", x + padding, currentY + 12, Color(200, 200, 200, alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                end
            end

            currentY = currentY + lineHeight
        end
    end

    function Heartbeat:GetAfflictionDetails(condition, metrics, state)
        if condition.name == "Heart Failure" then
            return "Damage: " .. math.Round(metrics.heart * 100) .. "%"
        elseif condition.name == "Liver Failure" then
            return "Damage: " .. math.Round(metrics.liver * 100) .. "%"
        elseif condition.name == "Kidney Failure" then
            return "Damage: " .. math.Round(metrics.kidneys * 100) .. "%"
        elseif condition.name == "Stomach Rupture" then
            return "Damage: " .. math.Round(metrics.stomach * 100) .. "%"
        end

        return nil
    end

    hook.Add("Think", "HeartbeatMonitor_Update", function()
        Heartbeat:Update()
    end)
    
    hook.Add("HUDPaint", "HeartbeatMonitor_Draw", function()
        Heartbeat:DrawAfflictions()
    end)
    
    
    hook.Add("PlayerDeath", "HeartbeatMonitor_PlayerDeath", function(victim, inflictor, attacker)
        if victim == LocalPlayer() then
            Heartbeat:OnPlayerDied()
            Heartbeat.IsActive = false
            Heartbeat.WasDead = true
        end
    end)
    
    
    hook.Add("PlayerSpawn", "HeartbeatMonitor_PlayerSpawn", function(ply)
        if ply == LocalPlayer() then
            Heartbeat.WasDead = false
            if Heartbeat.Enabled:GetBool() then
                Heartbeat:OnPlayerRespawned()
                Heartbeat.IsActive = true
            end
        end
    end)
    
    concommand.Add("hg_heartbeat_toggle", function()
        local current = Heartbeat.Enabled:GetBool()
        RunConsoleCommand("hg_heartbeat_enabled", current and "0" or "1")
        
        
        if LocalPlayer() and LocalPlayer():Alive() and not current then
            Heartbeat.IsActive = true
            Heartbeat:OnPlayerRespawned()
        elseif LocalPlayer() and LocalPlayer():Alive() and current then
            Heartbeat.IsActive = false
            Heartbeat:OnPlayerDied()
        end
    end)
    
    concommand.Add("hg_heartbeat_resetpos", function()
        RunConsoleCommand("hg_heartbeat_x", "50")
        RunConsoleCommand("hg_heartbeat_y", "50")
    end)
    
    local isDragging = false
    local dragOffsetX, dragOffsetY = 0, 0
    
    hook.Add("Think", "HeartbeatMonitor_Drag", function()
        if not Heartbeat.Enabled:GetBool() then return end
        if not Heartbeat.IsActive then return end
        
        local x = Heartbeat.PositionX:GetInt()
        local y = Heartbeat.PositionY:GetInt()
        
        local mouseX, mouseY = gui.MousePos()
        local totalHeight = Heartbeat.Height + Heartbeat.TraumaHeight
        local totalWidth = Heartbeat.Width + Heartbeat.StatsWidth + 5  
        
        
        if input.IsMouseDown(MOUSE_LEFT) then
            if not isDragging then
                
                local overMainWindow = mouseX >= x and mouseX <= x + Heartbeat.Width and 
                                      mouseY >= y and mouseY <= y + 30
                
                
                local overStatsWindow = mouseX >= x + Heartbeat.Width + 5 and 
                                       mouseX <= x + Heartbeat.Width + 5 + Heartbeat.StatsWidth and 
                                       mouseY >= y and mouseY <= y + 30
                
                if overMainWindow or overStatsWindow then
                    isDragging = true
                    dragOffsetX = mouseX - x
                    dragOffsetY = mouseY - y
                end
            else
                local newX = math.Clamp(mouseX - dragOffsetX, 0, ScrW() - totalWidth)
                local newY = math.Clamp(mouseY - dragOffsetY, 0, ScrH() - totalHeight)
                
                RunConsoleCommand("hg_heartbeat_x", tostring(newX))
                RunConsoleCommand("hg_heartbeat_y", tostring(newY))
            end
        else
            isDragging = false
        end
    end)
    
    hook.Add("HUDPaint", "HeartbeatMonitor_DragHint", function()
        if not Heartbeat.Enabled:GetBool() then return end
        if not Heartbeat.IsActive then return end
        
        local x = Heartbeat.PositionX:GetInt()
        local y = Heartbeat.PositionY:GetInt()
        
        local mouseX, mouseY = gui.MousePos()
        
        
        local overMainWindow = mouseX >= x and mouseX <= x + Heartbeat.Width and 
                              mouseY >= y and mouseY <= y + 30
        
        local overStatsWindow = mouseX >= x + Heartbeat.Width + 5 and 
                               mouseX <= x + Heartbeat.Width + 5 + Heartbeat.StatsWidth and 
                               mouseY >= y and mouseY <= y + 30
        
        if overMainWindow or overStatsWindow then
            draw.SimpleText("HOLD LMB TO MOVE", "Heartbeat_Small", 
                x + Heartbeat.Width/2, y + 35, 
                Color(200, 200, 200, 180), 
                TEXT_ALIGN_CENTER)
        end
    end)
    
    
    hook.Add("InitPostEntity", "HeartbeatMonitor_Init", function()
        timer.Simple(1, function()
            Heartbeat:CheckPlayerState()
            if Heartbeat.IsActive then
               -- print("[Heartbeat Monitor] Initialized and active")
            else
                --print("[Heartbeat Monitor] Initialized but inactive (player dead or not connected)")
            end
        end)
    end)
end