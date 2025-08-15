local addonName = "GoldTracker"

-- SavedVariables in TOC:  ## SavedVariables: GoldTrackerDB
GoldTrackerDB = GoldTrackerDB or {}

-- Saved state
local isTrackerEnabled = true

-- Create main frame
local f = CreateFrame("Frame", "GoldTrackerFrame", UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
f:SetSize(200, 100) -- Initial size, will be adjusted
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    GoldTrackerDB.pos = { point, relativePoint, xOfs, yOfs }
end)

-- Apply saved position or default
local function ApplyPosition()
    f:ClearAllPoints()
    if GoldTrackerDB.pos then
        local point, relativePoint, xOfs, yOfs = unpack(GoldTrackerDB.pos)
        f:SetPoint(point, UIParent, relativePoint, xOfs, yOfs)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
end

-- Backdrop
f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
f:SetBackdropColor(0, 0, 0, 0.6)

-- Refresh button
local refreshBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
refreshBtn:SetSize(60, 20)
refreshBtn:SetText("Refresh")

-- Reset button
local resetBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
resetBtn:SetSize(60, 20)
resetBtn:SetText("Reset")

-- Close button
local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
closeBtn:SetScript("OnClick", function()
    isTrackerEnabled = false
    f:Hide()
    print(addonName .. ": Tracker disabled.")
end)

-- Variables
local startTime, startGold

-- Get player's gold
local function GetPlayerGold()
    local totalCopper = GetMoney()
    local gold = math.floor(totalCopper / 10000)
    local silver = math.floor((totalCopper % 10000) / 100)
    local copper = totalCopper % 100
    return gold, silver, copper, totalCopper
end

local function renderMoney(g, s, c, gphColor, sessionGPh, goldChangeColor, sessionGoldChange)
	return string.format(
        "|cffffff00%d|r g |cffc0c0c0%d|r s |cffb87333%d|r c\n%s%.1f G/H|r\n%s%.1f g|r",
        g, s, c,
        gphColor, sessionGPh,
        goldChangeColor, sessionGoldChange / 10000
    )
end

-- Format session time as H:MM
local function FormatSessionTime(seconds)
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
	local secs = math.floor(seconds % 60)
    return string.format("%d:%02d:%02d", hours, mins, secs)
end

local function GetColorCode(value)
    if math.abs(value) < 0.01 then
        return "|cffffffff" -- white
    elseif value < 0 then
        if value <= -1000 then
            return "|cffff0000" -- pure red
        else
            -- Scale from -1000..0 → 0..1
            local t = (value + 1000) / 1000
            local r = 255
            local g = math.floor(255 * t)
            local b = math.floor(255 * t)
            return string.format("|cff%02x%02x%02x", r, g, b)
        end
    else
        if value >= 15000 then
            return "|cff00ff00" -- pure green
        else
            -- Scale from 0..15000 → 0..1
            local t = value / 15000
            local r = math.floor(255 * (1 - t))
            local g = 255
            local b = math.floor(255 * (1 - t))
            return string.format("|cff%02x%02x%02x", r, g, b)
        end
    end
end

---- NEW UI
-- Table to hold label/value fontstrings
local infoLabels = {}
local infoValues = {}

-- Labels for the left column
local labelsLeft = { "Current Gold", "Session G/H", "Session Change", "Session Time" }

-- Create the small info lines
local function CreateInfoTexts()
    local startY = -15 -- start position below main title
    local rowHeight = 15

    -- Left column
    for i, label in ipairs(labelsLeft) do
        local yOffset = startY - (i - 1) * rowHeight

        infoLabels[label] = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        infoLabels[label]:SetPoint("TOPLEFT", f, "TOPLEFT", 10, yOffset)
        infoLabels[label]:SetText(label .. ":")

        infoValues[label] = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        infoValues[label]:SetPoint("LEFT", infoLabels[label], "RIGHT", 5, 0)
        infoValues[label]:SetText("--")
    end
end

