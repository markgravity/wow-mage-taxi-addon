local Work = {}

function CreateWork(name, parent)
	local work = {}
	extends(work, Work)

	work.actions = {}
	work.isItemListCollaged = true

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

	-- Item List
	local itemList = CreateItemList(frame)
	itemList.frame:SetPoint('TOPLEFT', frame, 'TOPRIGHT', -12, 0)
	work.itemList = itemList

	-- ToggleItemListButton
	local toggleItemListButtonBG = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
	toggleItemListButtonBG:SetPoint('TOPLEFT', frame, 'TOPRIGHT', -27, -10)
	toggleItemListButtonBG:SetSize(20, 20)

	local toggleItemListButton = CreateFrame('Button', nil, toggleItemListButtonBG, '')
	toggleItemListButton:SetPoint('CENTER', toggleItemListButtonBG, 0, -0.5)
	toggleItemListButton:SetSize(25, 25)
	toggleItemListButton:SetNormalTexture('Interface\\Buttons\\UI-Panel-CollapseButton-Up')
	toggleItemListButton:SetPushedTexture('Interface\\Buttons\\UI-Panel-CollapseButton-Down')
	toggleItemListButton:SetScript('OnClick', function()
		work:ToggleItemList()
	end)
	work.toggleItemListButton = toggleItemListButton
	work:ToggleItemList(false)

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
	messageText:SetPoint('TOP', targetNameText, 'BOTTOM', 0, 0)
	messageText:SetPoint('LEFT', 30, 0)
	messageText:SetPoint('RIGHT', -30, 0)
	messageText:SetJustifyH('CENTER')
	work.messageText = messageText

	local endButton = CreateFrame('Button', nil, frame, 'GameMenuButtonTemplate')
	endButton:SetSize(64, 24)
	endButton:ClearAllPoints()
	endButton:SetPoint('BOTTOM', divider, 'TOP', -26, 4)
	endButton:SetText('End')
	work.endButton = endButton
	messageText:SetPoint('BOTTOM', endButton, 'TOP', 0, 4)

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
	scrollFrame:SetPoint('TOP', 0, -12)
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
	scrollFrame:SetScrollChild(scrollContent)
	work.actionListContent = scrollContent
	return work
end

function Work:SetTitle(title)
	self.headerTitle:SetText(title)
end

function Work:SetItem(iconTexture, name, itemLink)
	local work = self
	self.item.icon:SetTexture(iconTexture)
	self.item.title:SetText(name)

	if itemLink then
		self.item:SetScript('OnEnter', function(self)
			GameTooltip:SetOwner(work.frame, 'ANCHOR_NONE')
			GameTooltip:SetPoint('TOPRIGHT', work.frame, 'TOPLEFT')
			GameTooltip:SetHyperlink(itemLink)
			GameTooltip:Show()
		end)

		self.item:SetScript('OnLeave', function()
		  	GameTooltip:Hide()
		end)

		self.item:SetScript('OnClick', function(self, button)
			if button == 'LeftButton' and IsShiftKeyDown() then
		        ChatEdit_InsertLink(itemLink)
				return
		    end
		end)
	end
end

function Work:ToggleItemList(isShown)
	local isShown = isShown or self.isItemListCollaged
	local degree = isShown and -90 or 90
	local rotation = math.rad(degree)

	self.toggleItemListButton:GetNormalTexture():SetRotation(rotation)
	self.toggleItemListButton:GetPushedTexture():SetRotation(rotation)

	self.isItemListCollaged = not isShown
 	if self.isItemListCollaged then
		self.itemList:Show()
	else
		self.itemList:Hide()
	end
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

function Work:End(isCompleted, wantsLeave, isLazy)
	self:UnregisterEvents()
	if self.info == nil then
		return
	end

	if UnitIsGroupLeader('player') then
		if GetNumGroupMembers() <= 2 and UnitName('party1') == self.info.targetName then
			LeaveParty()
		else
			UninviteUnit(self.info.targetName)
		end
	else
		if wantsLeave then
			-- BUG: Leaving when another work is unable to contact
			LeaveParty()
		end
	end

	self.info = nil
	self:SetState('ENDED')
	self.frame:Hide()

	if self.onComplete then
		self.onComplete()
	end

	if isCompleted then
		PlaySound(6199)
	else
		if not isLazy then
			PlaySound(6295)
		end
	end

	-- Cancel all actions
	for _, action in ipairs(self.actions) do
		action:Cancel()
	end
end

function Work:AddAction(action)
	table.insert(self.actions, action)
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
