WorkWorkTradeFrame = CreateFrame('Frame')
WorkWorkTradeFrame:RegisterEvent('TRADE_ACCEPT_UPDATE')
WorkWorkTradeFrame:RegisterEvent('TRADE_CLOSED')
WorkWorkTradeFrame:RegisterEvent('TRADE_MONEY_CHANGED')
WorkWorkTradeFrame:SetScript('OnEvent', function(self, event, ...)
	self[event](self, ...)
end)

function GetTradeTargetName()
	if TradeFrameRecipientNameText ~= nil then
		return TradeFrameRecipientNameText:GetText()
	end
	return nil
end

-- function Trade(targetName, on)
