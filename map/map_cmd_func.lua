

--buff_type:1 物理攻击 2物理防御 3魔法攻击 4魔法防御 5冰抗 6火抗 7毒抗 8暴击 9命中 10闪避
local _buff = {Impact_1405,Impact_1425,Impact_1415,Impact_1435,
Impact_1705,Impact_1715,Impact_1725,Impact_1805,Impact_1815,Impact_1825}

--提示函数：obj_id玩家id，format_id格式化字符串id，...匹配字符串
function f_cmd_show(obj_id, format_id, ...)
	local new_pkt = {format_id, ...}
	g_cltsock_mgr:send_client(obj_id, CMD_MAP_OBJ_SHOW_S, new_pkt)
end

--游戏世界广播(tp广播类型1聊天 2屏 3聊天和屏)
function f_cmd_sysbd(str_json, tp)
	print("#################f_cmd_sysbd", Json.Encode(str_json))
	local new_pkt = {}
	new_pkt.msg_type = 3
	new_pkt.bdc_type = tp or 3
	new_pkt.say = str_json
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_CHAT_GAME_BROADCAST_REQ, new_pkt)
end

--游戏分线广播
function f_cmd_linebd(str_json)
	print("#################f_cmd_linebd", Json.Encode(str_json))
	local new_pkt = {}
	new_pkt.line = SELF_SV_ID
	new_pkt.msg_type = 3
	new_pkt.say = str_json
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_CHAT_GAME_LINE_REQ, new_pkt)
end

--游戏世界广播
function f_cmd_world_bd(str_json, bdc_type, msg_type,char_id)
	print("#################f_cmd_world_bd", Json.Encode(str_json))
	local new_pkt = {}
	new_pkt.msg_type = msg_type
	new_pkt.say = str_json
	new_pkt.bdc_type = bdc_type
	new_pkt.char_id = char_id
	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_CHAT_GAME_BROADCAST_REQ, new_pkt)
end


--批量执行sql到后台数据库
function f_multi_web_sql(str)
	--[[if _DEBUG then
		g_web_sql:write(str)
	else
		g_web_multi_sql:write(str)
	end]]
	g_web_sql:write(str)
end

--是否pvp线
--[[function f_is_pvp()
	--return PVP_MAP_ID == SELF_SV_ID
	return PVP_MAP_LIST[SELF_SV_ID] ~= nil 
end]]


--放烟花(src_id效果路径)
function f_other_protechny(obj_id, src_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then 
		local new_pkt = {}
		new_pkt.src_id = src_id
		new_pkt.obj_id = obj_id
		local scene_o = obj:get_scene_obj()
		scene_o:send_screen(obj_id, CMD_MAP_OTHER_PROTECHNY_S, new_pkt, 1)
		return 0
	end
	return 1
end

--送花(type:1 1朵，2 9朵，3 99朵)
function f_other_flower(obj_id, des_id, count, say, name, item_id)
	--print("*************f_other_flower1", obj_id, des_id, ty, say)
	local obj_d = g_obj_mgr:get_obj(des_id)
	if obj_d == nil then 
		return 10019
	end

	--print("*************f_other_flower2", obj_s, obj_d, type(ty), type(say))
	local new_pkt = {}
	new_pkt.item_id = item_id
	new_pkt.obj_id = obj_id
	new_pkt.obj_name = name
	new_pkt.des_id = des_id
	new_pkt.des_name = obj_d:get_name()
	new_pkt.say = say

	
	if count == 99 then
		obj_d:receive_flowers(99)
		--local scene_o = obj_d:get_scene_obj()
		--scene_o:send_screen(des_id, CMD_MAP_OTHER_FLOWER_S, new_pkt, 1)
		g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_M2C_FLOWER_SEND_S, new_pkt)
	elseif count == 999 then
		obj_d:receive_flowers(999)
		g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_M2C_FLOWER_SEND_S, new_pkt)

	else
		obj_d:receive_flowers(count)
		g_cltsock_mgr:send_client(des_id, CMD_MAP_OTHER_FLOWER_S, new_pkt)
	end
	
	g_event_mgr:notify_event(EVENT_SET.EVENT_ADD_CHARM, des_id, {['count'] = count})
	
	return 0
end

--大喇叭
function f_horm_send(pkt)
	local ret = pkt.content
	--if not ret.say or type(ret.say) ~= "string" then
		--return 1
	--end
--
	--if string.len(ret.say) >= 70 then
		--return 1
	--end
--
	--if ret.props and type(ret.props) == "table" and table.getn(ret.props) > 2 then
		--return 1
	--end

	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_M2C_HORM_SEND_S, ret)
	return 0
end

