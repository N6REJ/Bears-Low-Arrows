local addonName, addon = ...

local BACKDROP = BackdropTemplateMixin and "BackdropTemplate" or nil
local WHITE = "Interface\\Buttons\\WHITE8X8"
local FONT_FILE = "Fonts\\FRIZQT__.TTF"
local PALETTE = {
    bg = { 0.07, 0.07, 0.09, 0.96 },
    panel = { 0.12, 0.12, 0.15, 1 },
    button = { 0.16, 0.16, 0.2, 1 },
    border = { 0.3, 0.3, 0.35, 1 },
    gold = { 1, 0.82, 0, 1 },
    text = { 1, 1, 1, 1 },
}
local SOUND_ROW_HEIGHT = 18
local SOUND_VISIBLE_ROWS = 8

local panel
local fontLabel
local unlockCheck
local soundCheck
local soundButton
local soundList
local sliders = {}
local refreshing = false

local function Box(f, bg, border)
    f:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    f:SetBackdropColor(unpack(bg))
    f:SetBackdropBorderColor(unpack(border))
end

local function Text(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT_FILE, size, "")
    fs:SetTextColor(unpack(color or PALETTE.text))
    fs:SetJustifyH(justify or "LEFT")
    return fs
end

local function NewButton(parent, label, w, h)
    local b = CreateFrame("Button", nil, parent, BACKDROP)
    b:SetSize(w, h)
    Box(b, PALETTE.button, PALETTE.border)
    b.label = Text(b, 13, PALETTE.text, "CENTER")
    b.label:SetPoint("CENTER")
    b.label:SetText(label)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(PALETTE.gold))
    end)
    b:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(PALETTE.border))
    end)
    return b
end

local function NewCheck(parent, label, w)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(w, 20)
    b.box = CreateFrame("Frame", nil, b, BACKDROP)
    b.box:SetSize(16, 16)
    b.box:SetPoint("LEFT", b, "LEFT", 0, 0)
    Box(b.box, PALETTE.panel, PALETTE.border)
    b.label = Text(b, 13)
    b.label:SetPoint("LEFT", b.box, "RIGHT", 6, 0)
    b.label:SetText(label)
    b.checked = false
    function b:SetChecked(value)
        self.checked = value and true or false
        self.box:SetBackdropColor(unpack(self.checked and PALETTE.gold or PALETTE.panel))
    end
    function b:GetChecked()
        return self.checked
    end
    b:SetScript("OnClick", function(self)
        self:SetChecked(not self.checked)
        if self.onChange then
            self.onChange(self.checked)
        end
    end)
    return b
end

local colorRows = {}

local function ApplyColor(row, r, g, b)
    addon.db[row.key] = { r, g, b }
    row.swatch:SetBackdropColor(r, g, b, 1)
end

local function OpenColorPicker(row)
    local r0, g0, b0 = unpack(addon.db[row.key])
    ColorPickerFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    ColorPickerFrame:SetClampedToScreen(true)
    if ColorPickerFrame.SetupColorPickerAndShow then
        ColorPickerFrame:SetupColorPickerAndShow({
            r = r0,
            g = g0,
            b = b0,
            hasOpacity = false,
            swatchFunc = function()
                ApplyColor(row, ColorPickerFrame:GetColorRGB())
            end,
            cancelFunc = function()
                ApplyColor(row, r0, g0, b0)
            end,
        })
    else
        ColorPickerFrame.func = function()
            ApplyColor(row, ColorPickerFrame:GetColorRGB())
        end
        ColorPickerFrame.hasOpacity = false
        ColorPickerFrame.cancelFunc = function()
            ApplyColor(row, r0, g0, b0)
        end
        ColorPickerFrame:SetColorRGB(r0, g0, b0)
        ColorPickerFrame:Show()
    end
end

