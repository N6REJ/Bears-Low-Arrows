local addonName, addon = ...

addon.defaults = {
    enabled = true,
    threshold = 400,
    duration = 5,
    delay = 30,
    font = "Friz Quadrata TT",
    fontSize = 96,
    alertX = 0,
    alertY = 150,
    minimapAngle = 90,
    sound = true,
    soundName = "Raid Warning",
    lowColor = { 1, 0.1, 0.1 },
    reloadColor = { 1, 0.82, 0 },
}

addon.builtinSounds = {
    ["Raid Warning"] = "Sound\\Interface\\RaidWarning.ogg",
    ["Level Up"] = "Sound\\Interface\\iLevelUp.ogg",
    ["Ready Check"] = "Sound\\Interface\\ReadyCheck.ogg",
    ["Map Ping"] = "Sound\\Interface\\MapPing.ogg",
    ["Alarm Clock"] = "Sound\\Interface\\AlarmClockWarning3.ogg",
}

local frame = CreateFrame("Frame")

function addon:InitDB()
    BearsLowArrowsDB = BearsLowArrowsDB or {}
    for key, value in pairs(self.defaults) do
        if BearsLowArrowsDB[key] == nil then
            BearsLowArrowsDB[key] = value
        end
    end
    if BearsLowArrowsDB.font:find("\\") then
        BearsLowArrowsDB.font = self.defaults.font
    end
    self.db = BearsLowArrowsDB
    self:ApplyAlertPosition()
end

function addon:GetLSM()
    return LibStub("LibSharedMedia-3.0", true)
end

function addon:GetFontList()
    local LSM = self:GetLSM()
    if LSM then
        return LSM:List("font")
    end
    return { self.defaults.font }
end

function addon:GetFontPath(name)
    local LSM = self:GetLSM()
    return LSM and LSM:Fetch("font", name, true) or STANDARD_TEXT_FONT
end

function addon:GetSoundList()
    local names, seen = {}, {}
    for name in pairs(self.builtinSounds) do
        seen[name] = true
        table.insert(names, name)
    end
    local LSM = self:GetLSM()
    if LSM then
        for _, name in ipairs(LSM:List("sound")) do
            if not seen[name] then
                seen[name] = true
                table.insert(names, name)
            end
        end
    end
    table.sort(names)
    return names
end

function addon:GetSoundPath(name)
    if self.builtinSounds[name] then
        return self.builtinSounds[name]
    end
    local LSM = self:GetLSM()
    return LSM and LSM:Fetch("sound", name, true) or nil
end

function addon:IsHunter()
    local _, class = UnitClass("player")
    return class == "HUNTER"
end

local AMMO_CLASS = 6
local AMMO_SUBCLASSES = { [1] = true, [2] = true, [3] = true }
local QUIVER_CLASS = 11

local function GetItemClass(itemID)
    local getInstant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    local _, _, _, _, _, classID, subclassID = getInstant(itemID)
    return classID, subclassID
end

local function IsAmmo(itemID)
    local classID, subclassID = GetItemClass(itemID)
    return classID == AMMO_CLASS and AMMO_SUBCLASSES[subclassID] or false
end

local function IsQuiverBag(bag)
    local toInventoryID = (C_Container and C_Container.ContainerIDToInventoryID) or ContainerIDToInventoryID
    local itemID = GetInventoryItemID("player", toInventoryID(bag))
    if not itemID then
        return false
    end
    return (GetItemClass(itemID)) == QUIVER_CLASS
end

function addon:ScanQuivers()
    local total, quivers = 0, 0
    for bag = 1, (NUM_BAG_SLOTS or 4) do
        if IsQuiverBag(bag) then
            quivers = quivers + 1
            for slot = 1, C_Container.GetContainerNumSlots(bag) or 0 do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.itemID and IsAmmo(info.itemID) then
                    total = total + (info.stackCount or 0)
                end
            end
        end
    end
    return total, quivers
end

function addon:GetAmmoCount()
    return (self:ScanQuivers())
end

function addon:IsLow()
    return self.db.enabled and self:IsHunter() and self:GetAmmoCount() < self.db.threshold
end

function addon:Check()
    if not self.db then
        return
    end
    if self:IsLow() then
        if not self.cycleTimer then
            self:Remind()
        end
    else
        self:StopReminders()
    end
end

function addon:Remind()
    if self.cycleTimer then
        self.cycleTimer:Cancel()
    end
    if self.hideTimer then
        self.hideTimer:Cancel()
    end
    if not self:IsLow() then
        self:StopReminders()
        return
    end
    self:ShowAlert()
    self:PlayAlertSound()
    local db = self.db
    self.hideTimer = C_Timer.NewTimer(db.duration, function()
        self:HideAlert()
    end)
    self.cycleTimer = C_Timer.NewTimer(db.duration + db.delay, function()
        self:Remind()
    end)
end

function addon:StopReminders()
    if self.cycleTimer then
        self.cycleTimer:Cancel()
        self.cycleTimer = nil
    end
    if self.hideTimer then
        self.hideTimer:Cancel()
        self.hideTimer = nil
    end
    self:HideAlert()
end

function addon:Test()
    self:ShowAlert()
    self:PlayAlertSound()
    C_Timer.After(self.db.duration, function()
        self:HideAlert()
    end)
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("BAG_UPDATE_DELAYED")
frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == addonName then
            addon:InitDB()
        end
    elseif event == "PLAYER_LOGIN" then
        addon:InitOptions()
        addon:InitMinimap()
        C_Timer.NewTicker(2, function()
            addon:Check()
        end)
        addon:Check()
    elseif event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player" then
        return
    else
        addon:Check()
    end
end)
