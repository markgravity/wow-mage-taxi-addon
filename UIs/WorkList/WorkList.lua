local WorkList = {}
WorkWork.UIs.WorkList = WorkList

function CreateWorkList(parent)
	local workList = {
		works = {}
	}
	extends(workList, WorkList)

	local frame = CreateFrame(
		'Frame',
		'WorkWorkWorkList',
		parent,
		BackdropTemplateMixin and 'BackdropTemplate' or nil
	)
    frame:SetWidth(WORK_LIST_WIDTH)
    frame:SetHeight(WORK_LIST_HEIGHT)
    frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetPoint('TOPLEFT', -WORK_LIST_WIDTH, 0)
	workList.frame = frame

	local bg = frame:CreateTexture(nil, 'ARTWORK')
    bg:SetPoint('TOPLEFT', 12, -12)
    bg:SetPoint('BOTTOMRIGHT', -12, 12)
    bg:SetTexture('Interface\\FrameGeneral\\UI-Background-Rock')

	local tableWidth = frame:GetWidth() - 20
	local iconColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'TypeColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	iconColumnHeader:SetPoint('TOPLEFT', 13, -12)
    iconColumnHeader:SetText('')
    WhoFrameColumn_SetWidth(iconColumnHeader, 20)

	local targetNameColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'TargetNameColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	targetNameColumnHeader:SetPoint("LEFT", iconColumnHeader, "RIGHT", 0, 0)
    targetNameColumnHeader:SetText('Target')
    WhoFrameColumn_SetWidth(targetNameColumnHeader, tableWidth / 3)

	local statusColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'StatusColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	statusColumnHeader:SetPoint("LEFT", targetNameColumnHeader, "RIGHT", 0, 0)
    statusColumnHeader:SetText('Status')
    WhoFrameColumn_SetWidth(statusColumnHeader, tableWidth * 2 / 3 - 44)

	workList.columnHeaders = {
		iconColumnHeader,
		targetNameColumnHeader,
		statusColumnHeader
	}

	local tableBody = CreateFrame('Frame', nil, frame, 'InsetFrameTemplate')
    tableBody:SetPoint('TOPLEFT', 10, -33)
    tableBody:SetPoint('BOTTOMRIGHT', -10, 10)

	local scrollFrame = CreateFrame(
		'ScrollFrame',
		frame:GetName()..'ScrollFrame',
		tableBody,
		'UIPanelScrollFrameTemplate'
	)
	scrollFrame:SetPoint('LEFT', 5, 0)
	scrollFrame:SetPoint('TOP', 0, -6)
	scrollFrame:SetPoint('BOTTOM', 0, 4)
	scrollFrame:SetPoint('RIGHT', -26, 0)

	local scrollContent = CreateFrame(
		'Frame',
		scrollFrame:GetName()..'Content',
		scrollFrame
	)
	scrollContent:SetPoint('TOPLEFT', scrollFrame, 0, 0)
	workList.scrollContent = scrollContent

	scrollFrame:SetScrollChild(scrollContent)

	return workList
end

function WorkList:TryAdd(targetName, guid, text, parent)
	-- Prevent target spams chat
	for _, work in ipairs(self.works) do
		if work.targetName == targetName then
			return
		end
	end

	local detectors = {
		{
			type = 'portal',
			func = DetectPortalWork
		},
		{
			type = 'enchant',
			func = DetectEnchantWork
		}
	}
	for _, detector in ipairs(detectors) do
		local controller = detector.func(targetName, guid, text, parent)
		if controller then
			self:Add(targetName, controller, detector.type)
			return
		end
	end
end

function WorkList:ManualyAdd(targetName, type, parent)
	for _, work in ipairs(self.works) do
		if work.targetName == targetName then
			return
		end
	end

	local creators = {
		portal = {
			type = 'portal',
			makeController = function()
				return CreatePortalWork(targetName, '', nil, parent)
			end,
			item = nil
		},
		enchant = {
			type = 'enchant',
			makeController = function()
				return CreateEnchantWork(targetName, '', nil, parent)
			end,
			item = {}
		},
		prospecting = {
			type = 'prospecting',
			makeController = function()
				return CreateProspectingWork(parent)
			end,
			item = {}
		}
	}
	local creator = creators[type]
	local controller = creator.makeController()
	if controller then
		self:Add(targetName, controller, type)
		return
	end
