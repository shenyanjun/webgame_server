
local debug_print = function() end
--local debug_print = print
local _random = crypto.random

local proto_mgr = require("item.proto_mgr")

local config = require("config.loader.treasure_loader")
local scene_process = require("scene_ex.scene_process")

Treasure_mgr = oo.class(nil, "Treasure_mgr")


function Treasure_mgr:__init()
	self.time = ev.time + 40
end

--mytest
function Treasure_mgr:get_click_param()
	return self, self.on_timer, 3 ,nil
end


function Treasure_mgr:on_timer()
	local char_id = 4021
	local color = _random(1, 5)
	local now = ev.time
	if now > self.time then
		debug_print("dig_event:", char_id, color)
		self:dig_event(char_id, color)
		self.time = now + 10
	end
end

function Treasure_mgr:item_init(color)
	local s_config = config.color[color]
	local scene_l = s_config.scene_l
	local scene_count = s_config.scene_count
	local random_scene = _random(1, scene_count + 1)
	local scene = scene_l[random_scene]
	local scene_id = scene.scene_id
	local pos_count = scene.pos_count
	local random_pos = _random(1, pos_count + 1)
	local pos = scene.pos_l[random_pos]
	return scene_id , pos
end

function Treasure_mgr:check_eara(char_id, scene_id, pos)
	local obj = g_obj_mgr:get_obj(char_id)
	if not obj then return end
	local cur_pos = obj:get_pos()
	local cur_scene_id = obj:get_map_id()

	if obj:get_treasure_count() > 100 then
		return 21226
	end


	if scene_id == 30002 then
		scene_id = 30000
	end

	if scene_id == 11000 then
		scene_id = 10000
	end

	debug_print("===========>curscene, desscene", cur_scene_id, scene_id)
	if tostring(cur_scene_id) ~= tostring(scene_id) then
		return 31262
	end
	debug_print("==========>treasure pos", pos[1], pos[2])
	local area = config.area
	if ((cur_pos[1]-pos[1])^2 + (cur_pos[2] - pos[2])^2) > area*area then
		return 31261
	end
	return 0
end

function Treasure_mgr:dig_event(char_id, type, treasure_id, treasure_name)
	local obj = g_obj_mgr:get_obj(char_id)
	if not obj then 
		return 
	end
	obj:add_treasure_count()

	local weight_l = config.color[type].event.weight
	local event = self:get_event_from_list(weight_l, {3}) --副本
	if 1 == event then
		debug_print("=====>reward")
		local ret = {}
		ret.trap = 1
		g_cltsock_mgr:send_client(char_id, CMD_PUZZLE_MAP_TRAP_S, ret)
		self:reward_event(char_id, type, treasure_id, treasure_name)
	elseif 2 == event then
		debug_print("=====>boss")
		self:boss_event(char_id, type, treasure_id, treasure_name, 1)
	elseif 3 == event then
		
		debug_print("=====>copy")
		return
		self:copy_event(char_id, type, treasure_id, treasure_name)
	elseif 4 == event then
		debug_print("=====>trap")
		self:trap_event(char_id, type, treasure_id, treasure_name)
	end
end


