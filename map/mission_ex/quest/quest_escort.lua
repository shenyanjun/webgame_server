--押镖任务
local misson_loader = require("mission_ex.mission_loader")
local Quest_escort = oo.class(Quest_base, "Quest_escort")
local escort_config = require("config.escort_config")
local color = {'white', 'green', 'blue', 'purple', 'orange'}

local killer_lv_limit = 10
local rob_limit = 6
local timeout_addition = 0.6
local rob_addition = 0.3
local speed_rate = 0.2
local color_rat = {1, 1, 0.4, 0, 0}

function Quest_escort:__init(meta)
	Quest_base.__init(self, meta)
	self.has_die = false
	self.money_list = {}
	self.complete_time = 0
	self.color = 1
	self.owner_id = 0
end

function Quest_escort:get_reward(player)
	local money_list = {0, 0, 0, 0}
	
	local meta = misson_loader.get_meta(self.quest_id)
	local reward = meta and meta.reward
	if reward then
		local con = player:get_mission_mgr()
		local value = con:get_param(PARAM_TYPE_ESCORT)
		local addition = escort_config.addition[color[value.color]]
		
		--帮派加成
		addition = addition + (player:get_faction_id() and escort_config.addition.faction_addition or 0)
		
		--活动时间加成
		local time = ev.time - f_get_today()
		for _, v in pairs(escort_config.addition_time) do
			local start_time = v.hour * 3600 + v.min * 60
			local end_time = start_time + v.continue * 60
			if start_time <= time and time < end_time then
				addition = addition + escort_config.addition.time_addition
				break
			end
		end
		
		--后台和VIP加成
		local per, val = player:get_impact_effect(IMPACT_TYPE.ESCORT)
		addition = addition + g_buffer_reward_mgr:buff_reward(5) + player:get_addition(HUMAN_ADDITION.escort) + per
		local rat = color_rat[value.color]

		money_list[1] =  math.floor((reward.gold or 0) * addition)
		money_list[2] =  math.floor((reward.gift_gold or 0) * addition)
		money_list[3] =  math.floor((reward.gift_jade or 0) * addition)
		money_list[4] = math.floor((reward.jade or 0) * addition)

		local tmp_money = math.floor(money_list[1] * rat )
		money_list[2] = money_list[2] + tmp_money
		money_list[1] = money_list[1] - tmp_money
	end

	return money_list
end

function Quest_escort:calc_reward()
	local now = ev.time
	local addition = (now >= self.complete_time or self.has_die) and timeout_addition or 1

	local money_list = {}
	money_list[1] =  math.floor((self.money_list[1] or 0) * addition)
	money_list[2] =  math.floor((self.money_list[2] or 0) * addition)
	money_list[3] =  math.floor((self.money_list[3] or 0) * addition)
	money_list[4] = math.floor((self.money_list[4] or 0) * addition)

	return money_list
end


function Quest_escort:construct(con)
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	if not player then
		return
	end
	
	self.owner_id = char_id

	con:set_flags(MISSION_FLAG_ESCORT, true)

	if MISSION_STATUS_COMMIT == self.status then
		return
	end
	
	if ev.time >= self.complete_time then
		self:set_status(MISSION_STATUS_COMMIT)
		player:set_escort_status(0, 1)
	else
		player:set_escort_status(1, speed_rate)
		self:register_event(con)
	end
end

function Quest_escort:instance(con)
	local char_id = con:get_owner()
	local player = char_id and g_obj_mgr:get_obj(char_id)
	if not player then
		return
	end
	
	self.owner_id = char_id

	con:set_flags(MISSION_FLAG_ESCORT, true)
	
	local value = con:get_param(PARAM_TYPE_ESCORT)
	
	self.color = value.color
	if self.color >= 4 then
		local say_l = {}
		say_l[1] = player:get_name()
		local str_json = f_get_sysbd_format(10007, say_l)

		--世界广播改为个人广播
		f_cmd_sysbd(str_json, 2)
		--f_cmd_world_bd(str_json, 2, 3, char_id)
	end
	con:set_param(PARAM_TYPE_ESCORT, value)
	self.money_list = self:get_reward(player)
	
	player:set_escort_status(1, speed_rate)
	local meta = misson_loader.get_meta(self.quest_id)
	self.complete_time = ev.time + meta.postcondition.limit_time
	self:register_event(con)
end

function Quest_escort:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_DIE, self.quest_id, self, self.die_event)
end

function Quest_escort:unregister_event(con)
	con:unregister_event(MISSION_EVENT_DIE, self.quest_id)
end

function Quest_escort:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	
	if E_SUCCESS == e_code and obj then
		obj.has_die = record.has_die
		obj.color = record.color or 1
		obj.money_list = table.copy(record.money_list)
		obj.complete_time = record.complete_time or 0
	end
	return obj, E_SUCCESS
end

