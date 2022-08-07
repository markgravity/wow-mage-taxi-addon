WorkWorkTrade = CreateFrame('Frame')
WorkWorkTrade:RegisterEvent('TRADE_ACCEPT_UPDATE')
WorkWorkTrade:RegisterEvent('TRADE_CLOSED')
WorkWorkTrade:RegisterEvent('TRADE_MONEY_CHANGED')
WorkWorkTrade:SetScript('OnEvent', function(self, event, ...)
	self[event](self, ...)
end)

function WorkWorkTrade:TRADE_ACCEPT_UPDATE(playerAccepted, targetAccepted)
	self.playerAccepted = playerAccepted
	self.targetAccepted = targetAccepted
end

function WorkWorkTrade:TRADE_MONEY_CHANGED()
	if self.onMoneyChanged then
		self.onMoneyChanged()
	end
end

function WorkWorkTrade:TRADE_CLOSED()
	local isSuccess = self.playerAccepted == 1 and self.targetAccepted == 1
	if self.onComplete ~= nil then
		self.onComplete(isSuccess)
	end
end

function GetTradeTargetName()
	if TradeFrameRecipientNameText ~= nil then
		return TradeFrameRecipientNameText:GetText()
	end
	return nil
end

function Trade(unitID, targetName, onCompleted, onMoneyChanged)
	if TradeFrame:IsShown() then
		if targetName ~= GetTradeTargetName() then
			onComplete(false)
			return
		end
		WorkWorkTrade.onComplete = onComplete
		WorkWorkTrade.onMoneyChanged = onMoneyChanged
		return
	end

	local result = InitiateTrade(unitID)
	if result == nil then
		onCompleted(false)
	end
	WorkWorkTrade.onComplete = onComplete
	WorkWorkTrade.onMoneyChanged = onMoneyChanged
end
