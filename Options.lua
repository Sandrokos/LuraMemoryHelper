local _, Lura = ...
local ICON_PACK_URL = "https://github.com/Reloe/LuraMemoryFiles"

StaticPopupDialogs["LURA_MEMORY_COPY_ICON_PACK_LINK"] = {
    text = "Copy this link, then replace files in \\World of Warcraft_retail_\\Interface\\ICONS:",
    button1 = "Close",
    hasEditBox = true,
    editBoxWidth = 320,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
    OnShow = function(self, data)
        local editBox = self.editBox or _G[self:GetName() .. "EditBox"]
        if not editBox then
            return
        end
        editBox:SetText(data or ICON_PACK_URL)
        editBox:HighlightText()
        editBox:SetFocus()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
}

local function CreateCheckbox(parent, text, x, y, getter, setter)
    local check = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    check:SetPoint("TOPLEFT", x, y)
    check.Text:SetText(text)
    check:SetScript("OnClick", function(self)
        setter(self:GetChecked())
    end)
    check.Refresh = function()
        check:SetChecked(getter())
    end
    return check
end

function Lura:CreateOptionsPanel()
    if self.optionsPanel then
        return
    end

    local panel = CreateFrame("Frame", "LuraMemoryHelperOptionsFrame", UIParent, "BackdropTemplate")
    panel:SetSize(720, 400)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    panel:SetBackdropColor(0, 0, 0, 1)
    panel:Hide()
    self.optionsPanel = panel
    table.insert(UISpecialFrames, panel:GetName())

    local closeButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -6, -6)

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Lura Memory Helper Settings")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", 16, -42)
    subtitle:SetWidth(640)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText(
        "Lightweight standalone version of the L'ura memory helper from Northern Sky Raid Tools (NSRT). " ..
        "Full addon: https://github.com/Reloe/NorthernSkyRaidTools"
    )

    local warningTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    warningTitle:SetPoint("TOPLEFT", 16, -86)
    
    warningTitle:SetText("|cffff4040Important setup required!|r")

    local warningText = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    warningText:SetPoint("TOPLEFT", 16, -104)
    warningText:SetWidth(640)
    warningText:SetJustifyH("LEFT")
    warningText:SetText(
        "To make memory runes display, replace files in \\World of Warcraft\\_retail_\\Interface\\ICONS " ..
        "with the icon pack from " .. ICON_PACK_URL .. ". " ..
        "Restart WoW after replacing files."
    )

    local warningLinkButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    warningLinkButton:SetPoint("TOPLEFT", 16, -140)
    warningLinkButton:SetSize(190, 22)
    warningLinkButton:SetText("Copy Icon Pack Link")
    warningLinkButton:SetScript("OnClick", function()
        StaticPopup_Show("LURA_MEMORY_COPY_ICON_PACK_LINK", nil, nil, ICON_PACK_URL)
    end)

    local createMacrosButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    createMacrosButton:SetPoint("TOPLEFT", 16, -178)
    createMacrosButton:SetSize(220, 26)
    createMacrosButton:SetText("Create Rune Macros")
    createMacrosButton:SetScript("OnClick", function()
        Lura:CreateRuneMacros()
    end)

    local macroHint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    macroHint:SetPoint("TOPLEFT", 244, -175)
    macroHint:SetWidth(460)
    macroHint:SetJustifyH("LEFT")
    macroHint:SetText(
        "Creates general macros LMH_LURA_RUNE_1–5 (/raid + code). Same behavior as NSRT after clickable buttons were removed. Use out of combat."
    )

    local mythicHint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    mythicHint:SetPoint("TOPLEFT", 16, -208)
    mythicHint:SetWidth(640)
    mythicHint:SetJustifyH("LEFT")
    mythicHint:SetSpacing(3)
    mythicHint:SetText(
        "Mythic: tank as raid leader uses macros for runes 1 and 4; healers assign who clicks for runes 2, 3, and 5 (NSRT note)."
    )

    local controls = {}
    local top = -248

    controls[#controls + 1] = CreateCheckbox(panel, "RunesDisplay", 16, top, function()
        return self.db.RunesDisplay
    end, function(value)
        self.db.RunesDisplay = value
        self:SetupRunesDisplay(true)
    end)
    top = top - 30

    controls[#controls + 1] = CreateCheckbox(panel, "Enable sounds", 16, top, function()
        return self.db.EnableSounds
    end, function(value)
        self.db.EnableSounds = value
    end)
    top = top - 40

    local previewButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    previewButton:SetPoint("RIGHT", closeButton, "LEFT", -6, 0)
    previewButton:SetSize(160, 24)
    previewButton:SetScript("OnClick", function()
        local showPreview = not self.previewMode
        self:Preview(showPreview)
        if self.refreshOptionsButtons then
            self:refreshOptionsButtons()
        end
    end)

    local unlockButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    unlockButton:SetPoint("RIGHT", previewButton, "LEFT", -6, 0)
    unlockButton:SetSize(220, 24)
    unlockButton:SetScript("OnClick", function()
        self:EnsureFramesLoaded()
        self.db.locked = not self.db.locked
        self:ApplyLockedState()
        if self.refreshOptionsButtons then
            self:refreshOptionsButtons()
        end
    end)

    self.refreshOptionsButtons = function()
        if self.db.locked then
            unlockButton:SetText("Unlock and Move Frames")
        else
            unlockButton:SetText("Lock Frames")
        end
        if self.previewMode then
            previewButton:SetText("Hide Preview")
        else
            previewButton:SetText("Show Preview")
        end
    end

    panel:SetScript("OnShow", function()
        for _, control in ipairs(controls) do
            if control.Refresh then
                control:Refresh()
            end
        end
        self:refreshOptionsButtons()
    end)
    panel:SetScript("OnHide", function()
        self.previewModeFromUnlock = false
        self:Preview(false)
        self.db.locked = true
        self:ApplyLockedState()
        if self.refreshOptionsButtons then
            self:refreshOptionsButtons()
        end
    end)

end

function Lura:ToggleOptionsPanel()
    if not self.optionsPanel then
        self:CreateOptionsPanel()
    end
    if self.optionsPanel:IsShown() then
        self.optionsPanel:Hide()
    else
        self.optionsPanel:Show()
    end
end
