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

local L_ABILITY     = _safeKey("TXT_KEY_CIVVACCESS_UNIQUE_ABILITY",     "Unique ability")
local L_UNIT        = _safeKey("TXT_KEY_CIVVACCESS_UNIQUE_UNIT",        "Unique unit")
local L_BUILDING    = _safeKey("TXT_KEY_CIVVACCESS_UNIQUE_BUILDING",    "Unique building")
local L_IMPROVEMENT = _safeKey("TXT_KEY_CIVVACCESS_UNIQUE_IMPROVEMENT", "Unique improvement")
local L_REPLACES    = _safeKey("TXT_KEY_CIVVACCESS_REPLACES",           "replaces")

-- ---------------------------------------------------------------------------
-- Lazy DB query initialisation.  DB.CreateQuery is deferred to first use
-- inside AddCivilizationEntry (show-time), so include-time is truly DB-free.
-- ---------------------------------------------------------------------------
local _unitsQ, _buildingsQ, _improvementsQ

local function _initQueries()
    if _unitsQ and _buildingsQ and _improvementsQ then return end
    _unitsQ = DB.CreateQuery([[
        SELECT UniqueUnit.Description AS UniqueDesc,
               DefaultUnit.Description AS ReplacesDesc
        FROM   Civilization_UnitClassOverrides
               INNER JOIN Units AS UniqueUnit
                   ON UniqueUnit.Type = Civilization_UnitClassOverrides.UnitType
               INNER JOIN UnitClasses
                   ON UnitClasses.Type = Civilization_UnitClassOverrides.UnitClassType
               LEFT JOIN Units AS DefaultUnit
                   ON DefaultUnit.Type = UnitClasses.DefaultUnit
        WHERE  Civilization_UnitClassOverrides.CivilizationType = ?
               AND Civilization_UnitClassOverrides.UnitType IS NOT NULL]])
    _buildingsQ = DB.CreateQuery([[
        SELECT UniqueBuilding.Description AS UniqueDesc,
               DefaultBuilding.Description AS ReplacesDesc
        FROM   Civilization_BuildingClassOverrides
               INNER JOIN Buildings AS UniqueBuilding
                   ON UniqueBuilding.Type = Civilization_BuildingClassOverrides.BuildingType
               INNER JOIN BuildingClasses
                   ON BuildingClasses.Type = Civilization_BuildingClassOverrides.BuildingClassType
               LEFT JOIN Buildings AS DefaultBuilding
                   ON DefaultBuilding.Type = BuildingClasses.DefaultBuilding
        WHERE  Civilization_BuildingClassOverrides.CivilizationType = ?
               AND Civilization_BuildingClassOverrides.BuildingType IS NOT NULL]])
    _improvementsQ = DB.CreateQuery([[
        SELECT Description FROM Improvements WHERE CivilizationType = ?]])
end

-- Converts a TXT_KEY description string to a localized name, guarding NULL
-- and unresolved keys.  Returns "" when the value is not usable.
local function _loc(descKey)
    if not descKey then return "" end
    local ok, v = pcall(Locale.ConvertTextKey, descKey)
    if not ok or not v or v == descKey then return "" end
    return v
end

-- Appends "Label: name (replaces X)" to parts, handling nil ReplacesDesc.
local function _appendUnique(parts, label, uniqueDesc, replacesDesc)
    local name = _loc(uniqueDesc)
    if name == "" then return end
    local value = name
    if replacesDesc then
        local rep = _loc(replacesDesc)
        if rep ~= "" and rep ~= name then
            value = value .. " (" .. L_REPLACES .. " " .. rep .. ")"
        end
    end
    parts[#parts + 1] = label .. ": " .. value
end

-- Builds the full rich spoken label for a regular (non-random) civ entry.
-- Called inside AddCivilizationEntry at show-time; every DB access is
-- individually guarded by pcall so partial failure never silences the rest.
local function _buildRichLabel(civType, ct)
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

    -- 3. Unique units — lazy query, pcall-protected.
    local ok3, err3 = pcall(function()
        _initQueries()
        for row in _unitsQ(civType) do
            _appendUnique(parts, L_UNIT, row.UniqueDesc, row.ReplacesDesc)
        end
    end)
    if not ok3 then
        Log.warn("[vp-compat] SelectCiv: unique units query failed: " .. tostring(err3))
    end

    -- 4. Unique buildings — lazy query, pcall-protected.
    local ok4, err4 = pcall(function()
        _initQueries()
        for row in _buildingsQ(civType) do
            _appendUnique(parts, L_BUILDING, row.UniqueDesc, row.ReplacesDesc)
        end
    end)
    if not ok4 then
        Log.warn("[vp-compat] SelectCiv: unique buildings query failed: " .. tostring(err4))
    end

    -- 5. Unique improvements — lazy query, pcall-protected.
    local ok5, err5 = pcall(function()
        _initQueries()
        for row in _improvementsQ(civType) do
            local name = _loc(row.Description)
            if name ~= "" then
                parts[#parts + 1] = L_IMPROVEMENT .. ": " .. name
            end
        end
    end)
    if not ok5 then
        Log.warn("[vp-compat] SelectCiv: unique improvements query failed: " .. tostring(err5))
    end

    return table.concat(parts, ", ")
end

local g_entries  = {}   -- { title, richLabel, civID, scenarioCivID }
local g_focusIdx = 1

local origAddEntry  = AddCivilizationEntry
local origAddRandom = AddRandomCivilizationEntry
local origShowHide  = ShowHideHandler
local origInput     = InputHandler

-- Collect each entry as VP builds it.  _buildRichLabel reads already-rendered
-- controls (Title, BonusDescription) and runs lazy DB queries — all show-time.
AddCivilizationEntry = function(traitsQuery, populateUniqueBonuses, civ, leaderType, leaderDescription, leaderPortraitIndex, leaderIconAtlas, scenarioCivID)
    local ct = origAddEntry(traitsQuery, populateUniqueBonuses, civ, leaderType, leaderDescription, leaderPortraitIndex, leaderIconAtlas, scenarioCivID)
    if ct then
        local richLabel = _buildRichLabel(civ.Type, ct)
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
        end
    end
    if origInput then return origInput(uiMsg, wParam, lParam) end
end
ContextPtr:SetInputHandler(InputHandler)

VPSelectCivAccess_Installed = true
Log.info("[vp-compat] SelectCiv: installed (" .. tostring(#g_entries) .. " entries at include-time)")