local function UpdateColorRows()
    for _, row in ipairs(colorRows) do
        local color = addon.db[row.key]
        row.swatch:SetBackdropColor(color[1], color[2], color[3], 1)
    end
end

local function NewColorRow(labelText, key, y)
    local row = { key = key }
    row.label = Text(panel, 13)
    row.label:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, y - 6)
    row.label:SetText(labelText)
    row.swatch = CreateFrame("Button", nil, panel, BACKDROP)
    row.swatch:SetSize(60, 22)
    row.swatch:SetPoint("TOPLEFT", panel, "TOPLEFT", 170, y)
    Box(row.swatch, { 1, 1, 1, 1 }, PALETTE.border)
    row.swatch:SetScript("OnClick", function()
        OpenColorPicker(row)
    end)
    row.swatch:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(PALETTE.gold))
    end)
    row.swatch:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(PALETTE.border))
    end)
    table.insert(colorRows, row)
    return row
end

local function NewSlider(labelText, minValue, maxValue, step, y, key, suffix)
    local slider = CreateFrame("Slider", nil, panel, BACKDROP)
    slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 40, y)
    slider:SetSize(360, 12)
    slider:SetOrientation("HORIZONTAL")
    Box(slider, { 0, 0, 0, 0.6 }, PALETTE.border)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(unpack(PALETTE.gold))
    thumb:SetSize(10, 18)
    slider:SetThumbTexture(thumb)

    slider.label = Text(panel, 13)
    slider.label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)

    slider.key = key
    slider.labelText = labelText
    slider.suffix = suffix
    slider.step = step
    slider.SetLabel = function(self, value)
        self.label:SetText(labelText .. ": " .. value .. suffix)
    end
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        self:SetLabel(value)
        if not refreshing then
            addon.db[key] = value
            addon:Check()
        end
    end)
    return slider
end

local function UpdateFontLabel()
    fontLabel:SetText(addon.db.font)
    fontLabel:SetFont(addon:GetFontPath(addon.db.font), 14, "")
end

