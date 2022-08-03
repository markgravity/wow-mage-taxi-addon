function Whisper(targetName, message)
	SendChatMessage(
		message,
		"WHISPER" ,
		 nil,
		 targetName
	)
end

function SendPartyMessage(message)
	SendChatMessage(
		message,
		"PARTY"
	)
end

function SendSmartMessage(targetName, message, delay)
	local delay = delay or 1
	if not IsInGroup() or GetNumGroupMembers() > 2 then
		C_Timer.After(delay, function()
			Whisper(targetName, message)
		end)

	else
		C_Timer.After(delay, function()
			SendPartyMessage(message)
		end)
	end
end
