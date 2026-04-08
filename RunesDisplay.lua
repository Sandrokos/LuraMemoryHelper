local _, Lura = ...

-- Same icon file IDs as NSRT EncounterAlerts/MidnightS1/MidnightFalls.lua preview + Create Rune Macros.
local PREVIEW_ICON_IDS = { "134635", "340528", "351033", "7242384", "236903" }

local mythicRaidOrder = {
    CHAT_MSG_RAID = { 2, 3, 5 },
    CHAT_MSG_RAID_LEADER = { 1, 4 },
}

-- Normal (14) and Raid Finder / LFR (17) use three runes; instance chat instead of raid in LFR.
function Lura:IsThreeRuneDifficulty()
    local d = self.state.difficultyID or 0
    return d == 14 or d == 17
end

function Lura:GetRuneDisplayCap()
    local difficulty = self.state.difficultyID or 0
    if difficulty == 14 or difficulty == 17 then -- Normal, LFR
        return 3
    end
    if difficulty == 15 or difficulty == 16 then -- Heroic / Mythic
        return 5
    end
    return 5
end

function Lura:CreateRunesDisplayFrame()
    if self.runesFrame then
        return
    end

    self.runesFrame = CreateFrame("Frame", "LuraMemoryRunesDisplay", UIParent, "BackdropTemplate")
    self.runesFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    self.runesFrame:SetBackdropColor(0.5, 0.5, 0.5, 0.9)
    self.runesFrame:SetBackdropBorderColor(0, 0, 0, 0.9)
    self.runesFrame:SetMovable(true)
    self.runesFrame:EnableMouse(false)
    self.runesFrame:RegisterForDrag("LeftButton")
    self.runesFrame:SetScript("OnDragStart", function(frame)
        if Lura.db.locked then
            return
        end
        frame:StartMoving()
    end)
    self.runesFrame:SetScript("OnDragStop", function(frame)
        frame:StopMovingOrSizing()
        local point, _, _, x, y = frame:GetPoint(1)
        Lura.db.DisplayPoint = point
        Lura.db.DisplayX = x
        Lura.db.DisplayY = y
    end)

    self.runesDisplay = {}
    self.runesNumbers = {}
    self.runesCompleted = {}
    self.runesInverted = false
    self.alertTimers = nil
    self.hideTimer = nil

    self.runesFrame:SetScript("OnEvent", function(_, event, msg)
        self:OnRuneChatEvent(event, msg)
    end)

    self:CreateRunesRadarDecor(self.runesFrame)
    self:PositionRunesDisplay(false)
    self.runesFrame:Hide()
end

function Lura:CreateRunesRadarDecor(parent)
    if parent.radarCenterRed then
        return
    end

    local center = parent:CreateTexture(nil, "ARTWORK", nil, 0)
    center:SetSize(40, 40)
    center:SetPoint("CENTER", parent, "CENTER", 0, 14)
    center:SetTexture("Interface\\Buttons\\WHITE8X8")
    center:SetVertexColor(1, 0, 0, 1)

    local centerMask = parent:CreateMaskTexture()
    centerMask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    centerMask:SetAllPoints(center)
    center:AddMaskTexture(centerMask)
    parent.radarCenterRed = center

    local tank = parent:CreateTexture(nil, "ARTWORK", nil, 2)
    tank:SetSize(32, 32)
    tank:SetPoint("CENTER", parent, "CENTER", 0, 58)
    tank:SetTexture("Interface\\Icons\\Ability_Warrior_DefensiveStance")
    parent.radarTank = tank
end

function Lura:UpdateRunesRadarDecor(isP4Layout)
    if not self.runesFrame or not self.runesFrame.radarCenterRed then
        return
    end
    if isP4Layout then
        self.runesFrame.radarCenterRed:Hide()
        self.runesFrame.radarTank:Hide()
    else
        self.runesFrame.radarCenterRed:Show()
        self.runesFrame.radarTank:Show()
    end
end

