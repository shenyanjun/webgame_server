
require("activity_reward.activity_reward_db")
local collection_activity_loader = require("config.loader.collection_activity_loader")

Activity_reward_container = oo.class(nil, "Activity_reward_container")


local cost_table = {0, 0, 1, 2, 4, 6, 8,
					12, 16, 20, 24, 28}
for i = 13, 27 do
	cost_table[i] = 32
end
--print("13 =", j_e(cost_table))
-----------------------------------领取活动奖励情况-----------------------------


function Activity_reward_container:__init(char_id, first_login)
	self.char_id	= char_id

	self.flags = false
	--local change_t, id = collection_activity_loader.get_recently_id()
	local info = g_gm_function_con:get_long_info()
	if info then
		self.id = info.id 
		local change_t = info.end_t 
		--self:load( first_login)
	end
end

function Activity_reward_container:load(first_login)
	if self.id then
		local rows
		if not first_login then
			rows = Activity_reward_db:select_activity_reward(self.char_id, self.id)
			if rows then
				for k, v in pairs(rows) do
					self.lvl = v.lvl
					self.donate = v.donate

					self.buf_l = v.buf_l
					local t_flags = true
					for k, v in pairs(self.buf_l or {}) do
						t_flags = false
						break
					end
					if t_flags then
						local tmp_lvl = g_activity_reward_mgr:get_lvl()
						if tmp_lvl then
							local reward_info = collection_activity_loader.get_reward_info(self.id, tmp_lvl)
							for k, v in pairs(reward_info.buf_l) do
								self.buf_l[k] = 0
							end
						end
					end

					--self.item_l = v.item_l
					self.money_l = v.money_l
					self.item_index = {}		--物品ID索引
					self.item_l = {}
					self:add_item_l(v.item_l)
					break
				end
			else
				self.lvl = 0
				self.donate = 0

				--初始化buf奖励
				self.buf_l = {}
				local tmp_lvl = g_activity_reward_mgr:get_lvl()
				if tmp_lvl then
					local reward_info = collection_activity_loader.get_reward_info(self.id, tmp_lvl)
					for k, v in pairs(reward_info.buf_l) do
						self.buf_l[k] = 0
					end
				end

				self.item_l = {}
				self.money_l = {}
				for i = 1, 4 do
					self.money_l[i] = 0
				end

				self.item_index = {}
				self:new_player_get_reward()		

				self.flags = true
			end
		else
			self.lvl = 0
			self.donate = 0
			self.buf_l = {}
			self.item_l = {}
			self.money_l = {}
			for i = 1, 4 do
				self.money_l[i] = 0
			end

			self.item_index = {}
		end

		--self:lvlup_reward()		--每次登陆领取一次
	end
end

function Activity_reward_container:level_up_init()
	self.lvl = 0
	self.donate = 0
	self.buf_l = {}
	self.item_l = {}
	self.money_l = {}
	for i = 1, 4 do
		self.money_l[i] = 0
	end

	self.item_index = {}
end

--存盘
function Activity_reward_container:save()
	if self.id then
		local tmp_table = {}
		tmp_table.id = self.id
		tmp_table.lvl = self.lvl
		tmp_table.char_id = self.char_id
		tmp_table.buf_l = self.buf_l
		tmp_table.item_l = self.item_l
		tmp_table.money_l = self.money_l
		tmp_table.donate = self.donate

		Activity_reward_db:update(tmp_table)
	end
end

--清掉个人活动
function Activity_reward_container:clear()
	if self.id then
		local tmp_table = {}
		tmp_table.id = self.id
		tmp_table.char_id = self.char_id

		Activity_reward_db:update(tmp_table)
	end
end

-------------------------------------内部接口---------
--隔天和每日首登操作
function Activity_reward_container:newday_update()
	if self.char_id == 0 or not g_activity_reward_mgr:get_swicth() then
		return
	end

	local info = g_gm_function_con:get_long_info()
	local id = (info and info.id) or nil 
	local change_t = (info and info.end_t) or nil 

	--local change_t, id = collection_activity_loader.get_recently_id()
	--print("107 =", id)
	if not id then
		if self.id then		--活动已结束
			self:save()
		end
		self.lvl = nil
		self.buf_l = nil
		self.item_l = nil
		self.money_l = nil
		self.item_index = nil
	else
		--if not self.id then		--活动刚开始
			--self.lvl = 0
			--self.donate = 0
			--self.buf_l = {}
			--self.item_l = {}
			--self.money_l = {}
			--for i = 1, 4 do
				--self.money_l[i] = 0
			--end
			--self.item_index = {}
