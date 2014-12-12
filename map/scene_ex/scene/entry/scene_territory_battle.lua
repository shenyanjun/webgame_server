--local debug_print = print
local debug_print = function() end
local territory_config = require("scene_ex.config.territory_config_loader")
local filter_loader = require("config.loader.filter_loader")

local ENTER_NOTIFY_TIME = 60	--更新报名列表
local BATTLE_INFO_UPDATE_TIME = 60 --更新战况间格
local KICK_OUT_ADD = 30			--显示结果时间
local EXTRA_REWARD_FACTOR = 300	--额外奖励系数
-- 帮派领地攻防战
Scene_territory_battle = oo.class(Scene_territory_snatch, "Scene_territory_battle")

function Scene_territory_battle:__init(map_id, instance_id)
	Scene_territory_snatch.__init(self, map_id, instance_id)
	self.score = {{}, {}}	--攻方和防方的得分
	self.point = {}			--怪物对应的分数
	self.final_score = {{}, {}}--最终得分
	self.cache = {{},{}}	--缓存的数据
	self.score_map = {}		--玩家与排名的映射[玩家ID]={1排名，2得分, 3名称, 4等级, 5战斗力, 6帮派名}
	self.faction_score = {}			--帮派分数
	self.faction_score_map = {}		--帮派排名
	self.page = {0, 0}				--排行表页数
	self.battel_point = {0, 0}		--总战功
	
	local config = territory_config.config[map_id]
	if config and config.score and config.score.occ then
		for k, v in pairs(config.score.occ) do
			self.point[k] = v
		end
	end
	self.enter_l = {}	-- 已进入的列表
	self.enter_notify_time = ev.time + ENTER_NOTIFY_TIME

	--战况记录
	self.battle_info_update_time = ev.time
	self.battle_score = {{}, {}}	--阶段得分
	self.battle_score_map = {}		--阶段得分玩家与排名的映射[玩家ID]={排名，得分}
	self.battle_page = {0, 0}
	self.battle_cache = {{},{}}		--战况信息缓存的数据
	self.battle_size = {0, 0}	--人数

	--防止已帮派副本ID相同，而加入的附加字符
	if instance_id then
		self.i_id = string.sub(instance_id, 11, -1)
	end
end

function Scene_territory_battle:get_score(obj)
	local side = obj:get_side()
	return self.score[side][obj:get_id()] or 0
end

function Scene_territory_battle:instance()
	debug_print("Scene_territory_battle:instance()")
	if self.is_initial then
		return
	end
	
	self.scene_layer_l = {}
	--self.map_list = {}
	self.instance_list = {}

	local config = self:get_self_config()
	if not config or not config.scene_layer then
		return
	end

	for _, layer in pairs(config.scene_layer) do
		local map_id = layer.map
		table.insert(self.scene_layer_l, map_id)
		self.map_list[map_id] = self.map_list[map_id] or g_scene_config_mgr:load_map(map_id, layer.path)
		local map_obj = self.map_list[map_id]
		if not map_obj then
			return SCENE_ERROR.E_NOT_ON_SCENE, nil
		end
		local instance = Scene_territory_battle_entity(self, self.id, map_id, self.instance_id, map_obj:clone(map_id))
		self.instance_list[map_id] = instance
		instance:instance()
	end
	
	self:attack_layer_increase()
	self.is_initial = true
end

function Scene_territory_battle:get_self_config()
	return territory_config.config[self.id]
end

