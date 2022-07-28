local TaskList = CreateFrame('Frame', nil, UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
MageTaxi.taskList = TaskList

function TaskList:DrawUIs()
	self.isAutoInvite = true
	self:SetState('INITIALIZED')
	self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	self:RegisterEvent('CHAT_MSG_SYSTEM')
	self:RegisterEvent('WHO_LIST_UPDATE')

	self:SetPoint('CENTER')
	self:SetSize(210, 350)
	self:SetBackdrop(BACKDROP_DIALOG_32_32)
	self:SetMovable(true)
	self:EnableMouse(true)
	self:SetUserPlaced(true)
	self:RegisterForDrag('LeftButton')

	-- local closeButton = CreateFrame('BUTTON', nil, self, 'UIPanelCloseButton');
    -- closeButton:SetPoint('TOPRIGHT', self, 'TOPRIGHT', -4, -4)

    local header = self:CreateTexture('$parentHeader', 'OVERLAY')
    header:SetPoint('TOP', 0, 12)
    header:SetTexture(131080) -- 'Interface\\DialogFrame\\UI-DialogBox-Header'
    header:SetSize(290, 64)

    local headerText = self:CreateFontString('$parentHeaderText', 'OVERLAY', 'GameFontNormal')
    headerText:SetPoint('TOP', header, 0, -14)
    headerText:SetText('MageTaxi')

	local divider = self:CreateTexture(nil, 'OVERLAY')
    divider:SetHeight(32)
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

	local portrait = self:CreateTexture(nil, 'BACKGROUND')
	portrait:SetHeight(40)
	portrait:SetWidth(40)
	portrait:SetPoint('TOPLEFT', 32, -36)
	self.portrait = portrait

	local playerNameText = self:CreateFontString()
	playerNameText:SetFontObject('GameFontNormal')
	playerNameText:ClearAllPoints()
	playerNameText:SetPoint('LEFT', portrait, 'RIGHT', 10, 8)
	self.playerNameText = playerNameText

	local toText = self:CreateFontString()
	toText:SetFontObject('GameFontNormal')
	toText:SetTextColor(0.7, 0.7, 0.7)
	toText:SetText('to')
	toText:ClearAllPoints()
	toText:SetPoint('TOPLEFT', playerNameText, 'BOTTOMLEFT', 0, -8)

	local portalText = self:CreateFontString()
	portalText:SetFontObject('GameFontNormal')
	portalText:SetTextColor(1, 1, 1)
	portalText:ClearAllPoints()
	portalText:SetPoint('TOPLEFT', toText, 'TOPRIGHT', 4, 0)
	self.portalText = portalText

	local messageText = self:CreateFontString()
	messageText:SetFontObject('GameFontNormalSmall')
	messageText:SetTextColor(0.7, 0.7, 0.7)
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
		TaskList.job = nil
		TaskList:SetState('ENDED')
		TaskList:Hide()
		MageTaxi:Resume()
	end)
	self.endButton = endButton

	local inviteTask = self:CreateTask('Invite into group', 'Invite')
	self.inviteTask = inviteTask

	local detectZoneTask = self:CreateTask('Check player zone', 'Detect', inviteTask)
	self.detectZoneTask = detectZoneTask

	local movingTask = self:CreateTask('Move to player zone', 'Teleport', detectZoneTask)
	movingTask.actionButton:SetAttribute('type', 'macro')
	movingTask.actionButton:HookScript('OnClick', function(self)
		TaskList:SetState('CREATING_PORTAL')
	end)
	self.movingTask = movingTask

	local createPortalTask = self:CreateTask('Create the portal', 'Create', movingTask)
	self.createPortalTask = createPortalTask

	local finishTask = self:CreateTask('Waiting for the player enter the portal', nil, createPortalTask)
	self.finishTask = finishTask

    self:SetScript('OnEvent', function(self, event, ...)
        self[event](self, ...)
    end)

end

function TaskList:SetJob(playerName, message, portal)
	PlaySound(5274)
	FlashClientIcon()

	local job = {
		playerName = playerName,
		sellingPortal = portal
	}

	self.job = job
	self:SetState('SETTED_JOB')

	SetPortraitTexture(self.portrait, playerName)
	self.playerNameText:SetText(playerName)
	self.portalText:SetText(portal.name)
	self.messageText:SetText('"'..message..'"')

	self.inviteTask.actionButton:SetScript('OnClick', function(self)
		TaskList:SetState('WAITING_FOR_INVITE_RESPONSE')
		InviteUnit(job.playerName)
	end)

	self.detectZoneTask.actionButton:SetScript('OnClick', function(self)
		TaskList:SetState('WAITING_FOR_DETECT_PLAYER_ZONE')
		TaskList:SendWho('n-"' .. job.playerName .. '"')
	end)

	self.createPortalTask.actionButton:SetAttribute('type', 'macro')
	self.createPortalTask.actionButton:SetAttribute('macrotext', '/cast '..job.sellingPortal.portalSpellName)
	self.createPortalTask.actionButton:HookScript('OnClick', function(self)
		TaskList:SetState('CREATING_PORTAL')
	end)

	self:DisableTask(self.inviteTask)
	self:DisableTask(self.detectZoneTask)
	self:DisableTask(self.movingTask)
	self:DisableTask(self.createPortalTask)
	self:DisableTask(self.finishTask)

	self:EnableTask(self.inviteTask)
	if self.isAutoInvite then
		self.inviteTask.actionButton:Click()
	end
