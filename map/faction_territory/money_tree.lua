local debug_print = print
--local debug_print = function end
local _random = crypto.random
local _f_t_c = require("config.faction_territory_config")

Money_tree = oo.class(nil, "Money_tree")


function Money_tree:__init(id)
	self.id	= id --crypto.uuid()	-- 
	self.shake_count = 0
	self.m_list	= {}
end

function Money_tree:get_remain_time(char_id)
	return self.m_list[char_id] and (_f_t_c.MONEY_TREE_MAX_TIME - self.m_list[char_id]) or _f_t_c.MONEY_TREE_MAX_TIME
end

function Money_tree:get_time(char_id)
	return self.m_list[char_id] or 0
end

function Money_tree:get_watering_time()
	return self.shake_count or 0
end

function Money_tree:shake(char_id, time)
	self.m_list[char_id] = self.m_list[char_id] and self.m_list[char_id] + time or time

	self.shake_count = self.shake_count + time
	self:do_reward(char_id)
	if self.shake_count >= _f_t_c.MONEY_TREE_FULL - _f_t_c.MONEY_TREE_BROADCAST_TIME and self.shake_count < _f_t_c.MONEY_TREE_FULL then
		self:broadcast()
	end
	if self.shake_count >= _f_t_c.MONEY_TREE_FULL then
		self:make_drop_items()
		self.shake_count = 0
	end
	return 0
end

--生成掉落物品
function Money_tree:make_drop_items()
	debug_print("===>Money_tree:make_drop_items()")
	local lost_1 = _f_t_c._money_tree_lost_1
	local pos_m = {_f_t_c.MONEY_TREE_POS_X - _f_t_c.MONEY_TREE_RANG, _f_t_c.MONEY_TREE_POS_X + _f_t_c.MONEY_TREE_RANG, 
					_f_t_c.MONEY_TREE_POS_Y - _f_t_c.MONEY_TREE_RANG, _f_t_c.MONEY_TREE_POS_Y + _f_t_c.MONEY_TREE_RANG}
	local scene_o = g_scene_mgr_ex:get_scene({_f_t_c.MONEY_TREE_MAP_ID})
	local map_o = scene_o:get_map_obj()
	-- 必掉包
	for k, entry in ipairs(lost_1) do
		local size = _random(entry[2][1], entry[2][2]+1)
		debug_print("===>lost_1, entry:%d, size:%d", k, size)
		for i = 1, size do
			local pos = map_o:find_pos(pos_m)
			local box_obj = g_obj_mgr:create_box(nil, nil, pos, {_f_t_c.MONEY_TREE_MAP_ID, nil})
			for _,item_id in pairs(entry[1]) do
				local _,item_obj = Item_factory.create(item_id)
				if item_obj then
					box_obj:add_comm_item(item_obj)
				end
			end
			g_scene_mgr_ex:enter_scene(box_obj)
		end
	end
	-- 有概率掉
	local str = "!"
	local lost_2 = _f_t_c._money_tree_lost_2
	for k, entry in ipairs(lost_2) do
		local size = _random(entry[2][1], entry[2][2]+1)
		debug_print("===>lost_2, entry:%d, size:%d", k, size)
		local lost_size = 0
		for i = 1, size do
			if _random(1, 10000) <= entry[3] then
				local pos = map_o:find_pos(pos_m)
				local box_obj = g_obj_mgr:create_box(nil, nil, pos, {_f_t_c.MONEY_TREE_MAP_ID, nil})
				for _,item_id in pairs(entry[1]) do
					local _,item_obj = Item_factory.create(item_id)
					if item_obj then
						box_obj:add_comm_item(item_obj)
					end
				end
				g_scene_mgr_ex:enter_scene(box_obj)
				lost_size = lost_size + 1
			end
		end
		--广播
		if lost_size > 0 and entry[4] then
			str = string.format(f_get_string(entry[4]), size) .. str
		end
	end

	local msg = {}
	local bd_str = f_get_string(1602) .. str
	f_construct_content(msg, bd_str, 13)
	f_cmd_sysbd(msg)
end

--全服广播
function Money_tree:broadcast()
	local msg = {}
	f_construct_content(msg, string.format(f_get_string(1601), _f_t_c.MONEY_TREE_FULL - self.shake_count), 16)
	f_cmd_sysbd(msg)
end

--新的一天，重新计数
function Money_tree:on_new_day()
	debug_print("Money_tree:on_new_day()")
	self.m_list = {}
end

--增加礼券和经验值
function Money_tree:do_reward(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()

	--增加礼券
	local money_list = {}
	money_list[MoneyType.GIFT_JADE] =  _f_t_c.MONEY_TREE_GIFT_JADE
	pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.TASK})
	
	--增加经验值
	player:add_exp(_f_t_c.MONEY_TREE_EXP)
end


function Money_tree:serialize_to_db()
	local ret = {}
	ret.shake_count = self.shake_count
	return ret
end

function Money_tree:unserialize_from_db(m_t)
	self.shake_count = m_t and m_t.shake_count or 0
end