function Scene_territory_battle:carry_scene(obj, pos)
	debug_print("==>Scene_territory_battle:carry_scene:")
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local is_attacker = self:is_attacker(obj)

	local config = self:get_self_config()
	if not config or self.is_end then
		return SCENE_ERROR.E_NOT_OPNE, nil
	end
	local map_id = pos[1]
	local pos_new = pos[2]

	if not self.is_end and is_attacker and config.scene_layer[self.attack_layer+1] 
		and map_id == config.scene_layer[self.attack_layer+1].map then
		return SCENE_ERROR.E_NOT_KILL_BOSS, nil
	elseif not self.is_end and not is_attacker and not (map_id == config.scene_layer[self.attack_layer].map
		or map_id == config.scene_layer[self.defense_layer].map) then
		return SCENE_ERROR.E_NOT_YOUR_SIDE, nil
	end

	if is_attacker and self.battle_size[1] > filter_loader.member.max then
		return SCENE_ERROR.E_HUMAN_FULL, nil
	end

	local instance = self.instance_list[map_id]
	local fa = g_faction_mgr:get_faction_by_cid(obj:get_id())
	local f_id = fa and fa:get_faction_id()
	if not instance then
		local map_obj = self.map_list[map_id]
		if not map_obj then
			return SCENE_ERROR.E_NOT_ON_SCENE, nil
		end
		instance = Scene_territory_battle_entity(self, self.id, map_id, self.instance_id, map_obj:clone(map_id))
		self.instance_list[map_id] = instance
		instance:instance()
	end
	
	return self:push_scene(obj, pos)
end

function Scene_territory_battle:push_scene(obj, pos)
	local map_id = pos[1]
	local pos_new = pos[2]
	local instance = self.instance_list[map_id]
	if not instance then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end

	local is_attacker = self:is_attacker(obj)
	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		local config = self:get_self_config()
		local cycle_limit = config.limit and config.limit.cycle.number
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT, nil
		end
		con:add_count_copy(self.id)
		self.owner_list[obj_id] = true
		--
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end

	self.enter_l[obj_id] = (self.enter_l[obj_id] or 0) + 1
	local e_code, error_describe = instance:carry_scene(obj, pos_new)
	if SCENE_ERROR.E_SUCCESS == e_code then
		local side = is_attacker and 1 or 2
		if self.score[side][obj_id] == nil then self.score[side][obj_id] = 0 end

		if self.score_map[obj_id] == nil then
			self:build_player_info(obj_id)
		end
		local channal_id = self.side_channal[side]
		g_chat_channal_mgr:add_member(obj_id, channal_id)
	else
		self.enter_l[obj_id] = (self.enter_l[obj_id] or 0) - 1
	end
	return e_code, error_describe
end

function Scene_territory_battle:clone(instance_id)
	debug_print("=======> Scene_territory_battle:clone", instance_id)
	local obj = Scene_territory_battle(self.id, instance_id)
	return obj
end

-- 根据战斗力来计算并记录他的对应得分
function Scene_territory_battle:compute_point(bekill_id)
	local obj = g_obj_mgr:get_obj(bekill_id)
	local fighting = obj:get_fighting() or 1

	local config = self:get_self_config()
	for k, v in ipairs(config.score.power) do
		if fighting < v[1] then
			self.point[bekill_id] = v[2]
			debug_print("======> Scene_territory_battle:compute_point", bekill_id, fighting, self.point[bekill_id])
			return self.point[bekill_id]
		end
	end
	
	return 0
end

-- 记录分数 type1:为杀怪，type2:为杀人 3:队友杀怪 4:队友杀人  size:周围队友的人数
function Scene_territory_battle:build_score(char_id, bekill_id, type, size)
	debug_print("build_score:", char_id, bekill_id, type, size)
	local obj = g_obj_mgr:get_obj(char_id)
	local side = self:is_attacker(obj) and 1 or 2
	if type == 1 then
		self.score[side][char_id] = (self.score[side][char_id] or 0) + (self.point[bekill_id] or 0)
	elseif type == 2 then
		local point = self.point[bekill_id] or self:compute_point(bekill_id)
		self.score[side][char_id] = (self.score[side][char_id] or 0) + point
	elseif type == 3 then
		self.score[side][char_id] = (self.score[side][char_id] or 0) + math.ceil((self.point[bekill_id] or 0) / size)
	elseif type == 4 then
		local point = self.point[bekill_id] or self:compute_point(bekill_id)
		self.score[side][char_id] = (self.score[side][char_id] or 0) + math.ceil(point / size)
	end
end

