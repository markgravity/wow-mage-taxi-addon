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