--
			--self:get_daily_reward()
			----print("131")
		--else					--隔天更新
			----自动领取每日奖励
			--self:get_daily_reward()
			--self.donate = 0
			----print("136")
		--end

		--领取奖励
		self:get_daily_reward()
		self.donate = 0

	end

	self.id = id
end


--打开活动
function Activity_reward_container:open_activity(id, lvl)
	self.id = id
	self.lvl = lvl
	self.donate = 0
	self.buf_l = {}
	self.item_l = {}
	self.money_l = {}
	for i = 1, 4 do
		self.money_l[i] = 0
	end
	self.item_index = {}

	if not g_activity_reward_mgr:get_swicth() then
		return
	end

	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end
	if player:get_level() < 40 then return end

	local reward_info = collection_activity_loader.get_reward_info(self.id, lvl)
	--初始化buf奖励
	self.buf_l = {}
	for k, v in pairs(reward_info.buf_l) do
		self.buf_l[k] = 0
	end

	--领取物品奖励
	self:add_item_l(reward_info.item_l, 1)

	--领取货币奖励
	local money_l = {}
	for k, v in ipairs(reward_info.money_l) do
		local money = v * math.max((1 - math.max((90 - player:get_level()), 0) * 0.016), 0)
		if money > 0 then
			money_l[k] = money
		end
	end
	for k, v in pairs(money_l) do
		self.money_l[k] = (self.money_l[k] or 0) + v
	end

	local str = string.format("insert log_collect set char_id = %d, char_name='%s', io=%d, type=%d, reward='%s', keep='%s', time=%d",
			self.char_id, player:get_name(), 1, 4, Json.Encode(money_l), Json.Encode(self.money_l), os.time())

	f_multi_web_sql(str)
end

--自动领取每日奖励
function Activity_reward_container:get_daily_reward()
	if not g_activity_reward_mgr:get_swicth() then
		return
	end
	if not self.flags then
		local player = g_obj_mgr:get_obj(self.char_id)
		if not player then return end
		if player:get_level() < 40 then return end

		local lvl = g_activity_reward_mgr:get_lvl()
		if lvl then
			local reward_info = collection_activity_loader.get_reward_info(self.id, lvl)
			--初始化buf奖励
			self.buf_l = {}
			for k, v in pairs(reward_info.buf_l) do
				self.buf_l[k] = 0
			end

			--领取物品奖励
			self:add_item_l(reward_info.item_l, 1)

			--领取货币奖励
			local money_l = {}
			for k, v in ipairs(reward_info.money_l) do
				local money = v * math.max((1 - math.max((90 - player:get_level()), 0) * 0.016), 0)
				if money > 0 then
					money_l[k] = money
				end
			end
			for k, v in pairs(money_l) do
				self.money_l[k] = (self.money_l[k] or 0) + v
			end

			local str = string.format("insert log_collect set char_id = %d, char_name='%s', io=%d, type=%d, reward='%s', keep='%s', time=%d",
					self.char_id, player:get_name(), 1, 4, Json.Encode(money_l), Json.Encode(self.money_l), os.time())
		
			f_multi_web_sql(str)

		end
	end

	self.flags = false
end

--新玩家初始化领取每日奖励
function Activity_reward_container:new_player_get_reward()
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end
	if player:get_level() < 40 then return end

	local lvl = g_activity_reward_mgr:get_lvl()
	if lvl then
		local reward_info = collection_activity_loader.get_reward_info(self.id, lvl)
		--初始化buf奖励
		self.buf_l = {}
		for k, v in pairs(reward_info.buf_l) do
			self.buf_l[k] = 0
		end

		--领取物品奖励
		self:add_item_l(reward_info.item_l, 1)

		--领取货币奖励
		local money_l = {}
		for k, v in ipairs(reward_info.money_l) do
			local money = v * math.max((1 - math.max((90 - player:get_level()), 0) * 0.016), 0)
			if money > 0 then
				money_l[k] = money
			end
		end
		for k, v in pairs(money_l) do
			self.money_l[k] = (self.money_l[k] or 0) + v
		end

		local str = string.format("insert log_collect set char_id = %d, char_name='%s', io=%d, type=%d, reward='%s', keep='%s', time=%d",
					self.char_id, player:get_name(), 1, 4, Json.Encode(money_l), Json.Encode(self.money_l), os.time())
		
		f_multi_web_sql(str)
	end
