
local misson_loader = require("mission_ex.mission_loader")

Quest_base = oo.class(nil, "Quest_base")

function Quest_base:__init(meta)
	self.quest_id = meta.id
	self.type = meta.type
	self.status = MISSION_STATUS_NONE
	self.flag = meta.flag
end

function Quest_base:get_id()
	return self.quest_id
end

function Quest_base:get_f_id()
	return self.faction_id
end

function Quest_base:get_type()
	return self.type
end

function Quest_base:get_flag()
	return self.flag
end

function Quest_base:set_status(status)
	if status then
		self.status = status
	end
end

function Quest_base:get_status()
	return self.status
end

function Quest_base:clone(record)
	if record then
		if not record.quest_id or not record.status then
			return nil, E_MISSION_INVALID_DATA
		end
	else
		record = self
	end
	local obj, e_code = self:load_fields(record)
	if E_SUCCESS == e_code then
		setmetatable(obj, getmetatable(self))
	end
	return obj, e_code
end

function Quest_base:load_fields(record)
	local obj = {}
	obj.quest_id = record.quest_id
	obj.status = record.status
	obj.type = self.type
	obj.flag = self.flag
	return obj, E_SUCCESS
end

function Quest_base:serialize_to_net()
	local result = {}
	result.base = {self.quest_id, self.status, 0, 1, 0, 0}	--第四位 加成比例；第五位 环数； 第六位 次数
	return result
end

function Quest_base:serialize_to_db()
	local result = {}
	result.quest_id = self.quest_id
	result.status = self.status
	return result
end

---------------------------------------------------------------------------------------

function Quest_base:construct(con)
	if MISSION_STATUS_COMMIT == self.status then
		return
	end
	self:register_event(con)
end

function Quest_base:instance(con)
	self:register_event(con)
end

function Quest_base:register_event(con)
end

function Quest_base:unregister_event(con)
end

function Quest_base:deconstruct(con)
	self:unregister_event(con)
end

---------------------------------------------------------------------------------------
--是否右边可看
function Quest_base:can_accept(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local con = player and player:get_mission_mgr()
	if not con then
		return E_MISSION_UNKNOWN
	end
	
	if con:is_exists(self.quest_id) then
		return E_MISSION_ALREADY_ACCEPT
	end
	
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return E_MISSION_INVALID_ID
	end
	
	if meta.precondition then
		if meta.precondition.must_pre_quest_chain then
			for k, _ in pairs(meta.precondition.must_pre_quest_chain) do
				if not con:is_complete(k) then
					return E_MISSION_PREQUEST
				end
			end
		end
	
		if meta.precondition.pre_quest_chain then
			local is_complete = true
			for _, v in pairs(meta.precondition.pre_quest_chain) do
				is_complete = false
				if con:is_complete(v) then
					is_complete = true
					break
				end
			end
			if not is_complete then
				return E_MISSION_PREQUEST
			end	
		end
		
		local req_class = meta.precondition.req_class
		if req_class and 0 ~= req_class and player:get_occ() ~= req_class then
			return E_MISSION_OCC_NO_MATCH
		end
		
		local level = player:get_level()
		
		local min_level = meta.precondition.min_level
		if min_level and level < min_level then
			return E_MISSION_LEVEL_LOW
		end
		
		local max_level = meta.precondition.max_level
		if max_level and level > max_level then
			return E_MISSION_LEVEL_HIG
		end

		
		local need_ring = meta.precondition.ring_lvl
		if need_ring then
			if player:get_marriage_info() ~= 1 then
				return 25027
			end
			if player:get_ring() < need_ring then
				return 25028
			end
		end
		
		local accept_scene = meta.precondition.accept_scene
		if accept_scene and 0 ~= accept_scene and player:get_map_id() ~= accept_scene then
			return E_MISSION_BAD_SCENE
		end
	end
	
	return E_SUCCESS
end

function Quest_base:do_reward(player, reward, select_list, bonus)
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
	
	local e_code = pack_con:add_item_l(item_list, {['type'] = ITEM_SOURCE.TASK})
	if E_SUCCESS ~= e_code then
		return e_code
	end

	--计算额外奖励加乘
	local add_gold 		= reward.gold or 0
	local add_gift_gold = reward.gift_gold or 0
	local add_gift_jade = reward.gift_jade or 0
	local add_jade 		= reward.jade or 0
	local add_exp		= reward.exp or 0
	local add_honor		= reward.honor or 0
	local add_sp		= reward.skill_sp or 0
	if bonus then
		add_gold 		= math.ceil(add_gold * bonus)
		add_gift_gold	= math.ceil(add_gift_gold * bonus)
		add_gift_jade	= math.ceil(add_gift_jade * bonus)
		add_jade		= math.ceil(add_jade * bonus)
		add_exp			= math.ceil(add_exp * bonus)
		add_honor		= math.ceil(add_honor * bonus)
		add_sp			= math.ceil(add_sp * bonus)
	end
	--增加奖励
	local money_list = {}
	money_list[MoneyType.GOLD] 		=  add_gold
	money_list[MoneyType.GIFT_GOLD] =  add_gift_gold
	money_list[MoneyType.GIFT_JADE] =  add_gift_jade
	money_list[MoneyType.JADE] 		=  add_jade
	money_list[MoneyType.HONOR]		=  add_honor
	pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.TASK})
	
	--增加经验值
	if add_exp and add_exp > 0 then
		player:add_exp(add_exp)
	end
	--增加历练
	if add_sp and add_sp > 0 then
		player:add_sp(add_sp)
	end

	return E_SUCCESS
