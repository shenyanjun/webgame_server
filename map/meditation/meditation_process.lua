--2011-03-26
--laojc
--打坐处理类

--单人修炼
Clt_commands[1][CMD_B2M_SINGLE_MEDITATION_C] =
function(conn, pkt)
	if conn.char_id == nil or pkt == nil then return end

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	if not player:is_alive() then return end

	local meditation = g_meditation_mgr:get_meditation(conn.char_id)
	if meditation ~= nil then
		if not meditation:get_percent() then return g_meditation_mgr:del_container(conn.char_id) end--g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20410}) end
		if pkt.is_auto == 1 then  --自动
			if pkt.flag == 0 then
				g_meditation_mgr:del_container(conn.char_id)
			elseif pkt.flag == 1 then
				local player = g_obj_mgr:get_obj(conn.char_id)
				if player:get_level() < 20 then return end
				meditation:set_flag(1)
				local ret = {}
				ret[1] = conn.char_id
				player:set_meditation_status_l(ret)
			end
		else
			if pkt.flag == 0 then
				g_meditation_mgr:del_container(conn.char_id)
			else
				local player = g_obj_mgr:get_obj(conn.char_id)
				if player:get_level() < 20 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20416}) end
				meditation:set_flag(1)
				local ret = {}
				ret[1] = conn.char_id
				player:set_meditation_status_l(ret)
			end
		end
	end
end

--双人修炼请求
Clt_commands[1][CMD_B2M_DOUBLE_MEDITATION_C] =
function(conn,pkt)
	if conn.char_id == nil or pkt.char_id == nil then return end

	local player_s = g_obj_mgr:get_obj(conn.char_id)
	if not player_s then return end

	local player_d = g_obj_mgr:get_obj(pkt.char_id)
	if not player_d then return end

	--等级不够
	if player_s:get_level()<20 or player_d:get_level()<20 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20416})
	end

	--是否活的
	if not player_d:is_alive() then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20411}) end
	--是否异性
	if player_s:get_sex() == player_d:get_sex() then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20412}) end
	--场景是否符合
	local percent = g_meditation_mgr:get_meditation(conn.char_id):get_percent()
	if percent == nil then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20410}) end

	--是否对方已经是双休
	local meditation_s = g_meditation_mgr:get_meditation(pkt.char_id)
	local meditation_d = g_meditation_mgr:get_meditation(conn.char_id)
	if meditation_s:get_flag() == 2 or meditation_d:get_flag() == 2 then
		local ret = {}
		ret.result = 20413
		return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, ret)
	end

	--距离够不够
	local dist = f_distance(player_s:get_pos(),player_d:get_pos())
	if dist > 1 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20414}) end

	g_meditation_mgr:add_request(pkt.char_id, conn.char_id)

	local ret = {}
	ret.char_id = conn.char_id
	g_cltsock_mgr:send_client(pkt.char_id, CMD_M2B_DOUBLE_MEDITATION_S, ret) 
end

--确定双人修炼请求
Clt_commands[1][CMD_B2M_ANSWER_MEDITATION_C] =
function(conn,pkt)
	if conn.char_id == nil and pkt.char_id == nil then return end

	local meditation = g_meditation_mgr:get_meditation(conn.char_id)
	local flag = meditation:get_flag()
	if flag == 2 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20415}) end

	local player_s = g_obj_mgr:get_obj(conn.char_id)
	if not player_s then return end

	local player_d = g_obj_mgr:get_obj(pkt.char_id)
	if not player_d then return end

	--等级不够
	if player_s:get_level()<20 or player_d:get_level()<20 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20416})
	end

	--是否活的
	if not player_d:is_alive() then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20411}) end
	--是否异性
	if player_s:get_sex() == player_d:get_sex() then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20412}) end

	--场景是否符合
	local percent = g_meditation_mgr:get_meditation(conn.char_id):get_percent()
	if percent == nil then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20410}) end

	--距离够不够
	local dist = f_distance(player_s:get_pos(),player_d:get_pos())
	if dist > 1 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_MEDITATION_ERROR_S, {["result"]=20414}) end

	local result = g_meditation_mgr:get_request(conn.char_id,pkt.char_id)
	if result == 0 then
		g_meditation_mgr:add_container(conn.char_id,pkt.char_id)
		g_meditation_mgr:del_request(conn.char_id)
	end

end
