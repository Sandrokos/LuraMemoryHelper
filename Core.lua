local _, Lura = ...

local detectedDurations = {
    [15] = {
        { time = 45, phase = 2 },
        { time = 97, phase = 3 },
        { time = 180, phase = 4 },
    },
    [16] = {
        { time = 45, phase = 2 },
        { time = 97, phase = 3 },
        { time = 180, phase = 4 },
    },
}

function Lura:IsInTargetRaid()
    local inInstance, instanceType = IsInInstance()
    if not inInstance or instanceType ~= "raid" then
        return false
    end
    local instanceName = GetInstanceInfo()
    return instanceName == "March of Quel'danas"
end

function Lura:EnsureFramesLoaded()
    if self.framesLoaded then
        return
    end
    self:CreateRunesDisplayFrame()
    self.framesLoaded = true
end

function Lura:EnsureDB()
    LuraDB = LuraDB or {}
    for key, value in pairs(self.DEFAULTS) do
        if LuraDB[key] == nil then
            LuraDB[key] = value
        end
    end
    self.db = LuraDB

    if self.db.DisplayPoint == nil then
        self.db.DisplayPoint = self.db.LuraDisplayAnchor or "CENTER"
        self.db.DisplayX = self.db.LuraDisplayOffsetX or 300
        self.db.DisplayY = self.db.LuraDisplayOffsetY or 0
    end

    if (self.db.schemaVersion or 0) < 2 then
        self.db.EnableSounds = false
        self.db.schemaVersion = 2
    end
end

function Lura:StartEncounter(difficultyID)
    self:EnsureFramesLoaded()

    self.state.inEncounter = true
    self.state.phase = 1
    self.state.phaseSwapTime = GetTime()
    self.state.difficultyID = difficultyID or (select(3, GetInstanceInfo()) or 0)

    self:SetupRunesDisplay(false)
end

function Lura:StopEncounter()
    self.state.inEncounter = false
    self:TeardownRunesDisplay()
end

function Lura:ApplyPhaseVisibility()
    if not self.runesFrame then
        return
    end
    local phase = self.state.phase
    if phase == 2 or phase == 5 then
        self:TeardownRunesDisplay()
        return
    end

    if phase == 4 and self.state.difficultyID == 16 then
        self:EnableMythicP4RunesDisplay()
        return
    end

    if self.db.RunesDisplay and self.state.inEncounter then
        self:SetupRunesDisplay(false)
    end
end

function Lura:HandleTimelineEvent(info)
    if type(info) ~= "table" or not info.duration then
        return
    end
    if not self.state.inEncounter then
        return
    end

    local tableForDifficulty = detectedDurations[self.state.difficultyID]
    if not tableForDifficulty then
        return
    end

    local phaseInfo = tableForDifficulty[self.state.phase]
    if not phaseInfo then
        return
    end

    local now = GetTime()
    if now <= (self.state.phaseSwapTime + 5) then
        return
    end

    if info.duration == phaseInfo.time and phaseInfo.phase > self.state.phase then
        self.state.phase = phaseInfo.phase
        self.state.phaseSwapTime = now
        self:ApplyPhaseVisibility()
    end
end

function Lura:Preview(show)
    if show then
        self:EnsureFramesLoaded()
        self:SetupRunesDisplay(true)
    else
        self:TeardownRunesDisplay()
    end
end

function Lura:OnSlashCommand(msg)
    msg = string.lower(msg or "")
    if msg == "" then
        self:ToggleOptionsPanel()
    elseif msg == "preview" then
        self:Preview(true)
    elseif msg == "hide" then
        self:Preview(false)
    elseif msg == "lock" then
        self.db.locked = true
        self:ApplyLockedState()
    elseif msg == "unlock" then
        self.db.locked = false
        self:ApplyLockedState()
    elseif msg == "options" then
        self:ToggleOptionsPanel()
    else
        self:Print("Commands: /lmh, /lmh preview, /lmh hide, /lmh lock, /lmh unlock, /lmh options")
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
events:RegisterEvent("ENCOUNTER_START")
events:RegisterEvent("ENCOUNTER_END")
events:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_ADDED")
events:RegisterEvent("ENCOUNTER_TIMELINE_EVENT_REMOVED")

events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        Lura:EnsureDB()
        Lura.db.locked = true
        Lura:CreateOptionsPanel()
        if Lura:IsInTargetRaid() then
            Lura:EnsureFramesLoaded()
        end
        Lura:ApplyLockedState()
        Lura:Print("Loaded. Use /lmh to open options.")
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        if Lura:IsInTargetRaid() then
            Lura:EnsureFramesLoaded()
        end
    elseif event == "ENCOUNTER_START" then
        local encounterID, _, difficultyID = ...
        if encounterID == Lura.ENCOUNTER_ID then
            Lura:StartEncounter(difficultyID)
        end
    elseif event == "ENCOUNTER_END" then
        local encounterID = ...
        if encounterID == Lura.ENCOUNTER_ID then
            Lura:StopEncounter()
        end
    elseif event == "ENCOUNTER_TIMELINE_EVENT_ADDED" then
        local info = ...
        Lura:HandleTimelineEvent(info)
    elseif event == "ENCOUNTER_TIMELINE_EVENT_REMOVED" then
        local info = ...
        Lura:HandleTimelineEvent(info)
    end
end)

SLASH_LMH1 = "/lmh"
SlashCmdList.LMH = function(msg)
    Lura:OnSlashCommand(msg)
end