end

----------------------------------------------------事件------------------------------------------------------

function Quest_base:on_accept(char_id)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	local con = player and player:get_mission_mgr()
	if not con then
		return E_MISSION_UNKNOWN
	end
	
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return E_MISSION_INVALID_ID
	end
	
	if meta.precondition then
		if meta.precondition.src_item then
			local item_list = {}
			for _, v in pairs(meta.precondition.src_item) do
				local item = {}
				item.type = 1
				item.number = v.number
				item.item_id = v.id
				table.insert(item_list, item)
			end
			
			local pack_con = player:get_pack_con()
			local e_code = pack_con:add_item_l(item_list, {['type'] = ITEM_SOURCE.TASK})
			if E_SUCCESS ~= e_code then
				return e_code
			end
		end
		
		local accept_scene = meta.precondition.accept_scene
		if accept_scene and 0 ~= accept_scene and player:get_map_id() ~= accept_scene then
			return E_MISSION_BAD_SCENE
		end
	end
	
	self:set_status(MISSION_STATUS_INCOMPLETE)
	self:instance(con)
	return E_SUCCESS
end

function Quest_base:on_delete(con)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return E_MISSION_INVALID_ID
	end
	
	if meta.give_up and 0 ~= meta.give_up then
		return E_MISSION_GIVE_UP_INVALID
	end
	
	self:deconstruct(con)
	return E_SUCCESS
end

function Quest_base:get_quest_bonus()
	return 1
end

function Quest_base:get_faction_id()
	return 25023
end

function Quest_base:get_sns_mission_status(f_id)
	return 0
end

--偷取任务副本
local scene_flag_table = {[12] = true}
function Quest_base:get_scene_id(char_id, s_id_list)
	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID
	end
	
	if not scene_flag_table[meta.flag] then
		return 25016
	end
	
	--判断是不是目标帮派
	local obj = g_obj_mgr:get_obj(self.char_id)
	local scene_obj = obj:get_scene_obj()
	local manor_owner_id = scene_obj.get_manor_owner and scene_obj:get_manor_owner()
	if not manor_owner_id then return 1 end
	local f_id = self:get_f_id()
	if not f_id or f_id ~= manor_owner_id then 
		return 25016
	end

	if meta.scene_id and s_id_list[meta.scene_id] then
		return E_SUCCESS, meta.scene_id
	end

	return 25016
end

function Quest_base:on_complete(char_id, select_list, bonus, param_l)
	local player = char_id and g_obj_mgr:get_obj(char_id)
	assert(player)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end
	--如果客户端判断错误
	if MISSION_STATUS_COMMIT ~= self.status then
		return E_MISSION_INCOMPLETE, nil
	end
	
	self:set_status(MISSION_STATUS_FINISH)
	
	local next_quest_chain = nil
	if meta.reward then
		local e_code = self:do_reward(player, meta.reward, select_list, bonus)
		if E_SUCCESS ~= e_code then
			self:set_status(MISSION_STATUS_COMMIT)
			return e_code, nil
		end
		
		next_quest_chain = meta.reward.next_quest_chain
	end
	
	self:unregister_event(player:get_mission_mgr())
	return E_SUCCESS, next_quest_chain
end
function Quest_base:on_send(con)
	return true
end