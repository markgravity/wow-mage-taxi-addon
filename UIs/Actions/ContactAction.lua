local ContactAction = {}

function CreateContactAction(
	targetName,
	whisperMessage,
	waitingTimeout,
	isLazy,
	titleText,
	descriptionText,
	parent,
	previousAction
)
	local action = CreateAction(titleText, descriptionText, parent, previousAction)
	extends(action, ContactAction)

	-- DEBUG
	if WorkWork.isDebug and targetName == 'Iina' then
		waitingTimeout = 100000
	end

	action.info = {
		targetName = targetName,
		whisperMessage = whisperMessage,
		timeout = waitingTimeout,
		isLazy = isLazy
	}
	action:SetState('INITIALIZED')
	action:SetScript('OnClick', function()
		action:SetState('WAITING_FOR_CONTACT_RESPONSE')
	end)
	action:RegisterEvents({ 'CHAT_MSG_SYSTEM' })

	return action
end

function ContactAction:SetState(state)
	local action = self
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end

	if state == 'WAITING_FOR_CONTACT_RESPONSE' then
		if self.info.isLazy then
			local oldDescription = self.description:GetText()
			self:SetDescription('|c60808080Making sure |r|cffffd100'..self.info.targetName..'|r|c60808080 is same zone|r')
			GetZoneByPlayerName(self.info.targetName, function (zone)
				local playerZone = GetPlayerZone()
				if zone == nil or playerZone ~= zone then
					action:SetState('CONTACT_FAILED')
					return
				end
				action:SetDescription(oldDescription)
				action:InviteTarget()
			end)
			return
		end
		self:InviteTarget()
		return
	end

	if state == 'CONTACTED_TARGET' then
		FlashClientIcon()
		return
	end
end

function ContactAction:GetState()
	return self.state
end

function ContactAction:InviteTarget()
	InviteUnit(self.info.targetName)
	self:BeginInviteTimeout()
end

function ContactAction:BeginInviteTimeout()
	local action = self
	C_Timer.After(action.info.timeout, function()
		if action.state == 'CONTACTED_TARGET' then
			return
		end
		action:SetState('CONTACT_FAILED')
	end)
end

function ContactAction:SetScript(super, event, script)
	if event == 'OnStateChange' then
		self.onStateChange = script
		return
	end

	super(event, script)
end

function ContactAction:CHAT_MSG_SYSTEM(text)
	local task = self
	if self.state == 'WAITING_FOR_CONTACT_RESPONSE' then
		if text == self.info.targetName..' is already in a group.' then
			Whisper(self.info.targetName, self.info.whisperMessage)
			self:SetDescription('|c60808080Waiting for |r|cffffd100'..self.info.targetName..'|r|c60808080 invites you into the party|r')
			WorkWorkAutoAcceptInvite:SetEnabled(true, function ()
				task:SetState('CONTACTED_TARGET')
			end)
			return
		end

		if text == self.info.targetName..' joins the party.' then
			task:SetState('CONTACTED_TARGET')
			return
		end
		return
	end
end