function Scene_territory_battle:compute_final_score()
	debug_print("Scene_territory_battle:compute_final_score()")
	local cmp = function(e1,e2) 
					return e1[2] > e2[2]
				end
	--攻方
	for char_id, point in pairs(self.score[1]) do
		table.insert(self.final_score[1], {char_id, point})
		self:build_player_info(char_id)
		--debug_print("====>score[1]:", char_id, point)
		--计算帮派得分
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		local faction_id = faction and faction:get_faction_id()
		if faction_id then
			self.faction_score[faction_id] = { (self.faction_score[faction_id] and self.faction_score[faction_id][1] or 0) + point, 
			faction:get_faction_name(), faction:get_factioner_name() }
		end
	end
	table.sort(self.final_score[1], cmp)
	for ranking, v in ipairs(self.final_score[1]) do
		self.score_map[v[1]][1] = ranking
		self.score_map[v[1]][2] = v[2]
		self.battel_point[1] = self.battel_point[1] + v[2]
		--f_scene_info_log("instance_id:%s, side1, %d, char_id:%d point:%d", self.instance_id, ranking, v[1], v[2])
	end
	self.page[1] = math.ceil(#self.final_score[1] / 10)
	-- 帮派排序
	for f_id, v in pairs(self.faction_score) do
		table.insert(self.faction_score_map, {f_id, v[1], v[3], v[2]})
		--f_scene_info_log("instance_id:%s, f_id:%s, point:%d, name:%s, factioner:%s", self.instance_id, f_id, v[1], v[2], v[3])
	end
	table.sort(self.faction_score_map, cmp)

	for k, v in ipairs(self.faction_score_map) do
		self.faction_score[v[1]][4] = k
	end
	self.page[3] = math.ceil(#self.faction_score_map / 10)
	--设置领地新的得主
	if self.winner_side == 1 then
		local owner_id = self.faction_score_map[1] and self.faction_score_map[1][1] or ""
		g_faction_territory:set_owner_id(owner_id)
	end

	--防方
	for char_id, point in pairs(self.score[2]) do
		table.insert(self.final_score[2], {char_id, point})
		self:build_player_info(char_id)
	end

	table.sort(self.final_score[2], cmp)
	for ranking, v in ipairs(self.final_score[2]) do
		self.score_map[v[1]][1] = ranking
		self.score_map[v[1]][2] = v[2]
		self.battel_point[2] = self.battel_point[2] + v[2]
		--f_scene_info_log("instance_id:%s, side2, %d, char_id:%d point:%d", self.instance_id, ranking, v[1], v[2])
	end
	self.page[2] = math.ceil(#self.final_score[2] / 10)

	--保存到数据库
	self:serialize_to_db()
end

function Scene_territory_battle:get_cache(side, page)
	if side == 1 or side == 2 then
		if page > self.page[side] then
			return {}
		end
		return self.cache[side][page] or self:build_cache(side, page)
	else	-- 帮派排名

		if self.faction_score_end == nil then
			if #self.faction_score_map <= 10 then
				self.faction_score_end = self.faction_score_map
			else
				self.faction_score_end = {}
				for i = 1, 10 do
					self.faction_score_end[i] = self.faction_score_map[i]
				end
			end
		end
		return self.faction_score_end
	end
end

function Scene_territory_battle:get_self_score(char_id)
	local my_order = {}
	local obj = g_obj_mgr:get_obj(char_id)
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local faction_id = faction and faction:get_faction_id() or 0
	--[[
	my_order[1] = self.score_map[char_id] and self.score_map[char_id][1] or 0	--排名
	my_order[2] = self.score_map[char_id] and self.score_map[char_id][2] or 0	--战功
	my_order[3] = obj:get_name()		--姓名
	my_order[4] = obj:get_level()		--等级
	my_order[5] = obj:get_fighting() 	--战斗力
	my_order[6] = faction:get_faction_name() or ""	--帮派名
	]]
	my_order[1] = self.score_map[char_id] and self.score_map[char_id][1] or 0	--排名
	my_order[2] = self.score_map[char_id] and self.score_map[char_id][2] or 0	--战功
	my_order[3] = self.faction_score[faction_id] and self.faction_score[faction_id][4] or 0--帮派排名
							  
	return my_order
end

function Scene_territory_battle:get_end_result(char_id, time)
	debug_print("Scene_territory_battle:get_end_result", char_id, time)
	local result = {}
	result.score_list = {self:get_cache(1, 1), self:get_cache(2, 1)}
	result.my_score = self:get_self_score(char_id)
	result.faction_score = self:get_cache(3, 1)
	result.new_owner = g_faction_territory:get_owner_name()
	result.winner = self.winner_side
	result.time = time or 30
	local obj = g_obj_mgr:get_obj(char_id)
	local side = obj and obj:get_side() or self.winner_side
	result.lose = (self.winner_side == side) and 1 or 2
	--result.total_page = self.page

	return result
end

function Scene_territory_battle:to_end()
	debug_print("Scene_territory_battle:to_end()")
	self.is_end = true
	for k, instance in pairs(self.instance_list) do
		instance:the_end(KICK_OUT_ADD)
	end

	self:compute_final_score()
	self:build_cache(1, 1)
	self:build_cache(2, 1)

	--同步排名领地得主
	local owner_id = g_faction_territory:get_owner_id()
	local ret = {}
	ret.owner_id = owner_id
	g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_APPLICATION_WAR_OVER_C, ret)
	--发奖励
	self:do_reward()
end

function Scene_territory_battle:is_attacker(obj)
	debug_print("Scene_territory_battle:is_attacker(obj)")
	local faction = g_faction_mgr:get_faction_by_cid(obj:get_id())
	local instance_id = faction and faction:get_faction_id()
	return instance_id ~= self.i_id
end

--通知更新列表
function Scene_territory_battle:update_enter_list()
	if self.enter_notify_time > 0 and self.enter_notify_time < ev.time and not self.is_end then
		self.enter_notify_time = 0
		local msg = {}
		f_construct_content(msg, f_get_string(1613), 12)
		f_cmd_sysbd(msg)
	end
	--[[
	if self.enter_notify_time < ev.time and not self.is_end then
		debug_print("Scene_territory_battle:update_enter_list()")
		self.enter_notify_time = ev.time + ENTER_NOTIFY_TIME
		local ret = {}
		for k, v in pairs(self.enter_l) do
			if v > 0 then
				--debug_print("===> update_enter_list", k, v)
				table.insert(ret, k)
			end
		end
		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_APPLICATION_SORT_C, ret)
	end
	]]
end


function Scene_territory_battle:attacker_win()
	self:set_winner(1)
	self:to_end()
	local config = self:get_self_config()
	local str = g_faction_territory:get_owner_name()
	local msg = {}
	local bd_str = str .. (config.broadcast.succeed)
	f_construct_content(msg, bd_str, 13)
	f_cmd_sysbd(msg)
	f_scene_info_log("battle attacker_win, owner_name:%s", str)

	--local ret = {}
	--ret.owner_id = g_faction_territory:get_owner_id()
	--g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_APPLICATION_WAR_OVER_C, ret)
