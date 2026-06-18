-- CivVAccess_VP_GameSetupAccess.lua
-- VP-compat accessibility wrapper for the Vox Populi no-EUI GameSetupScreen.
--
-- Included from the bottom of src/vp-compat/UI/FrontEnd/GameSetupScreen.lua
-- (VP's verbatim copy with an appended include bridge), which runs in the
-- same Lua Context as the screen. Every VP global (Controls.*, OnBack,
-- OnStart, OnCivilization, OnMapType, OnMapSize, OnDifficulty, OnSpeed,
-- OnRandomize, OnSetCivNames, OnCancel, OnSenarioCheck, ShowHideHandler,
-- InputHandler) is directly reachable.
--
-- VP's GameSetupScreen uses the same Controls.* and global functions as the
-- base game (confirmed from reading
-- Community-Patch-DLL/(2) Vox Populi/Core Files/Overrides/GameSetupScreen.lua
-- v17). The menu layout therefore mirrors CivVAccess_GameSetupScreenAccess
-- from the Civ V Access DLC, with the addition of hard guard, locale support,
-- and the installed-sentinel flag.
--
-- VP uses Locale.ConvertTextKey for all its own UI text; no VP_TRANS table
-- is needed. FALLBACK_STRINGS covers the one mod-authored key (screen name).
--
-- Front-end Contexts that show this file:
--   Single Player -> New Game                 (ContextPtr ID = GameSetupScreen)
--   Mods -> Next -> Single Player -> Play Map (ContextPtr ID = ModdingGameSetupScreen)

-- pcall guard: ensures a stem resolution failure in this Context (e.g. a
-- chain member unreachable in ModdingGameSetupScreen's lua_State) is
-- diagnosed instead of propagating silently through the GameSetupScreen.lua
-- bridge pcall, where it would appear only as a generic "include failed" entry.
local _cvaBoot_ok, _cvaBoot_err = pcall(include, "CivVAccess_FrontendCommon")
if not _cvaBoot_ok then
    -- Primary chain failed. Try the subset needed for the hard guard to pass.
    -- Stem cache makes re-includes no-ops for stems already loaded by a
    -- partial chain run before the failure point.
    local _fallbacks = {
        "CivVAccess_Log",
        "CivVAccess_SpeechPipeline",
        "CivVAccess_BaseMenuCore",
        "CivVAccess_BaseMenuInstall",
        "CivVAccess_BaseMenuItems",
    }
    for _, m in ipairs(_fallbacks) do
        local ok2, err2 = pcall(include, m)
        if not ok2 then
            if Log ~= nil then
                Log.warn("[vp-compat] fallback include failed: " .. m .. ": " .. tostring(err2))
            else
                print("[vp-compat][WARNING] fallback include failed: " .. m .. ": " .. tostring(err2))
            end
        end
    end
    local _bootErrMsg = "[vp-compat][ERROR] CivVAccess_FrontendCommon failed: " .. tostring(_cvaBoot_err)
    if Log ~= nil then Log.error(_bootErrMsg) else print(_bootErrMsg) end
end

-- Diagnostic: records the active Context and module availability in Lua.log
-- (LoggingEnabled=1). Placed before the hard guard to capture both the
-- "guard fires" and "installed" outcomes.
do
    local _ctxID = (ContextPtr ~= nil and ContextPtr.GetID ~= nil)
        and ContextPtr:GetID() or "nil"
    local _diag = "[vp-compat][DEBUG] VP setup wrapper"
        .. " context=" .. tostring(_ctxID)
        .. " BaseMenu=" .. tostring(BaseMenu ~= nil)
        .. " SpeechPipeline=" .. tostring(SpeechPipeline ~= nil)
        .. " Log=" .. tostring(Log ~= nil)
    if Log ~= nil then Log.info(_diag) else print(_diag) end
end

-- Hard guard: if the Civ V Access front-end chain did not resolve (DLC not
-- active, or its UISkin not exposing UI/Shared to this Context), bail without
-- touching the screen so VP keeps working for sighted players.
if BaseMenu == nil or BaseMenuItems == nil or SpeechPipeline == nil or Log == nil then
    local _guardMsg = "[vp-compat][WARNING] CVA front-end modules unavailable; VP game setup not vocalized"
    if Log ~= nil then Log.warn(_guardMsg) else print(_guardMsg) end
    return
end

Log.info("[vp-compat] loaded in VP GameSetupScreen context")

-- FALLBACK_STRINGS: safety-net values for CivVAccess_Strings keys this
-- wrapper speaks. applyLocaleStrings() retries the CVA overlay at show-time
-- when Locale is ready; these values cover the case where the overlay cannot
-- resolve in this Context. Both en_US and it_IT are required here.
--
-- VP uses Locale.ConvertTextKey for all its own UI strings, so no VP_TRANS
-- table is needed (there are no hardcoded English strings in VP's screen).
local FALLBACK_STRINGS = {
    en_US = {
        -- Screen name announced on open. CVA ships this key; fallback for
        -- the case where StringsLoader cannot reach this Context.
        ["TXT_KEY_CIVVACCESS_SCREEN_GAME_SETUP"] = "Set up game",
    },
    it_IT = {
        ["TXT_KEY_CIVVACCESS_SCREEN_GAME_SETUP"] = "Configura partita",
    },
}

local function activeLocale()
    if Locale ~= nil and Locale.GetCurrentLanguage ~= nil then
        local lang = Locale.GetCurrentLanguage()
        if lang ~= nil and lang.Type ~= nil then
            return lang.Type
        end
    end
    return "en_US"
end

local function detectBundledLocale()
    -- Prefer the explicit engine locale when it is a bundled, non-en locale.
    local lang = activeLocale()
    if lang ~= "en_US" and FALLBACK_STRINGS[lang] ~= nil then
        return lang
    end
    -- In this Context, Locale.GetCurrentLanguage() can briefly report en_US
    -- while engine TXT_KEY lookups are already localized. Probe a base-game
    -- key to detect Italian reliably before the first announce.
    local ok, back = pcall(function()
        return Locale.ConvertTextKey("TXT_KEY_BACK_BUTTON")
    end)
    if ok and back == "Indietro" then
        return "it_IT"
    end
    if FALLBACK_STRINGS[lang] ~= nil then
        return lang
    end
    return "en_US"
end

local function applyLocaleStrings(phase)
    CivVAccess_Strings = CivVAccess_Strings or {}
    -- Primary: re-run the CVA overlay so all CVA keys are localized.
    local ok, err = pcall(function()
        if StringsLoader ~= nil and StringsLoader.loadOverlay ~= nil then
            StringsLoader.loadOverlay("CivVAccess_FrontEndStrings")
        end
    end)
    if not ok then
        Log.error("[vp-compat] CVA overlay reload failed: " .. tostring(err))
    end
    -- Safety net: assert the key this screen needs in the detected locale.
    local loc = detectBundledLocale()
    local bundle = FALLBACK_STRINGS[loc]
    if bundle ~= nil then
        for key, value in pairs(bundle) do
            CivVAccess_Strings[key] = value
        end
    end
    if CivVAccess_Strings["TXT_KEY_CIVVACCESS_SCREEN_GAME_SETUP"] == nil then
        Log.warn("[vp-compat] TXT_KEY_CIVVACCESS_SCREEN_GAME_SETUP missing after apply (locale "
            .. tostring(loc) .. ")")
    else
        Log.info("[vp-compat] locale apply phase=" .. tostring(phase or "n/a")
            .. " locale=" .. tostring(loc))
    end
end

local priorShowHide = ShowHideHandler
local priorInput    = InputHandler

-- Read the current text from a named label control at announce-time so the
-- screen's own setter functions (SetMapTypeForScript, SetDifficulty, etc.)
-- remain the single source of truth. Returns empty string on nil control.
local function labelFromControl(controlName)
    return function()
        return Text.controlText(Controls[controlName],
            "VPGameSetupScreen " .. controlName) or ""
    end
end

-- Human civ slot: leader name, civ short name, and unique-trait description,
-- joined from the two live labels VP updates in SetSelectedCiv / SetCivName.
local function civilizationLabel()
    local title = Text.controlText(Controls.Title,
        "VPGameSetupScreen Title") or ""
    local bonus = Text.controlText(Controls.BonusDescription,
        "VPGameSetupScreen BonusDescription") or ""
    if bonus ~= "" then
        return title .. ", " .. bonus
    end
    return title
end

local handler = BaseMenu.install(ContextPtr, {
    name        = "VPGameSetupScreen",
    displayName = Text.key("TXT_KEY_CIVVACCESS_SCREEN_GAME_SETUP"),
    priorShowHide = priorShowHide,
    priorInput    = priorInput,
    items = {
        -- 1. Civilization selection: reads live leader / civ / trait.
        --    Activating opens the SelectCivilization popup.
        BaseMenuItems.Button({
            controlName = "CivilizationButton",
            labelFn     = civilizationLabel,
            activate    = function() OnCivilization() end,
        }),
        -- 2. Edit custom civ / leader name (opens SetCivNames modal).
        BaseMenuItems.Button({
            controlName = "EditButton",
            textKey     = "TXT_KEY_EDIT_BUTTON",
            tooltipKey  = "TXT_KEY_NAME_CIV_TITLE",
            activate    = function() OnSetCivNames() end,
        }),
        -- 3. Remove custom civ name (conditionally shown by VP's OnCancel).
        BaseMenuItems.Button({
            controlName = "RemoveButton",
            textKey     = "TXT_KEY_CANCEL_BUTTON",
            activate    = function() OnCancel() end,
        }),
        -- 4. Map type: reads the live TypeName label; toggles SelectMapType
        --    sub-panel. Label already contains the localized TXT_KEY_AD_MAP_TYPE_SETTING
        --    prefix plus the map name, so no extra prefix is needed.
        BaseMenuItems.Button({
            controlName = "MapTypeButton",
            labelFn     = labelFromControl("TypeName"),
            tooltipFn   = labelFromControl("TypeHelp"),
            activate    = function() OnMapType() end,
        }),
        -- 5. Scenario mode checkbox: only shown inside LoadScenarioBox when
        --    a World Builder map is selected. visibilityControlName suppresses
        --    the item when the box is hidden (non-scenario maps).
        BaseMenuItems.Checkbox({
            controlName           = "ScenarioCheck",
            visibilityControlName = "LoadScenarioBox",
            textKey               = "TXT_KEY_LOAD_SCENARIO",
            activateCallback      = function() OnSenarioCheck() end,
        }),
        -- 6. Map size: reads SizeName live; toggles SelectMapSize sub-panel.
        BaseMenuItems.Button({
            controlName = "MapSizeButton",
            labelFn     = labelFromControl("SizeName"),
            tooltipFn   = labelFromControl("SizeHelp"),
            activate    = function() OnMapSize() end,
        }),
        -- 7. Difficulty: reads DifficultyName live; toggles SelectDifficulty.
        BaseMenuItems.Button({
            controlName = "DifficultyButton",
            labelFn     = labelFromControl("DifficultyName"),
            tooltipFn   = labelFromControl("DifficultyHelp"),
            activate    = function() OnDifficulty() end,
        }),
        -- 8. Game speed: reads SpeedName live; toggles SelectGameSpeed.
        BaseMenuItems.Button({
            controlName = "GameSpeedButton",
            labelFn     = labelFromControl("SpeedName"),
            tooltipFn   = labelFromControl("SpeedHelp"),
            activate    = function() OnSpeed() end,
        }),
        -- 9. Randomize all settings.
        BaseMenuItems.Button({
            controlName = "RandomizeButton",
            textKey     = "TXT_KEY_GAME_SETUP_RANDOMIZE",
            activate    = function() OnRandomize() end,
        }),
        -- 10. Advanced settings: opens the AdvancedSetup sub-popup which
        --     carries more options (era, city-states, victory conditions,
        --     game options). Accessibility for that popup is out of scope
        --     for VP-SETUP-ACCESS-1.
        BaseMenuItems.Button({
            controlName = "AdvancedButton",
            textKey     = "TXT_KEY_GAME_ADVANCED_SETUP",
            activate    = function() OnAdvanced() end,
        }),
        -- 11. Back.
        BaseMenuItems.Button({
            controlName = "BackButton",
            textKey     = "TXT_KEY_BACK_BUTTON",
            activate    = function() OnBack() end,
        }),
        -- 12. Start game. Uses a static textKey rather than labelFn because
        --     GridButton:GetText() is not documented in the Civ V Lua API and
        --     its availability cannot be guaranteed at runtime. The WB scenario
        --     case (VP changes the label to TXT_KEY_START_SCENARIO when a World
        --     Builder map is loaded) is out of scope for M2 and tracked under
        --     VP-ADVANCEDSETUP-1. Sighted players see the dynamic label; the
        --     spoken label is always "Start game".
        BaseMenuItems.Button({
            controlName = "StartButton",
            textKey     = "TXT_KEY_START_GAME",
            activate    = function() OnStart() end,
        }),
    },
    onShow = function(h)
        -- Locale is ready by the time the screen shows; apply the active
        -- translation into CivVAccess_Strings before the first announce and
        -- refresh the (statically captured) displayName so it speaks localized.
        applyLocaleStrings("onShow")
        h.displayName = Text.key("TXT_KEY_CIVVACCESS_SCREEN_GAME_SETUP")
        -- Retry one tick later to cover Contexts where locale metadata
        -- updates after show-time boot but before the first interaction.
        TickPump.runOnce(function()
            applyLocaleStrings("deferred")
            h.displayName = Text.key("TXT_KEY_CIVVACCESS_SCREEN_GAME_SETUP")
        end)
    end,
})

-- Sentinel: the include bridge in GameSetupScreen.lua wraps this include in
-- pcall to protect sighted players from any error. Publishing this flag lets
-- the bridge distinguish "wired" from "loaded but did nothing" (guard fired
-- or BaseMenu.install failed) and log accordingly.
VPSetupAccess_Installed = true
Log.info("[vp-compat] VP game setup screen wired")
