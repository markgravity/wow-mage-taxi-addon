local Work = {}

function CreateWork(name, parent)
	local work = {}
	extends(work, Work)

	local frame = CreateFrame('Frame', name, parent, BackdropTemplateMixin and 'BackdropTemplate' or nil)
	frame:SetSize(WORK_WIDTH, WORK_HEIGHT)
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	work.frame = frame

    local header = frame:CreateTexture('$parentHeader', 'OVERLAY')
    header:SetPoint('TOP', 0, 12)
    header:SetTexture(131080) -- 'Interface\\DialogFrame\\UI-DialogBox-Header'
    header:SetSize(290, 64)

    local headerText = frame:CreateFontString('$parentHeaderText', 'OVERLAY', 'GameFontNormal')
    headerText:SetPoint('TOP', header, 0, -14)
    headerText:SetText('Portal')
	work.headerTitle = headerText

	local divider = frame:CreateTexture(nil, 'OVERLAY')
	divider:SetPoint('TOP', 0, -150)
	divider:SetPoint('LEFT', 10, 0)
	divider:SetPoint('RIGHT', 52, 0)
    divider:SetTexture('Interface\\DialogFrame\\UI-DialogBox-Divider')

	local background = frame:CreateTexture(nil, 'ARTWORK')
    background:SetPoint('TOPLEFT', 11, -11)
	background:SetPoint('BOTTOMRIGHT', divider, 'TOPRIGHT', 11, -11)
    background:SetTexture('Interface\\PaperDollInfoFrame\\UI-Character-Reputation-DetailBackground')

	-- Item
	local itemFrameName = frame:GetName()..'Item'
	local item =  CreateFrame('BUTTON', itemFrameName, frame, 'LootButtonTemplate')
	item:SetScript("OnClick", nil)
    item:SetScript("OnUpdate", nil)
    item:SetScript("OnEnter", nil)
	item:SetPoint('TOPLEFT', 32, -36)
	item.icon = _G[itemFrameName.."IconTexture"]
	item.title = _G[itemFrameName.."Text"]
	work.item = item

	local targetNameText = frame:CreateFontString()
	targetNameText:SetFontObject('GameFontNormal')
	targetNameText:ClearAllPoints()
	targetNameText:SetPoint('LEFT', 32, 0)
	targetNameText:SetPoint('RIGHT', -20, 0)
	targetNameText:SetPoint('TOP', item, 'BOTTOM', 0, -8)
	targetNameText:SetJustifyH('LEFT')
	targetNameText:SetTextColor(0.75, 0.75, 0.75)
	work.targetNameText = targetNameText

	local messageText = frame:CreateFontString()
	messageText:SetFontObject('GameFontNormalSmall')
	messageText:SetTextColor(1, 1, 1)
	messageText:ClearAllPoints()
	messageText:SetPoint('TOP', targetNameText, 'BOTTOM', 0, -4)
	messageText:SetPoint('LEFT', 20, 0)
	messageText:SetPoint('RIGHT', -20, 0)
	messageText:SetJustifyH('CENTER')
	work.messageText = messageText

	local endButton = CreateFrame('Button', nil, frame, 'GameMenuButtonTemplate')
	endButton:SetSize(64, 24)
	endButton:ClearAllPoints()
	endButton:SetPoint('BOTTOM', divider, 'TOP', -26, 4)
	endButton:SetText('End')
	work.endButton = endButton


	local actionList = CreateFrame('Frame', nil, frame, 'InsetFrameTemplate')
	actionList:SetPoint('TOPLEFT', divider, 'TOPLEFT', 0, -10)
	actionList:SetPoint('BOTTOMRIGHT', -10, 10)

	local scrollFrame = CreateFrame(
		'ScrollFrame',
		frame:GetName()..'ScrollFrame',
		actionList,
		'UIPanelScrollFrameTemplate'
	)
	scrollFrame:SetPoint('LEFT', 5, 0)
	scrollFrame:SetPoint('TOP', 0, -6)
	scrollFrame:SetPoint('BOTTOM', 0, 4)
	scrollFrame:SetPoint('RIGHT', -5, 0)
	_G[frame:GetName()..'ScrollFrameScrollBar']:Hide()
	_G[frame:GetName()..'ScrollFrameScrollBarScrollUpButton']:SetAlpha(0)
	_G[frame:GetName()..'ScrollFrameScrollBarScrollDownButton']:SetAlpha(0)
	_G[frame:GetName()..'ScrollFrameScrollBarThumbTexture']:SetAlpha(0)

	local scrollContent = CreateFrame(
		'Frame',
		scrollFrame:GetName()..'Content',
		scrollFrame
	)
	scrollContent:SetPoint('TOPLEFT', scrollFrame, 0, 0)
	scrollContent:SetPoint('TOPLEFT', scrollFrame, 0, 0)
	scrollFrame:SetScrollChild(scrollContent)
	work.actionListContent = scrollContent
	return work
end

function Work:SetTitle(title)
	self.headerTitle:SetText(title)
end

function Work:SetItem(iconTexture, name)
	self.item.icon:SetTexture(iconTexture)
	self.item.title:SetText(name)
end

function Work:SetMessage(targetName, message)
	self.targetNameText:SetText(targetName)
	self.messageText:SetText(message)
end

function Work:Hide()
	self.frame:Hide()
end

function Work:Show()
	self.frame:Show()
end

function Work:Start()
	PlaySound(6197)
	FlashClientIcon()
end

function Work:GetState()
	return self.state
end

function Work:SetState(state)
	self.state = state
	if self.onStateChange then
		self.onStateChange()
	end
end

function Work:GetStateText(state)
	return 'Initialized'
end

function Work:Complete()
	if UnitIsGroupLeader('player') then
		UninviteUnit(self.info.targetName)
	else
		LeaveParty()
	end

	self.info = nil
	self:SetState('ENDED')
	self.frame:Hide()

	if self.onComplete then
		self.onComplete()
	end

	PlaySound(6199)
end

function Work:SetScript(event, script)
	if event == 'OnStateChange' then
		self.onStateChange = script
		return
	end

	if event == 'OnComplete' then
		self.onComplete = script
		return
	end
end

function Work:GetPriorityLevel()
	return 4
end