end

function Scene_territory_battle:build_player_info(char_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if self.score_map[char_id] == nil then 
		self.score_map[char_id] = {} 
		self.score_map[char_id][1] = 0				--排名
		self.score_map[char_id][2] = 0				--战功
	end
	self.score_map[char_id][3] = obj:get_name()			--姓名
	self.score_map[char_id][4] = obj:get_level()		--等级
	self.score_map[char_id][5] = obj:get_fighting() 	--战斗力
	self.score_map[char_id][6] = faction and faction:get_faction_name() or ""	--帮派名
end

function Scene_territory_battle:build_cache(side, page)
	debug_print("Scene_territory_battle:build_cache(page)", side, page)
	local cache = {}
	for i = 1, 10 do
		local score = self.final_score[side][i + ((page-1)*10)]
		if score then
			local obj = g_obj_mgr:get_obj(score[1])
			local faction = g_faction_mgr:get_faction_by_cid(score[1])
			cache[i] = {}
			--[[
			cache[i][1] = score[2]				--战功
			cache[i][2] = obj:get_name()		--姓名
			cache[i][3] = obj:get_level()		--等级
			cache[i][4] = obj:get_fighting() 	--战斗力
			cache[i][5] = faction:get_faction_name() or ""	--帮派名
			]]
			cache[i][1] = obj and obj:get_name() or self.score_map[score[1]][3]	--姓名
			cache[i][2] = faction and faction:get_faction_name() or self.score_map[score[1]][6]	--帮派名
			cache[i][3] = score[2]				--战功
			cache[i][4] = score[1]				--char_id
		else
			break
		end
	end

	self.cache[side][page] = cache
	return self.cache[side][page]
end

function Scene_territory_battle:do_reward()
	debug_print("Scene_territory_battle:do_reward()")
	local config = self:get_self_config()
	--if config.reward == nil then return end

	local owner_id = g_faction_territory:get_owner_id()
	for char_id, v in pairs(self.score_map) do
		f_scene_info_log("instance_id:%s, char_id:%d, ranking:%d point:%d", 
							self.instance_id, char_id, v[1], v[2])
		local obj = g_obj_mgr:get_obj(char_id)
		local player_level = obj and obj:get_level() or 40
		local my_side = obj and obj:get_side() or (self.score[1][char_id] and 1 or 2)
		--发送攻防战结果
		local result = self:get_end_result(char_id, KICK_OUT_ADD)
		g_cltsock_mgr:send_client(char_id, CMD_TERRITORY_BATTLE_SCORE_S, result)

		local reward = self.score[self.winner_side][char_id] and (config.reward and config.reward.winner) or (config.reward and config.reward.loser)
		if reward then
			
			local give_box = nil
			if v[1] == 1 then
				give_box = reward[1]
			elseif v[1] >= 2 and v[1] <= 10 then
				give_box = reward[2]
			else
				give_box = reward[3]
			end
			--发奖励包
			local pkt = {}
			pkt.sender = -1
			pkt.recevier = char_id
			pkt.title = config.reward.title
			pkt.content = config.reward.content
			pkt.box_title = give_box.box_title
			pkt.item_list = give_box.item_list
			pkt.money_list = {}
			for _, money in pairs(give_box.money_list or {}) do
				pkt.money_list[money[1]] = money[2] * v[2]
			end
			--额外奖励
			if self.winner_side == 2 then
				if my_side == self.winner_side then
					pkt.money_list[MoneyType.GOLD] = (pkt.money_list[MoneyType.GOLD] or 0) + EXTRA_REWARD_FACTOR * player_level
				else
					pkt.money_list[MoneyType.GIFT_GOLD] = (pkt.money_list[MoneyType.GIFT_GOLD] or 0) + EXTRA_REWARD_FACTOR * player_level
				end
			elseif self.winner_side == 1 then
				local faction = g_faction_mgr:get_faction_by_cid(char_id)
				local f_id = faction and faction:get_faction_id() or " "
				if my_side == self.winner_side and owner_id == f_id then
					pkt.money_list[MoneyType.GOLD] = (pkt.money_list[MoneyType.GOLD] or 0) + EXTRA_REWARD_FACTOR * player_level
				else
					pkt.money_list[MoneyType.GIFT_GOLD] = (pkt.money_list[MoneyType.GIFT_GOLD] or 0) + EXTRA_REWARD_FACTOR * player_level
				end
			end
			g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, pkt)
		end
	end
