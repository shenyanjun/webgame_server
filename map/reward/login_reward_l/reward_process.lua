--2010-01-21
--laojc
--奖励处理事件

Clt_commands[1][CMD_C2M_LOGIN_REWARD_C] =
function(conn, pkt)
	if conn.char_id == nil then return end

	local char_id = conn.char_id

	local ret = g_reward_gift_mgr:get_net_info(char_id)
	g_cltsock_mgr:send_client(char_id, CMD_M2C_LOGIN_REWARD_S, ret)
	--推送签到信息
	--local sign_in_con = g_reward_gift_mgr:get_sign_in_obj(char_id)
	--sign_in_con:send_net_info()
	
end

--世界等级
Clt_commands[1][CMD_C2M_WORLD_LEVEL_C] =
function(conn, pkt)
	if conn.char_id == nil then return end

	local char_id = conn.char_id

	local ret = {}
	ret.world_level = g_world_lvl_mgr:get_average_level()
	g_cltsock_mgr:send_client(char_id, CMD_M2C_WORLD_LEVEL_S, ret)

end

--获取礼包
Clt_commands[1][CMD_C2M_FETCH_REWARD_C] =
function(conn, pkt)
	if conn.char_id == nil or pkt == nil or pkt.type == nil then return end
	local char_id = conn.char_id
	local type = pkt.type
	local pkt = {}
	pkt.result = 0

	local result = g_reward_gift_mgr:can_be_fetch(char_id,type)
	pkt.result = result
	if result ~= 0 then return g_cltsock_mgr:send_client(char_id, CMD_M2C_FETCH_REWARD_S, pkt) end

	result = g_reward_gift_mgr:fetch_item(char_id,type)

	pkt.result = result
	pkt.type = type
	pkt.flag = 1
	g_cltsock_mgr:send_client(char_id, CMD_M2C_FETCH_REWARD_S, pkt)
end


--定时轮询消息

Clt_commands[1][CMD_C2M_TIME_POLL_C] =
function(conn, pkt)
	g_reward_gift_mgr:click_return()
	--g_daily_reward_mgr:click_return()
	g_off_mgr:click_return()
end


--新手卡礼包
Clt_commands[1][CMD_C2M_NOVICE_REWARD_C] =
function(conn, pkt)
	if conn.char_id == nil or pkt.key == nil then return end

	local char_id = conn.char_id
	local key = pkt.key
	local pkt = {}
	pkt.result = 0

	local result = Novice_reward:can_be_fetch(key,char_id)
	if result ~= 0 then
		pkt.result = result 
		g_cltsock_mgr:send_client(char_id, CMD_M2C_NOVICE_REWARD_S, pkt)
		return
	end

	result = Novice_reward:fetch_item(char_id,key)
	pkt.result = result
	
	g_cltsock_mgr:send_client(char_id, CMD_M2C_NOVICE_REWARD_S, pkt)
end

--首充礼包
Clt_commands[1][CMD_C2M_RECHAGE_REWARD_C] =
function(conn, pkt)
	if conn.char_id == nil then return end
	local char_id = conn.char_id
	
	local pkt = {}
	pkt.result = 0
	local result = Rechage_reward:can_be_fetch(char_id,1)
	
	if result ~= 0 then 
		pkt.result = result
		g_cltsock_mgr:send_client(char_id, CMD_M2C_RECHAGE_REWARD_S, pkt) 
		return 
	end

	result = Rechage_reward:fetch_item(char_id)
	pkt.result = result

	g_cltsock_mgr:send_client(char_id, CMD_M2C_RECHAGE_REWARD_S, pkt)
end

--充值
Sv_commands[0][CMD_B2M_RECHAGE_C] =
function(conn, char_id, pkt)
	if pkt.rechage_id == nil then return end
	local rechage_id = pkt.rechage_id
	local jade = pkt.jade
	local char_id = pkt.char_id
	local obj = g_obj_mgr:get_obj(char_id)
	--local jade,char_id = Rechage_reward:get_money_by_rechage_id(rechage_id)
	if jade == nil or char_id == nil or obj == nil then return end
	local result = Rechage_reward:add_money(char_id,jade,rechage_id)
	local pkt = {}
	pkt.result = result
	--pkt.jade = jade

	g_cltsock_mgr:send_client(char_id, CMD_M2C_RECHAGE_S, pkt)

	local result = Rechage_reward:fetch_flag(char_id,1)
	
	local ret = {}
	ret.flag = result
	g_cltsock_mgr:send_client(char_id, CMD_M2C_RECHAGE_GIFT_S, ret)
