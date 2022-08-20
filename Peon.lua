local Peon = CreateFrame('Frame', 'WorkWorkPeon', UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)

function Peon:Init()
	self:SetScript('OnEvent', function(self, event, ...)
        self[event](self, ...)
    end)
	self.isPaused = false
	self.isOn = false
	self:SetFrameStrata("HIGH")
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag('LeftButton')
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	self:SetSize(WORK_WIDTH - 11, WORK_HEIGHT)
	self:SetToplevel(true)
	if not self:IsUserPlaced() then
		self:SetPoint('CENTER')
	end
	self:Hide()

	local peon = self
	local workList = CreateWorkList(self)
	workList:SetScript('OnWorksUpdate', function()
		local count = workList:GetWorksCount()
		if count == 0 then
			peon:Hide()
		else
			peon:Show()
		end
	end)
	self.workList = workList

	-- ToggleWorkListButton
	local toggleWorkListButtonBG = CreateFrame('Button', nil, self, 'UIPanelButtonTemplate')
	toggleWorkListButtonBG:SetPoint('TOPRIGHT', workList.frame, 'TOPRIGHT', 20, -10)
	toggleWorkListButtonBG:SetSize(20, 20)
	toggleWorkListButtonBG:SetFrameLevel(9999 - 1)

	local toggleWorkListButton = CreateFrame('Button', nil, self, '')
	toggleWorkListButton:SetPoint('CENTER', toggleWorkListButtonBG, 0, -0.5)
	toggleWorkListButton:SetSize(25, 25)
	toggleWorkListButton:SetNormalTexture('Interface\\Buttons\\UI-Panel-CollapseButton-Up')
	toggleWorkListButton:SetPushedTexture('Interface\\Buttons\\UI-Panel-CollapseButton-Down')
	toggleWorkListButton:SetScript('OnClick', function()
		peon:ToggleWorkList()
	end)
	self.toggleWorkListButton = toggleWorkListButton
	self:ToggleWorkList(WorkWork.charConfigs.isWorkListCollaged)

	if WorkWork.isDebug then
		-- workList:TryAdd('Iina', nil, 'wtb theramore port', self)
		-- workList:TryAdd('Iina', nil, 'WTB fiery', self)
		-- C_Timer.After(5, function()
		-- 	workList:ManualyAdd('Iina', 'prospecting', self)
		-- end)

		WorkWorkMinimapButton:OnClick()
	end

	-- Hook UnitPopup
	UnitPopupButtons['ADD_WORK'] = { text = 'Add Work', dist = 0, nested = 1 }
	UnitPopupButtons['PORTAL_WORK'] = { text = 'Portal', dist = 0, icon = 'Interface\\ICONS\\Spell_Arcane_PortalShattrath' }
	UnitPopupButtons['ENCHANT_WORK'] = { text = 'Enchant', dist = 0, icon = 135913 }
	UnitPopupButtons['PROSPECTING_WORK'] = { text = 'Prospecting', dist = 0, icon = 134081 }
	UnitPopupMenus['ADD_WORK'] = { 'PORTAL_WORK', 'ENCHANT_WORK', 'PROSPECTING_WORK'}

	-- DEBUG
	if WorkWork.isDebug then
		table.insert(UnitPopupMenus['SELF'], 1, 'ADD_WORK')
	end

	-- PARTY
	local index = table.indexOf(UnitPopupMenus['PARTY'], 'ADD_FRIEND') + 2
	table.insert(UnitPopupMenus['PARTY'], index, 'ADD_WORK')

	-- RAID_PLAYER
	local index = table.indexOf(UnitPopupMenus['RAID_PLAYER'], 'ADD_FRIEND') + 2
	table.insert(UnitPopupMenus['RAID_PLAYER'], index, 'ADD_WORK')

	-- PLAYER
	local index = table.indexOf(UnitPopupMenus['PLAYER'], 'ADD_FRIEND') + 2
	table.insert(UnitPopupMenus['PLAYER'], index, 'ADD_WORK')

	-- FRIEND
	local index = table.indexOf(UnitPopupMenus['FRIEND'], 'TARGET') + 2
	table.insert(UnitPopupMenus['FRIEND'], index, 'ADD_WORK')

	hooksecurefunc('UnitPopup_OnClick', function(...)
		peon:UnitPopupOnClickCalled(...)
	end)
end

function Peon:On()
	self.isPaused = false
	self.isOn = true
    self:RegisterEvent('CHAT_MSG_SAY')
    self:RegisterEvent('CHAT_MSG_YELL')
    self:RegisterEvent('CHAT_MSG_WHISPER')
	self:RegisterEvent('CHAT_MSG_CHANNEL')
end

function Peon:Off()
	self.isOn = false
    self:UnregisterEvent('CHAT_MSG_SAY')
    self:UnregisterEvent('CHAT_MSG_YELL')
    self:UnregisterEvent('CHAT_MSG_WHISPER')
	self:UnregisterEvent('CHAT_MSG_CHANNEL')
end

function Peon:Toggle()
	self.isOn = not self.isOn
	if self.isOn then
		self:On()
	else
		self:Off()
	end
end

function Peon:ToggleWorkList(isCollaged)
	local configs = WorkWork.charConfigs
	if isCollaged == nil then
		isCollaged = not configs.isWorkListCollaged
	end

	local degree = isCollaged and 90 or -90
	local rotation = math.rad(degree)
	self.toggleWorkListButton:GetNormalTexture():SetRotation(rotation)
	self.toggleWorkListButton:GetPushedTexture():SetRotation(rotation)
	configs.isWorkListCollaged = isCollaged

 	if not isCollaged then
		self.workList:Show()
	else
		self.workList:Hide()
	end
	self.toggleWorkListButton:SetFrameLevel(9999)
end

function Peon:UnitPopupOnClickCalled(dropdownMenu)
	local dropdownFrame = UIDROPDOWNMENU_INIT_MENU
	local button = dropdownMenu.value
	local targetName = dropdownFrame.name

	if button == 'PORTAL_WORK' then
		self.workList:ManualyAdd(targetName, 'portal', self)
		return
	end

	if button == 'ENCHANT_WORK' then
		self.workList:ManualyAdd(targetName, 'enchant', self)
		return
	end

	if button == 'PROSPECTING_WORK' then
		self.workList:ManualyAdd(targetName, 'prospecting', self)
		return
	end
end

-- EVENTS
function Peon:CHAT_MSG_SAY(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function Peon:CHAT_MSG_YELL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function Peon:CHAT_MSG_WHISPER(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function Peon:CHAT_MSG_CHANNEL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	if zoneChannelID ~= 2 then
		return
	end
    self:OnChat(playerName2, guid, text)
end

function Peon:OnChat(playerName, guid, text)
	self.workList:TryAdd(playerName, guid, text, self)
end