end

function TaskList:SetState(state)
	self.state = state
end

function TaskList:CreateTask(message, action, previousTask)
	local task = CreateFrame('Frame', nil, self)
	task:SetPoint('LEFT')
	task:SetPoint('RIGHT')
	if previousTask ~= nil then
		task:SetPoint('TOP', previousTask, 'BOTTOM', 0, 16)
	else
		task:SetPoint('TOP', self.divider, 'BOTTOM', 0, 16)
	end
	task:SetHeight(50)

	if action ~= nil then
		local actionButton = CreateFrame('Button', nil, task, 'GameMenuButtonTemplate, InSecureActionButtonTemplate')
		actionButton:SetSize(64, 24)
		actionButton:ClearAllPoints()
		actionButton:SetPoint('RIGHT', task, 'RIGHT', -16, 0)
		actionButton:SetText(action)
		task.actionButton = actionButton
	end

	local messageText = task:CreateFontString()
	messageText:SetFontObject('GameFontNormal')
	messageText:SetText(message)
	messageText:ClearAllPoints()
	messageText:SetPoint('LEFT', task, 'LEFT', 16, 0)
	if task.actionButton ~= nil then
		messageText:SetPoint('RIGHT', task.actionButton, 'LEFT', -8, 0)
	else
		messageText:SetPoint('RIGHT', task, 'RIGHT', -16, 0)
	end

	messageText:SetJustifyH('LEFT')
	messageText:SetTextColor(1, 1, 1)
	task.messageText = messageText

	return task
end

function TaskList:MarkAsComplete(task)
	self:DisableTask(task)
end

function TaskList:DisableTask(task)
	if task.actionButton ~= nil then
		task.actionButton:SetEnabled(false)
	end
	task.messageText:SetTextColor(0.7, 0.7, 0.7)
end

function TaskList:EnableTask(task)
	if task.actionButton ~= nil then
		task.actionButton:SetEnabled(true)
	end
	task.messageText:SetTextColor(1, 1, 1)
end

function TaskList:SendWho(command)
	C_FriendList.SetWhoToUi(true)
	FriendsFrame:UnregisterEvent("WHO_LIST_UPDATE")
	C_FriendList.SendWho(command);
end

function TaskList:FindPortal(name)
	for _, portal in ipairs(MageTaxi.portals) do
		if portal.name == name then
			return portal
		end
	end
	return nil
end

function TaskList:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
	if self.state == 'CREATING_PORTAL'
		and spellID == self.job.sellingPortal.portalSpellID then
		self:MarkAsComplete(self.createPortalTask)
		self:SetState('WAITING_FOR_PLAYER_ENTER_PORTAL')
		self:EnableTask(self.finishTask)
		return
	end

	if self.state == 'MOVING_TO_PLAYER_ZONE'
		and spellID == self.job.movingPortal.teleportSpellID then
		self:MarkAsComplete(self.movingTask)
		self:SetState('MOVED_TO_PLAYER_ZONE')
		self:EnableTask(self.createPortalTask)
		return
	end
end

function TaskList:CHAT_MSG_SYSTEM(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	if self.state == 'WAITING_FOR_INVITE_RESPONSE' then
		if text == self.job.playerName..' is already in a group.' then
			SendChatMessage(
				"Hey, please invite me for a portal to "..self.job.sellingPortal.name ,
				"WHISPER" ,
				 nil,
				 self.job.playerName
		 	)
			return
		end

		if text == self.job.playerName..' joins the party.' then
			self:MarkAsComplete(self.inviteTask)
			self:EnableTask(self.detectZoneTask)
			self:SetState("INVITED_PLAYER")
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

function TaskList:WHO_LIST_UPDATE()
	FriendsFrame:RegisterEvent("WHO_LIST_UPDATE")
	local playerName = self.job.playerName
	local numWhos, totalCount = C_FriendList.GetNumWhoResults()

	for i = 1, totalCount do
		local whoPlayer = C_FriendList.GetWhoInfo(i)
		if whoPlayer.fullName == playerName then
			foundPlayerName = whoPlayer.fullName
			foundZone = whoPlayer.area
		end
	end

	if self.state == 'WAITING_FOR_DETECT_PLAYER_ZONE' then
		if foundPlayerName == nil then
			return
		end
		self.job.playerZone = foundZone
		self:MarkAsComplete(self.detectZoneTask)
		local myZone = GetZoneText()
		if string.find(myZone, foundZone) ~= nil then
			self:SetState('MOVED_TO_PLAYER_ZONE')
			self:MarkAsComplete(self.movingTask)
			self:EnableTask(self.createPortalTask)
			return
		end

		local portal = self:FindPortal(foundZone)
		self.job.movingPortal = portal
		self.movingTask.actionButton:SetAttribute('macrotext', '/cast '..portal.portalSpellName)
		self:EnableTask(self.movingTask)
		return
	end
end
