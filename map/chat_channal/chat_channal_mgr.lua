Chat_channal_mgr = oo.class(nil, "Chat_channal_mgr")

function Chat_channal_mgr:__init()
	self.channal_list = {}
	self.member_list = {}
end

function Chat_channal_mgr:new_channal()
	local channal_id = crypto.uuid()
	self.channal_list[channal_id] = Chat_channal()
	return channal_id
end

function Chat_channal_mgr:remove_channal(channal_id)
	local channal = self.channal_list[channal_id]
	if channal then
		self.channal_list[channal_id] = nil
		for k, _ in pairs(channal:get_members()) do
			if self.member_list[k] == channal_id then
				self.member_list[k] = nil
			end
		end
	end
end

function Chat_channal_mgr:add_member(char_id, channal_id)
	local channal = self.channal_list[channal_id]
	if channal then
		local old_id = self.member_list[char_id]
		if not old_id then
			channal:add(char_id)
			self.member_list[char_id] = channal_id
		elseif old_id ~= channal_id then
			local old_channal = self.channal_list[old_id]
			if old_channal then
				old_channal:del(char_id)
			end
			channal:add(char_id)
			self.member_list[char_id] = channal_id
		end
	end
end

function Chat_channal_mgr:del_member(char_id, channal_id)
	local old_id = self.member_list[char_id]
	if old_id == channal_id then
		local channal = self.channal_list[channal_id]
		if channal then
			channal:del(char_id)
		end
		self.member_list[char_id] = nil
	end
end

function Chat_channal_mgr:say(char_id, content)
	local channal_id = self.member_list[char_id]
	local channal = channal_id and self.channal_list[channal_id]
	if channal then
		channal:say(char_id, content)
	end
end

function Chat_channal_mgr:message(channal_id, content)
	local channal = channal_id and self.channal_list[channal_id]
	if channal then
		channal:message(content)
	end
end