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
end
