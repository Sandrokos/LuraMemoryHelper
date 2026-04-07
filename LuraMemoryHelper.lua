local _, Lura = ...

-- =========================
-- CONFIG
-- =========================
Lura.MAX_SYMBOLS = 5
Lura.icons = {
    "Interface\\AddOns\\LuraMemoryHelper\\Media\\circle.blp",
    "Interface\\AddOns\\LuraMemoryHelper\\Media\\triangle.blp",
    "Interface\\AddOns\\LuraMemoryHelper\\Media\\diamond.blp",
    "Interface\\AddOns\\LuraMemoryHelper\\Media\\cross.blp",
    "Interface\\AddOns\\LuraMemoryHelper\\Media\\t.blp",
}

Lura.macroNames = {
    "LMH:Circle",
    "LMH:Triangle",
    "LMH:Diamond",
    "LMH:Cross",
    "LMH:T"
}

Lura.macroMsg = {
    "{circle}",
    "{triangle}",
    "{diamond}",
    "{cross}",
    "T"
}

Lura.symbolMap = {
    ["Circle"] = 1,
    ["Triangle"] = 2,
    ["Diamond"] = 3,
    ["Cross"] = 4,
    ["T"] = 5
}

Lura.channels = {
    ["Raid"] = "/raid",
    ["Raid Warning"] = "/rw",
    ["Yell"] = "/y",
    ["Instance"] = "/i"
}

-- =========================
-- STATE
-- =========================
Lura.inEncounter = false
Lura.locked = false
Lura.testMode = false
Lura.selectedChannel = "Instance"
Lura.currentIndex = 1

-- =========================
-- Options
-- =========================
Lura.macroIds = {}

-- =========================
-- RAID LEADER SESSION
-- =========================
function Lura:GetRaidLeaderGUID()
    if IsInRaid() then
        for i = 1, 40 do
            local unit = "raid" .. i
            if UnitExists(unit) and UnitIsGroupLeader(unit) then
                return UnitGUID(unit)
            end
        end
    end

    if UnitExists("party1") and UnitIsGroupLeader("party1") then
        return UnitGUID("party1")
    end

    return UnitGUID("player")
end

-- =========================
-- Create Macro
-- =========================
function Lura:CreateMacros()
    for i = 1, 5 do
        local name = Lura.macroNames[i]
        local exists = GetMacroIndexByName(name)
        local channel = Lura.channels[Lura.selectedChannel]
        local msg = channel.." "..Lura.macroMsg[i]

        if exists == 0 then
            local macroId = CreateMacro(name, 134400, msg)
            table.insert(self.macroIds, macroId);
        else
            local macroId = EditMacro(GetMacroInfo(name), name, 134400, msg)
            table.insert(self.macroIds, macroId);
        end
    end
end

-- =========================
-- EVENTS
-- =========================
function Lura:OnInitialize()
    Lura:CreateMacros()
    Lura:CreateUI()
    Lura:BuildButtons()
    Lura:CreateRadar()

    print("|cff00ff00[Lura]|r Initialized DB")
end

function Lura:TestIcons()
    for i = 1, 5 do
        local icon = self.icons[i]
        local symbol = self.radar.symbols[i]
        local label = self.radar.labels[i]

        C_Timer.After(1+i, function()
            symbol:SetTexture(icon)
            symbol:Show()
            label:Show()
        end)
    end
end

function Lura:ProcessMessage(msg)
    local symbol = self.radar.symbols[self.currentIndex]
    local label = self.radar.labels[self.currentIndex]
    label:SetAttribute("Text", msg)
    label:Show()

    self.currentIndex = self.currentIndex + 1
end

-- =========================
-- EVENTS
-- =========================
local loader = CreateFrame("Frame")
loader:RegisterEvent("GROUP_ROSTER_UPDATE")
loader:RegisterEvent("ENCOUNTER_START")
loader:RegisterEvent("ENCOUNTER_END")
loader:RegisterEvent("PLAYER_LOGIN")

loader:RegisterEvent("CHAT_MSG_RAID_WARNING")
loader:RegisterEvent("CHAT_MSG_RAID")
loader:RegisterEvent("CHAT_MSG_RAID_LEADER")
loader:RegisterEvent("CHAT_MSG_INSTANCE_CHAT")
loader:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER")
loader:RegisterEvent("CHAT_MSG_SAY")
loader:RegisterEvent("CHAT_MSG_YELL")
loader:RegisterEvent("CHAT_MSG_CHANNEL")
loader:RegisterEvent("CHAT_MSG_COMMUNITIES_CHANNEL")

-- Chat events that carry "L'Ura Order:" messages
local CHAT_EVENTS = {
    CHAT_MSG_RAID_WARNING = true,
    CHAT_MSG_RAID = true,
    CHAT_MSG_RAID_LEADER = true,
    CHAT_MSG_INSTANCE_CHAT = true,
    CHAT_MSG_INSTANCE_CHAT_LEADER = true,
    CHAT_MSG_SAY = true,
    CHAT_MSG_YELL = true,
    CHAT_MSG_CHANNEL = true,
    CHAT_MSG_COMMUNITIES_CHANNEL = true,
}

loader:SetScript("OnEvent", function(_, event, arg1)

    if event == "ENCOUNTER_START" then
        local encounterID = arg1
        if encounterID == 214650 then
            Lura:StartEncounter()
        end

    elseif event == "PLAYER_LOGIN" then
        Lura:OnInitialize()

    elseif CHAT_EVENTS[event] then
        Lura:ProcessMessage(arg1)
    end

end)

SLASH_LURA1 = "/lura"

SlashCmdList["LURA"] = function(msg)

    msg = string.lower(msg or "")

    if msg == "test" then
        Lura:TestIcons()
    elseif msg == "cache" then
        Lura:CacheChannels()

    elseif msg == "test off" then
        Lura:DisableTestMode()

    elseif msg == "lock" or msg == "unlock" then
        Lura:SetDragLock(not Lura.locked)

    else
        print("|cff00ff00[Lura]|r Commands:")
        print(" /lura test on")
        print(" /lura test off")
        print(" /lura lock")
        print(" /lura unlock")
    end
end