--[[	
		local sql = string.format(
				"insert into faction_copy set copy_id=%d, faction_id='%s', kill_boss=%d, into_count=%d, reward_count=%d, create_time=%d"
				, self.id
				, self.instance_id
				, has_boss and 1 or 0
				, self.human_count
				, count
				, self.start_time)
				
		f_multi_web_sql(sql)
	end
]]

end

function Scene_territory_battle:get_battle_info(char_id)
	if self.battle_info_update_time < ev.time then
		self:compute_battle_score()
	end
	local pkt = {}
	pkt.info = {}
	pkt.info[1] = self.battle_size[1]	  --攻方人数
	pkt.info[2] = self.battle_size[2]	  --防方人数
	pkt.info[3] = self.instance_list[2401001] and self.instance_list[2401001]:get_last_time()	  --剩余时间
	pkt.info[4] = self.battle_score_map[char_id] and self.battle_score_map[char_id][1] or 0  --我的排行
	pkt.info[5] = self.battle_score_map[char_id] and self.battle_score_map[char_id][2] or 0	 --战功

	pkt.score_list = {self:get_battle_cache(1, 1), self:get_battle_cache(2, 1)}
	return pkt
end


function Scene_territory_battle:compute_battle_score()
	debug_print("Scene_territory_battle:compute_battle_score()")
	self.battle_info_update_time = ev.time + BATTLE_INFO_UPDATE_TIME
	self.battle_score = {{}, {}}	--阶段得分
	self.battle_score_map = {}		--阶段得分玩家与排名的映射[玩家ID]={排名，得分}
	self.battle_page = {}
	self.battle_cache = {{},{}}		--战况信息缓存的数据
	self.battle_size = {}			--人数

	local cmp = function(e1,e2) 
					return e1[2] > e2[2]
				end
	--攻方
	for char_id, point in pairs(self.score[1]) do
		table.insert(self.battle_score[1], {char_id, point})
		self:build_player_info(char_id)
		debug_print("====>score[1]:", char_id, point)
	end
	table.sort(self.battle_score[1], cmp)
	for ranking, v in ipairs(self.battle_score[1]) do
		self.battle_score_map[v[1]] = {ranking, v[2]}
		debug_print("====>final_score[1]:", ranking, v[1], v[2])
	end
	self.battle_size[1] = #self.battle_score[1]
	self.battle_page[1] = math.ceil(self.battle_size[1] / 10)


	--防方
	for char_id, point in pairs(self.score[2]) do
		table.insert(self.battle_score[2], {char_id, point})
		self:build_player_info(char_id)
		debug_print("====>score[1]:", char_id, point)
	end
	table.sort(self.battle_score[2], cmp)
	for ranking, v in ipairs(self.battle_score[2]) do
		self.battle_score_map[v[1]] = {ranking, v[2]}
		debug_print("====>final_score[1]:", ranking, v[1], v[2])
	end
	self.battle_size[2] = #self.battle_score[2]
	self.battle_page[2] = math.ceil(self.battle_size[2] / 10)