end

--获得缓存物品，平衡self.item_index
function Activity_reward_container:add_item_l(item_l, type)
	for k, v in ipairs(item_l) do
		if not self.item_index[v.item_id] then
			--if not v.name then 
				--print("171 =", debug.traceback())
			--end
			local item_t = {}
			item_t.item_id = v.item_id
			item_t.number = v.number
			item_t.item_name = v.name or v.item_name
			item_t.type = 1
			table.insert(self.item_l, item_t)
			self.item_index[v.item_id] = table.getn(self.item_l)
		else
			local item_t = self.item_l[self.item_index[v.item_id]]
			item_t.number = item_t.number + v.number
		end
	end

	if type then		--写日志
		local player = g_obj_mgr:get_obj(self.char_id)
		if not player then return end

		local str = string.format("insert log_collect set char_id = %d, char_name='%s', io=%d, type=%d, reward='%s', keep='%s', time=%d",
					self.char_id, player:get_name(), 1, type, Json.Encode(item_l), Json.Encode(self.item_l), os.time())
		
		f_multi_web_sql(str)
	end
end

--捐赠获取奖励 还有经验
--type1普通 2昂贵		index物品索引		count数量
function Activity_reward_container:add_reward(type, index, count)
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end
	local exp = collection_activity_loader.get_donate_item_exp(self.id, index) or 0
	exp = count * exp * math.max((1 - math.max((90 - player:get_level()), 0) * 0.016), 0)
	player:add_exp(exp)

	local item_param = collection_activity_loader.Gift_Random_Item

	local id 		--随机ID
	if type == 1 then
		id = collection_activity_loader.get_common_random_id(self.id, index)
	elseif type == 2 then
		id = collection_activity_loader.get_exp_random_id(self.id, index)
	end

	local player = g_obj_mgr:get_obj(self.char_id)
	local p_name = player:get_name()

	local item_list = {}
	local s_list = {}
	local l_list = {}
	local cnt , rd, ret
	local flags = false

	for i = 1, count do
		for k,v in pairs(item_param[id]['item_list']) do
			cnt = item_param[id]['count'][k] 
			while cnt>0 do	
				if not item_param[id]['length'] then	
					print("379 =", id, k)
				end
				rd = crypto.random(1,item_param[id]['length'][k] + 1)			
				ret = item_param[type]['ret'][k][rd]  
				
				if tonumber(ret['id']) ~= 0 then
					item_list[#item_list + 1] = { ['item_id']=tonumber(ret['id']), ['number']=tonumber(ret['count']) or 1 , 
						['name']=ret.name, ['type']=1}	
						local tmp_table = {}
					if tonumber(ret['broadcast']) == 1	then
						flags = true
						tmp_table[1] = p_name
						tmp_table[2] = ret.name
						tmp_table[3] = tonumber(ret.id)
						tmp_table[4] = tonumber(ret.count)
						s_list[#s_list + 1] = tmp_table
					else
						tmp_table[1] = p_name
						tmp_table[2] = ret.name
						tmp_table[3] = tonumber(ret.id)
						tmp_table[4] = tonumber(ret.count)
						tmp_table[5] = self.char_id
						l_list[#l_list + 1] = tmp_table
					end
				end
				cnt = cnt - 1
			end
		end
	end
--	print("281 =", j_e(item_list))
	self:add_item_l(item_list, 1 + type)

	if table.getn(l_list) > 0 then
		g_svsock_mgr:send_server_ex(COMMON_ID,self.char_id, CMD_COLLECTION_ACTIVITY_EXP_M, l_list)
	end

	if flags then
		g_svsock_mgr:send_server_ex(COMMON_ID,self.char_id, CMD_COLLECTION_ACTIVITY_EXP_M, s_list)
	end
end


--通知公共服增加
function Activity_reward_container:notice_common_add(index, count)
	local pkt = {}
	pkt.count = count
	pkt.index = index

	g_svsock_mgr:send_server_ex(COMMON_ID,self.char_id, CMD_COLLECTION_ACTIVITY_DONATE_M, pkt)
	return
end
-------------------------------------外部接口---------
--外部通知计算升级
--function Activity_reward_container:reward_lvlup()
	--self:get_lvlup_reward()
--
	--return
--end

--获取灵气卷轴信息
function Activity_reward_container:get_donate_info()
	local player = g_obj_mgr:get_obj(self.char_id)

	local pkt = {}
	pkt[1] = self.donate
	pkt[2] = player:get_addition(HUMAN_ADDITION.collections)
	

	return pkt
end

--灵气捐赠
function Activity_reward_container:donate_anima(id)
	if not self.id then return 22721 end

	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	local limit_cnt = player:get_addition(HUMAN_ADDITION.collections)
	
	if self.donate >= limit_cnt then
		return 22722
	end
	
	if self.donate >= 2 then	--超过2次收费
		local cost = cost_table[self.donate + 1]
		local money_l = {}
		money_l[MoneyType.GIFT_JADE] = cost
		local e_code = pack_con:dec_money_l_inter_face(money_l, {['type']=MONEY_SOURCE.ACTIVITY_COST})
		if e_code ~= 0 then
			return e_code
		end

		self.donate = self.donate + 1

		--加物品
		self:add_reward(2, id, 1)
	else
		self.donate = self.donate + 1
		--加物品
		self:add_reward(1, id, 1)
	end
	

	--通知加捐赠物
	self:notice_common_add(id, 1)

	return 0
end

--实物捐赠
function Activity_reward_container:donate_real(id, count)
	if not self.id then return 22721 end
	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()

	
	local item_id = collection_activity_loader.get_donate_item_id(self.id, id)
	--扣物品
	local e_code = pack_con:del_item_by_item_id_inter_face(item_id, count, {['type']=ITEM_SOURCE.ACTIVITY_DONATE}, 1)
	if e_code ~= 0 then
		return e_code
	end

	--加奖励
	self:add_reward(1, id, count)

	--通知更新
	self:notice_common_add(id, count)

	return 0
end

--获取个人奖励情况
function Activity_reward_container:get_player_reward_info()
	local pkt = {}
	pkt.result = 0

	if not self.id then
		pkt.result = 22721
		return pkt 
	end
	
	pkt.buf_l = {}
	for k, v in pairs(self.buf_l) do
		local tmp_t = {}
		tmp_t.buf_id = k
		tmp_t.time = g_activity_reward_mgr:get_buf_limit(k) - v
		table.insert(pkt.buf_l, tmp_t)
	end
	pkt.item_l = self.item_l
	pkt.money_l = self.money_l

	return pkt
end

--获取个人奖励
function Activity_reward_container:get_player_reward(pkt)
	if not self.id then return 22721 end
	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()

	if pkt.type == 1 then
		local item_l = table.copy(self.item_l)
		local money_l = table.copy(self.money_l)

		local e_code = pack_con:check_add_item_l_inter_face(item_l)
		if e_code ~= 0 then
			return e_code
		end

		self.item_l = {}
		self.item_index = {}
		self.money_l = {}

		pack_con:add_item_l(item_l, {['type']=ITEM_SOURCE.ACTIVITY_GAIN})
		pack_con:add_money_l(money_l, {['type']=MONEY_SOURCE.ACTIVITY_GAIN})

		return 0
	else
		local buf_id = tonumber(pkt.buf_id)
		local time = pkt.time
		local limit = g_activity_reward_mgr:get_buf_limit(buf_id) - self.buf_l[buf_id]
		
		if time > limit then
			return 22724
		end

		self.buf_l[buf_id] = self.buf_l[buf_id] + time

		local impact_o
		local effect, lvl = g_activity_reward_mgr:get_buf_effect(buf_id)
		if buf_id == 1 then
			impact_o = Impact_1991(self.char_id, lvl)
		elseif buf_id == 2 then		--打怪buf
			impact_o = Impact_3003(self.char_id, lvl)
		end
		
		
		impact_o:set_count(time * 60)
		local param = {}
		param.per = effect
		impact_o:effect(param)
		--print("394 =", time * 60, j_e(param), self.char_id, lvl)
		local tmp_buf = {}
		tmp_buf.buf_id = buf_id
		tmp_buf.time = time

		local left_buf = {}
		left_buf.buf_id = buf_id
		left_buf.time = self.buf_l[buf_id]

		local str = string.format("insert log_collect set char_id = %d, char_name='%s', io=%d, type=%d, reward='%s', keep='%s', time=%d",
					self.char_id, player:get_name(), 0, 5, Json.Encode(tmp_buf), Json.Encode(left_buf), os.time())
		
		f_multi_web_sql(str)

		return 0
	end
end


