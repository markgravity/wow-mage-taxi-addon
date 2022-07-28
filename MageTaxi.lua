local AceEvent = LibStub('AceEvent-3.0')

MageTaxi = CreateFrame('Frame', nil, UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
MageTaxiAddon = LibStub('AceAddon-3.0'):NewAddon('MageTaxi', 'AceConsole-3.0')
function MageTaxiAddon:OnInitialize()
	MageTaxi:Init()
	MinimapButton:Init()
end

function MageTaxi:Init()
	self:SetScript('OnEvent', function(self, event, ...)
        self[event](self, ...)
    end)

	self.isPaused = false
	self.isOn = false

	self.taskList:DrawUIs()
	self.taskList:Hide()

	self.taskList:Show()
	self.taskList:SetJob('Iina', 'text', self.portals[1])
	-- self:On()
end

function MageTaxi:On()
	self.isPaused = false
	self.isOn = true
    self:RegisterEvent('CHAT_MSG_SAY')
    self:RegisterEvent('CHAT_MSG_YELL')
    self:RegisterEvent('CHAT_MSG_WHISPER')
	self:RegisterEvent('CHAT_MSG_CHANNEL')
end

function MageTaxi:Off()
	self.isOn = false
    self:UnregisterEvent('CHAT_MSG_SAY')
    self:UnregisterEvent('CHAT_MSG_YELL')
    self:UnregisterEvent('CHAT_MSG_WHISPER')
	self:UnregisterEvent('CHAT_MSG_CHANNEL')
end

function MageTaxi:Toggle()
	self.isOn = not self.isOn
	if self.isOn then
		self:On()
	else
		self:Off()
	end
end

function MageTaxi:Pause()
    self.isPaused = true
end

function MageTaxi:Resume()
    self.isPaused = false
end

function MageTaxi:CHAT_MSG_SAY(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function MageTaxi:CHAT_MSG_YELL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function MageTaxi:CHAT_MSG_WHISPER(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
    self:OnChat(playerName2, guid, text)
end

function MageTaxi:CHAT_MSG_CHANNEL(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	if zoneChannelID ~= 2 then
		return
	end
    self:OnChat(playerName2, guid, text)
end

function MageTaxi:FindPortal(playerName, guid, message)
    -- if playerName == UnitName('player') then
    --     return nil
    -- end
	--
    -- local _, playerClass = GetPlayerInfoByGUID(guid)
    -- if playerClass == 'MAGE' then
    --     return nil
    -- end

	local message = string.lower(message)
    if message:match('port') == nil and message:match('portal') == nil then
		return nil
	end


	for _, portal in ipairs(self.portals) do
		for _, keyword in ipairs(portal.keywords) do
			if message:match('to '..keyword) ~= nil then
				return portal
			end
		end
	end
    return nil
end


function MageTaxi:OnChat(playerName, guid, text)
	if self.isPaused then
		return
	end

	local portal = self:FindPortal(playerName, guid, text)
    if portal == nil then
        return
    end

	if not IsSpellKnown(portal.portalSpellID) then
		return
	end

	self.job = {
		portal = portal
	}

	self:Pause()
	self.taskList:Show()
	self.taskList:SetJob(playerName, text, portal)
end
