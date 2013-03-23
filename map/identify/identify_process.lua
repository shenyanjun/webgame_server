

local config = require("config.identify_config")

--验证
Clt_commands[1][CMD_IDENTIFY_ANSWER_C] = 
function(conn, pkt)
	if not conn.char_id then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local sence_id = player:get_scene()[1]
	if not config._sence_config[sence_id] then 
		local ret = {}
		g_cltsock_mgr:send_client(conn.char_id, CMD_IDENTIFY_CLOSE_S, ret)
		ret.result = 22713
		g_cltsock_mgr:send_client(conn.char_id, CMD_IDENTIFY_ANSWER_S, ret)
		return
	end
	local ret = {}
	ret.map_id = sence_id
	ret.answer = pkt.answer
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_IDENTIFY_AUTH_C, ret)
end

--刷新
Clt_commands[1][CMD_IDENTIFY_REFRESH_C] = 
function(conn, pkt)
	if not conn.char_id then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local sence_id = player:get_scene()[1]
	if not config._sence_config[sence_id] then 
		local ret = {}
		g_cltsock_mgr:send_client(conn.char_id, CMD_IDENTIFY_CLOSE_S, ret)
		ret.result = 22713
		g_cltsock_mgr:send_client(conn.char_id, CMD_IDENTIFY_ANSWER_S, ret)
		return
	end
	local ret = {}
	ret.map_id = sence_id
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_IDENTIFY_REFRESH_C, ret)
end

--踢人
Sv_commands[0][CMD_C2M_IDENTIFY_KICKOUT_C] = 
function(conn, char_id, pkt)
	if not char_id then return end
	local obj = g_obj_mgr:get_obj(char_id)
	if not obj then return end
	local sence_id = obj:get_scene()[1]
	if sence_id ~= pkt.sence_id then return end
	local pos = {}
	pos[1] = config._sence_config[sence_id].back_sence[2]
	pos[2] = config._sence_config[sence_id].back_sence[3]
	f_scene_carry(obj:get_id(), config._sence_config[sence_id].back_sence[1], pos)
end

--通过验证加经验
Sv_commands[0][CMD_C2M_IDENTIFY_ADD_EXP_C] = 
function(conn, char_id, pkt)
	if not char_id then return end
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local sence_id = player:get_scene()[1]
	if sence_id ~= pkt.sence_id then return end
	player:add_exp(config._exp*player:get_level())
end

--发验证
Sv_commands[0][CMD_C2M_IDENTIFY_CODE_C] = 
function(conn, char_id, pkt)
	if not char_id then return end
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local sence_id = player:get_scene()[1]
	if sence_id ~= pkt.sence_id then return end	
	local ret = {}
	ret.identify_code = pkt.identify_code
	ret.remain_time = pkt.remain_time
	ret.result = pkt.result	
	g_cltsock_mgr:send_client(char_id, CMD_IDENTIFY_QUESTION_S, ret)
end