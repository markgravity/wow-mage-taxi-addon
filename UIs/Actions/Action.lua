local Eventable = WorkWork.Trails.Eventable
local Action = {}

function CreateAction(titleText, descriptionText, parent, previousAction)
	local action = {}
	extends(action, Action, Eventable)

	action.isCompleted = false
	action.isEnabled = true
	action.isCancel = false

	local backdrop = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	local frame = CreateFrame('Button', nil, parent, BackdropTemplateMixin and "InSecureActionButtonTemplate, BackdropTemplate" or nil)
	frame:SetBackdrop(backdrop)
	frame:SetPoint('LEFT', 8, 0)
	frame:SetPoint('RIGHT', -8, 0)
	frame:SetAttribute('type', 'macro')
	frame:RegisterForClicks('AnyUp')
	if previousAction ~= nil then
		frame:SetPoint('TOP', previousAction.frame, 'BOTTOM', 0, -16)
	end
	frame:SetScript('OnEnter', function(self)
		if action.isEnabled then
			frame:SetBackdropColor(0.851, 0.608, 0.0, 0.4)
		end

		if action.itemLink == nil then return end

		GameTooltip:SetOwner(frame, 'ANCHOR_NONE')
		GameTooltip:SetPoint('TOPRIGHT', frame, 'TOPLEFT', -20, 0)
		GameTooltip:SetHyperlink(action.itemLink)
		GameTooltip:Show()
	end)

	frame:SetScript('OnLeave', function()
		if action.isEnabled then
			frame:SetBackdropColor(0.851, 0.608, 0.0, 0.3)
		end

		if action.itemLink == nil then return end
		GameTooltip:Hide()
	end)

	frame:HookScript('OnClick', function(self, button)
		if button == 'LeftButton' and IsShiftKeyDown() and action.itemLink then
			ChatEdit_InsertLink(action.itemLink)
			return
		end

		if button == 'RightButton' and action.contextMenu then
			EasyMenu(action.contextMenu, action.contextMenuFrame, 'cursor', 0 , 0, 'MENU')
			return
		end
	end)
	action.frame = frame

	-- Count
	local countFrame = CreateFrame('Frame', nil, frame)
	countFrame:SetPoint('BOTTOMRIGHT', 3, -3)
	countFrame:Hide()
	local texture = countFrame:CreateTexture(nil, 'OVERLAY', 'Talent-PointBg')
	texture:ClearAllPoints()
	texture:SetPoint('CENTER', 0, 0)
	local count = countFrame:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	count:SetPoint('CENTER', texture, 0, 0)
	countFrame.number = count
	countFrame:SetSize(texture:GetSize())
	action.countFrame = countFrame

	local title = frame:CreateFontString()
	title:SetFont(GameFontNormal:GetFont(), 11)
	title:SetText(titleText)
	title:SetPoint('LEFT', frame, 'LEFT', 8, 0)
	title:SetPoint('RIGHT', frame, 'RIGHT', -8, 0)
	title:SetPoint('TOP', frame, 'TOP', 0, -8)
	title:SetJustifyH('CENTER')
	title:SetTextColor(1, 1, 1)
	title:SetMaxLines(1)
	title:SetWordWrap(false)
	action.title = title

	local description = frame:CreateFontString()
	description:SetFont(GameFontNormal:GetFont(), 9)
	description:SetPoint('LEFT', frame, 'LEFT', 16, 0)
	description:SetPoint('RIGHT', frame, 'RIGHT', -16, 0)
	description:SetPoint('TOP', title, 'BOTTOM', 0, -4)
	description:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 8)
	description:SetJustifyH('CENTER')
	action.description = description
	action:SetDescription(descriptionText)

	local line = frame:CreateLine()
	line:SetDrawLayer("ARTWORK",2)
	line:SetThickness(6)
	line:SetStartPoint("TOP", 0, 0)
	line:SetEndPoint("TOP", 0, 16)
	line:Hide()
	action.line = line
	if previousAction ~= nil then
		line:Show()
	end

	local contextMenuFrame = CreateFrame(
		'Frame',
		nil,
		frame,
		'UIDropDownMenuTemplate'
	)
	contextMenuFrame:Hide()
	action.contextMenuFrame = contextMenuFrame
	return action
end

function Action:SetDescription(description)
	self.description:SetText(description)
	local totalHeight = self.title:GetHeight() + self.description:GetHeight() + 20
	self.frame:SetHeight(totalHeight)
end

function Action:IsCompleted()
	return self.isCompleted
end

function Action:Complete()
	self:UnregisterEvents()
	self.isCompleted = true
	-- self.frame:SetEnabled(false)
	self:SetupUIForComplete()
	if self.onComplete then
		self.onComplete()
	end
end

function Action:Uncomplete()
	self:RegisterEvents()
	self.isCompleted = false
	if self.isEnabled then
		self:Endable()
	else
		self:Disable()
	end
end

function Action:Disable(isFinish)
	self.isEnabled = false
	if isFinish then
		self.frame:SetBackdropColor(0.557, 0.055, 0.075, 0.4) -- red
		self.frame:SetBackdropBorderColor(1, 1, 1)
	else
		self.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.5) -- gray
		self.frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
	end

	self.line:SetColorTexture(0.2, 0.2, 0.2, 1)
	self.line:SetDrawLayer("ARTWORK",0)
	if self.macrotext then
		local macrotext = self.macrotext
		self:SetMarcro(nil)
		self.macrotext = macrotext
	end
end

function Action:Enable()
	if self.isCompleted then
		self:SetupUIForComplete()
		return
	end

	self.isEnabled = true
	self.frame:SetBackdropColor(0.851, 0.608, 0.0, 0.3) -- yellow
	self.frame:SetBackdropBorderColor(0.851, 0.608, 0.0, 1)
	self.line:SetColorTexture(0.851, 0.608, 0.0, 1) -- yellow
	self.line:SetDrawLayer("ARTWORK",1)

	if self.macrotext ~= nil then
		self:SetMarcro(self.macrotext)
	end
end

function Action:SetupUIForComplete()
	self.frame:SetEnabled(false)
	self.frame:SetBackdropColor(0.373, 0.729, 0.275, 0.3) -- green, to match website colors
	self.frame:SetBackdropBorderColor(0.373, 0.729, 0.275)
	self.line:SetColorTexture(0.388, 0.686, 0.388, 1) -- green
end

function Action:HookScript(event, script)
	local action = self
	self.frame:HookScript(event, function()
		if not action.isEnabled then return end
		script()
	end)
end

function Action:SetScript(event, script)
	local action = self
	if event == 'OnComplete' then
		self.onComplete = script
		return
	end

	self.frame:SetScript(event, function()
		if not action.isEnabled then return end
		script()
	end)
end

function Action:SetSpell(name)
	self:SetMarcro('/cast '..name)
end

function Action:SetMarcro(content)
	self.macrotext = content
	self.frame:SetAttribute('macrotext', content)
end

function Action:SetCount(number)
	if number == nil then
		self.countFrame:Hide()
	end
	self.countFrame:Show()
	self.countFrame.number:SetText(number)
end

function Action:SetItemLink(itemLink)
	self.itemLink = itemLink
end

function Action:Excute()
	self.frame:Click()
end

function Action:Cancel()
	self.isCancel = true
end

function Action:SetPoint(...)
	self.frame:SetPoint(...)
end

function Action:SetContextMenu(menu)
	self.contextMenu = menu
end
