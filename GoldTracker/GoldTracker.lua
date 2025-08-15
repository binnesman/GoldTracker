local f = CreateFrame("Frame", "GoldTrackerFrame", UIParent)
f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
f:SetWidth(200)
f:SetHeight(70)
f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")
f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", f.StopMovingOrSizing)

-- Transparent background
f:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background"})
f:SetBackdropColor(0,0,0,0)

-- Fontstring for display
local text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER", f, "CENTER", 0, 10)
text:SetText("Loading...")

-- Variables
local startTime, startGold

-- Function to get player's gold
local function GetPlayerGold()
    local copper = GetMoney()
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local copperOnly = copper % 100
    return gold, silver, copperOnly, copper
end

-- Function to update the display
local function UpdateDisplay()
    local now = time()
    local _, _, _, currentCopper = GetPlayerGold()

    local sessionTime = now - startTime
    local sessionGoldChange = currentCopper - startGold
    local sessionGPH = (sessionGoldChange / 10000) / (sessionTime / 3600)

    -- Colors
    local gphColor = sessionGPH < 0 and "|cffff0000" or "|cff00ff00"
    local goldChangeColor = sessionGoldChange < 0 and "|cffff0000" or "|cff00ff00"

    -- Format values
    local g, s, c = GetPlayerGold()
    text:SetText(
        string.format("|cffffff00%d|r g |cffc0c0c0%d|r s |cffb87333%d|r c\n%s%.1f G/h|r\n%s%.1f g|r",
        g, s, c,
        gphColor, sessionGPH,
        goldChangeColor, sessionGoldChange / 10000)
    )
end

-- Event handler
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        local _, _, _, currentCopper = GetPlayerGold()
        startTime = time()
        startGold = currentCopper
        self:SetScript("OnUpdate", UpdateDisplay)
    end
end)

-- Reset button click
resetBtn:SetScript("OnClick", function()
    local _, _, _, currentCopper = GetPlayerGold()
    startTime = time()
    startGold = currentCopper
end)
