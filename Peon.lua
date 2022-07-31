local Peon = CreateFrame('Frame', 'WorkWorkPeon', UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)

function Peon:Init()
	self:SetScript('OnEvent', function(self, event, ...)
        self[event](self, ...)
    end)
	self.isPaused = false
	self.isOn = false
	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag('LeftButton')
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	self:SetSize(WORK_LIST_WIDTH + WORK_WIDTH - 11, WORK_HEIGHT)
	if not self:IsUserPlaced() then
		self:SetPoint('CENTER')
	end

	self.workList = CreateWorkList(self)
	self.workList:Hide()
	self.workList:TryAdd('Iina', nil, 'lf port to sw')
	-- self.workList:TryAdd('Iina', nil, 'lf minor speed')
	-- self:On()
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

function Peon:Pause()
    self.isPaused = true
end

function Peon:Resume()
    self.isPaused = false
end

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
	-- print(gsub(text, "\124", "\124\124"))
	if self.isPaused then
		return
	end

	self.workList:TryAdd(playerName, guid, text)
end
