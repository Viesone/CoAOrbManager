-- ============================================
-- CoA Orb Manager - Complete Script
-- Hides action bar, manages orb with movement, position saving, and slash commands
-- ============================================

-- Initialize saved variables
if not CoAOrbManagerDB then
    CoAOrbManagerDB = {}
end

-- Only set defaults if they don't exist yet
if CoAOrbManagerDB.scale == nil then
    CoAOrbManagerDB.scale = 0.7
end
if CoAOrbManagerDB.anchor == nil then
    CoAOrbManagerDB.anchor = "BOTTOM"
end
if CoAOrbManagerDB.anchorX == nil then
    CoAOrbManagerDB.anchorX = 0
end
if CoAOrbManagerDB.anchorY == nil then
    CoAOrbManagerDB.anchorY = 100
end
if CoAOrbManagerDB.locked == nil then
    CoAOrbManagerDB.locked = false
end

-- Debug: Show what's loaded
print("CoA Orb Manager: Loaded settings - Scale: "..CoAOrbManagerDB.scale..", Anchor: "..CoAOrbManagerDB.anchor..", Offset: "..CoAOrbManagerDB.anchorX..", "..CoAOrbManagerDB.anchorY)

local orb = nil
local appliedOnce = false

-- Function to force save settings
local function ForceSaveSettings()
    local temp = CoAOrbManagerDB
    CoAOrbManagerDB = temp
    print("Settings saved!")
    print("  Scale: "..CoAOrbManagerDB.scale)
    print("  Anchor: "..CoAOrbManagerDB.anchor)
    print("  Offset: "..CoAOrbManagerDB.anchorX..", "..CoAOrbManagerDB.anchorY)
    print("  Locked: "..tostring(CoAOrbManagerDB.locked))
end

-- ============================================
-- Hide ALL CoA Frames (except the orb)
-- ============================================
local function HideCoAFrames()
    -- 1. Hide the main action bar frame
    local coa = _G["CoAMultiCastActionBarFrame"]
    if coa then
        -- Detach the orb first
        for i = 1, coa:GetNumChildren() do
            local child = select(i, coa:GetChildren())
            if child and child:GetName() and string.find(child:GetName(), "Orb") then
                child:SetParent(UIParent)
            end
        end
        coa:Hide()
    end
    
    -- 2. Hide the flyout frame
    local flyout = _G["CoAMultiCastActionBarFrameFlyoutFrame"]
    if flyout then
        flyout:Hide()
    end
    
    -- 3. Hide the flyout close button
    local closeBtn = _G["CoAMultiCastActionBarFrameFlyoutFrameCloseButton"]
    if closeBtn then
        closeBtn:Hide()
    end
    
    -- 4. Hide the flyout open button
    local openBtn = _G["CoAMultiCastActionBarFrameFlyoutFrameOpenButton"]
    if openBtn then
        openBtn:Hide()
    end
    
    -- 5. Hide the pool frame (contains the action buttons)
    local pool = _G["CoAMultiCastActionBarFramePoolFrame"]
    if pool then
        pool:Hide()
    end
    
    -- 6. Hide individual action buttons (1-5)
    for i = 1, 5 do
        local btn = _G["CoAMultiCastActionBarFrameButton"..i]
        if btn then
            btn:Hide()
        end
    end
    
    -- 7. Also try to hide any buttons with the template name
    for i = 1, 5 do
        local btn = _G["CoAMultiCastActionButtonTemplate"..i]
        if btn then
            btn:Hide()
        end
    end
end

-- ============================================
-- Apply Orb Settings
-- ============================================
local function ApplyOrbSettings()
    orb = _G["CoAResourceOrb"]
    if not orb then 
        return false 
    end
    
    -- Make sure orb is properly parented
    orb:SetParent(UIParent)
    orb:SetFrameLevel(100)
    
    -- Apply scale
    orb:SetScale(CoAOrbManagerDB.scale)
    
    -- Apply position using saved anchor
    local anchor = CoAOrbManagerDB.anchor or "CENTER"
    local xOffset = CoAOrbManagerDB.anchorX or 0
    local yOffset = CoAOrbManagerDB.anchorY or 0
    
    -- Clear all points and set new position
    orb:ClearAllPoints()
    orb:SetPoint(anchor, UIParent, anchor, xOffset, yOffset)
    
    -- Set lock state
    if CoAOrbManagerDB.locked then
        orb:SetMovable(false)
        orb:EnableMouse(true)
        orb:SetScript("OnDragStart", nil)
        orb:SetScript("OnDragStop", nil)
    else
        orb:SetMovable(true)
        orb:EnableMouse(true)
        orb:RegisterForDrag("LeftButton")
        orb:SetScript("OnDragStart", function(self) 
            self:StartMoving() 
        end)
        orb:SetScript("OnDragStop", function(self) 
            self:StopMovingOrSizing()
            local point, _, _, xOffset, yOffset = self:GetPoint(1)
            if point then
                CoAOrbManagerDB.anchor = point
                CoAOrbManagerDB.anchorX = xOffset or 0
                CoAOrbManagerDB.anchorY = yOffset or 0
                print("Orb position saved! Anchor: "..point..", Offset: "..(xOffset or 0)..", "..(yOffset or 0))
                ForceSaveSettings()
            end
        end)
    end
    
    return true
