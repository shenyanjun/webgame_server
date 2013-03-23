--[[Sv_commands = {                                           
	[0] = {},
} --]]          

local gm_mall_config = require("mall.gm_mall_loader")
local _gm_exchange = require("gm_exchange.gm_exchange_loader")

--玩家上线
Sv_commands[1][CMD_M2P_PLAYER_ONLINE_ACK] = 
function(conn,char_id,pkt)
	g_player_mgr:join_in(char_id,pkt,pkt.line)
	--宠物繁殖
	g_pet_breed_mgr:on_line(char_id)

	--邮件
	Gm_email:online_send_email(char_id)
	g_char_mgr:online(char_id)
	--全服成就
	g_global_achi_mgr:online(char_id, pkt.line)
	--公测礼包
	g_beta_test_reward_mgr:check_send_reward(char_id, pkt.account_name)
end
--
--玩家下线
Sv_commands[0][CMD_M2P_PLAYER_OUTLINE_REQ] =
function(conn,char_id,pkt)
	g_player_mgr:quit(char_id)
	g_faction_mgr:outline(conn,char_id)
	g_pet_adventure_mgr:out_line(char_id)
	--宠物繁殖
	g_pet_breed_mgr:out_line(char_id)
	g_char_mgr:outline(char_id)
end

--服务器重启
Sv_commands[0][CMD_M2P_PLAYER_INFO_S] =
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_player_mgr:reset_online_l(pkt.line,pkt.player_list,conn)
	for k, v in pairs(pkt.player_list or {}) do
		g_faction_mgr:restart_server(v.obj_id)
		g_char_mgr:online(v.obj_id)
	end

	-- 报名同步
	local ret = Application_filter:syn_info()
	g_server_mgr:send_to_all_map(0, CMD_P2M_APPLICATION_SYN_S, Json.Encode(ret), true)
end


Sv_commands[0][CMD_SERVER_CONNECTION] =
function(conn, char_id, pkt)
	g_server_mgr:accept_server(conn, pkt)
	
	-- 报名同步
	local ret = Application_filter:syn_info()
	g_server_mgr:send_to_server(conn.id,0, CMD_P2M_APPLICATION_SYN_S, ret)
end

--升级
Sv_commands[0][CMD_M2P_PLAYER_UPDATE_LEVEL_REQ] =
function(conn,char_id,pkt)
	g_player_mgr:change_level(char_id, pkt.level)
	g_faction_mgr:update_level(conn,char_id,pkt.level)
end

--热更新
Sv_commands[0][CMD_G2C_COMMON_HOT_UPDATE_ACK] =
function(conn, char_id, pkt)
	for k,file in pairs(pkt.file_list) do
		require_ex(file)
	end
end

Sv_commands[0][CMD_M2P_TEST_REQ] =
function(conn,char_id,pkt)
	print("hello world~!")
end

--获取不同线玩家属性
local callback_attr_func = function(obj, param, pkt)
	local char_id = param.char_id
	local line = param.line
	g_server_mgr:send_to_server(line, char_id, CMD_C2M_GET_HUMAN_ATTR_REP, pkt)
end

Sv_commands[0][CMD_M2C_GET_HUMAN_ATTR_ACK] =
function(conn,char_id,pkt)
	if g_player_mgr:is_online_char(pkt.obj_id) then
		local line = g_player_mgr:get_char_line(pkt.obj_id)
		local param = {}
		param.line = conn.id
		param.char_id = char_id
		g_sock_event_mgr:add_event(char_id, CMD_M2C_REQUEST_HUMAN_ATTR_REP, nil, callback_attr_func, nil, param, 3)
		g_server_mgr:send_to_server(line, char_id, CMD_C2M_REQUEST_HUMAN_ATTR_ACK, pkt) 
	else
		local attr_l = g_player_mgr:get_player_attr(pkt.obj_id)
		if attr_l ~= nil then
			g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_GET_HUMAN_ATTR_REP, attr_l)
		end
	end
end
--其他线返回玩家属性
--[[Sv_commands[0][CMD_M2C_REQUEST_HUMAN_ATTR_REP] =
function(conn,char_id,pkt)
	g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_REQUEST_HUMAN_ATTR_ACK, pkt)
end]]

--获取不同线玩家吸仙灵属性
local callback_child_attr_func = function(obj, param, pkt)
	local char_id = param.char_id
	local line = param.line
	--print("==>callback_child_attr_func")
	g_server_mgr:send_to_server(line, char_id, CMD_C2M_GET_CHILD_ATTR_REP, pkt)
end

Sv_commands[0][CMD_M2C_GET_CHILD_ATTR_ACK] =
function(conn,char_id,pkt)
	local child_id = pkt.child_id
	--print("==>CMD_M2C_GET_CHILD_ATTR_ACK")
	if g_player_mgr:is_online_char(pkt.owner_id) then
		local line = g_player_mgr:get_char_line(pkt.owner_id)
		local param = {}
		param.line = conn.id
		param.char_id = char_id
		g_sock_event_mgr:add_event(char_id, CMD_M2C_REQUEST_CHILD_ATTR_REP, nil, callback_child_attr_func, nil, param, 3)
		--print("online pkt:", j_e(pkt))
		g_server_mgr:send_to_server(line, char_id, CMD_C2M_REQUEST_CHILD_ATTR_ACK, pkt) 
	else
		local err, row = g_char_mgr:get_child_info_from_db(pkt.child_id)
		--print("errrrrr===", err, j_e(row), pkt.child_id)
		if err == 0 then
			local ret = {}
			ret[1] = {}
			ret[1][1] = row.info
			ret[2] = pkt.owner_id
			--print("from_db:", j_e(ret))
			g_server_mgr:send_to_server(conn.id, char_id, CMD_C2M_GET_CHILD_ATTR_REP, ret)
		end
	end
end


--后台商城更新
Sv_commands[0][CMD_G2C_MALL_HOT_UPDATE_ACK] =
function(conn, char_id, pkt)
	if pkt.type == 1 then
		gm_mall_config.update_gm_mall()
	end
end

--后台兑换
Sv_commands[0][CMD_G2C_GM_EXC_HOT_UPDATE_ACK] = 
function(conn,char_id,pkt)
	_gm_exchange.load_exchange_db()
end