function Lura:PositionRunesDisplay(isP4Layout)
    if not self.runesFrame then
        return
    end

    self.runesFrame:ClearAllPoints()
    self.runesFrame:SetPoint(
        self.db.DisplayPoint or "CENTER",
        UIParent,
        self.db.DisplayPoint or "CENTER",
        self.db.DisplayX or 300,
        self.db.DisplayY or 0
    )

    if isP4Layout then
        self.runesFrame:SetSize(300, 60)
    else
        self.runesFrame:SetSize(200, 200)
    end
    self:UpdateRunesRadarDecor(isP4Layout)
end

function Lura:ApplyRunesDragState(unlocked)
    if not self.runesFrame then
        return
    end
    self.runesFrame:EnableMouse(unlocked)
    if unlocked then
        self.runesFrame:SetBackdropBorderColor(1, 0.82, 0, 1)
    else
        self.runesFrame:SetBackdropBorderColor(0, 0, 0, 0.9)
    end
end

function Lura:ResetRunesDisplay()
    self.runesCompleted = {}
    for i = 1, 5 do
        if self.runesDisplay[i] then
            self.runesDisplay[i]:Hide()
        end
        if self.runesNumbers[i] then
            self.runesNumbers[i]:Hide()
        end
    end
end

function Lura:GetMythicPosition(eventName)
    local order = mythicRaidOrder[eventName]
    if not order then
        return nil
    end
    for _, position in ipairs(order) do
        if not self.runesCompleted[position] then
            return position
        end
    end
    return nil
end

function Lura:EnsureRuneSlot(position)
    if self.runesDisplay[position] then
        return
    end

    self.runesDisplay[position] = self.runesFrame:CreateFontString(nil, "OVERLAY")
    self.runesDisplay[position]:SetFont("Fonts\\FRIZQT__.TTF", 15)
    self.runesDisplay[position]:SetTextColor(1, 1, 1)

    self.runesNumbers[position] = self.runesFrame:CreateFontString(nil, "OVERLAY")
    self.runesNumbers[position]:SetFont("Fonts\\FRIZQT__.TTF", 25, "OUTLINE")
    self.runesNumbers[position]:SetTextColor(1, 1, 1)
    self.runesNumbers[position]:SetShadowColor(0, 0, 0, 1)
end

function Lura:DisplayRune(position, msg)
    self:EnsureRuneSlot(position)

    local xOffset = { 50, 60, 0, -60, -50 }
    local yOffset = { 50, -25, -70, -25, 50 }
    local isNormal = self:IsThreeRuneDifficulty()

    if isNormal then
        -- Normal memory game only uses 3 calls: east, south, west.
        xOffset = { 50, -70, -50, 0, 0 }
        yOffset = { 50, 0, 50, 0, 0 }
    end

    self.runesDisplay[position]:ClearAllPoints()
    self.runesNumbers[position]:ClearAllPoints()

    -- Match NSRT MidnightFalls: horizontal strip whenever encounter phase is 4.
    if self.state.phase == 4 then
        self.runesDisplay[position]:SetPoint("LEFT", self.runesFrame, "LEFT", (position - 1) * 60, 0)
        self.runesNumbers[position]:SetPoint("LEFT", self.runesFrame, "LEFT", (position - 1) * 60 + 22, 30)
    else
        self.runesDisplay[position]:SetPoint("CENTER", self.runesFrame, "CENTER", xOffset[position], yOffset[position])
        self.runesNumbers[position]:SetPoint("CENTER", self.runesFrame, "CENTER", xOffset[position], yOffset[position] + 30)
    end

    self.runesDisplay[position]:SetFormattedText("|T%s:48:48|t", msg)
    self.runesDisplay[position]:Show()

    local number = position
    if self.runesInverted then
        number = 6 - position
    end
    self.runesNumbers[position]:SetText(number)
    self.runesNumbers[position]:Show()

    if self.db.EnableSounds and self.Sounds and self.Sounds.PlayCount and not self.previewMode then
        self.Sounds:PlayCount(number)
    end
end

function Lura:ApplyPreviewRuneIcons()
    if not self.runesFrame then
        return
    end
    self.runesInverted = false
    self:ResetRunesDisplay()
    for i = 1, 5 do
        self.runesCompleted[i] = true
        self:DisplayRune(i, PREVIEW_ICON_IDS[i])
    end