end

local function SetupOrb()
    HideCoAFrames()
    if ApplyOrbSettings() then
        if not appliedOnce then
            print("CoA Orb loaded! Anchor: "..CoAOrbManagerDB.anchor..", Scale: "..CoAOrbManagerDB.scale.." | Use /orb for commands.")
            appliedOnce = true
        end
    end
end

-- ============================================
-- Event Handler
-- ============================================
local function DelayedSetup()
    C_Timer.After(0.5, SetupOrb)
    C_Timer.After(1.5, SetupOrb)
    C_Timer.After(3, SetupOrb)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function()
    DelayedSetup()
end)

-- Run immediately if already loaded
DelayedSetup()

-- ============================================
-- Slash Commands
-- ============================================
SLASH_ORB1 = "/orb"
SlashCmdList["ORB"] = function(msg)
    orb = _G["CoAResourceOrb"]
    if not orb then 
        print("Orb not found! Try /reload.")
        return 
    end
    
    msg = msg:lower()
    
    if msg == "move" or msg == "unlock" then
        CoAOrbManagerDB.locked = false
        orb:SetMovable(true)
        orb:EnableMouse(true)
        orb:RegisterForDrag("LeftButton")
        orb:SetScript("OnDragStart", function(self) self:StartMoving() end)
        orb:SetScript("OnDragStop", function(self) 
            self:StopMovingOrSizing()
            local point, _, _, xOffset, yOffset = self:GetPoint(1)
            if point then
                CoAOrbManagerDB.anchor = point
                CoAOrbManagerDB.anchorX = xOffset or 0
                CoAOrbManagerDB.anchorY = yOffset or 0
                print("Orb position saved! Anchor: "..point..", Offset: "..(xOffset or 0)..", "..(yOffset or 0))
                ForceSaveSettings()
            end
        end)
        print("Orb is now movable! Drag it with left mouse button.")
        ForceSaveSettings()
        
    elseif msg == "lock" then
        CoAOrbManagerDB.locked = true
        orb:SetMovable(false)
        orb:SetScript("OnDragStart", nil)
        orb:SetScript("OnDragStop", nil)
        print("Orb is now locked in place!")
        ForceSaveSettings()
        
    elseif msg == "reset" then
        CoAOrbManagerDB.anchor = "BOTTOM"
        CoAOrbManagerDB.anchorX = 0
        CoAOrbManagerDB.anchorY = 100
        orb:ClearAllPoints()
        orb:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
        print("Orb reset to bottom center! (Offset: 0, 100)")
        ForceSaveSettings()
        
    elseif msg:match("scale") then
        local scale = tonumber(msg:match("(%d+%.?%d*)"))
        if scale and scale > 0 and scale < 5 then
            CoAOrbManagerDB.scale = scale
            orb:SetScale(scale)
            print("Orb scale set to: "..scale)
            ForceSaveSettings()
        else
            print("Usage: /orb scale 1.5 (valid range: 0.1 - 5.0)")
        end
        
    elseif msg == "hide" then
        orb:Hide()
        print("Orb hidden!")
        
    elseif msg == "show" then
        orb:Show()
        print("Orb shown!")
        
    elseif msg == "status" or msg == "info" then
        local point, _, _, xOffset, yOffset = orb:GetPoint(1)
        print("=== Orb Status ===")
        print("Current Scale: "..orb:GetScale())
        print("Saved Scale: "..CoAOrbManagerDB.scale)
        print("Current Anchor: "..(point or "unknown"))
        print("Current Offset: "..(xOffset or "unknown")..", "..(yOffset or "unknown"))
        print("Saved Anchor: "..CoAOrbManagerDB.anchor)
        print("Saved Offset: "..CoAOrbManagerDB.anchorX..", "..CoAOrbManagerDB.anchorY)
        print("Locked: "..tostring(CoAOrbManagerDB.locked))
        print("Movable: "..tostring(orb:IsMovable()))
        print("Visible: "..tostring(orb:IsVisible()))
        
    elseif msg == "bottom" then
        CoAOrbManagerDB.anchor = "BOTTOM"
        CoAOrbManagerDB.anchorX = 0
        CoAOrbManagerDB.anchorY = 100
        orb:ClearAllPoints()
        orb:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
        print("Orb moved to bottom center! (Offset: 0, 100)")
        ForceSaveSettings()
        
    elseif msg == "top" then
        CoAOrbManagerDB.anchor = "TOP"
        CoAOrbManagerDB.anchorX = 0
        CoAOrbManagerDB.anchorY = -100
        orb:ClearAllPoints()
        orb:SetPoint("TOP", UIParent, "TOP", 0, -100)
        print("Orb moved to top center! (Offset: 0, -100)")
        ForceSaveSettings()
        
    elseif msg == "center" then
        CoAOrbManagerDB.anchor = "CENTER"
        CoAOrbManagerDB.anchorX = 0
        CoAOrbManagerDB.anchorY = 0
        orb:ClearAllPoints()
        orb:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        print("Orb moved to center!")
        ForceSaveSettings()
        
    elseif msg == "save" or msg == "savesettings" then
        local point, _, _, xOffset, yOffset = orb:GetPoint(1)
        if point then
            CoAOrbManagerDB.anchor = point
            CoAOrbManagerDB.anchorX = xOffset or 0
            CoAOrbManagerDB.anchorY = yOffset or 0
        end
        ForceSaveSettings()
        
    elseif msg == "debug" then
        print("=== Debug Info ===")
        print("CoAOrbManagerDB contents:")
        for k, v in pairs(CoAOrbManagerDB) do
            print("  "..k..": "..tostring(v))
        end
        if orb then
            print("Orb exists: YES")
            print("Orb scale: "..orb:GetScale())
            local point, _, _, xOffset, yOffset = orb:GetPoint(1)
            print("Orb anchor: "..(point or "nil"))
            print("Orb offset: "..(xOffset or "nil")..", "..(yOffset or "nil"))
            print("UIParent size: "..UIParent:GetWidth().."x"..UIParent:GetHeight())
        else
            print("Orb exists: NO")
        end
        
        -- Check if all frames are hidden
        print("Checking hidden frames:")
        local framesToCheck = {
            "CoAMultiCastActionBarFrame",
            "CoAMultiCastActionBarFrameFlyoutFrame",
            "CoAMultiCastActionBarFrameFlyoutFrameCloseButton",
            "CoAMultiCastActionBarFrameFlyoutFrameOpenButton",
            "CoAMultiCastActionBarFramePoolFrame"
        }
        for _, name in ipairs(framesToCheck) do
            local f = _G[name]
            if f then
                print("  "..name..": "..(f:IsVisible() and "VISIBLE" or "HIDDEN"))
            else
                print("  "..name..": NOT FOUND")
            end
        end
        
    elseif msg == "resetall" then
        CoAOrbManagerDB.scale = 0.7
        CoAOrbManagerDB.anchor = "BOTTOM"
        CoAOrbManagerDB.anchorX = 0
        CoAOrbManagerDB.anchorY = 100
        CoAOrbManagerDB.locked = false
        orb:SetScale(0.7)
        orb:ClearAllPoints()
        orb:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 100)
        orb:SetMovable(true)
        print("All settings reset to defaults!")
        ForceSaveSettings()
        
    -- New: Show all CoA frames (for debugging)
    elseif msg == "showall" then
        local framesToShow = {
            "CoAMultiCastActionBarFrame",
            "CoAMultiCastActionBarFrameFlyoutFrame",
            "CoAMultiCastActionBarFrameFlyoutFrameCloseButton",
            "CoAMultiCastActionBarFrameFlyoutFrameOpenButton",
            "CoAMultiCastActionBarFramePoolFrame"
        }
        for _, name in ipairs(framesToShow) do
            local f = _G[name]
            if f then
                f:Show()
                print("Showed: "..name)
            end
        end
        print("All CoA frames shown!")
        
    elseif msg == "hideall" then
        HideCoAFrames()
        print("All CoA frames hidden!")
        
    elseif msg == "" or msg == "help" then
        print("=== CoA Orb Commands ===")
        print("/orb move      - Make orb movable (saves lock state)")
        print("/orb lock      - Lock orb in place (saves lock state)")
        print("/orb reset     - Reset to bottom center")
        print("/orb bottom    - Move to bottom center")
        print("/orb top       - Move to top center")  
        print("/orb center    - Move to center")
        print("/orb scale 1.5 - Change orb size (0.1-5.0)")
        print("/orb hide      - Hide the orb")
        print("/orb show      - Show the orb")
        print("/orb status    - Show orb info")
        print("/orb save      - Manually save settings")
        print("/orb debug     - Show debug information")
        print("/orb hideall   - Hide all CoA frames")
        print("/orb showall   - Show all CoA frames (debug)")
        print("/orb resetall  - Reset ALL settings to defaults")
        print("/orb help      - Show this menu")
    else
        print("Unknown command. Use /orb help for commands.")
    end
end

print("CoA Orb Manager loaded! Type /orb for commands.")