-- CivVAccess_VP_ModsMenuAccess.lua
-- VP-compat accessibility wrapper for ModsMenu (Mods → play options screen).
--
-- Loaded from the bottom of src/vp-compat/UI/FrontEnd/ModsMenu.lua via a
-- pcall bootstrap. Runs in the same Lua Context as ModsMenu.lua, so every
-- ModsMenu global (NavigateBack, OnSinglePlayerClick, OnMultiPlayerClick,
-- Controls.*) is directly reachable.
--
-- VP does not override ModsMenu.lua. Civ-V-Access's DLC version is normally
-- the active one. This VP-compat file supplies the same 3-item menu as
-- Civ-V-Access's src/dlc/UI/FrontEnd/CivVAccess_ModsMenuAccess.lua, but adds
-- the hard guard required to prevent a native crash when VP_LUAAPI reloads in
-- an inconsistent state (VPUI_loader.lua failure causes engine objects to be
-- invalidated before the Lua GC collects them).
--
-- Root cause (from Lua.log analysis):
--   VP_LUAAPI: File Error: VPUI_loader.lua
--   VP_LUAAPI: Runtime Error: Error loading VPUI_loader.lua.
--   VP_LUAAPI: New api context created!  ← partial VP reload
--   ModsMenu: HandlerStack.push 'ModsMenu' (depth=1) ← CRASH
-- The crash occurs because BaseMenu.install touches SpeechPipeline or Log
-- objects that VP_LUAAPI invalidated, with no guard protecting the call.
--
-- Pattern source: YnAEMP-Access / YnAEMP_Access_Setup.lua (hard guard before
-- BaseMenu.install so the screen degrades gracefully when CVA modules are nil).
--
-- Files read as reference:
--   Civ-V-Access: src/dlc/UI/FrontEnd/CivVAccess_ModsMenuAccess.lua
--   Civ-V-Access: src/dlc/UI/FrontEnd/ModsMenu.lua
--   Civ-V-Access: src/dlc/UI/FrontEnd/CivVAccess_ModListPreamble.lua
--   Civ-V-Access: src/dlc/UI/FrontEnd/CivVAccess_FrontendCommon.lua
--   YnAEMP-Access: YnAEMP_Access_Setup.lua
--
-- Constraint: does not modify VP, Civ-V-Access, or Community-Patch-DLL files.

include("CivVAccess_FrontendCommon")
include("CivVAccess_ModListPreamble")

-- Hard guard: if the Civ V Access front-end chain did not resolve (DLC not
-- active, or its UISkin not exposing UI/Shared to this Context), bail without
-- touching the screen so VP keeps working for sighted players.
if BaseMenu == nil or BaseMenuItems == nil or SpeechPipeline == nil or Log == nil then
    if print ~= nil then
        print("[vp-compat] CivVAccess_VP_ModsMenuAccess: CVA front-end modules unavailable; ModsMenu not vocalized")
    end
    return
end

Log.info("[vp-compat] CivVAccess_VP_ModsMenuAccess: loaded")

BaseMenu.install(ContextPtr, {
    name = "ModsMenu",
    displayName = Text.key("TXT_KEY_CIVVACCESS_SCREEN_MODS_MENU"),
    preamble = ModListPreamble.fn(),
    priorInput = BaseMenu.escOnlyInput(NavigateBack),
    items = {
        BaseMenuItems.Button({
            controlName = "SinglePlayerButton",
            textKey = "TXT_KEY_MODDING_SINGLE_PLAYER",
            activate = function()
                OnSinglePlayerClick()
            end,
        }),
        BaseMenuItems.Button({
            controlName = "MultiPlayerButton",
            textKey = "TXT_KEY_MODDING_MULTIPLAYER",
            activate = function()
                OnMultiPlayerClick()
            end,
        }),
        BaseMenuItems.Button({
            controlName = "BackButton",
            textKey = "TXT_KEY_MODDING_MENU_BACK",
            activate = function()
                NavigateBack()
            end,
        }),
    },
})

CivVAccessVP_ModsMenuAccess_Installed = true
Log.info("[vp-compat] CivVAccess_VP_ModsMenuAccess: wired")