end

Clt_commands[1][CMD_C2M_RECHAGE_GIFT_C] =
function(conn, pkt)
	if conn.char_id == nil then return end
	local result = Rechage_reward:fetch_flag(conn.char_id,1)
	
	local ret = {}
	ret.flag = result
	g_cltsock_mgr:send_client(conn.char_id, CMD_M2C_RECHAGE_GIFT_S, ret)
end

Clt_commands[1][CMD_RECHAGE_GIFT_FETCH_C] =
function(conn, pkt)
	if conn == nil then return end
	local gift_con = Rechage_reward:get_container(conn.char_id)
	if not gift_con then return end

	local ret = gift_con:serialize_to_net()
	
	g_cltsock_mgr:send_client(conn.char_id, CMD_RECHAGE_GIFT_FETCH_S, ret)
end

--连续登陆 基础 and 黄钻 奖励
Clt_commands[1][CMD_MAP_ADD_LOGIN_REWARD_C] =
function(conn, pkt)
	if conn.char_id == nil then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	local login_reward_con = g_reward_gift_mgr:get_addlogin_obj(conn.char_id)
	if not login_reward_con then return end
	if login_reward_con:get_login_day() > login_reward_con:get_reward_maxday() then return 22741 end

	local ret = {}	
	if not pkt.id or not pkt.type then   
		ret = login_reward_con:send_net_info()
		ret.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ADD_LOGIN_REWARD_S , ret) -- 通知客户端
		return
	end
	
	ret.result = login_reward_con:is_can_get_gift(pkt.id, pkt.type)
	if 0 ~= ret.result then 
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ADD_LOGIN_REWARD_S , ret) -- 通知客户端
		return
	end

	local reward_list = login_reward_con:get_gift(pkt.id, pkt.type)

	local new_item_list = {}
	local count = 1
	for k,v in pairs(reward_list or {}) do
		new_item_list[count] = {}
		new_item_list[count]["item_id"]     = v.item_id
		new_item_list[count]["type"]   		= 1
		new_item_list[count]["number"] 		= v.number
		count = count + 1
	end
	local pack_con = player:get_pack_con()	
	if pack_con then
		ret.result = pack_con:add_item_l(new_item_list,{['type']=ITEM_SOURCE.ADD_LOGIN_REWARD})
		if ret.result ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ADD_LOGIN_REWARD_S , ret) -- 通知客户端
			return
		end
	end
	login_reward_con:set_gain_gift(pkt.id, pkt.type)
	ret = login_reward_con:send_net_info()
	ret.result = 0
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ADD_LOGIN_REWARD_S , ret) -- 通知客户端
end

--签到
Clt_commands[1][CMD_MAP_SIGN_IN_C] =
function(conn, pkt)
	local sign_in_con = g_reward_gift_mgr:get_sign_in_obj(conn.char_id)
	if not sign_in_con then return end
	
	sign_in_con:sign_in()
	sign_in_con:send_net_info()
end

--签到领奖
Clt_commands[1][CMD_MAP_SIGN_IN_REWARD_C] =
function(conn, pkt)
	local sign_in_con = g_reward_gift_mgr:get_sign_in_obj(conn.char_id)
	if not sign_in_con then return end
	print("=====print info ======")
	print("conn.char_id".. conn.char_id)
	print("pkt.type".. pkt.type)
	print("pkt.day" .. pkt.day)
	print("===== end ======")
	local ret = sign_in_con:get_reward(pkt.type, pkt.day)
	if ret ~= 0 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SIGN_IN_REWARD_C, {["result"] = ret})
	end
end

--取信息
Clt_commands[1][CMD_MAP_SIGN_IN_INFO_C] =
function(conn, pkt)
	local sign_in_con = g_reward_gift_mgr:get_sign_in_obj(conn.char_id)
	if not sign_in_con then return end
	sign_in_con:check_next_month()
	sign_in_con:send_net_info()
end