-- Auto-resize function
local function AutoResizeFrame()
    local padding = 20 -- padding around content
    local buttonHeight = 25 -- space for buttons at bottom
    local closeButtonSpace = 20 -- space for close button at top
    local closeButtonWidth = 32 -- width needed for close button on the right
    
    local maxWidth = 0
    local totalHeight = closeButtonSpace
    
    -- Calculate required width and height based on text content
    for i, label in ipairs(labelsLeft) do
        if infoLabels[label] and infoValues[label] then
            local labelWidth = infoLabels[label]:GetStringWidth()
            local valueWidth = infoValues[label]:GetStringWidth()
            local rowWidth = labelWidth + valueWidth + 15 -- 15 for spacing between label and value
            
            if rowWidth > maxWidth then
                maxWidth = rowWidth
            end
            
            totalHeight = totalHeight + 15 -- 15 pixels per row
        end
    end
    
    -- Add padding and button space
    local frameWidth = math.max(maxWidth + padding + closeButtonWidth, 130) -- minimum width to fit buttons, plus close button space
    local frameHeight = totalHeight + buttonHeight + 10 -- extra padding
    
    -- Set the new size
    f:SetSize(frameWidth, frameHeight)
    
    -- Reposition close button to top right
    closeBtn:ClearAllPoints()
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)
    
    -- Reposition buttons at the bottom
    refreshBtn:ClearAllPoints()
    refreshBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 3, 3)
    
    resetBtn:ClearAllPoints()
    resetBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -3, 3)
end

CreateInfoTexts()

--- NEW UI

-- Update display
local function UpdateDisplay()
    if not isTrackerEnabled then return end

    local now = time()
    local g, s, c, currentCopper = GetPlayerGold()
    local sessionTime = now - startTime
    local sessionGoldChange = currentCopper - startGold
    local sessionGPh
    if sessionTime < 5 then
        sessionGPh = 0 -- Avoid nonsense values for the first 5 seconds
    else
        sessionGPh = (sessionGoldChange * 9) / (25 * sessionTime)
    end
    local gphColor = GetColorCode(sessionGPh)
    local goldChangeColor = GetColorCode(sessionGoldChange)
    
    -- Update small fields
    infoValues["Current Gold"]:SetText(string.format("|cffffffff%d|r|cffffd700g|r |cffffffff%d|r|cffc7c7cfs|r |cffffffff%d|r|cffb87333c|r", g, s, c))
    infoValues["Session G/H"]:SetText(gphColor .. string.format("%.1f", sessionGPh) .. "|r")
    
    -- Format session change with gold, silver, copper
    local changeGold = math.floor(math.abs(sessionGoldChange) / 10000)
    local changeSilver = math.floor((math.abs(sessionGoldChange) % 10000) / 100)
    local changeCopper = math.abs(sessionGoldChange) % 100
    infoValues["Session Change"]:SetText(string.format("%s%d|r|cffffd700g|r %s%d|r|cffc7c7cfs|r %s%d|r|cffb87333c|r", 
        goldChangeColor, changeGold, goldChangeColor, changeSilver, goldChangeColor, changeCopper))
    
    infoValues["Session Time"]:SetText(FormatSessionTime(sessionTime))
    
    -- Auto-resize the frame to fit content
    AutoResizeFrame()
end

-- Reset tracker
local function ResetTracker()
    local _, _, _, currentCopper = GetPlayerGold()
    startTime = time()
    startGold = currentCopper
    UpdateDisplay()
end
resetBtn:SetScript("OnClick", ResetTracker)
refreshBtn:SetScript("OnClick", UpdateDisplay)

-- Events
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_MONEY")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        ApplyPosition()
        ResetTracker()
    else 
        UpdateDisplay()
    end
end)

-- Slash commands
SLASH_GOLDTRACKER1 = "/gt"
SlashCmdList["GOLDTRACKER"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "on" then
        isTrackerEnabled = true
        f:Show()
        UpdateDisplay()
        print(addonName .. ": Tracker enabled.")
    elseif msg == "off" then
        isTrackerEnabled = false
        f:Hide()
        print(addonName .. ": Tracker disabled.")
    elseif msg == "toggle" then
        isTrackerEnabled = not isTrackerEnabled
        if isTrackerEnabled then
            f:Show()
            UpdateDisplay()
            print(addonName .. ": Tracker enabled.")
        else
            f:Hide()
            print(addonName .. ": Tracker disabled.")
        end
    elseif msg == "reset" then
        ResetTracker()
    elseif msg == "refresh" then
        UpdateDisplay()
    else
        print("|cffffff00GoldTracker Commands:|r")
        print("/gt on      - Enable tracker")
        print("/gt off     - Disable tracker")
        print("/gt toggle  - Toggle tracker on/off")
		print("/gt reset   - Reset the tracker sesion")
		print("/gt refresh - Force an update on the G/h")
    end
end