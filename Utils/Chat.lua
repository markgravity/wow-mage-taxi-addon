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

function SendSmartMessage(targetName, message)
	if GetNumGroupMembers() > 2 then
		Whisper(targetName, message)
	else
		SendPartyMessage(message)
	end
end
