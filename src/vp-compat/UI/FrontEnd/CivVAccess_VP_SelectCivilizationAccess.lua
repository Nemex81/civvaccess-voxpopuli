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
-- g_entries with rich spoken labels built at show-time (never at include-time).
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

-- ---------------------------------------------------------------------------
-- Label prefixes: try CVA InGame TXT_KEY first; fall back to English literals
-- if the keys are not loaded in the FrontEnd context. Locale API is an engine
-- call (not a DB query), safe at include-time.
-- ---------------------------------------------------------------------------
local function _safeKey(key, fallback)
    local ok, v = pcall(Locale.ConvertTextKey, key)
    return (ok and v and v ~= key) and v or fallback
end

local L_ABILITY = _safeKey("TXT_KEY_CIVVACCESS_UNIQUE_ABILITY",   "Unique ability")
local L_UNIQUE  = _safeKey("TXT_KEY_CIVVACCESS_UNIQUE_COMPONENT", "Unique")

-- Builds the full rich spoken label for a regular (non-random) civ entry.
-- Called inside AddCivilizationEntry at show-time. Reads only from
-- already-rendered VP controls — no DB access, no prepared statements.
local function _buildRichLabel(ct)
    local parts = {}

    -- 1. Base title: "Leader (Civ) (TraitShort)" — already rendered by VP.
    local ok1, title = pcall(function() return ct.Title:GetText() end)
    if ok1 and title and title ~= "" then
        parts[#parts + 1] = title
    elseif not ok1 then
        Log.warn("[vp-compat] SelectCiv: Title:GetText() failed: " .. tostring(title))
    end

    -- 2. Unique ability description — BonusDescription already set by VP's
    --    traitsQuery in AddCivilizationEntry before the control is returned.
    local ok2, bonus = pcall(function() return ct.BonusDescription:GetText() end)
    if ok2 and bonus and bonus ~= "" then
        parts[#parts + 1] = L_ABILITY .. ": " .. bonus
    elseif not ok2 then
        Log.warn("[vp-compat] SelectCiv: BonusDescription:GetText() failed: " .. tostring(bonus))
    end

    -- 3. Unique components — read tooltip from VP's already-rendered icon buttons.
    --    No DB query: VP has already populated B1..B6 before returning controlTable.
    local ok3, err3 = pcall(function()
        for i = 1, 6 do
            local btn = ct["B" .. i]
            if btn and not btn:IsHidden() then
                local tip = btn:GetToolTipString()
                if tip and tip ~= "" then
                    parts[#parts + 1] = L_UNIQUE .. ": " .. tip
                end
            end
        end
    end)
    if not ok3 then
        Log.warn("[vp-compat] SelectCiv: unique buttons read failed: " .. tostring(err3))
    end

    return table.concat(parts, ", ")
end

local g_entries  = {}   -- { title, richLabel, civID, scenarioCivID }
local g_focusIdx = 1

local origAddEntry  = AddCivilizationEntry
local origAddRandom = AddRandomCivilizationEntry
local origShowHide  = ShowHideHandler
local origInput     = InputHandler

-- Flush speech before the context is destroyed so no pending callbacks
-- can reference upvalues of a dead context.  Note: the BackButton callback
-- was registered before this wrapper ran and holds a direct reference to
-- VP's original OnBack, so replacing the global covers the ESC path
-- (via origInput -> VP's InputHandler -> OnBack) and any other caller
-- that looks up OnBack by name at call-time.
local origOnBack = OnBack
OnBack = function()
    local ok, err = pcall(function() SpeechPipeline.speakInterrupt("") end)
    if not ok then Log.warn("[vp-compat] SelectCiv: OnBack speech flush failed: " .. tostring(err)) end
    if origOnBack then origOnBack() end
end

-- Collect each entry as VP builds it.  _buildRichLabel reads already-rendered
-- controls (Title, BonusDescription) and runs lazy DB queries — all show-time.
AddCivilizationEntry = function(traitsQuery, populateUniqueBonuses, civ, leaderType, leaderDescription, leaderPortraitIndex, leaderIconAtlas, scenarioCivID)
    local ct = origAddEntry(traitsQuery, populateUniqueBonuses, civ, leaderType, leaderDescription, leaderPortraitIndex, leaderIconAtlas, scenarioCivID)
    if ct then
        local richLabel = _buildRichLabel(ct)
        local title = ""
        local ok, v = pcall(function() return ct.Title:GetText() end)
        if ok and v and v ~= "" then title = v end
        g_entries[#g_entries + 1] = {
            title         = title,
            richLabel     = richLabel,
            civID         = civ.ID,
            scenarioCivID = scenarioCivID,
        }
    end
    return ct
end

-- Random entry: no DB queries, no rich label needed.
AddRandomCivilizationEntry = function()
    origAddRandom()
    local label = ""
    local ok, v = pcall(Locale.ConvertTextKey, "TXT_KEY_RANDOM_LEADER")
    if ok and v then label = v else label = "Random" end
    g_entries[#g_entries + 1] = { title = label, richLabel = "", civID = -1, scenarioCivID = nil }
end

local function announce(idx)
    local e = g_entries[idx]
    if not e then return end
    local text = (e.richLabel ~= "" and e.richLabel) or e.title
    if text == "" then return end
    SpeechPipeline.speakInterrupt(text)
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
        g_entries      = {}
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
        elseif wParam == Keys.VK_ESCAPE then
            local ok, err = pcall(function() SpeechPipeline.speakInterrupt("") end)
            if not ok then Log.warn("[vp-compat] SelectCiv: ESC speech flush failed: " .. tostring(err)) end
            if origInput then return origInput(uiMsg, wParam, lParam) end
            return true
        end
    end
    if origInput then return origInput(uiMsg, wParam, lParam) end
end
ContextPtr:SetInputHandler(InputHandler)

VPSelectCivAccess_Installed = true
Log.info("[vp-compat] SelectCiv: installed (" .. tostring(#g_entries) .. " entries at include-time)")

