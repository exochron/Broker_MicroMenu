-- Broker_MicroMenu by yess
local ldb = LibStub:GetLibrary("LibDataBroker-1.1",true)
local L = LibStub("AceLocale-3.0"):GetLocale("Broker_MicroMenu")

local _G, floor, string, GetNetStats, GetFramerate  = _G, floor, string, GetNetStats, GetFramerate
local delay, counter = 1,0
local dataobj, db
local _
local addonName = Broker_MicroMenuEmbeddedName or "Broker_MicroMenu"
local path = Broker_MicroMenuEmbeddedPath or "Interface\\AddOns\\Broker_MicroMenu\\media\\"

local function Debug(...)
	--@debug@
	local s = addonName.." Debug:"
	for i=1,_G.select("#", ...) do
		local x = _G.select(i, ...)
		s = _G.strjoin(" ",s,_G.tostring(x))
	end
	_G.DEFAULT_CHAT_FRAME:AddMessage(s)
	--@end-debug@
end

local function RGBToHex(r, g, b)
	return ("%02x%02x%02x"):format(r*255, g*255, b*255)
end

local mb = _G.MainMenuMicroButton:GetScript("OnMouseUp")
local function mainmenu(self, ...) self.down = 1; mb(self, ...) end

dataobj = ldb:NewDataObject(addonName, {
	type = "data source",
	icon = path.."green.tga",
	label = "MicroMenu",
	text  = "",
	OnClick = function(self, button, ...)
		if button == "RightButton" then
			if _G.IsModifierKeyDown() then
				mainmenu(self, button, ...)
			else
				dataobj:OpenOptions()
			end
		else
			_G.ToggleCharacter("PaperDollFrame")
		end
	end
})

-------------------------

function dataobj:UpdateText()
	local fps = floor(GetFramerate())
	local _, _, latencyHome, latencyWorld = GetNetStats()

    local colorGood = "|cff00ff00"
	local fpsColor, colorHome, colorWorld = "", "", ""
	if db.enableColoring then
		if fps > 30 then
			fpsColor = colorGood
		elseif fps > 20 then
			fpsColor = "|cffffd200"
		else
			fpsColor = "|cffdd3a00"
		end
		if latencyHome < 300 then
			colorHome = colorGood
		elseif latencyHome < 500 then
			colorHome = "|cffffd200"
		else
			colorHome = "|cffdd3a00"
		end
		if latencyWorld < 300 then
			colorWorld = colorGood
			dataobj.icon = path.."green.tga"
		elseif latencyWorld < 500 then
			colorWorld = "|cffffd200"
			dataobj.icon = path.."yellow.tga"
		else
			colorWorld = "|cffdd3a00"
			dataobj.icon = path.."red.tga"
		end
	end

	if db.customTextSetting then
		local lw_string = colorWorld..latencyWorld.."|r"
		local lh_string = colorHome..latencyHome.."|r"
		local fps_string = fpsColor..fps.."|r"
		local text = string.gsub(string.gsub(string.gsub(db.textOutput, "{fps}", (fps_string or "fps")), "{lw}", (lw_string or "lw")), "{lh}", (lh_string or "lh"))
		dataobj.text = text
	else
		local text = ""
		if db.showWorldLatency then
			text = string.format("%s%i|r %s ", colorWorld, latencyWorld, _G.MILLISECONDS_ABBR)
		end
		if db.showHomeLatency then
			text = string.format("%s%s%i|r %s ", text, colorHome, latencyHome, _G.MILLISECONDS_ABBR)
		end
		if db.showFPS then
			if db.fpsFirst then
				dataobj.text = string.format("%s%i|r %s %s", fpsColor, fps , L["fps"], text)
			else
				dataobj.text = string.format("%s%s%i|r fps", text, fpsColor, fps )
			end
		else
			dataobj.text = text
		end
	end
end

local menu

function dataobj:OnEnter()

	local generator = function(owner, root)
		root:SetTag(addonName);

		local microbuttons = { -- or see MICRO_BUTTONS
			"CharacterMicroButton",
			"ProfessionMicroButton",
			"PlayerSpellsMicroButton",
			"AchievementMicroButton",
			"QuestLogMicroButton",
			"GuildMicroButton",
			"LFDMicroButton",
			"EJMicroButton",
			"CollectionsMicroButton",
			"StoreMicroButton",
			"MainMenuMicroButton",
		}

		for _, microButtonName in ipairs(microbuttons) do
			local microButton = _G[microButtonName]
			if microButton and microButton:IsEnabled() then
				local clickhandler = function()
					microButton:GetScript("OnClick")(microButton)
				end
				if microButtonName == "MainMenuMicroButton" then
					clickhandler = mainmenu
				end

				local button = root:CreateButton(microButton.tooltipText, clickhandler)
				button:AddInitializer(function(button)
					local icon = button:AttachTexture()
					icon:SetSize(16, 20)
					icon:SetPoint("LEFT", button, "LEFT")

					if microButton.Portrait then
						_G.SetPortraitTexture(icon, "player")
					else
						icon:SetAtlas("UI-HUD-MicroMenu-"..microButton.textureName.."-Up")
						icon:SetVertexColor(microButton:GetNormalTexture():GetVertexColor())
					end

					if microButton.Emblem then
						local emblem = button:AttachTexture()
						emblem:SetSize(6, 7)
						emblem:SetPoint("CENTER", icon, "CENTER", 0, 1)
						emblem:SetDrawLayer("OVERLAY")
						_G.SetSmallGuildTabardTextures("player", emblem, emblem)
					end

					button.fontString:SetPoint("LEFT", icon, "RIGHT")
				end)
			end
		end

		root:QueueSpacer()

		local function buildCenterButton(text, func)
			local element = root:CreateButton(text, func)
			element:AddInitializer(function(button)
				button.fontString:ClearAllPoints()
				button.fontString:SetPoint("CENTER")
			end)
		end
		buildCenterButton(GAMEMENU_OPTIONS, function()
			SettingsPanel:Open()
		end)
		buildCenterButton(ADDONS, function()
			ShowUIPanel(AddonList)
		end)
		if C_SplashScreen.CanViewSplashScreen() then
			buildCenterButton(GAMEMENU_NEW_BUTTON, function()
				C_SplashScreen.RequestLatestSplashScreen(true)
			end)
		end
		buildCenterButton(HUD_EDIT_MODE_MENU, function()
			ShowUIPanel(EditModeManagerFrame)
		end)
		buildCenterButton(MACROS, function()
			ShowMacroFrame()
		end)
	end

	local elementDescription = MenuUtil.CreateRootMenuDescription(MenuVariants.GetDefaultContextMenuMixin())

	Menu.PopulateDescription(generator, self, elementDescription)

	local anchor = CreateAnchor("TOPLEFT", self, "BOTTOMLEFT", 0, 5)
	menu = Menu.GetManager():OpenMenu(self, elementDescription, anchor)
	menu:SetClosedCallback(function()
		menu = nil
	end)
	menu:HookScript("OnLeave", function()
		if not menu:IsMouseOver() then
			menu:Close()
		end
	end)
end

function dataobj:OnLeave(...)
	if menu and not menu:IsMouseOver() then
		menu:Close()
	end
end

function dataobj:SetDB(database)
	db = database
end

local function OnUpdate(self, elapsed)
	counter = counter + elapsed
	if counter >= delay then
		dataobj:UpdateText()
		counter = 0
	end
end

local frame = CreateFrame("Frame")
local function OnEnterWorld(self)
	dataobj:RegisterOptions()
	frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
end


frame:SetScript("OnUpdate", OnUpdate)
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", OnEnterWorld)

