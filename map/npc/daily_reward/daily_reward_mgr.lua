

local database = "npc_reward"


Daily_reward_mgr = oo.class(nil,"Daily_reward_mgr")


function Daily_reward_mgr:__init()
	self.reward_list ={}
end


function Daily_reward_mgr:create_reward(char_id)
	self.reward_list[char_id] = Daily_reward(char_id)
end


function Daily_reward_mgr:can_be_fetch(char_id,action_id)
	return self.reward_list[char_id]:can_be_fetch(action_id)
end

function Daily_reward_mgr:fetch_item(char_id,action_id,item)
	return self.reward_list[char_id]:fetch_item(action_id,item)
end

function Daily_reward_mgr:login(char_id)
	self:select_char(char_id)
	self.reward_list[char_id]:login()
end

function Daily_reward_mgr:leave(char_id)
	if self.reward_list[char_id] ~= nil then
		self.reward_list[char_id]:update_char()
		self.reward_list[char_id] = nil
	end
end


function Daily_reward_mgr:click_return()
	for k,v in pairs(self.reward_list or {}) do
		v:login()
	end
end



---------------------------------------------数据读写--------------------------------------------------------
function Daily_reward_mgr:select_char(char_id)

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	if not player:is_first_login() then
		local dbh = f_get_db()
		local query =string.format("{char_id:%d}",char_id)
		local row, e_code = dbh:select_one(database, nil, query , nil,"{char_id:1}")
		if e_code == 0 and row ~= nil then
			self:create_reward(char_id)
			self.reward_list[char_id].login_time = row.login_time
			self.reward_list[char_id].action_list = row.action_list
		end 
		if row == nil then		
			self:create_reward(char_id)
			self.reward_list[char_id]:insert_char()
		end
	else
		self:create_reward(char_id)
	end
end