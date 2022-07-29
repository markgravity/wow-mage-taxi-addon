local PortalWork = CreateFrame('Frame', 'WorkWorkPortalWork', UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
WorkWork.portalWork = PortalWork

function PortalWork:Dectect(playerName, guid, message)
	if playerName == UnitName('player') then
        return nil
    end

    local _, playerClass = GetPlayerInfoByGUID(guid)
    if playerClass == 'MAGE' then
        return nil
    end

	local message = string.lower(message)
    if message:match('port') == nil and message:match('portal') == nil then
		return false
	end


	for _, portal in ipairs(WorkWork.portals) do
		for _, keyword in ipairs(portal.keywords) do
			if message:match('to '..keyword) ~= nil
				or message:match('port '..keyword)
				or message:match(keyword..' port') then
				return true
			end
		end
	end
    return false
end

function PortalWork:DrawUIs()
	self.isAutoInvite = true
	self:SetState('INITIALIZED')
	self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	self:RegisterEvent('CHAT_MSG_SYSTEM')
	self:RegisterEvent('ZONE_CHANGED_NEW_AREA')

	if not self:IsUserPlaced() then
		self:SetPoint('CENTER')
	end
	self:SetSize(210, 400)
	self:SetBackdrop(BACKDROP_DIALOG_32_32)
	self:SetMovable(true)
	self:EnableMouse(true)
	self:SetUserPlaced(true)
	self:RegisterForDrag('LeftButton')
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)

    local header = self:CreateTexture('$parentHeader', 'OVERLAY')
    header:SetPoint('TOP', 0, 12)
    header:SetTexture(131080) -- 'Interface\\DialogFrame\\UI-DialogBox-Header'
    header:SetSize(290, 64)

    local headerText = self:CreateFontString('$parentHeaderText', 'OVERLAY', 'GameFontNormal')
    headerText:SetPoint('TOP', header, 0, -14)
    headerText:SetText('Portal')

	local divider = self:CreateTexture(nil, 'OVERLAY')
	divider:SetPoint('TOP', 0, -139)
	divider:SetPoint('LEFT', 10, 0)
	divider:SetPoint('RIGHT', 52, 0)
    divider:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Divider')
	self.divider = divider

	local background = self:CreateTexture(nil, 'ARTWORK')
    background:SetPoint('TOPLEFT', 11, -11)
    background:SetWidth(257)
    background:SetHeight(138)
    background:SetTexture('Interface\\PaperDollInfoFrame\\UI-Character-Reputation-DetailBackground')

	local portrait = CreateFrame('Button', nil, self, 'ActionButtonTemplate')
	portrait:SetHeight(40)
	portrait:SetWidth(40)
	portrait:SetPoint('TOPLEFT', 32, -36)
	portrait:SetEnabled(false)
	self.portrait = portrait

	local targetNameText = self:CreateFontString()
	targetNameText:SetFontObject('GameFontNormal')
	targetNameText:ClearAllPoints()
	targetNameText:SetPoint('LEFT', portrait, 'RIGHT', 10, 8)
	self.targetNameText = targetNameText

	local toText = self:CreateFontString()
	toText:SetFontObject('GameFontNormal')
	toText:SetTextColor(0.7, 0.7, 0.7)
	toText:SetText('port to')
	toText:ClearAllPoints()
	toText:SetPoint('TOPLEFT', targetNameText, 'BOTTOMLEFT', 0, -8)

	local portalText = self:CreateFontString()
	portalText:SetFontObject('GameFontNormal')
	portalText:SetTextColor(1, 1, 1)
	portalText:ClearAllPoints()
	portalText:SetPoint('TOPLEFT', toText, 'TOPRIGHT', 4, 0)
	self.portalText = portalText

	local messageText = self:CreateFontString()
	messageText:SetFontObject('GameFontNormalSmall')
	messageText:SetTextColor(0.75, 0.75, 0.75)
	messageText:ClearAllPoints()
	messageText:SetPoint('TOP', portrait, 'BOTTOM', 0, -8)
	messageText:SetPoint('LEFT', 20, 0)
	messageText:SetPoint('RIGHT', -20, 0)
	self.messageText = messageText

	local endButton = CreateFrame('Button', nil, self, 'GameMenuButtonTemplate')
	endButton:SetSize(64, 24)
	endButton:ClearAllPoints()
	endButton:SetPoint('TOP', self, 'TOP', 0, -110)
	endButton:SetText('End')
	endButton:SetScript('OnClick', function(self)
		PortalWork.job = nil
		PortalWork:SetState('ENDED')
		PortalWork:Hide()
		WorkWork:Resume()
		LeaveParty()
	end)
	self.endButton = endButton

	-- Create tasks
	self.contactTask = CreateWorkTask(self, 'Contact', nil)
	self.contactTask:SetPoint('TOP', divider, 'BOTTOM', 0, 16)
	self.moveTask = CreateWorkTask(self, 'Move', nil, self.contactTask)
	self.makeTask = CreateWorkTask(self, 'Make', nil, self.moveTask)
	self.finishTask = CreateWorkTask(self, 'Finish', nil, self.makeTask)

	self.moveTask:HookScript('OnClick', function(self)
		PortalWork:SetState('CREATING_PORTAL')
	end)

    self:SetScript('OnEvent', function(self, event, ...)
        self[event](self, ...)
    end)

end

