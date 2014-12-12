local debug_print = function() end


---------------------------------------------------------------------------------------
--------------------所需累计时间,奖励item_id, 数量
local T_REWARD_INFO = {}
T_REWARD_INFO[1] = {1  * 60, 104001100120, 1} --小钱袋
T_REWARD_INFO[2] = {2  * 60, 104001140220, 15} --+1礼券卡
T_REWARD_INFO[3] = {3  * 60, 126010000140, 3} --一级元神加速符
T_REWARD_INFO[4] = {4  * 60, 610000000520, 3} --一阶防具强化石
T_REWARD_INFO[5] = {5  * 60, 610000000120, 3} --一阶神器强化石
T_REWARD_INFO[6] = {5  * 60, 105000000120, 5} --复活令
T_REWARD_INFO[7] = {5 * 60, 124020000120, 3} --一阶宠灵果
T_REWARD_INFO[8] = {5 * 60, 112010000120, 5} --洗炼神水
T_REWARD_INFO[9] = {6 * 60, 104001100120, 5} --小钱袋
T_REWARD_INFO[10] = {6 * 60, 202003606140, 2} --天元丹
T_REWARD_INFO[11] = {6 * 60, 126010000240, 2} --二级元神加速符
T_REWARD_INFO[12] = {7 * 60, 101180000320, 1} --还血丹（大）
T_REWARD_INFO[13] = {7 * 60, 101190000321, 1} --还灵丹（大）
T_REWARD_INFO[14] = {7 * 60, 610000000620, 2} --二阶防具强化石
T_REWARD_INFO[15] = {8 * 60, 610000000220, 2} --二阶神器强化石
T_REWARD_INFO[16] = {8 * 60, 124020000220, 2} --二阶宠灵果
T_REWARD_INFO[17] = {9 * 60, 202003606140, 3} --天元丹
T_REWARD_INFO[18] = {9* 60, 106010200230, 1} --经验卡（蓝）
T_REWARD_INFO[19] = {9 * 60, 613000000040, 5} --紫色洗炼石
T_REWARD_INFO[20] = {10 * 60, 104001100120, 8} --小钱袋
T_REWARD_INFO[20] = {10 * 60, 104001140220, 88} --+88礼券卡

--T_REWARD_INFO[1] = {0  * 60, 103030000120, 5}
--T_REWARD_INFO[2] = {1  * 10, 105000000120, 5}
--T_REWARD_INFO[3] = {1 * 10, 101030000020, 20}
--T_REWARD_INFO[4] = {1 * 10, 101040000020, 20}
--T_REWARD_INFO[5] = {1 * 10, 104001100120, 1}


--最后10秒同步一次客户端时间
local LAST_SYNC_TIME = 10

---------------------------------------------------------------------------------------

Obj_reward = oo.class(nil,"Obj_reward")

function Obj_reward:__init(char_id)
	self.char_id = char_id
	self.remain_time = 0		--剩余时间
	self.reward_level = 1

	self.begin_time = os.time() --登陆时间
end

function Obj_reward:load()
	
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end
	
	if not player:is_first_login() then
		local dbh = f_get_db()
		local str_char = string.format("{char_id:%d}", self.char_id)

		--print("Obj_reward:load", str_char)

		local t_reward, e_code = dbh:select_one("online_reward", nil, str_char, nil, "{char_id:1}")
		if 0 ~= e_code then
			print("Error:online_reward")
		end

		if t_reward ~= nil then
			if t_reward.reward_level > table.getn(T_REWARD_INFO) then
				return false
			end
			self.reward_level = t_reward.reward_level
			self.remain_time = t_reward.remain_time
			self.begin_time = ev.time
		end
		return true
	end

	return true
end

function Obj_reward:update_remain_time()
	--玩家下线
	if self.reward_level > table.getn(T_REWARD_INFO) then
		return
	end

	local t_time = self.remain_time - (ev.time - self.begin_time)
	if t_time > 0 then
		self.remain_time = t_time
	else
		self.remain_time = 0
	end

