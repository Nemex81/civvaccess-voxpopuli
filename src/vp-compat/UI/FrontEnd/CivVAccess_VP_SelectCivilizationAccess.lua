-- CivVAccess_VP_SelectCivilizationAccess.lua
-- VP-compat accessibility for the SelectCivilization popup.
--
-- WHY A CUSTOM WRAPPER (not CivVAccess_SelectCivilizationAccess):
-- CVA's SelectCivilizationAccess calls rebuildItems() at include-time. It
-- builds civ labels via CivDetails.richLabel(), which calls Text.key() on
-- Leaders.Description from DB. VP has leaders where this field is NULL,
-- causing Text.key(nil) -> ConvertTextKey(nil) -> Lua error. Our pcall bridge
-- in SelectCivilization.lua catches the crash, but BaseMenu.install never
-- completes, so no accessibility is installed.
--
-- This wrapper avoids the DB entirely at include-time. Instead, it
-- monkeypatches AddCivilizationEntry and AddRandomCivilizationEntry (VP
-- globals in this context) so every entry VP builds is also captured in
-- g_entries with the already-rendered Title:GetText() text. Navigation and
-- speech happen fully at show-time, never at include-time.
--
-- Globals available in this context (VP's SelectCivilization.lua has run):
--   AddCivilizationEntry, AddRandomCivilizationEntry, CivilizationSelected,
--   ShowHideHandler, InputHandler, Controls.Stack, g_bRefreshCivs,
--   g_bIsScenario, IsWBMap, PreGame, KeyEvents, Keys

local _ok, _err = pcall(include, "CivVAccess_FrontendCommon")
if not _ok then
    local _fallbacks = { "CivVAccess_Log", "CivVAccess_SpeechPipeline" }
    for _, m in ipairs(_fallbacks) do
        pcall(include, m)
    end
    local msg = "[vp-compat] SelectCiv: FrontendCommon failed: " .. tostring(_err)
    if Log then Log.warn(msg) else print(msg) end
end

if not SpeechPipeline or not Log then
    local msg = "[vp-compat] SelectCiv: CVA modules unavailable; not installing"
    if Log then Log.warn(msg) else print(msg) end
    return
end

Log.info("[vp-compat] SelectCiv: installing VP-compat accessibility")

local g_entries  = {}   -- { title, civID, scenarioCivID }
local g_focusIdx = 1

local origAddEntry  = AddCivilizationEntry
local origAddRandom = AddRandomCivilizationEntry
local origShowHide  = ShowHideHandler
local origInput     = InputHandler

-- Collect each entry as VP builds it. Title and BonusDescription are already
-- localized and set by AddCivilizationEntry before it returns, so GetText()
-- returns the final display string with no DB dependency here.
AddCivilizationEntry = function(traitsQuery, populateUniqueBonuses, civ, leaderType, leaderDescription, leaderPortraitIndex, leaderIconAtlas, scenarioCivID)
    local ct = origAddEntry(traitsQuery, populateUniqueBonuses, civ, leaderType, leaderDescription, leaderPortraitIndex, leaderIconAtlas, scenarioCivID)
    if ct then
        local title = ""
        local ok1, v1 = pcall(function() return ct.Title:GetText() end)
        if ok1 and v1 and v1 ~= "" then title = v1 end
        g_entries[#g_entries + 1] = {
            title        = title,
            civID        = civ.ID,
            scenarioCivID = scenarioCivID,
        }
    end
    return ct
end

-- Random entry comes before regular civs in InitCivSelection; append here so
-- index 1 in g_entries matches position 1 in the visual stack.
AddRandomCivilizationEntry = function()
    origAddRandom()
    local label = ""
    local ok, v = pcall(Locale.ConvertTextKey, "TXT_KEY_RANDOM_LEADER")
    if ok and v then label = v else label = "Random" end
    g_entries[#g_entries + 1] = { title = label, civID = -1, scenarioCivID = nil }
end

local function announce(idx)
    local e = g_entries[idx]
    if not e or e.title == "" then return end
    SpeechPipeline.speakInterrupt(e.title)
end

local function setInitialFocus()
    local current = PreGame.GetCivilization(0)
    g_focusIdx = 1
    for i, e in ipairs(g_entries) do
        if e.civID == current then
            g_focusIdx = i
            break
        end
    end
end

-- Override ShowHideHandler: force VP to always rebuild the list (so our
-- monkeypatched AddCivilizationEntry populates g_entries), then announce
-- the focused entry on open.
ShowHideHandler = function(bIsHide)
    if not bIsHide then
        g_entries     = {}
        g_bRefreshCivs = true   -- force VP to call InitCivSelection -> our wrappers
    end
    if origShowHide then origShowHide(bIsHide) end
    if not bIsHide then
        setInitialFocus()
        announce(g_focusIdx)
    end
end
ContextPtr:SetShowHideHandler(ShowHideHandler)

-- Override InputHandler: intercept Up/Down/Enter, pass everything else.
InputHandler = function(uiMsg, wParam, lParam)
    if uiMsg == KeyEvents.KeyDown and #g_entries > 0 then
        if wParam == Keys.VK_DOWN then
            if g_focusIdx < #g_entries then g_focusIdx = g_focusIdx + 1 end
            announce(g_focusIdx)
            return true
        elseif wParam == Keys.VK_UP then
            if g_focusIdx > 1 then g_focusIdx = g_focusIdx - 1 end
            announce(g_focusIdx)
            return true
        elseif wParam == Keys.VK_RETURN then
            local e = g_entries[g_focusIdx]
            if e then
                local ok, err = pcall(CivilizationSelected, e.civID, e.scenarioCivID)
                if not ok then
                    Log.error("[vp-compat] SelectCiv: CivilizationSelected failed: " .. tostring(err))
                end
            end
            return true
        end
    end
    if origInput then return origInput(uiMsg, wParam, lParam) end
end
ContextPtr:SetInputHandler(InputHandler)

VPSelectCivAccess_Installed = true
Log.info("[vp-compat] SelectCiv: installed (" .. tostring(#g_entries) .. " entries at include-time)")