function PortalWork:SetWork(targetName, message, portal)
	PlaySound(5274)
	FlashClientIcon()

	local job = {
		targetName = targetName,
		sellingPortal = portal
	}

	self.job = job
	self:SetState('SETTED_JOB')

	local texture = GetSpellTexture(portal.portalSpellID)
	getglobal(self:GetName() .. "Icon"):SetTexture(texture)

	self.targetNameText:SetText(targetName)
	self.portalText:SetText(portal.name)
	self.messageText:SetText('"'..message..'"')

	-- Config tasks
	self.contactTask:SetScript('OnClick', function(self)
		PortalWork:SetState('WAITING_FOR_INVITE_RESPONSE')
		InviteUnit(job.targetName)
	end)
	self.contactTask:SetDescription('|c60808080Invite |r|cffffd100'..job.targetName..'|r|c60808080 into the party|r')

	self.moveTask:SetDescription('|c60808080Waiting for contact|r')

	self.makeTask:SetSpell(job.sellingPortal.portalSpellName)
	self.makeTask:SetDescription('|c60808080Create a |r|cffffd100'..job.sellingPortal.name..'|r|c60808080 portal|r')
	self.makeTask:HookScript('OnClick', function(self)
		PortalWork:SetState('CREATING_PORTAL')
	end)

	self.finishTask:SetDescription('|c60808080Waiting for |r|cffffd100'..job.targetName..'|r|c60808080 to enter the portal|r')

	self.contactTask:Disable()
	self.moveTask:Disable()
	self.makeTask:Disable()
	self.finishTask:Disable(true)

	self.contactTask:Enable()
	if self.isAutoInvite then
		self.contactTask:Run()
	end
end

function PortalWork:SetState(state)
	self.state = state
end

function PortalWork:CompleteContactTask()
	self.contactTask:Complete()
	self:SetState("INVITED_PLAYER")
	C_Timer.After(1, function() PortalWork:DetectTargetZone() end)
end

function PortalWork:SendWho(command)
	C_FriendList.SetWhoToUi(true)
	FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
	C_FriendList.SendWho(command);
end

function PortalWork:FindPortal(zoneName)
	for _, portal in ipairs(WorkWork.portals) do
		if portal.zoneName == zoneName then
			return portal
		end
	end
	return nil
end

function PortalWork:DetectTargetZone()
	local targetZone = GetPartyMemberZone(self.job.targetName)
	local playerZone = GetRealZoneText()

	if playerZone == targetZone then
		self:SetState('MOVED_TO_PLAYER_ZONE')
		self.moveTask:Complete()
		self.makeTask:Enable()
		return
	end

	local portal = self:FindPortal(targetZone)
	if portal == nil then
		self:SetState('MOVING_TO_PLAYER_ZONE')
		self.moveTask:SetDescription('|c60808080Move to |r|cffffd100'..targetZone..'|r|c60808080 manually|r')
		return
	end

	self.job.movingPortal = portal
	self.moveTask:SetSpell(portal.teleportSpellName)
	self.moveTask:HookScript('OnClick', function(self)
		self:SetState('MOVING_TO_PLAYER_ZONE')
	end)
	self.moveTask:SetDescription('|c60808080Teleport to |r|cffffd100'..portal.name..'|r')
	self.moveTask:Enable()
end

function PortalWork:WaitingForTargetEnterPortal()
	local targetZone = GetPartyMemberZone(self.job.targetName)
	if targetZone ~= self.job.sellingPortal.zoneName then
		C_Timer.After(1, function() PortalWork:WaitingForTargetEnterPortal() end)
		return
	end
	self.endButton:Click()
end

-- EVENTS
function PortalWork:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
	if self.state == 'CREATING_PORTAL'
		and spellID == self.job.sellingPortal.portalSpellID then
		self.makeTask:Complete()
		self:SetState('WAITING_FOR_PLAYER_ENTER_PORTAL')
		self.finishTask:Enable()
		self:WaitingForTargetEnterPortal()
		return
	end

	if self.state == 'MOVING_TO_PLAYER_ZONE'
		and spellID == self.job.movingPortal.teleportSpellID then
		self.moveTask:Complete()
		self:SetState('MOVED_TO_PLAYER_ZONE')
		self.makeTask:Enable()
		return
	end
end

function PortalWork:CHAT_MSG_SYSTEM(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	if self.state == 'WAITING_FOR_INVITE_RESPONSE' then
		if text == self.job.targetName..' is already in a group.' then
			SendChatMessage(
				"Hey, please invite me for a portal to "..self.job.sellingPortal.name ,
				"WHISPER" ,
				 nil,
				 self.job.targetName
		 	)
			self.contactTask:SetDescription('|c60808080Waiting for |r|cffffd100'..self.job.targetName..'|r|c60808080 invites you into the party|r')
			WorkWorkAutoAcceptInvite:SetEnabled(true, function ()
				self:CompleteContactTask()
			end)
			return
		end

		if text == self.job.targetName..' joins the party.' then
			self:CompleteContactTask()
			return
		end
		return
	end


	if self.state == 'WAITING_FOR_PLAYER_ENTER_PORTAL' then
		if text == 'Your group has been disbanded.' then
			self.endButton:Click()
			return
		end
	end
end

function PortalWork:ZONE_CHANGED_NEW_AREA()
	if self.state == 'MOVING_TO_PLAYER_ZONE' then
		local playerZone = GetRealZoneText()
		local targetZone = GetPartyMemberZone(self.job.targetName)

		if playerZone == targetZone then
			self.moveTask:Complete()
			self.SetState('MOVED_TO_PLAYER_ZONE')
			self.makeTask:Enable()
		end
	end
end
