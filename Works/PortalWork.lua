local PortalWork = {}
PortalWork.__index = PortalWork

function CreatePortalWork(targetName, message, portal)
	local job = {
		targetName = targetName,
		sellingPortal = portal
	}
	local work = {}
	setmetatable(work, PortalWork)
	work.isAutoInvite = true
	work.job = job
	work:SetState('INITIALIZED')

	local frame = CreateFrame('Frame', 'WorkWorkPortalWork'..targetName, UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
	frame:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
	frame:RegisterEvent('ZONE_CHANGED_NEW_AREA')

	if not frame:IsUserPlaced() then
		frame:SetPoint('CENTER')
	end
	frame:SetSize(210, 400)
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetUserPlaced(true)
	frame:RegisterForDrag('LeftButton')
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	work.frame = frame

    local header = frame:CreateTexture('$parentHeader', 'OVERLAY')
    header:SetPoint('TOP', 0, 12)
    header:SetTexture(131080) -- 'Interface\\DialogFrame\\UI-DialogBox-Header'
    header:SetSize(290, 64)

    local headerText = frame:CreateFontString('$parentHeaderText', 'OVERLAY', 'GameFontNormal')
    headerText:SetPoint('TOP', header, 0, -14)
    headerText:SetText('Portal')

	local divider = frame:CreateTexture(nil, 'OVERLAY')
	divider:SetPoint('TOP', 0, -139)
	divider:SetPoint('LEFT', 10, 0)
	divider:SetPoint('RIGHT', 52, 0)
    divider:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Divider')
	work.divider = divider

	local background = frame:CreateTexture(nil, 'ARTWORK')
    background:SetPoint('TOPLEFT', 11, -11)
    background:SetWidth(257)
    background:SetHeight(138)
    background:SetTexture('Interface\\PaperDollInfoFrame\\UI-Character-Reputation-DetailBackground')

	local portrait = CreateFrame('Button', nil, frame, 'ActionButtonTemplate')
	portrait:SetHeight(40)
	portrait:SetWidth(40)
	portrait:SetPoint('TOPLEFT', 32, -36)
	portrait:SetEnabled(false)

	local texture = GetSpellTexture(portal.portalSpellID)
	getglobal(frame:GetName() .. "Icon"):SetTexture(texture)

	local targetNameText = frame:CreateFontString()
	targetNameText:SetFontObject('GameFontNormal')
	targetNameText:ClearAllPoints()
	targetNameText:SetPoint('LEFT', portrait, 'RIGHT', 10, 8)
	targetNameText:SetText(targetName)

	local toText = frame:CreateFontString()
	toText:SetFontObject('GameFontNormal')
	toText:SetTextColor(0.7, 0.7, 0.7)
	toText:SetText('port to')
	toText:ClearAllPoints()
	toText:SetPoint('TOPLEFT', targetNameText, 'BOTTOMLEFT', 0, -8)

	local portalText = frame:CreateFontString()
	portalText:SetFontObject('GameFontNormal')
	portalText:SetTextColor(1, 1, 1)
	portalText:ClearAllPoints()
	portalText:SetPoint('TOPLEFT', toText, 'TOPRIGHT', 4, 0)
	portalText:SetText(portal.name)

	local messageText = frame:CreateFontString()
	messageText:SetFontObject('GameFontNormalSmall')
	messageText:SetTextColor(0.75, 0.75, 0.75)
	messageText:ClearAllPoints()
	messageText:SetPoint('TOP', portrait, 'BOTTOM', 0, -8)
	messageText:SetPoint('LEFT', 20, 0)
	messageText:SetPoint('RIGHT', -20, 0)
	messageText:SetText('"'..message..'"')

	local endButton = CreateFrame('Button', nil, frame, 'GameMenuButtonTemplate')
	endButton:SetSize(64, 24)
	endButton:ClearAllPoints()
	endButton:SetPoint('TOP', frame, 'TOP', 0, -110)
	endButton:SetText('End')
	endButton:SetScript('OnClick', function(self)
		PortalWork.job = nil
		PortalWork:SetState('ENDED')
		PortalWork:Hide()
		WorkWork:Resume()
		LeaveParty()
	end)
	work.endButton = endButton

	-- Create tasks
	work.contactTask = CreateWorkTask(frame, 'Contact', '|c60808080Invite |r|cffffd100'..job.targetName..'|r|c60808080 into the party|r')
	work.contactTask:SetScript('OnClick', function(self)
		PortalWork:SetState('WAITING_FOR_INVITE_RESPONSE')
		InviteUnit(job.targetName)
	end)
	work.contactTask:SetPoint('TOP', divider, 'BOTTOM', 0, 16)

	work.moveTask = CreateWorkTask(frame, 'Move', '|c60808080Waiting for contact|r', work.contactTask)
	work.moveTask:HookScript('OnClick', function(self)
		work:SetState('CREATING_PORTAL')
	end)

	work.makeTask = CreateWorkTask(frame, 'Make', '|c60808080Create a |r|cffffd100'..job.sellingPortal.name..'|r|c60808080 portal|r', work.moveTask)
	work.makeTask:SetSpell(job.sellingPortal.portalSpellName)
	work.makeTask:HookScript('OnClick', function(self)
		PortalWork:SetState('CREATING_PORTAL')
	end)

	work.finishTask = CreateWorkTask(frame, 'Finish', '|c60808080Waiting for |r|cffffd100'..job.targetName..'|r|c60808080 to enter the portal|r', work.makeTask)

	work.moveTask:Disable()
	work.makeTask:Disable()
	work.finishTask:Disable(true)
	work.contactTask:Enable()

	if work.isAutoInvite then
		work.contactTask:Run()
	end

    frame:SetScript('OnEvent', function(self, event, ...)
        work[event](work, ...)
    end)

	return work
end

function DetectPortalWork(playerName, guid, message)
	if playerName == UnitName('player') then
        return nil
    end

    local _, playerClass = GetPlayerInfoByGUID(guid)
    if playerClass == 'MAGE' then
        return nil
    end

	local message = string.lower(message)
    if message:match('port') == nil and message:match('portal') == nil then
		return nil
	end


	for _, portal in ipairs(WorkWork.portals) do
		for _, keyword in ipairs(portal.keywords) do
			if message:match('to '..keyword) ~= nil
				or message:match('port '..keyword)
				or message:match(keyword..' port') then
				if not IsSpellKnown(portal.portalSpellID) then
					return nil
				end
				return CreatePortalWork(playerName, message, portal)
			end
		end
	end
    return nil
end

function PortalWork:Start()
	PlaySound(5274)
	FlashClientIcon()
	self.frame:Show()
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
