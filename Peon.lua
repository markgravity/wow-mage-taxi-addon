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
	self:SetSize(WORK_LIST_WIDTH + WORK_WIDTH - 11, WORK_HEIGHT)
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
	toggleWorkListButtonBG:SetPoint('TOPRIGHT', workList.frame, 'TOPRIGHT', 10, 2)
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
	self:ToggleWorkList(not WorkWork.charConfigs.isWorkListCollaged)

	if WorkWork.isDebug then
		-- workList:TryAdd('Iina', nil, 'wtb theramore port')
		workList:TryAdd('Iina', nil, 'WTB 30 healing to bracer fiery speed to boot greater agility to back')
		WorkWorkMinimapButton:OnClick()
	end
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

function Peon:ToggleWorkList(isShown)
	local configs = WorkWork.charConfigs
	local isShown = isShown or configs.isWorkListCollaged
	local degree = isShown and -90 or 90
	local rotation = math.rad(degree)

	self.toggleWorkListButton:GetNormalTexture():SetRotation(rotation)
	self.toggleWorkListButton:GetPushedTexture():SetRotation(rotation)

	configs.isWorkListCollaged = not isShown
 	if configs.isWorkListCollaged then
		self.workList:Show()
	else
		self.workList:Hide()
	end
	self.toggleWorkListButton:SetFrameLevel(9999)
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
	self.workList:TryAdd(playerName, guid, text)
end
