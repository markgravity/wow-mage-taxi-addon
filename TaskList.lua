local TaskList = CreateFrame('Frame', 'MageTaxiTaskList', UIParent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
MageTaxi.taskList = TaskList

function TaskList:DrawUIs()
	self.isAutoInvite = true
	self:SetState('INITIALIZED')
	self:RegisterEvent('UNIT_SPELLCAST_SUCCEEDED')
	self:RegisterEvent('CHAT_MSG_SYSTEM')

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
		TaskList.job = nil
		TaskList:SetState('ENDED')
		TaskList:Hide()
		MageTaxi:Resume()
		LeaveParty()
	end)
	self.endButton = endButton

	-- Create tasks
	local contactTask = self:CreateTask('Contact')
	self.contactTask = contactTask

	local moveTask = self:CreateTask('Move', nil, contactTask)
	moveTask:SetAttribute('type', 'macro')
	moveTask:HookScript('OnClick', function(self)
		TaskList:SetState('CREATING_PORTAL')
	end)
	self.moveTask = moveTask

	local makeTask = self:CreateTask('Make', nil, moveTask)
	self.makeTask = makeTask

	local finishTask = self:CreateTask('Finish', nil, makeTask)
	self.finishTask = finishTask

    self:SetScript('OnEvent', function(self, event, ...)
        self[event](self, ...)
    end)

end

function TaskList:SetJob(targetName, message, portal)
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

	self.contactTask:SetScript('OnClick', function(self)
		TaskList:SetState('WAITING_FOR_INVITE_RESPONSE')
		InviteUnit(job.targetName)
	end)
	self:SetTaskDescription(self.contactTask, '|c60808080Invite |r|cffffd100'..job.targetName..'|r|c60808080 into the party|r')

	self:SetTaskDescription(self.moveTask, '|c60808080Waiting for contact|r')

	self.makeTask:SetAttribute('type', 'macro')
	self.makeTask:SetAttribute('macrotext', '/cast '..job.sellingPortal.portalSpellName)
	self.makeTask:HookScript('OnClick', function(self)
		TaskList:SetState('CREATING_PORTAL')
	end)
	self:SetTaskDescription(self.makeTask, '|c60808080Create a |r|cffffd100'..job.sellingPortal.name..'|r|c60808080 portal|r')

	self:SetTaskDescription(self.finishTask, '|c60808080Waiting for |r|cffffd100'..job.targetName..'|r|c60808080 to enter the portal|r')

	self:DisableTask(self.contactTask)
	self:DisableTask(self.moveTask)
	self:DisableTask(self.makeTask)
	self:DisableTask(self.finishTask, true)

	self:EnableTask(self.contactTask)
	if self.isAutoInvite then
		self.contactTask:Click()
	end
end

function TaskList:SetState(state)
	self.state = state
end

function TaskList:CreateTask(titleText, descriptionText, previousTask)
	local backdrop = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	local task = CreateFrame('Button', nil, self, BackdropTemplateMixin and "InSecureActionButtonTemplate, BackdropTemplate" or nil)
	task:SetBackdrop(backdrop)
	task:SetPoint('LEFT', 16, 0)
	task:SetPoint('RIGHT', -16, 0)
	if previousTask ~= nil then
		task:SetPoint('TOP', previousTask, 'BOTTOM', 0, -16)
	else
		task:SetPoint('TOP', self.divider, 'BOTTOM', 0, 16)
	end

	local texture = task:CreateTexture()
	texture:SetColorTexture(0.5, 0.5, 0.5, 1)
	texture:SetBlendMode('BLEND')
	texture:SetPoint('TOPLEFT', 1, -1)
	texture:SetPoint('BOTTOMRIGHT', -1, 1)
	texture:SetGradientAlpha('HORIZONTAL', .5, .5, .5, .8, .5, .5, .5, 0)
	task:SetHighlightTexture(texture)

	local title = task:CreateFontString()
	title:SetFont(GameFontNormal:GetFont(), 11)
	title:SetText(titleText)
	title:SetPoint('LEFT', task, 'LEFT', 16, 0)
	title:SetPoint('RIGHT', task, 'RIGHT', -16, 0)
	title:SetPoint('TOP', task, 'TOP', 0, -8)
	title:SetJustifyH('CENTER')
	title:SetTextColor(1, 1, 1)
	task.title = title

	local description = task:CreateFontString()
	description:SetFont(GameFontNormal:GetFont(), 9)
	description:SetPoint('LEFT', task, 'LEFT', 16, 0)
	description:SetPoint('RIGHT', task, 'RIGHT', -16, 0)
	description:SetPoint('TOP', title, 'BOTTOM', 0, -4)
	description:SetJustifyH('CENTER')
	task.description = description
	self:SetTaskDescription(task, descriptionText)

	local line = task:CreateLine()
	line:SetDrawLayer("ARTWORK",2)
	line:SetThickness(6)
	line:SetStartPoint("TOP", 0, 0)
	line:SetEndPoint("TOP", 0, 16)
	line:Hide()
	task.line = line
	if previousTask ~= nil then
		line:Show()
	end
	return task
