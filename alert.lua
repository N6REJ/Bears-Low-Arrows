local addonName, addon = ...

local alert = CreateFrame("Frame", "BearsLowArrowsAlert", UIParent)
alert:SetSize(1400, 220)
alert:SetFrameStrata("FULLSCREEN_DIALOG")
alert:SetMovable(true)
alert:SetClampedToScreen(true)
alert:RegisterForDrag("LeftButton")
alert:EnableMouse(false)
alert:Hide()

local text = alert:CreateFontString(nil, "OVERLAY")
text:SetPoint("CENTER")
text:SetTextColor(1, 0.1, 0.1)

alert:SetScript("OnDragStart", function(self)
    if addon.unlocked then
        self:StartMoving()
    end
end)

alert:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    addon:SaveAlertPosition()
end)

function addon:ApplyAlertPosition()
    alert:ClearAllPoints()
    alert:SetPoint("CENTER", UIParent, "CENTER", self.db.alertX, self.db.alertY)
end

function addon:SaveAlertPosition()
    local cx, cy = alert:GetCenter()
    local ux, uy = UIParent:GetCenter()
    self.db.alertX = math.floor(cx - ux + 0.5)
    self.db.alertY = math.floor(cy - uy + 0.5)
    self:ApplyAlertPosition()
end

function addon:SetAlertUnlocked(flag)
    self.unlocked = flag
    alert:EnableMouse(flag)
    if flag then
        self:ShowAlert()
    else
        self:StopReminders()
        self:Check()
    end
end

function addon:ResetAlertPosition()
    self.db.alertX = self.defaults.alertX
    self.db.alertY = self.defaults.alertY
    self:ApplyAlertPosition()
end

function addon:ShowAlert()
    if not text:SetFont(self:GetFontPath(self.db.font), self.db.fontSize, "THICKOUTLINE") then
        text:SetFont(STANDARD_TEXT_FONT, self.db.fontSize, "THICKOUTLINE")
    end
    local count, quivers = self:ScanQuivers()
    if quivers > 0 and count == 0 then
        text:SetText("RELOAD YOUR QUIVER")
        text:SetTextColor(unpack(self.db.reloadColor))
    else
        text:SetText("LOW AMMO: " .. count)
        text:SetTextColor(unpack(self.db.lowColor))
    end
    alert:Show()
end

function addon:HideAlert()
    if self.unlocked then
        return
    end
    alert:Hide()
end

function addon:ShowAlertFor(seconds)
    self:ShowAlert()
    if self.hideTimer then
        self.hideTimer:Cancel()
    end
    self.hideTimer = C_Timer.NewTimer(seconds, function()
        addon.hideTimer = nil
        addon:HideAlert()
    end)
end

function addon:TestSound()
    local path = self:GetSoundPath(self.db.soundName)
    if path and path ~= "" and PlaySoundFile(path, "Master") then
        return
    end
    if SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
        return
    end
    print("|cffff5555Bears Low Arrows|r: could not play sound '" .. tostring(self.db.soundName) .. "' (" .. tostring(path) .. ")")
end

function addon:PlayAlertSound()
    if self.db.sound then
        self:TestSound()
    end
end

function addon:FlashAlert()
    local startTime = GetTime()
    local duration = self.db.duration
    self:ShowAlertFor(duration)
    alert:SetScript("OnUpdate", function(frame)
        local elapsed = GetTime() - startTime
        if elapsed >= duration then
            frame:SetScript("OnUpdate", nil)
            frame:SetAlpha(1)
            return
        end
        frame:SetAlpha(0.3 + 0.7 * math.abs(math.sin(elapsed * 4)))
    end)
end