end

function WorkList:Add(targetName, controller, type)
	local work = {
		id = targetName,
		targetName = targetName,
		status = controller:GetStateText(),
		type = type,
		icon = WorkWork.works[type].icon,
		controller = controller,
		createdAt = GetTime()
	}
	table.insert(self.works, work)

	controller.frame:SetPoint('TOPLEFT', self.frame, 'TOPRIGHT', -11, 0)

	self:Reload()
	self:AutoAssign()
	if self.onWorksUpdate then
		self.onWorksUpdate()
	end

	controller:Start()
end

function WorkList:Remove(work)
	local foundIndex
	for i, v in ipairs(self.works) do
		if work.id == v.id then
			foundIndex = i
		end

		-- Hide the rest
		if foundIndex ~= nil then
			v.item:Hide()
		end
	end

	if foundIndex == nil then
		return
	end

	if work.id == self.selectedWork.id then
		self.selectedWork = nil
	end

	work.item:Hide()
	table.remove(self.works, foundIndex)

	self:Reload()
	self:AutoAssign()
	if self.onWorksUpdate then
		self.onWorksUpdate()
	end
end

function WorkList:AutoAssign()
	if #self.works == 0 then
		return
	end

	if self.selectedWork == nil
	 	or self.selectedWork.priorityLevel == 4 then
		local work = self:FindHighestPriorityLevel()
		if self.selectedWork ~= nil and work.priorityLevel >= 4 then
			return
		end
		self:Select(work)
		return
	end
end

function WorkList:Select(work)
	if self.selectedWork ~= nil then
		self.selectedWork.controller:Hide()
		self.selectedWork.item:SetSelected(false)
	end

	self.selectedWork = work
	work.item:SetSelected(true)
	work.controller:Show()
end

function WorkList:Reload()
	local workList = self
	self.scrollContent:SetSize(self.frame:GetWidth() - 40, WORK_LIST_ITEM_HEIGHT * #self.works)

	local previousItem
	for i, work in ipairs(self.works) do
		local item = CreateWorkListItem(
			i,
			work,
			self.scrollContent,
			self.columnHeaders,
			previousItem
		)
		local priorityLevel = workList:GetWorkPriorityLevel(work)
		item:SetPriorityLevel(priorityLevel)
		item:Show()
		item:SetScript('OnClick', function()
			workList:Select(work)
		end)
		work.priorityLevel = priorityLevel
		work.item = item
		work.controller:SetScript('OnStateChange', function()
			local priorityLevel = workList:GetWorkPriorityLevel(work)
			item:SetStatus(work.controller:GetStateText())
			item:SetPriorityLevel(priorityLevel)
			work.priorityLevel = priorityLevel
			workList:AutoAssign()
		end)
		work.controller:SetScript('OnComplete', function()
			workList:Remove(work)
		end)
		previousItem = item
	end

	if self.selectedWork ~= nil then
		self.selectedWork.item:SetSelected(true)
	end
end

function WorkList:GetWorkPriorityLevel(work)
	local waitingTime = GetTime() - work.createdAt
	local priorityLevel = work.controller:GetPriorityLevel()
	if priorityLevel == 2 and waitingTime > 60*3 then
		priorityLevel = 1
	end

	return priorityLevel
end

function WorkList:FindHighestPriorityLevel()
	local unpack = unpack or table.unpack
	local sortedWorks = { unpack(self.works) }
	table.sort(sortedWorks, function (a, b)
		local waitingTimeA = GetTime() - a.createdAt
		local waitingTimeB = GetTime() - b.createdAt
		if a.priorityLevel <= 2 and a.priorityLevel == b.priorityLevel then
			return waitingTimeA > waitingTimeB
		end
		return a.priorityLevel < b.priorityLevel
	end)

	return sortedWorks[1]
end

function WorkList:SetScript(event, script)
	if event == 'OnWorksUpdate' then
		self.onWorksUpdate = script
		return
	end
end

function WorkList:GetWorksCount()
	return #self.works
end

function WorkList:Show()
	self.frame:Show()
end

function WorkList:Hide()
	self.frame:Hide()
end
