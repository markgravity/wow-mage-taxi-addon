local ContactAction = {}

function CreateContactAction(
	targetName,
	whisperMessage,
	waitingTimeout,
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
		timeout = waitingTimeout
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
		InviteUnit(self.info.targetName)
		C_Timer.After(self.info.timeout, function()
			if action.state == 'CONTACTED_TARGET' then
				return
			end
			action:SetState('CONTACT_FAILED')
		end)
		return
	end

	if state == 'CONTACTED_TARGET' then
		SetRaidTarget('player', 1)
		FlashClientIcon()
		return
	end
end

function ContactAction:GetState()
	return self.state
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