--道具增加buff（buff_type类型 val值 count分钟）
function f_obj_add_buff(obj_id, buff_type, val, count)
	if _buff[buff_type] ~= nil then
		local impact_o = _buff[buff_type](sour_id, self:get_level())
		impact_o:set_count(count)  
		
		local param = {}
		param.des_id = obj_id
		param.per = val
		impact_o:effect(param)
	end
end


module("map_cmd_func", package.seeall)

local close_char = function(conn, char_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj ~= nil then 
		g_scene_mgr_ex:leave_scene(obj)
		g_obj_mgr:char_outline(char_id)
	end
	g_cltsock_mgr:leave(conn)
end


--玩家进入
f_enter_map = function(conn, char_id, param)
	local old_conn = g_cltsock_mgr:get_conn(char_id)
	if old_conn ~= nil then
		close_char(old_conn, char_id)
	end
	
	if not (f_is_pvp() or f_is_line_faction()) then
		param = nil
	end

	if g_obj_mgr:char_online(conn, char_id, param) then
		g_cltsock_mgr:enter(conn, char_id) 

		--聊天服通知
		local pkt = {}
		local player = g_obj_mgr:get_obj(char_id)
		pkt.is_first_login = player:is_first_login()
		--pkt.char_nm = player:get_name()
		--pkt.occ = player:get_occ()
		pkt.level = player:get_level()
		--pkt.qlevel = player:get_qlevel()
		--pkt.sex = player:get_sex()
		--pkt.line = SELF_SV_ID
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_ENTER_ACK, pkt)

		--改为由world直接通知common服
		--local ret = {}
		--local player = g_obj_mgr:get_obj(char_id)
		--ret.char_nm = player:get_name()
		--ret.occ = player:get_occ()
		--ret.level = player:get_level()
		--ret.sex = player:get_sex()
		--ret.line = SELF_SV_ID
		--g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2P_PLAYER_ONLINE_ACK, ret)
		return 0
	end
	return 20001
end

--玩家离开map: code 离开方式（1sock断开 2world通知退出）
f_leave_map = function(conn, code)
	print("f_leave_map", conn.char_id, code)
	local char_id = conn and conn.char_id
	close_char(conn, char_id)
	--g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})

	g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2P_PLAYER_OUTLINE_REQ, {})
	if code == 2 then
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
	else
		--g_cltsock_mgr:Destroy()
	end
end

function f_switch_leave_map(conn)
	local char_id = conn.char_id
	f_leave_map(conn, 2)
	if char_id ~= nil then
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
	end
	--g_cltsock_mgr:leave(conn)
end
--断开玩家(flag:非nil 不通知其他服务器,2断开所有玩家,不通知switch；1断开所有玩家，通知switch)
f_kill_char = function(conn, char_id, flag)
	--print("&&&&&&&&&&&&f_kill_char", conn, char_id)
	--close_char(conn, char_id)
	--g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})

	--if conn ~= nil then
		----g_cltsock_mgr:send_server(conn, conn.char_id, CMD_MAP_PLAYER_EXIT_C, {})
		----conn:Destroy()
	--elseif flag == nil then
		--print("&&&&&&&&&&&&f_kill_char", debug.traceback())
		--g_cltsock_mgr:send_server(conn, conn.char_id, CMD_MAP_PLAYER_EXIT_C, {})
		--g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
	--end
	


	if conn ~= nil then
		g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2P_PLAYER_OUTLINE_REQ, {})

		if  flag == nil then
		--print("&&&&&&&&&&&&f_kill_char", conn, char_id)
			g_cltsock_mgr:send_server(conn, conn.char_id, CMD_MAP_PLAYER_EXIT_C, {})
			g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
		elseif flag == 2 then
			g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
			local obj = g_obj_mgr:get_obj(char_id)
			if obj ~= nil then 

				g_scene_mgr_ex:leave_scene(obj)
				g_obj_mgr:char_outline(char_id)
			end
		end
	end
end

--强行断开所有玩家
f_kill_all_char = function(type)
	print("&&&&&&&&&&&&f_kill_all_char")
	g_warning_log:write("&&&&&&&&&&&&f_kill_all_char")

	local list = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
	for obj_id,_ in pairs(list or {}) do
		local conn = g_cltsock_mgr:get_conn(obj_id)
		--[[if conn ~= nil then
			close_char(conn, obj_id)
			g_svsock_mgr:send_server_ex(WORLD_ID, obj_id, CMD_MAP_PLAYER_LEAVE_ACK, {})
		end]]
		f_kill_char(conn, obj_id, type)
	end
end


--接口函数
--[[function f_cmd_func()
	return cmd_func
end]]


