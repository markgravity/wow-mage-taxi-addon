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
	frame:SetPoint('LEFT', 0, 0)
	frame:SetPoint('RIGHT', 0, 0)
	frame:SetAttribute('type', 'macro')
	if previousAction ~= nil then
		frame:SetPoint('TOP', previousAction.frame, 'BOTTOM', 0, -16)
	end
	action.frame = frame

	-- Highlight Texture
 	local texture = frame:CreateTexture()
	texture:SetColorTexture(0.5, 0.5, 0.5, 1)
	texture:SetBlendMode('BLEND')
	texture:SetPoint('TOPLEFT', 1, -1)
	texture:SetPoint('BOTTOMRIGHT', -1, 1)
	texture:SetGradientAlpha('HORIZONTAL', .5, .5, .5, .8, .5, .5, .5, 0)
	frame:SetHighlightTexture(texture)

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
	title:SetPoint('LEFT', frame, 'LEFT', 16, 0)
	title:SetPoint('RIGHT', frame, 'RIGHT', -16, 0)
	title:SetPoint('TOP', frame, 'TOP', 0, -8)
	title:SetJustifyH('CENTER')
	title:SetTextColor(1, 1, 1)
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
	self.frame:SetEnabled(false)
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
	self.frame:SetEnabled(false)
	if isFinish then
		self.frame:SetBackdropColor(0.557, 0.055, 0.075, 0.7) -- red
		self.frame:SetBackdropBorderColor(1, 1, 1)
	else
		self.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.5) -- gray
		self.frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
	end

	self.line:SetColorTexture(0.2, 0.2, 0.2, 1)
	self.line:SetDrawLayer("ARTWORK",0)
end

function Action:Enable()
	if self.isCompleted then
		self:SetupUIForComplete()
		return
	end

	self.isEnabled = true
	self.frame:SetEnabled(true)
	self.frame:SetBackdropColor(0.851, 0.608, 0.0, 0.3) -- yellow
	self.frame:SetBackdropBorderColor(0.851, 0.608, 0.0, 1)
	self.line:SetColorTexture(0.851, 0.608, 0.0, 1) -- yellow
	self.line:SetDrawLayer("ARTWORK",1)
end

function Action:SetupUIForComplete()
	self.frame:SetEnabled(false)
	self.frame:SetBackdropColor(0.373, 0.729, 0.275, 0.3) -- green, to match website colors
	self.frame:SetBackdropBorderColor(0.373, 0.729, 0.275)
	self.line:SetColorTexture(0.388, 0.686, 0.388, 1) -- green
end

function Action:HookScript(event, script)
	self.frame:HookScript(event, script)
end

function Action:SetScript(event, script)
	if event == 'OnComplete' then
		self.onComplete = script
		return
	end
	self.frame:SetScript(event, script)
end

function Action:SetSpell(name)
	self.frame:SetAttribute('macrotext', '/cast '..name)
end

function Action:SetMarcro(content)
	self.frame:SetAttribute('macrotext', content)
end

function Action:SetCount(number)
	if number == nil then
		self.countFrame:Hide()
	end
	self.countFrame:Show()
	self.countFrame.number:SetText(number)
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
