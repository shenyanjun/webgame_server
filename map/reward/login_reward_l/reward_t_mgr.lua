--2010-01-20
--laojc
--登录奖励管理类
local database = "reward"

Reward_t_mgr = oo.class(nil,"Reward_t_mgr")

function Reward_t_mgr:__init()
	self.reward_list = {}
	self.reward_list[1] = {}
	self.reward_list[2] = {}
	self.reward_list[3] = {}
	self.reward_list[4] = {}

	self.add_login_list = {}
	self.sign_in_list = {}
end

--[[
功能：获取玩家相关奖励管理对象
参数：char_id -- 角色ID
      type -- 所要获取的奖励信息类型
返回：nil
--]]
function Reward_t_mgr:create_reward(char_id,type)
	if type == 1 then
		self.reward_list[type][char_id] = Day_reward(char_id)
	elseif type == 2 then
		self.reward_list[type][char_id] = Week_reward(char_id)
	elseif type == 3 then
		self.reward_list[type][char_id] = Festival_reward(char_id)
	elseif type == 4 then
		self.reward_list[type][char_id] = Continuous_reward(char_id)
	elseif type == 6 then
		self.sign_in_list[char_id] = Sign_in_reward(char_id)
	elseif type == 98 then
		self.add_login_list[char_id] = Add_login_reward(char_id)
	end
end

function Reward_t_mgr:can_be_fetch(char_id,type)
	if self.reward_list[type] == nil or self.reward_list[type][char_id] == nil then return end
	return self.reward_list[type][char_id]:can_be_fetch()
end

function Reward_t_mgr:fetch_item(char_id,type)
	if self.reward_list[type] == nil or self.reward_list[type][char_id] == nil then return end
	return self.reward_list[type][char_id]:fetch_item()
end

function Reward_t_mgr:online(char_id,first_login)
	self:select_char(char_id)
	for i=1,4 do
		if self.reward_list[i] == nil or self.reward_list[i][char_id] == nil then
			self:create_reward(char_id, i)
		end
		self.reward_list[i][char_id]:login()
	end
	if self.add_login_list[char_id] == nil then
		self:create_reward(char_id,98)
	end
	self.add_login_list[char_id]:login(first_login)
	--
	if self.sign_in_list[char_id] == nil then
		self:create_reward(char_id,6)
	end

	Rechage_reward:login(char_id)

end

function Reward_t_mgr:outline(char_id)
	for i=1, 4 do
		if self.reward_list[i] ~= nil and self.reward_list[i][char_id] ~= nil then
			self.reward_list[i][char_id]:leave()
			self.reward_list[i][char_id] = nil
		end
	end

	self.add_login_list[char_id] = nil
	self.sign_in_list[char_id] = nil
	Rechage_reward:logout(char_id)
end

function Reward_t_mgr:click_return()
	for i=1,4 do
		for k,v in pairs(self.reward_list[i] or {}) do
			v:login()
		end
	end
end

function Reward_t_mgr:get_net_info(char_id)
	local ret = {}
	for i=1,4 do
		ret[i] ={}
		ret[i] = self.reward_list[i][char_id]:get_net_info()
	end
	return ret
end

function Reward_t_mgr:new_day_come(char_id)
	self.add_login_list[char_id]:login()
	local ret = {}	
	ret = self.add_login_list[char_id]:send_net_info()
	ret.result = 0
	g_cltsock_mgr:send_client(char_id, CMD_MAP_ADD_LOGIN_REWARD_S , ret) -- 通知客户端
end

---------------------------------------------数据读写--------------------------------------------------------
function Reward_t_mgr:select_char(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	if player:is_first_login() then
		for i =1,4 do
			self:create_reward(char_id,i)
		end
		self:create_reward(char_id,98)
		self:create_reward(char_id,6)
	else
		local dbh = f_get_db()
		--local data = "{flag:1}"
		local query =string.format("{char_id:%d}",char_id)
		local rows, e_code = dbh:select(database, nil, query, nil, 0, 0, "{char_id:1,type:1}")
		if e_code == 0 and rows ~= nil then			
			for k,v in pairs(rows or {}) do
				local type = v.type
				-- 99为之前的累计登陆奖励 被删掉了 因为测试版没删除数据库数据所以没有删除99的判断（数据库清理后可删） 98为后来新手连续登陆及黄钻奖励要保留
				if type == 6 then
					self:create_reward(char_id,type)
					self.sign_in_list[char_id]:set_info(v)
				elseif type ~= 99 and type ~= 98 then      					
					self:create_reward(char_id,type)  
					self.reward_list[type][char_id].login_time = v.login_time
					self.reward_list[type][char_id].flag = v.flag
					self.reward_list[type][char_id].day = v.day 
					self.reward_list[type][char_id].item_list = v.item_list
				elseif type == 98 then
					self:create_reward(char_id,type)
					self.add_login_list[char_id].login_time = v.login_time
					self.add_login_list[char_id].login_day  = v.login_day
					self.add_login_list[char_id].reward_state = v.reward_state
					self.add_login_list[char_id].reward_yellow_state = v.reward_yellow_state
				end
			end
		end 
		if rows == nil then		
			for i =1,4 do
				self:create_reward(char_id,i)
				self.reward_list[i][char_id]:insert_char()
			end
			self:create_reward(char_id,98)
			self:create_reward(char_id,6)
		end
	end
end

--获取累计登陆对象
function Reward_t_mgr:get_addlogin_obj(char_id)
	return self.add_login_list[char_id]
end

--获取签到对象
function Reward_t_mgr:get_sign_in_obj(char_id)
	return self.sign_in_list[char_id]
end