function Treasure_mgr:reward_event(char_id, type, treasure_id, treasure_name)
	local reward = config.color[type].event.reward
	local event = self:get_event_from_list(reward.weight)
	local broadcast
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local char_name = player:get_name()
	local type = event
	local money_type = nil
	local count
	local item_name

	if 1 == event then
		debug_print("=====>money")
		local money = reward.money
		local random_money = self:get_event_from_list(money.weight)
		local money_l = money.money_l[random_money]
		self:add_money(char_id, money_l, treasure_id, treasure_name)
		broadcast = money.broadcast_l[random_money]
		if broadcast == 1 then
			if money_l[1] > 0 then
				money_type = 1
				count = money_l[1]
			else
				money_type = 2
				count = money_l[2]
			end
		end
	elseif 2 == event then
		debug_print("=====>exp")
		local exp = reward.exp
		local random_exp = self:get_event_from_list(exp.weight)
		local exp_count = exp.exp_l[random_exp]
		self:add_exp(char_id, exp_count, treasure_id, treasure_name)
		broadcast = exp.broadcast_l[random_exp]
		count = exp_count
	elseif 3 == event then
		debug_print("=====>item")
		local item = reward.item
		local except_l = g_whole_mgr:check_lost_item_l(item.item_l)
		debug_print("=====>item, except_l", j_e(except_l))
		local random_id = self:get_event_from_list(item.weight, except_l)
		debug_print("random_id", random_id)
		local item_id = item.item_l[random_id]
		debug_print("item_id:", item_id)
		self:add_item(char_id, item_id, treasure_id, treasure_name, 1)
		broadcast = item.broadcast_l[random_id]
		if broadcast == 1 then
			local e_code, proto = proto_mgr.get_proto(item_id)
			if not proto then return end
			item_name = proto.value.name
		end
	end
	--[[--
	if broadcast == 1 then
		local ret = {}
		ret.item_name = item_name
		ret.char_name = char_name
		ret.type = type
		ret.money_type = money_type
		ret.count = count
		g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2C_TREASURE_BROADCAST_M, ret)
	end
	--]]--
end

function Treasure_mgr:boss_event(char_id, type, treasure_id, treasure_name)
	local boss = config.color[type].event.boss
	debug_print("boss", j_e(boss))
	local random_boss = self:get_event_from_list(boss.weight)
	local boss_id = boss.list[random_boss]
	debug_print("boss_id, random_boss", boss_id, random_boss)
	self:create_boss(char_id, boss_id, treasure_id, treasure_name)
	local ret = {}
	ret.trap = 2
	g_cltsock_mgr:send_client(char_id, CMD_PUZZLE_MAP_TRAP_S, ret)
end

function Treasure_mgr:copy_event(char_id, type, treasure_id, treasure_name)
	local copy_l = config.color[type].event.copy
	local random_id = get_event_from_list(copy.weight)
	local scene_id = copy_l[random_id]
	--切换地图
	scene_process.change_scene(char_id, scene_id)
	--CMD_MAP_CHANGE_MAP_C = 20009
	--CMD_MAP_CHANGE_MAP_S = 20010
	--enter_scene()
	--local str = string.format("insert into treasure_map set char_id = %d, create_time = %d, color = %d, event = %d, scene_id = %d", 
	 --				char_id, ev.time, color, 3, scene_id)
	--g_web_sql:write(str)
end

function Treasure_mgr:trap_event(char_id, type, treasure_id, treasure_name)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local impact_con = player:get_impact_con()
	local impact_o = impact_con:find_impact(1502)
	if impact_o == nil then
		f_prop_change(player, 283)
	end
	local ret = {}
	ret.trap = 0
	g_cltsock_mgr:send_client(char_id, CMD_PUZZLE_MAP_TRAP_S, ret)
	local char_name = player:get_name()
	local str = string.format("insert into log_treasure set \
		char_id = %d, char_name = '%s', create_time = %d, treasure_id = %d, treasure_name = '%s', first_event = %d", 
		char_id, char_name, ev.time, treasure_id, treasure_name, 4)
	g_web_sql:write(str)
end

function Treasure_mgr:get_event_from_list(weight_l, except_l)
	local except_table = {}
	for k, v in pairs(except_l or {}) do
		except_table[v] = 1
	end

	local result_l = {}
	local weight_t = 0
	for id, weight in pairs(weight_l or {}) do
		if except_table[id] == nil then
			weight_t = weight_t + weight
			table.insert(result_l, {weight_t, id})
		end
	end

	if weight_t <= 0 then return end
	local r = crypto.random(1, weight_t+1)
	for _, v in ipairs(result_l) do
		if r <= v[1] then
			return v[2]
		end
	end
end


