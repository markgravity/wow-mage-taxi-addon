WorkWorkAutoAcceptInvite = CreateFrame('Frame')

WorkWorkAutoAcceptInvite:SetScript('OnEvent', function(self, event, ...)
	self[event](self, ...)
end)

function WorkWorkAutoAcceptInvite:AcceptInvite()
	AcceptGroup()
	for i = 1, STATICPOPUP_NUMDIALOGS do
		local dialog = _G["StaticPopup" .. i]
		if dialog.which == "PARTY_INVITE" then
			dialog.inviteAccepted = 1
			break
		end
	end
	StaticPopup_Hide("PARTY_INVITE")
	if self.callback ~= nil then
		self.callback()
	end
end

function WorkWorkAutoAcceptInvite:PARTY_INVITE_REQUEST(eventName, inviter)
	self:AcceptInvite()
end

function WorkWorkAutoAcceptInvite:GROUP_JOINED()

end

function WorkWorkAutoAcceptInvite:SetEnabled(isEnabled, callback)
	if isEnabled then
		self.callback = callback
		self:RegisterEvent("PARTY_INVITE_REQUEST")
		self:RegisterEvent("GROUP_JOINED")
	else
		self:UnregisterEvent("PARTY_INVITE_REQUEST")
		self:UnregisterEvent("GROUP_JOINED")
	end
end
