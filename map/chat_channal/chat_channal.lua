Chat_channal = oo.class(nil, "Chat_channal")

function Chat_channal:__init()
	self.member_list = {}
end

function Chat_channal:say(char_id, content)
	if not self.member_list[char_id] then
		return
	end
	
	local result = Json.Encode({["say"] = content})
	for k, v in pairs(self.member_list) do
		g_cltsock_mgr:send_client(k, CMD_MAP_SIDE_SAY_S, result, true)
	end
end

function Chat_channal:add(char_id)
	self.member_list[char_id] = true
end

function Chat_channal:del(char_id)
	self.member_list[char_id] = nil
end

function Chat_channal:get_members()
	return self.member_list
end

function Chat_channal:message(content)

	local result = Json.Encode({["message"] = content})
	for k, v in pairs(self.member_list) do
		g_cltsock_mgr:send_client(k, CMD_MAP_SIDE_MESSAGE_S, result, true)
	end
end