end

function TaskList:SetTaskDescription(task, description)
	task.description:SetText(description)

	local totalHeight = 6 + task.title:GetStringHeight() + 6 + task.description:GetStringHeight() + 6 + 4
	task:SetHeight(totalHeight)
end

function TaskList:Complete(task)
	task:SetBackdropColor(0.055, 0.306, 0.576, 0.7) -- blue, attune
	task:SetBackdropBorderColor(1, 1, 1)
	task.line:SetColorTexture(0.388, 0.686, 0.388, 1) -- green
end

function TaskList:DisableTask(task, isFinish)
	if isFinish then
		task:SetBackdropColor(0.557, 0.055, 0.075, 0.7	) -- red
		task:SetBackdropBorderColor(1, 1, 1)
	else
		task:SetBackdropColor(0.1, 0.1, 0.1, 0.5) -- gray
		task:SetBackdropBorderColor(0.4, 0.4, 0.4)
	end

	task.line:SetColorTexture(0.2, 0.2, 0.2, 1)
	task.line:SetDrawLayer("ARTWORK",0)
end

function TaskList:EnableTask(task)
	task:SetBackdropColor(0.851, 0.608, 0.0, 0.3) -- yellow
	task:SetBackdropBorderColor(0.851, 0.608, 0.0, 1)
	task.line:SetColorTexture(0.851, 0.608, 0.0, 1) -- yellow
	task.line:SetDrawLayer("ARTWORK",1)
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

function TaskList:DetectTargetZone()
	local targetZone = GetPartyMemberZone(self.job.targetName)
	local playerZone = GetZoneText()
	print(targetZone, playerZone)
	if string.find(playerZone, targetZone) ~= nil then
		self:SetState('MOVED_TO_PLAYER_ZONE')
		self:Complete(self.moveTask)
		self:EnableTask(self.makeTask)
		return
	end

	local portal = self:FindPortal(targetZone)
	if portal == nil then
		self:SetState('MOVED_TO_PLAYER_ZONE')
		self:Complete(self.moveTask)
		self:EnableTask(self.makeTask)
	end

	self.job.movingPortal = portal
	self.moveTask:SetAttribute('macrotext', '/cast '..portal.teleportSpellID)
	self:SetTaskDescription(self.moveTask, '|c60808080Teleport to |r|cffffd100'..portal.name..'|r')
	self:EnableTask(self.moveTask)
end

function TaskList:CompleteContactTask()
	self:Complete(self.contactTask)
	self:SetState("INVITED_PLAYER")
	self:DetectTargetZone()
end

-- EVENTS
function TaskList:UNIT_SPELLCAST_SUCCEEDED(target, castGUID, spellID)
	if self.state == 'CREATING_PORTAL'
		and spellID == self.job.sellingPortal.portalSpellID then
		self:Complete(self.makeTask)
		self:SetState('WAITING_FOR_PLAYER_ENTER_PORTAL')
		self:EnableTask(self.finishTask)
		return
	end

	if self.state == 'MOVING_TO_PLAYER_ZONE'
		and spellID == self.job.movingPortal.teleportSpellID then
		self:Complete(self.moveTask)
		self:SetState('MOVED_TO_PLAYER_ZONE')
		self:EnableTask(self.makeTask)
		return
	end
end

function TaskList:CHAT_MSG_SYSTEM(text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	if self.state == 'WAITING_FOR_INVITE_RESPONSE' then
		if text == self.job.targetName..' is already in a group.' then
			SendChatMessage(
				"Hey, please invite me for a portal to "..self.job.sellingPortal.name ,
				"WHISPER" ,
				 nil,
				 self.job.targetName
		 	)
			self:SetTaskDescription(self.contactTask, '|c60808080Waiting for |r|cffffd100'..self.job.targetName..'|r|c60808080 invites you into the party|r')
			MageTaxiAutoAcceptInvite:SetEnabled(true, function ()
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