end

function Lura:GetSequentialPosition()
    local cap = self:GetRuneDisplayCap()
    local position = 1
    if self.runesCompleted[cap] then
        return nil
    end
    for i = 2, 5 do
        if self.runesCompleted[i - 1] then
            position = i
        else
            break
        end
    end
    if position > cap then
        return nil
    end
    return position
end

function Lura:StartRuneHideTimer()
    if self.hideTimer and self.hideTimer.Cancel then
        self.hideTimer:Cancel()
    end
    self.hideTimer = C_Timer.NewTimer(15, function()
        self:ResetRunesDisplay()
        self.runesFrame:Hide()
    end)
end

function Lura:OnRuneChatEvent(eventName, msg)
    if not self.state.inEncounter and not self.previewMode then
        return
    end

    if type(msg) ~= "string" or msg == "" then
        return
    end

    self.runesFrame:Show()
    self:StartRuneHideTimer()

    -- Match NSRT: mythic slot mapping only outside phase 4; P4 and non-mythic use sequential fill.
    local position
    local useMythicSlots = (self.state.difficultyID == 16) and (self.state.phase ~= 4)
    if useMythicSlots then
        position = self:GetMythicPosition(eventName)
        if not position then
            return
        end
        if self.runesInverted then
            position = 6 - position
        end
    else
        position = self:GetSequentialPosition()
    end

    if not position then
        return
    end
    if position > self:GetRuneDisplayCap() then
        return
    end

    self.runesCompleted[position] = true
    self:DisplayRune(position, msg)
end

function Lura:RegisterRuneChatEvents()
    if not self.runesFrame then
        return
    end
    self.runesFrame:RegisterEvent("CHAT_MSG_RAID")
    self.runesFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
    self.runesFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
    self.runesFrame:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
end

function Lura:SetupRunesDisplay(preview)
    self.previewMode = preview and true or false
    if not preview and not self.db.RunesDisplay then
        self:TeardownRunesDisplay()
        return
    end

    self:PositionRunesDisplay(false)
    self:ResetRunesDisplay()
    self:RegisterRuneChatEvents()
    if preview then
        self.runesFrame:Show()
        self:ApplyPreviewRuneIcons()
    else
        self.runesFrame:Hide()
    end

    if self.alertTimers then
        for _, timer in pairs(self.alertTimers) do
            if timer and timer.Cancel then
                timer:Cancel()
            end
        end
    end
    self.alertTimers = {}

    if not preview then
        self.alertTimers[1] = C_Timer.NewTimer(60, function()
            self.runesInverted = (self.state.difficultyID == 16)
            self.runesCompleted = {}
        end)
        self.alertTimers[2] = C_Timer.NewTimer(120, function()
            self.runesInverted = false
            self.runesCompleted = {}
        end)
    end
end

function Lura:EnableMythicP4RunesDisplay()
    if not self.runesFrame then
        return
    end
    self:PositionRunesDisplay(true)
    self:RegisterRuneChatEvents()
    self.runesFrame:Show()
end

function Lura:TeardownRunesDisplay()
    if not self.runesFrame then
        return
    end
    self.previewMode = false
    self.runesFrame:UnregisterAllEvents()
    self.runesFrame:Hide()
    self:ResetRunesDisplay()

    if self.hideTimer and self.hideTimer.Cancel then
        self.hideTimer:Cancel()
    end
    self.hideTimer = nil

    if self.alertTimers then
        for _, timer in pairs(self.alertTimers) do
            if timer and timer.Cancel then
                timer:Cancel()
            end
        end
    end
    self.alertTimers = nil
end

function Lura:ApplyLockedState()
    local unlocked = not self.db.locked
    self:ApplyRunesDragState(unlocked)

    if unlocked then
        if not self.previewMode then
            self.previewModeFromUnlock = true
            self:Preview(true)
        end
    elseif self.previewModeFromUnlock then
        self.previewModeFromUnlock = false
        self:Preview(false)
    end
end
