local AutoTrade = CreateFrame('Frame')
MageTaxi.autoTrade = AutoTrade

AutoTrade.isEnabled = false
AutoTrade:SetScript('OnEvent', function(self, event, ...)
	self[event](self, ...)
end)

AutoTrade:RegisterEvent('TRADE_SHOW')
AutoTrade:RegisterEvent('TRADE_ACCEPT_UPDATE')

function AutoTrade:SetEnabled(isEnabled)
	self.isEnabled = isEnabled
end

function AutoTrade:TRADE_SHOW()
end

function AutoTrade:TRADE_ACCEPT_UPDATE(isPlayerAccepted, isTargetAccepted)
	if not self.isEnabled then
		return
	end
end