end

function Scene_territory_battle:build_battle_cache(side, page)
	debug_print("Scene_territory_battle:build_battle_cache()", side, page)
	local cache = {}
	for i = 1, 10 do
		local score = self.battle_score[side][i + ((page-1)*10)]
		if score then
			local obj = g_obj_mgr:get_obj(score[1])
			local faction = g_faction_mgr:get_faction_by_cid(score[1])
			cache[i] = {}
			cache[i][1] = score[2]				--战功
			cache[i][2] = self.score_map[score[1]][3]	--姓名
			cache[i][3] = self.score_map[score[1]][4]	--等级
			cache[i][4] = self.score_map[score[1]][5] 	--战斗力
			cache[i][5] = self.score_map[score[1]][6]	--帮派名
		else
			break
		end
	end

	self.battle_cache[side][page] = cache
	return self.battle_cache[side][page]
end

function Scene_territory_battle:get_battle_cache(side, page)
	if page > self.battle_page[side] then
		return {}
	end
	if side == 1 or side == 2 then
		return self.battle_cache[side][page] or self:build_battle_cache(side, page)
	end
end

function Scene_territory_battle:serialize_to_db()
	for i = 1, 2 do
		for j = 1, self.page[i] do
			self:get_cache(i, j)
		end
	end
	local result = {}
	result.score_list = self.cache
	result.faction_score = self.faction_score_map
	result.new_owner = {g_faction_territory:get_owner_id(), g_faction_territory:get_owner_name()}
	result.winner = self.winner_side
	result.player_s = {#self.final_score[1], #self.final_score[2]}
	result.battle_point = self.battel_point
	result.end_time = ev.time

	--print("======>serialize_to_db:", j_e(result))
	local info = {}
	local str_date = os.date("%y%m%d")
	info.date = tonumber(str_date)
	info.scene_id = 2401000
	info.detail = result
	local m_db = f_get_db()
	local query = string.format("{scene_id:%d, date:%d}", info.scene_id, info.date)

	m_db:update("result_record", query, Json.Encode(info), true)
end

function Scene_territory_battle:add_buff_to_side(side, buff_id, per, val, time)
	for k, v in pairs(self.score[side] or {})do
		local obj = g_obj_mgr:get_obj(k)
		local scene_id = obj and obj:get_scene()[1]
		if scene_id == self.id then
			f_add_buff_impact(obj, buff_id, per, val, time)			
		end
	end
end

function Scene_territory_battle:change_pos(obj, pos)
	return SCENE_ERROR.E_NOT_ON_SCENE
end