function Quest_escort:serialize_to_net()
	if MISSION_STATUS_INCOMPLETE == self.status and ev.time >= self.complete_time then
		self:set_status(MISSION_STATUS_COMMIT)
		local player = g_obj_mgr:get_obj(self.owner_id)
		player:set_escort_status(0, 1)
	end
	
	local result = Quest_base.serialize_to_net(self)
	result.base[3] = math.max(self.complete_time - ev.time, 0)
	result.calc_reward = self:calc_reward()
	return result
end

function Quest_escort:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.has_die = self.has_die
	result.color = self.color or 1
	result.money_list = table.copy(self.money_list)
	result.complete_time = self.complete_time or 0
	return result
end

-----------------------------------------------------------------------------------------------------------------------

function Quest_escort:do_rob(player, killer)
	if OBJ_TYPE_HUMAN == killer:get_type() then
		local count_con = killer:get_copy_con()
		if count_con:get_count_escort() < rob_limit then
			count_con:add_count_escort()
			if (player:get_level() + killer_lv_limit) >= killer:get_level() then
		 		local pack_con = killer:get_pack_con()
				local addition = rob_addition
				local money_list = {}
				money_list[MoneyType.GOLD] =  math.floor((self.money_list[1] or 0) * addition)
				money_list[MoneyType.GIFT_GOLD] =  math.floor((self.money_list[2] or 0) * addition)
				money_list[MoneyType.GIFT_JADE] =  math.floor((self.money_list[3] or 0) * addition)
				money_list[MoneyType.JADE] = math.floor((self.money_list[4] or 0) * addition)
				pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.TASK})
			end
		end
	--广播
		if self.color >= 4 then
			local say_l = {}
			say_l[1] = player:get_name()
			say_l[2] = killer:get_name()
			local str_json = f_get_sysbd_format(10008, say_l)
			f_cmd_sysbd(str_json)
			--f_cmd_world_bd(str_json, 2, 3, player:get_id())
		end
	--
	end
end

function Quest_escort:die_event(con, killer_id, args)
	local obj_mgr = g_obj_mgr
	local char_id = con:get_owner()
	local player = char_id and obj_mgr:get_obj(char_id)
	if not player or 0 == player:get_escort_status() or not killer_id then
		return
	end
	
	self.has_die = true
	player:set_escort_status(0, 1)
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	con:notity_update_quest(self.quest_id, true)
	
	local killer = obj_mgr:get_obj(killer_id)
	args.is_evil = false
	if killer then
		if OBJ_TYPE_PET == killer:get_type() then  --pet
			local owner_id = killer:get_owner_id()
			killer = obj_mgr:get_obj(owner_id)
		end
		self:do_rob(player, killer)
	end
end

-----------------------------------------------------------------------------------------------------------------------

function Quest_escort:do_reward(player, reward, select_list)
	local pack_con = player:get_pack_con()
	assert(pack_con)
	
	local item_list = {}
	if reward.all_reward then
		for _, v in pairs(reward.all_reward) do
			local item = {}
			item.type = 1
			item.number = v.number
			item.item_id = v.id
			table.insert(item_list, item)
		end
	end
	
	local occ = player:get_occ()
	if reward.occ_reward then
		for _, v in pairs(reward.occ_reward) do
			if occ == v.occ then
				local item = {}
				item.type = 1
				item.number = v.number
				item.item_id = v.id
				table.insert(item_list, item)
			end
		end	
	end
	
	local item_id = select_list and (select_list[1] and select_list[1].item_id)
	if item_id and reward.option_reward then
		item_id = tonumber(item_id)
		for _, v in pairs(reward.option_reward) do
			if v.id == item_id then
				local item = {}
				item.type = 1
				item.number = v.number
				item.item_id = v.id
				table.insert(item_list, item)
				break
			end
		end
	end
	
	local extra_reward = reward.extra_reward
	local exp = reward.exp or 0
	local reward_money = self:calc_reward()
	
	--增加奖励
	local money_list = {}
	money_list[MoneyType.GOLD] =  reward_money[1] or 0
	money_list[MoneyType.GIFT_GOLD] =  reward_money[2] or 0
	money_list[MoneyType.GIFT_JADE] =  reward_money[3] or 0
	money_list[MoneyType.JADE] = reward_money[4] or 0
	
	if self.extra and extra_reward then
		exp = (extra_reward.exp or 0) + exp
		money_list[MoneyType.GOLD] =  money_list[MoneyType.GOLD] + (extra_reward.gold or 0)
		money_list[MoneyType.GIFT_GOLD] = money_list[MoneyType.GIFT_GOLD] + (extra_reward.gift_gold or 0)
		money_list[MoneyType.GIFT_JADE] =  money_list[MoneyType.GIFT_JADE] + (extra_reward.gift_jade or 0)
		money_list[MoneyType.JADE] = money_list[MoneyType.JADE] + (extra_reward.jade or 0)

		for _, v in pairs(extra_reward.item_list or {}) do
			local item = {}
			item.type = 1
			item.number = v.number
			item.item_id = v.id
			table.insert(item_list, item)
		end
	end
	
	local e_code = pack_con:add_item_l(item_list, {['type'] = ITEM_SOURCE.TASK})
	if E_SUCCESS ~= e_code then
		return e_code
	end

	pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.TASK})
	player:add_exp(exp)

	
	local cut_gold = 0
	local cut_gift_gold = 0
	local is_out_time = 0
	if self.has_die then
		cut_gold = math.floor((self.money_list[1] or 0) * rob_addition)
		cut_gift_gold = math.floor((self.money_list[2] or 0) * rob_addition)
	end
	
	-- 押镖任务后台流水
	local str = string.format("insert into mission_daily_complete values(NULL, %d, '%s', %d, %d ,%d ,%d, %d, %d)",
						player:get_id()
						, self.quest_id
						, money_list[MoneyType.GOLD] 
						, cut_gold
						, money_list[MoneyType.GIFT_GOLD]
						, cut_gift_gold
						, is_out_time
						, ev.time)
	f_multi_web_sql(str)
	
	return E_SUCCESS
