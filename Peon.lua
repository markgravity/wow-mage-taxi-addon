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
	self:HookUnitPopup()
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

function Peon:HookUnitPopup()
	local peon = self
	local works = WorkWork.works
	local menus = {}

	for type, work in pairs(works) do
		local key = string.upper(type)..'_WORK'
		UnitPopupButtons[key] = {
			text = work.name,
			dist = 0,
			icon = work.icon
		}

		for _, menuKey in ipairs(work.supportedUnitPopupMenus) do
			local menu = menus['ADD_WORK_'..menuKey]
			if menu == nil then
				menu = {}
				menus['ADD_WORK_'..menuKey] = menu
				UnitPopupButtons['ADD_WORK_'..menuKey] = { text = 'Add Work', dist = 0, nested = 1 }
			end
			table.insert(menu, key)
		end
	end

	for key, menu in pairs(menus) do
		UnitPopupMenus[key] = menu

		-- SELF
		if string.find(key, 'SELF') then
			table.insert(UnitPopupMenus['SELF'], 1, key)
		end

		-- PARTY
		if string.find(key, 'PARTY') then
			local index = table.indexOf(UnitPopupMenus['PARTY'], 'ADD_FRIEND') + 2
			table.insert(UnitPopupMenus['PARTY'], index, key)
		end

		-- RAID_PLAYER
		if string.find(key, 'RAID_PLAYER') then
			local index = table.indexOf(UnitPopupMenus['RAID_PLAYER'], 'ADD_FRIEND') + 2
			table.insert(UnitPopupMenus['RAID_PLAYER'], index, key)
		end

		-- PLAYER
		if string.find(key, 'PLAYER') then
			local index = table.indexOf(UnitPopupMenus['PLAYER'], 'ADD_FRIEND') + 2
			table.insert(UnitPopupMenus['PLAYER'], index, key)
		end

		-- FRIEND
		if string.find(key, 'FRIEND') then
			local index = table.indexOf(UnitPopupMenus['FRIEND'], 'TARGET') + 2
			table.insert(UnitPopupMenus['FRIEND'], index, key)
		end
	end

	hooksecurefunc('UnitPopup_OnClick', function(...)
		peon:UnitPopupOnClickCalled(...)
	end)
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
