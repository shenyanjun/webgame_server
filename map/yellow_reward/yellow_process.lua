
local yellow_reward_load = require("yellow_reward.yellow_reward_load")


--获取 黄钻新手礼包 每日礼包状态
Clt_commands[1][CMD_MAP_YELLOW_GIFT_C] =
function(conn, pkt)
	local ret = g_yellow_reward_mgr:info_to_net(conn.char_id)
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_YELLOW_GIFT_S, ret)
end

--领取黄钻 新手礼包 每日礼包
Clt_commands[1][CMD_MAP_GET_YELLOW_GIFT_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player and not pkt.type then return end
	local pack_con = player:get_pack_con()
	if not pack_con then return end

	if player:get_qlevel() == 0 then
		return 
	end

	local ret = {}
	ret.result = 0
	if g_yellow_reward_mgr:can_reward(conn.char_id,pkt.type) ~= 0 then
		ret.result = 24002
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GET_YELLOW_GIFT_S, ret)
		return 
	end
	
	local reward = {}
	local reward_extra = {}
	if pkt.type == 1 then
		reward = yellow_reward_load.get_new_gift()
	elseif pkt.type == 2 then
		reward = yellow_reward_load.get_every_gift(player:get_qlevel())
		if player:get_qlevel() > yellow_reward_load.get_max_lv() then
			reward_extra = yellow_reward_load.get_every_extra_gift(player:get_qlevel())
		end
	end
	local new_item_list = {}
	local count = 1
	for k,v in pairs(reward or {})do
		new_item_list[count] = {}
		new_item_list[count]["item_id"]     = k
		new_item_list[count]["type"]   = 1
		new_item_list[count]["number"] = v
		count = count + 1
	end	
	for c,d in pairs(reward_extra or {}) do
		new_item_list[count] = {}
		new_item_list[count]["item_id"]     = c
		new_item_list[count]["type"]   = 1
		new_item_list[count]["number"] = d
		count = count + 1
	end

	local e_code = pack_con:add_item_l(new_item_list,{['type']=ITEM_SOURCE.YELLOW_REWARD})
	if e_code~=0 then
		ret.result = e_code
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GET_YELLOW_GIFT_S, ret)
		return 
	end
	g_yellow_reward_mgr:set_sign(conn.char_id,pkt.type)
	ret = g_yellow_reward_mgr:info_to_net(conn.char_id)
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GET_YELLOW_GIFT_S, ret)
end