function Treasure_mgr:add_money(char_id, money_l, treasure_id, treasure_name)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local lock_con = player:get_protect_lock()
	if not lock_con then return end
	local pack_con = player:get_pack_con()
	debug_print("=====>add_money", j_e(money_l))
	local money_list = {}
	money_list[MoneyType.GOLD] 		=  money_l[1]
	money_list[MoneyType.GIFT_GOLD] =  money_l[2]
	pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.TREASURE_MAP})
	local char_name = player:get_name()
	local str = string.format("insert into log_treasure set \
		char_id = %d, char_name = '%s', create_time = %d, treasure_id = '%s', treasure_name = '%s', first_event = %d, second_event = %d, gold = %d, gift_gold = %d", 
		char_id, 	 char_name,  ev.time, treasure_id, treasure_name, 	1,	1,	 money_l[1], money_l[2])
	g_web_sql:write(str)
end

function Treasure_mgr:add_exp(char_id, exp, treasure_id, treasure_name)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	debug_print("=====>add_exp", exp)
	player:add_exp(exp)
	local char_name = player:get_name()
	exp = tonumber(exp)
	local str = string.format("insert into log_treasure set \
		char_id = %d, 	char_name = '%s', 	create_time = %d, treasure_id = '%s', treasure_name = '%s', first_event = %d, second_event = %d, exp = %d", 
		char_id, char_name, ev.time, treasure_id, treasure_name, 1, 2, 	exp)
	g_web_sql:write(str)
end

function Treasure_mgr:add_item(char_id, item_id, treasure_id, treasure_name, flag)
	debug_print("Treasure_mgr:add_item")
	local player = g_obj_mgr:get_obj(char_id)
	if player ~= nil then
		local pack_con = player:get_pack_con()
		local item_list = {}
		item_list[1] = {}
		item_list[1].type = 1
		item_list[1].item_id = item_id
		item_list[1].number  = 1
		
		local error = pack_con:check_add_item_l_inter_face(item_list)
		debug_print("error:", error)
		if error == 0 then 
			debug_print("=====>add_itme", j_e(item_list))
			g_whole_mgr:add_lost_item_l({tonumber(item_id)})
			pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.TREASURE_MAP})
			local char_name = player:get_name()
			local e_code, proto = proto_mgr.get_proto(tonumber(item_id))
			local item_name = proto and proto.value.name
			if flag then
				local str = string.format("insert into log_treasure set \
						char_id = %d, char_name = '%s', create_time = %d, treasure_id = '%s', treasure_name = '%s',  first_event = %d, second_event = %d,  item_id = %s, item_name = '%s'", 
						char_id, 	char_name, ev.time, treasure_id, treasure_name, 1, 	3, item_id, item_name)
				g_web_sql:write(str)
			end
		else
			--背包满

		end
	end
end

function Treasure_mgr:create_boss(obj_id, boss_id, treasure_id, treasure_name, flag)
	
	local obj_mgr = g_obj_mgr
	local obj = obj_mgr:get_obj(obj_id)
	if not obj then return end
	debug_print("boss:", obj_id, boss_id)
	local param = {}
	local cur_pos = obj and obj:get_pos()
	local pos_m = {cur_pos[1]-5,cur_pos[1]+5,cur_pos[2]-5,cur_pos[2]+5}
	local map_obj = obj:get_scene_obj():get_map_obj()
	local pos = map_obj:find_pos(pos_m)
	local scene_d = obj:get_scene()
	local obj = obj_mgr:create_monster(boss_id, pos, scene_d)
	g_scene_mgr_ex:enter_scene(obj)
	local char_name = obj:get_name()
	if flag then
		local str = string.format("insert into log_treasure set \
			char_id = %d, char_name = '%s', create_time = %d, treasure_id = '%s', treasure_name = '%s', remark = '%s'",
			obj_id, char_name, ev.time, 2, 4, treasure_id, treasure_name, boss_id)
		g_web_sql:write(str)
	end

end
