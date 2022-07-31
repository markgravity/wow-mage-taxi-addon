local ContactTask = {}

function CreateContactTask(
	targetName,
	whisperMessage,
	titleText,
	descriptionText,
	parent,
	previousTask
)
	local task = CreateTask(titleText, descriptionText, parent, previousTask)
	extends(task, ContactTask)
	task.info = {
		targetName = targetName,
		whisperMessage = whisperMessage
	}
	task:SetScript('OnClick', function()
		task:SetState('WAITING_FOR_CONTACT_RESPONSE')
	end)
	task:SetState('INITIALIZED')

	local frame = task.frame
	frame:RegisterEvent('CHAT_MSG_SYSTEM')
	frame:SetScript('OnEvent', function(self, event, ...)
		task[event](task, ...)
	end)

	return task
end

function ContactTask:SetState(state)
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end

	if state == 'WAITING_FOR_CONTACT_RESPONSE' then
		InviteUnit(self.info.targetName)
		return
	end

	if state == 'CONTACTED_TARGET' then
		return
	end
end

function ContactTask:GetState()
	return self.state
end

function ContactTask:SetScript(super, event, script)
	if event == 'OnStateChange' then
		self.onStateChange = script
		return
	end

	super(event, script)
end

function ContactTask:CHAT_MSG_SYSTEM(text)
	local work = self
	if self.state == 'WAITING_FOR_CONTACT_RESPONSE' then
		if text == self.info.targetName..' is already in a group.' then
			Whisper(self.info.targetName, self.info.whisperMessage)
			self.contactTask:SetDescription('|c60808080Waiting for |r|cffffd100'..self.info.targetName..'|r|c60808080 invites you into the party|r')
			WorkWorkAutoAcceptInvite:SetEnabled(true, function ()
				work:SetState('CONTACTED_TARGET')
			end)
			return
		end

		if text == self.info.targetName..' joins the party.' then
			work:SetState('CONTACTED_TARGET')
			return
		end
		return
	end
end
