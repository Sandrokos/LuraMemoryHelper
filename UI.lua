local _, Lura = ...

Lura.frame = CreateFrame("Frame", "LuraMainFrame", UIParent, "BackdropTemplate")

-- =========================
-- MAIN FRAME
-- =========================
function Lura:CreateUI()

    local f = self.frame
    f:SetSize(240, 120)
    f:SetPoint("CENTER")

    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")

    f:SetScript("OnDragStart", function(self)
        if self.locked then return end
        self:StartMoving()
    end)

    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
    end)
end

function Lura:ShowUI()
    self.frame:Show()
end

function Lura:HideUI()
    self.frame:Hide()
end

-- =========================
-- RADAR
-- =========================
function Lura:CreateRadar()

    local r = CreateFrame("Frame", "LuraRadar", UIParent, "BackdropTemplate")
    r:SetMovable(true)
    r:EnableMouse(true)
    r:RegisterForDrag("LeftButton")
    r:SetSize(240, 240)
    r:SetPoint("CENTER", 200, 0)
    r:SetScript("OnDragStart", function(self)
        if Lura.locked then return end
        self:StartMoving()
    end)

    r:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Lura:SaveFramePosition(self, "radar")
    end)

    r.symbols = {}
    r.labels = {}

    local radius = 80
    local angleStep = (2 * math.pi) / 6

    local bg = r:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(100, 100)
    bg:SetAllPoints()
    
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.15, 0.15, 0.15, 1) -- grey
    r.bg = bg


    local mask = r:CreateMaskTexture()
    mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(bg)
    bg:AddMaskTexture(mask)

    local center = r:CreateTexture(nil, "ARTWORK")
    center:SetSize(40, 40)
    center:SetPoint("CENTER")
    center:SetTexture("Interface\\Buttons\\WHITE8x8")
    center:SetVertexColor(1, 0, 0, 1)

    local centerMask = r:CreateMaskTexture()
    centerMask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    centerMask:SetAllPoints(center)
    center:AddMaskTexture(centerMask)

    r.center = center

    -- TANK ICON (top)
    local tank = r:CreateTexture(nil, "ARTWORK")
    tank:SetSize(32, 32)
    tank:SetPoint("CENTER", 0, radius)
    tank:SetTexture("Interface\\Icons\\Ability_Warrior_DefensiveStance")
    r.tank = tank

    -- 5 SYMBOL SLOTS clockwise
    for i = 1, 5 do

        local angle = (math.pi / 2) - (i * angleStep)
        local tex = r:CreateTexture(nil, "ARTWORK")
        tex:SetSize(60, 60)
        tex:SetPoint("CENTER", math.cos(angle) * radius, (math.sin(angle) * radius) + 10)
        --tex:Hide()
        
        -- number label
        local label = r:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER", tex, "BOTTOM", 0,-4)
        label:SetText("{circle}")
        local path, size, flags = label:GetFont()
        label:SetFont(path, 20, flags)
        label:Hide()

        r.symbols[i] = tex
        r.labels[i] = label
    end

    self.radar = r
end

function Lura:ShowRadar()
    self.radar:Show()
end

function Lura:HideRadar()
    self.radar:Hide()
end

-- =========================
-- BUTTONS
-- =========================
function Lura:BuildButtons()

    self.buttons = {}
    self.buttonHolder = {}

    local visible = true
    local h = CreateFrame("Frame", "LuraButtonFrame", UIParent, "BackdropTemplate")
    h:SetSize(400, 300)
    h:SetPoint("CENTER")
    h:SetMovable(true)
    h:EnableMouse(true)
    h:RegisterForDrag("LeftButton")

    h:SetScript("OnDragStart", function(self)
        if Lura.locked then return end
        self:StartMoving()
    end)

    h:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        Lura:SaveFramePosition(self, "radar")
    end)
    self.buttonHolder = h

    for i = 1, self.MAX_SYMBOLS do

        local b = CreateFrame("Button", nil, self.buttonHolder, "SecureActionButtonTemplate, UIPanelButtonTemplate")
        b:SetSize(50, 50)
        b:SetPoint("LEFT", (i - 1) * 50, 0)

        if not visible then
            b:Hide()
        end

        b:RegisterForClicks("LeftButtonUp")
        b:SetAttribute("type","macro")
        b:SetAttribute("macro", self.macroNames[i])
        local texture = b:CreateTexture("buttonTexture", "ARTWORK")
        texture:SetTexture(self.icons[i])
        texture:SetAllPoints(b)
        b.texture = texture
        self.buttons[i] = b
    end
end

function Lura:GetCurrentIndex()
    return self.currentIndex
end

function Lura:SaveFramePosition(frame, key)

    if not self.db then
        self.db = { positions = {} }
    end

    local point, _, _, x, y = frame:GetPoint()

    self.db.positions[key] = {
        point = point,
        x = x,
        y = y
    }
end

function Lura:RestorePositions()

    if not self.db or not self.db.positions then return end

    local radarPos = self.db.positions["radar"]
    if radarPos and self.RadarFrame then
        self.RadarFrame:ClearAllPoints()
        self.RadarFrame:SetPoint(radarPos.point, UIParent, radarPos.x, radarPos.y)
    end

    local inputPos = self.db.positions["input"]
    if inputPos and self.InputFrame then
        self.InputFrame:ClearAllPoints()
        self.InputFrame:SetPoint(inputPos.point, UIParent, inputPos.x, inputPos.y)
    end
end

function Lura:SetDragLock(state)

    self.locked = state

    -- INPUT FRAME
    if self.InputFrame then
        self.InputFrame:EnableMouse(not state)
        self.InputFrame:SetMovable(not state)
        self.InputFrame:RegisterForDrag("LeftButton")

        if not state then
            self.InputFrame:SetScript("OnDragStart", self.InputFrame.StartMoving)

            self.InputFrame:SetScript("OnDragStop", function(frame)
                frame:StopMovingOrSizing()
                self:SaveFramePosition(frame, "input")
            end)
        else
            self.InputFrame:SetScript("OnDragStart", nil)
            self.InputFrame:SetScript("OnDragStop", nil)
        end
    end

    -- RADAR FRAME
    if self.RadarFrame then
        self.RadarFrame:EnableMouse(not state)
        self.RadarFrame:SetMovable(not state)
        self.RadarFrame:RegisterForDrag("LeftButton")

        if not state then
            self.RadarFrame:SetScript("OnDragStart", self.RadarFrame.StartMoving)

            self.RadarFrame:SetScript("OnDragStop", function(frame)
                frame:StopMovingOrSizing()
                self:SaveFramePosition(frame, "radar")
            end)
        else
            self.RadarFrame:SetScript("OnDragStart", nil)
            self.RadarFrame:SetScript("OnDragStop", nil)
        end
    end

    print("|cff00ff00[Lura]|r UI Lock: " .. (state and "LOCKED" or "UNLOCKED"))
end
