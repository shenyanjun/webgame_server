local database = "yellow_reward"
local ONE_DAY = 86400


Yellow_reward_mgr = oo.class(nil,"Yellow_reward_mgr")


function Yellow_reward_mgr:__init()
	self.yellow_reward = {}
end

function Yellow_reward_mgr:create_yellow_reward(char_id)
	self.yellow_reward[char_id] = Yellow_reward(char_id)
end

function Yellow_reward_mgr:online(char_id,first_login)
	self:select_db(char_id,first_login)
	if not self.yellow_reward[char_id] then
		self:create_yellow_reward(char_id)
	else
		self.yellow_reward[char_id]:online()
	end	
end

function Yellow_reward_mgr:outline(char_id)	
	if self.yellow_reward[char_id] then
		self.yellow_reward[char_id]:update_char()
	end
end

function Yellow_reward_mgr:select_db(char_id,first_login)
	if first_login then
		self:create_yellow_reward(char_id)
	else
		local dbh = f_get_db()
		local query =string.format("{char_id:%d}",char_id)
		local row, e_code = dbh:select(database,nil,query)
		if e_code == 0 and row then
			for i,v in pairs(row or {}) do
				if v.yellow_reward then
					self:create_yellow_reward(v.char_id)
					self.yellow_reward[v.char_id].login_time = v.yellow_reward.login_time
					self.yellow_reward[v.char_id].new_sign = v.yellow_reward.new_sign
					self.yellow_reward[v.char_id].every_sign = v.yellow_reward.every_sign				
				end
			end
		end 
	end
end

function Yellow_reward_mgr:can_reward(char_id,type)
	return self.yellow_reward[char_id]:is_can_reward(type)
end

function Yellow_reward_mgr:set_sign(char_id,type)
	self.yellow_reward[char_id]:set_gift_sign(type)
end

function Yellow_reward_mgr:info_to_net(char_id)
	return self.yellow_reward[char_id]:info_to_net()
end

