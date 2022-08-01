function GetTradeTargetName()
	if TradeFrameRecipientNameText ~= nil then
		return TradeFrameRecipientNameText:GetText()
	end
	return nil
end
