
local WorkTask = {}
WorkTask.__index = WorkTask

function CreateWorkTask(parent, titleText, descriptionText, previousTask)
	local task = {}
	setmetatable(task, WorkTask)

	local backdrop = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 3, right = 3, top = 3, bottom = 3 }
	}

	local frame = CreateFrame('Button', nil, parent, BackdropTemplateMixin and "InSecureActionButtonTemplate, BackdropTemplate" or nil)
	frame:SetBackdrop(backdrop)
	frame:SetPoint('LEFT', 16, 0)
	frame:SetPoint('RIGHT', -16, 0)
	frame:SetAttribute('type', 'macro')
	if previousTask ~= nil then
		frame:SetPoint('TOP', previousTask.frame, 'BOTTOM', 0, -16)
	end
	task.frame = frame

	-- Highlight Texture
 	local texture = frame:CreateTexture()
	texture:SetColorTexture(0.5, 0.5, 0.5, 1)
	texture:SetBlendMode('BLEND')
	texture:SetPoint('TOPLEFT', 1, -1)
	texture:SetPoint('BOTTOMRIGHT', -1, 1)
	texture:SetGradientAlpha('HORIZONTAL', .5, .5, .5, .8, .5, .5, .5, 0)
	frame:SetHighlightTexture(texture)

	local title = frame:CreateFontString()
	title:SetFont(GameFontNormal:GetFont(), 11)
	title:SetText(titleText)
	title:SetPoint('LEFT', frame, 'LEFT', 16, 0)
	title:SetPoint('RIGHT', frame, 'RIGHT', -16, 0)
	title:SetPoint('TOP', frame, 'TOP', 0, -8)
	title:SetJustifyH('CENTER')
	title:SetTextColor(1, 1, 1)
	task.title = title

	local description = frame:CreateFontString()
	description:SetFont(GameFontNormal:GetFont(), 9)
	description:SetPoint('LEFT', frame, 'LEFT', 16, 0)
	description:SetPoint('RIGHT', frame, 'RIGHT', -16, 0)
	description:SetPoint('TOP', title, 'BOTTOM', 0, -4)
	description:SetJustifyH('CENTER')
	task.description = description
	task:SetDescription(descriptionText)

	local line = frame:CreateLine()
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

function WorkTask:SetDescription(description)
	self.description:SetText(description)
	local totalHeight = 6 + self.title:GetStringHeight() + 6 + self.description:GetStringHeight() + 6 + 4
	self.frame:SetHeight(totalHeight)
end

function WorkTask:Complete()
	self.frame:SetBackdropColor(0.373, 0.729, 0.275, 0.3) -- green, to match website colors
	self.frame:SetBackdropBorderColor(0.373, 0.729, 0.275)
	self.line:SetColorTexture(0.388, 0.686, 0.388, 1) -- green
end

function WorkTask:Disable(isFinish)
	self.frame:SetEnabled(false)
	if isFinish then
		self.frame:SetBackdropColor(0.557, 0.055, 0.075, 0.7	) -- red
		self.frame:SetBackdropBorderColor(1, 1, 1)
	else
		self.frame:SetBackdropColor(0.1, 0.1, 0.1, 0.5) -- gray
		self.frame:SetBackdropBorderColor(0.4, 0.4, 0.4)
	end

	self.line:SetColorTexture(0.2, 0.2, 0.2, 1)
	self.line:SetDrawLayer("ARTWORK",0)
end

function WorkTask:Enable()
	self.frame:SetEnabled(true)
	self.frame:SetBackdropColor(0.851, 0.608, 0.0, 0.3) -- yellow
	self.frame:SetBackdropBorderColor(0.851, 0.608, 0.0, 1)
	self.line:SetColorTexture(0.851, 0.608, 0.0, 1) -- yellow
	self.line:SetDrawLayer("ARTWORK",1)
end

function WorkTask:HookScript(event, script)
	self.frame:HookScript(event, script)
end

function WorkTask:SetScript(event, script)
	self.frame:SetScript(event, script)
end

function WorkTask:SetSpell(name)
	self.frame:SetAttribute('macrotext', '/cast '..name)
end

function WorkTask:Run()
	self.frame:Click()
end

function WorkTask:SetPoint(...)
	self.frame:SetPoint(...)
end
