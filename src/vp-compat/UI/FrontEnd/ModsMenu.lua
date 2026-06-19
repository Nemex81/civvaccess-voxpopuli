-- ModsMenu.lua
-- VP-compat override of the Mods Menu screen.
--
-- This file supersedes both the base-game Assets/UI/FrontEnd/Modding/ModsMenu.lua
-- and the Civ-V-Access DLC version via mod import flag (import="1"). The body
-- above the bootstrap marker is a verbatim copy of the base-game content as
-- preserved in Civ-V-Access src/dlc/UI/FrontEnd/ModsMenu.lua.
--
-- The Civ-V-Access accessibility bootstrap (include("CivVAccess_ModsMenuAccess"))
-- is replaced with a VP-compat pcall bridge that loads
-- CivVAccess_VP_ModsMenuAccess, which adds a hard guard preventing a native
-- crash when VP_LUAAPI reloads in an inconsistent state.
--
-- RE-SYNC: if Civ-V-Access updates ModsMenu.lua, replace the verbatim section
-- below (everything above the bootstrap marker) and recompute the MD5 in
-- CivVAccess_VoxPopuli.modinfo.
--
-- Reference: Civ-V-Access src/dlc/UI/FrontEnd/ModsMenu.lua
-- Source MD5 (Civ-V-Access verbatim body): see modinfo entry for this file.
----------------------------------------------------
-- Mods Menu
----------------------------------------------------
include( "InstanceManager" );


g_InstanceManager = InstanceManager:new( "ModInstance", "Label", Controls.ModsStack );


--------------------------------------------------
-- Navigation Routines (Installed,Online,Back)
--------------------------------------------------
function NavigateBack()
	UIManager:SetUICursor( 1 );
	Modding.DeactivateMods();
	UIManager:DequeuePopup( ContextPtr );
	UIManager:SetUICursor( 0 );
	
	Events.SystemUpdateUI( SystemUpdateUIType.RestoreUI, "ModsBrowserReset" );
end

----------------------------------------------------
-- UI Event Handlers
----------------------------------------------------
function OnSinglePlayerClick()
	UIManager:QueuePopup( Controls.ModdingSinglePlayer, PopupPriority.ModdingSinglePlayer );
end
Controls.SinglePlayerButton:RegisterCallback(Mouse.eLClick, OnSinglePlayerClick);
----------------------------------------------------
function OnMultiPlayerClick()
	UIManager:QueuePopup( Controls.ModdingMultiplayer, PopupPriority.ModMultiplayerSelectScreen );
end
Controls.MultiPlayerButton:RegisterCallback(Mouse.eLClick, OnMultiPlayerClick);
----------------------------------------------------------------------
Controls.BackButton:RegisterCallback(Mouse.eLClick, NavigateBack);


--------------------------------------------------
-- Show/Hide Handler
--------------------------------------------------
ContextPtr:SetShowHideHandler(function(isHiding)
	if(not isHiding) then
		local supportsSinglePlayer = Modding.AllEnabledModsContainPropertyValue("SupportsSinglePlayer", 1);
		local supportsMultiplayer = Modding.AllEnabledModsContainPropertyValue("SupportsMultiplayer", 1);
		
		Controls.SinglePlayerButton:SetDisabled(not supportsSinglePlayer);
		Controls.MultiPlayerButton:SetDisabled(not supportsMultiplayer);
		
		--if(supportsSinglePlayer and not supportsMultiplayer) then
			--OnSinglePlayerClick();
		--elseif(supportsMultiplayer and not supportsSinglePlayer) then
			--OnMultiPlayerClick();
		--end
		
		g_InstanceManager:ResetInstances();
		
		local mods = Modding.GetEnabledModsByActivationOrder();
		
		if(#mods == 0) then
			Controls.ModsInUseLabel:SetHide(true);
		else
			Controls.ModsInUseLabel:SetHide(false);
			for i,v in ipairs(mods) do
				local displayName = Modding.GetModProperty(v.ModID, v.Version, "Name");
				local displayNameVersion = string.format("[ICON_BULLET] %s (v. %i)", displayName, v.Version);			
				local listing = g_InstanceManager:GetInstance();
				listing.Label:SetText(displayNameVersion);
				listing.Label:SetToolTipString(displayNameVersion);
			end
		end
	end
end);
--------------------------------------------------
-- Input Handler
--------------------------------------------------
ContextPtr:SetInputHandler( function(uiMsg, wParam, lParam)

	if uiMsg == KeyEvents.KeyDown then
		if wParam == Keys.VK_ESCAPE then
			NavigateBack();
		end
	end

	return true;
end);

Controls.MultiPlayerButton:SetHide(true);


-- vp-compat accessibility bridge
-- Loaded via pcall: never crashes the screen for sighted players.
-- If CVA front-end modules are unavailable, the wrapper hard-guards itself
-- and exits before installing handlers (CivVAccessVP_ModsMenuAccess_Installed
-- remains nil / not true).
do
    local ok, err = pcall(function()
        include("CivVAccess_VP_ModsMenuAccess")
    end)
    if not ok then
        if print ~= nil then
            print("[vp-compat] CivVAccess VP ModsMenu bootstrap error: " .. tostring(err))
        end
    elseif CivVAccessVP_ModsMenuAccess_Installed ~= true then
        if print ~= nil then
            print("[vp-compat] CivVAccess VP ModsMenu: wrapper not installed (silent skip)")
        end
    end
end