--	self.remain_time = math.max(T_REWARD_INFO[self.reward_level][1] - (os.time() - self.begin_time), 0)
	--[[
	local str_update_sql = string.format("replace into online_reward (owner,remain_time,reward_level) values (%d,%d,%d)", self.char_id, self.remain_time, self.reward_level)
	g_game_sql:write(str_update_sql)
	--]]

	local dbh = f_get_db()
	local data = string.format("{remain_time:%d,reward_level:%d}", self.remain_time, self.reward_level)
	local query = string.format("{char_id:%d}", self.char_id)
	dbh:update("online_reward", query, data,true)
end

--玩家领取更新
function Obj_reward:save_remain_time(cur_level)
	--[[
	local str_update_sql = string.format("replace into online_reward (owner,remain_time,reward_level) values (%d,%d,%d)", self.char_id, self.remain_time, self.reward_level)
	g_game_sql:write(str_update_sql)
	--]]

	local dbh = f_get_db()
	--if cur_level == 1 then
		--local data = {}
		--data["char_id"] = self.char_id
		--data["remain_time"] = self.remain_time
		--data["reward_level"] = self.reward_level
		--dbh:insert("online_reward", Json.Encode(data))
		--return
	--end

	local update_data = string.format("{remain_time:%d,reward_level:%d}", self.remain_time, self.reward_level)
	local update_query = string.format("{char_id:%d}", self.char_id)
	dbh:update("online_reward", update_query, update_data,true)
end

function Obj_reward:get_remain_time()
	return self.remain_time
end

function Obj_reward:get_reward_level()
	return self.reward_level
end

function Obj_reward:get_reward_item()
	return T_REWARD_INFO[self.reward_level]
end

--领取奖励
function Obj_reward:featch_reward_present()
	--时间验证
	if os.time() - self.begin_time <= self.remain_time - 10 then
		return 27001
	end

	local reward_info = T_REWARD_INFO[self.reward_level]

	--背包是否满了
	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:get_bag_free_slot_cnt(INVENTORY_SLOT_BAG_START) <= 0 then
		return 43004
	end
	--奖励添加到背包
	local item_id_list = {}
	item_id_list[1] = {}
	item_id_list[1].type = 1
	item_id_list[1].item_id = reward_info[2]
	item_id_list[1].number = reward_info[3]
	local err_code = pack_con:add_item_l(item_id_list, {['type']=ITEM_SOURCE.ONLINE_REWARD})
	if err_code ~= 0 then
		return 27003
	end

	--开始下一个领取奖励倒计时
	local cur_level = self.reward_level
	--print("table.getn(T_REWARD_INFO)", table.getn(T_REWARD_INFO))

	if cur_level >= table.getn(T_REWARD_INFO) then
		self.reward_level = table.getn(T_REWARD_INFO) + 1
		self:save_remain_time(cur_level)
		return 27002 --领取完了
	end
	self.reward_level = cur_level + 1
	local next_reward_info = T_REWARD_INFO[self.reward_level]
	--debug_print("next_reward_info", j_e(next_reward_info))

	self.remain_time = next_reward_info[1]
	self.begin_time = os.time()

	self:save_remain_time(cur_level)

	return 0
end

--[[
-------------event------------
function Obj_reward:on_timer(tm)
	local need_sec = T_REWARD_INFO[self.reward_level][1]
	local diff_time
	if self.need_second  > 0  then
		 diff_time = self.need_second - math.floor(os.time() - self.begin_time)	
	else
		diff_time = need_sec - math.floor(os.time() - self.begin_time)
	end
	self.remain_time = diff_time

	if self.remain_time <= 0 then
		self.state = 0
		self.need_second = 0
		self:update_remain_time()
		return
	end

	if self.remain_time == LAST_SYNC_TIME then --
		local s_pkt = {}
		s_pkt["remain_tm"] = self.remain_time
		s_pkt["item_id"] = 10001
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_REWARD_LOGIN_S, s_pkt)
	end
end
--]]