end

function Quest_escort:can_accept(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local con = player:get_mission_mgr()
	if 0 ~= player:get_escort_status() or con:get_flags(MISSION_FLAG_ESCORT) then
		return E_MISSION_ALREADY_ACCEPT
	end
	return Quest_base.can_accept(self, char_id)
end

function Quest_escort:on_complete(char_id, select_list)
	local now = ev.time
	local meta = misson_loader.get_meta(self.quest_id)
	local limit_time = meta and meta.postcondition and meta.postcondition.limit_time

	if now < self.complete_time then
		local player = char_id and g_obj_mgr:get_obj(char_id)
		local con = player:get_mission_mgr()
		local value = con:get_param(PARAM_TYPE_ESCORT)
		
		local time = limit_time - (self.complete_time - now)
		
		if 0 == player:get_escort_status() or (not con:get_flags(MISSION_FLAG_ESCORT)) or (time < 50)then
			f_quest_error_log(
				"Escort quest complete not escort status, char_id = %s, has_escort = %s, flags = %s, status = %s, time = %s."
				, tostring(char_id)
				, tostring(con:get_flags(MISSION_FLAG_ESCORT))
				, tostring(player:get_escort_status())
				, tostring(self.status)
				, tostring(time))
			if 0 == player:get_escort_status() and self.status == MISSION_STATUS_INCOMPLETE then
				return E_MISSION_BAD_ESCORT
			elseif time < 50 and not self.has_die then
				self.has_die = true
				return E_MISSION_BAD_ESCORT
			end
		end
	end

	if self.status == MISSION_STATUS_INCOMPLETE then
		self:set_status(MISSION_STATUS_COMMIT)
	end
	

	if not self.extra and not self.has_die and self.complete_time > now and meta.precondition and limit_time then
		local extra_time = meta.precondition.extra and meta.precondition.extra.limit_time
		if extra_time and extra_time >= (limit_time - (self.complete_time - now)) then
			self.extra = true
		end
	end
	
	local e_code, next_quest_chain = Quest_base.on_complete(self, char_id, select_list)
	if E_SUCCESS ~= e_code then
		self.extra = false
		if not self.has_die then
			self:set_status(MISSION_STATUS_INCOMPLETE)
		end
	else
		local player = char_id and g_obj_mgr:get_obj(char_id)
		if not self.has_die then
			player:set_escort_status(0, 1)
		end
		
		local con = player:get_mission_mgr()
		con:set_flags(MISSION_FLAG_ESCORT, false)
		local value = con:get_param(PARAM_TYPE_ESCORT)
		if value then
			if 1 ~= value.flag then
				con:set_param(PARAM_TYPE_ESCORT, nil)
			end
		end

		if not self.has_die and self.complete_time > now then
			if limit_time then
				local time = limit_time - (self.complete_time - now)
				g_public_sort_mgr:update_record(
					PUBLIC_SORT_TYPE.ESCORT
					, time
					, {['obj_id'] = char_id, ['name'] = player:get_name()}
					, PUBLIC_SORT_ORDER.ASC)
			end		
		end
		
		if self.extra then
			local say_l = {}
			say_l[1] = player:get_name()
			local str_json = f_get_sysbd_format(10009, say_l)
			--f_cmd_sysbd(str_json, 2)
			f_cmd_world_bd(str_json, 2, 3, char_id)
		end
	end
	
	return e_code, next_quest_chain
end

function Quest_escort:on_delete(con)
	local e_code = Quest_base.on_delete(self, con)
	if E_SUCCESS == e_code then
		con:set_flags(MISSION_FLAG_ESCORT, false)
		local char_id = con:get_owner()
		local player = char_id and g_obj_mgr:get_obj(char_id)
		player:set_escort_status(0, 1)
	end
	return e_code
end

Mission_mgr.register_class(MISSION_FLAG_ESCORT, Quest_escort)