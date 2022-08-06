local ItemList = {}
WorkWork.UIs.ItemList = ItemList

function ItemList:Init(parent)
	local frame = CreateFrame(
		'Frame',
		'WorkWorkItemList',
		parent,
		BackdropTemplateMixin and 'BackdropTemplate' or nil
	)

	local bg = frame:CreateTexture(nil, 'ARTWORK')
    bg:SetPoint('TOPLEFT', 12, -12)
    bg:SetPoint('BOTTOMRIGHT', -12, 12)
    bg:SetTexture('Interface\\FrameGeneral\\UI-Background-Rock')

	local checkColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'CheckColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	checkColumnHeader:SetPoint('TOPLEFT', 13, -12)
    checkColumnHeader:SetText('')
    WhoFrameColumn_SetWidth(checkColumnHeader, 20)

	local targetNameColumnHeader = CreateFrame(
		'BUTTON',
		frame:GetName()..'NameColumnHeader',
		frame,
		'GuildFrameColumnHeaderTemplate'
	)
	targetNameColumnHeader:SetPoint("LEFT", iconColumnHeader, "RIGHT", 0, 0)
    targetNameColumnHeader:SetText('Name')
    WhoFrameColumn_SetWidth(targetNameColumnHeader, frame:GetWidth() - 20)
end