local function CycleFont(delta)
    local list = addon:GetFontList()
    local index = 1
    for i, name in ipairs(list) do
        if name == addon.db.font then
            index = i
        end
    end
    addon.db.font = list[(index - 1 + delta) % #list + 1]
    UpdateFontLabel()
end

local function Refresh()
    refreshing = true
    for _, slider in ipairs(sliders) do
        local value = addon.db[slider.key]
        slider:SetValue(value)
        slider:SetLabel(value)
    end
    panel.enabled:SetChecked(addon.db.enabled)
    unlockCheck:SetChecked(addon.unlocked and true or false)
    UpdateFontLabel()
    soundCheck:SetChecked(addon.db.sound)
    soundButton.label:SetText("Sound: " .. addon.db.soundName)
    UpdateColorRows()
    refreshing = false
end

function addon:ToggleOptions()
    if not panel then
        return
    end
    if panel:IsShown() then
        panel:Hide()
    else
        Refresh()
        panel:Show()
    end
end

function addon:InitOptions()
    refreshing = true
    panel = CreateFrame("Frame", "BearsLowArrowsOptions", UIParent, BACKDROP)
    panel:SetSize(440, 640)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    Box(panel, PALETTE.bg, PALETTE.border)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetScript("OnHide", function()
        if soundList then
            soundList:Hide()
        end
        if addon.unlocked then
            addon:SetAlertUnlocked(false)
        end
    end)
    panel:Hide()

    local title = Text(panel, 18, PALETTE.gold, "CENTER")
    title:SetPoint("TOP", panel, "TOP", 0, -18)
    title:SetText("Bears Low Arrows")

    local closeButton = NewButton(panel, "X", 20, 20)
    closeButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
    closeButton:SetScript("OnClick", function()
        panel:Hide()
    end)

    panel.enabled = NewCheck(panel, "Enable alerts", 170)
    panel.enabled:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -56)
    panel.enabled.onChange = function(checked)
        addon.db.enabled = checked
        addon:Check()
    end

    unlockCheck = NewCheck(panel, "Unlock alert position", 190)
    unlockCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 220, -56)
    unlockCheck.onChange = function(checked)
        addon:SetAlertUnlocked(checked)
    end

    sliders = {
        NewSlider("Alert below", 200, 2000, 200, -100, "threshold", " ammo"),
        NewSlider("Alert duration", 1, 30, 1, -150, "duration", " s"),
        NewSlider("Delay between alerts", 5, 120, 5, -200, "delay", " s"),
        NewSlider("Alert font size", 24, 128, 4, -250, "fontSize", " pt"),
    }

    local prevButton = NewButton(panel, "<", 32, 24)
    prevButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -300)
    prevButton:SetScript("OnClick", function()
        CycleFont(-1)
    end)

    local nextButton = NewButton(panel, ">", 32, 24)
    nextButton:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -24, -300)
    nextButton:SetScript("OnClick", function()
        CycleFont(1)
    end)

    fontLabel = Text(panel, 14, PALETTE.text, "CENTER")
    fontLabel:SetPoint("LEFT", prevButton, "RIGHT", 8, 0)
    fontLabel:SetPoint("RIGHT", nextButton, "LEFT", -8, 0)

    NewColorRow("Low ammo text", "lowColor", -340)
    NewColorRow("Reload quiver text", "reloadColor", -370)

    soundCheck = NewCheck(panel, "Play alert sound", 170)
    soundCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -405)
    soundCheck.onChange = function(checked)
        addon.db.sound = checked
    end

    soundList = CreateFrame("Frame", "BearsLowArrowsSoundList", panel, BACKDROP)
    soundList:SetSize(240, SOUND_VISIBLE_ROWS * SOUND_ROW_HEIGHT + 8)
    soundList:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -463)
    soundList:SetFrameStrata("DIALOG")
    soundList:SetFrameLevel(panel:GetFrameLevel() + 10)
    Box(soundList, { 0, 0, 0, 0.92 }, PALETTE.border)
    soundList:EnableMouse(true)
    soundList:Hide()

    local soundScroll = CreateFrame("ScrollFrame", nil, soundList)
    soundScroll:SetPoint("TOPLEFT", soundList, "TOPLEFT", 4, -4)
    soundScroll:SetPoint("BOTTOMRIGHT", soundList, "BOTTOMRIGHT", -14, 4)
    soundScroll:EnableMouseWheel(true)

    local soundContent = CreateFrame("Frame", nil, soundScroll)
    soundContent:SetSize(222, 1)
    soundScroll:SetScrollChild(soundContent)

    local track = soundList:CreateTexture(nil, "ARTWORK")
    track:SetColorTexture(0, 0, 0, 0.5)
    track:SetPoint("TOPRIGHT", soundList, "TOPRIGHT", -4, -4)
    track:SetPoint("BOTTOMRIGHT", soundList, "BOTTOMRIGHT", -4, 4)
    track:SetWidth(6)

    local thumb = soundList:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(unpack(PALETTE.gold))
    thumb:SetWidth(6)

    local function UpdateSoundThumb()
        local viewHeight = soundScroll:GetHeight()
        local contentHeight = soundContent:GetHeight()
        if contentHeight <= viewHeight then
            thumb:Hide()
            return
        end
        local trackHeight = track:GetHeight()
        local thumbHeight = math.max(24, trackHeight * viewHeight / contentHeight)
        local maxOffset = contentHeight - viewHeight
        local y = -(soundScroll:GetVerticalScroll() / maxOffset) * (trackHeight - thumbHeight)
        thumb:SetHeight(thumbHeight)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOP", track, "TOP", 0, y)
        thumb:Show()
    end

    soundScroll:SetScript("OnMouseWheel", function(self, delta)
        local maxScroll = math.max(0, soundContent:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.min(maxScroll, math.max(0, self:GetVerticalScroll() - delta * SOUND_ROW_HEIGHT)))
        UpdateSoundThumb()
    end)
    soundScroll:SetScript("OnVerticalScroll", UpdateSoundThumb)

    local soundRows = {}

    local function RebuildSoundRows()
        local list = addon:GetSoundList()
        soundContent:SetHeight(math.max(1, #list * SOUND_ROW_HEIGHT))
        for i, name in ipairs(list) do
            local row = soundRows[i]
            if not row then
                row = CreateFrame("Button", nil, soundContent)
                row:SetHeight(SOUND_ROW_HEIGHT)
                row:SetPoint("TOPLEFT", soundContent, "TOPLEFT", 0, -(i - 1) * SOUND_ROW_HEIGHT)
                row:SetPoint("TOPRIGHT", soundContent, "TOPRIGHT", 0, -(i - 1) * SOUND_ROW_HEIGHT)
                row.text = Text(row, 12)
                row.text:SetPoint("LEFT", row, "LEFT", 4, 0)
                row.hl = row:CreateTexture(nil, "BACKGROUND")
                row.hl:SetAllPoints()
                row.hl:SetColorTexture(1, 1, 1, 0.1)
                row.hl:Hide()
                row:SetScript("OnEnter", function(self)
                    self.hl:Show()
                end)
                row:SetScript("OnLeave", function(self)
                    self.hl:Hide()
                end)
                row:SetScript("OnClick", function(self)
                    addon.db.soundName = self.name
                    soundButton.label:SetText("Sound: " .. self.name)
                    soundList:Hide()
                end)
                soundRows[i] = row
            end
            row.name = name
            row.text:SetText(name)
            if name == addon.db.soundName then
                row.text:SetTextColor(unpack(PALETTE.gold))
            else
                row.text:SetTextColor(unpack(PALETTE.text))
            end
            row:Show()
        end
        for i = #list + 1, #soundRows do
            soundRows[i]:Hide()
        end
        UpdateSoundThumb()
    end

    soundButton = NewButton(panel, "", 240, 24)
    soundButton:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -435)
    soundButton:SetScript("OnClick", function()
        if soundList:IsShown() then
            soundList:Hide()
        else
            RebuildSoundRows()
            soundScroll:SetVerticalScroll(0)
            soundList:Show()
        end
    end)

    local soundTestButton = NewButton(panel, "Test sound", 90, 24)
    soundTestButton:SetPoint("LEFT", soundButton, "RIGHT", 8, 0)
    soundTestButton:SetScript("OnClick", function()
        addon:TestSound()
    end)

    local testButton = NewButton(panel, "Test alert", 120, 24)
    testButton:SetPoint("BOTTOM", panel, "BOTTOM", -130, 20)
    testButton:SetScript("OnClick", function()
        addon:Test()
    end)

    local flashButton = NewButton(panel, "Flash text", 120, 24)
    flashButton:SetPoint("BOTTOM", panel, "BOTTOM", 0, 20)
    flashButton:SetScript("OnClick", function()
        addon:FlashAlert()
    end)

    local resetButton = NewButton(panel, "Reset position", 120, 24)
    resetButton:SetPoint("BOTTOM", panel, "BOTTOM", 130, 20)
    resetButton:SetScript("OnClick", function()
        addon:ResetAlertPosition()
    end)

    Refresh()

    SLASH_BEARSLOWARROWS1 = "/arrows"
    SLASH_BEARSLOWARROWS2 = "/bla"
    SlashCmdList["BEARSLOWARROWS"] = function(msg)
        msg = strtrim(msg or ""):lower()
        if msg == "test" then
            addon:Test()
        elseif msg == "flash" then
            addon:FlashAlert()
        elseif msg == "sound" then
            addon:TestSound()
        else
            addon:ToggleOptions()
        end
    end
end
