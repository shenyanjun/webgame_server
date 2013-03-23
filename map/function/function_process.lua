--每日活动面板处理类

--打开活动面板
Clt_commands[1][CMD_B2M_FUNC_OPEN_C] =
function(conn, pkt)
	if conn.char_id == nil then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local function_con = player:get_function_con()
	local ret = function_con:get_net_info()
	ret.result = 0
	g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_DAILY_S, ret)

end

--每日必做 每日必做  chendong 120927
--[[
--获取物品
Clt_commands[1][CMD_B2M_FUNC_FETCH_ITEM_C] =
function(conn, pkt)
	if conn.char_id == nil or pkt.type == nil then return end

	local player = g_obj_mgr:get_obj(conn.char_id)
	local function_con = player:get_function_con()

	local result = function_con:can_be_fetch(pkt.type)
	if result ~= 0 then 
		return f_cmd_show(conn.char_id,result) 
	end

	result, item_list = function_con:fetch_item(pkt.type)
	if result ~= 0 then 
		return f_cmd_show(conn.char_id,result)
	end

	local ret = function_con:get_net_info()
	ret.reward_items = {}
	ret.reward_items[1] = pkt.type
	ret.reward_items[2] = item_list
	g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_INFO_S, ret)
end

--定时轮询消息
Clt_commands[1][CMD_B2M_FUNC_TIME_POLL_C] =
function(conn, pkt)
	--local obj_list = g_obj_mgr:get_list(OBJ_HUMAN)
	--for k,v in pairs(obj_list or {}) do
		--local function_con = v:get_function_con()
		--function_con:login()
	--end
end


--客户端直接完成活动
Clt_commands[1][CMD_B2M_FUNC_NET_C] = 
function(conn,pkt)
	if conn.char_id == nil or pkt.type == nil then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local function_con = player:get_function_con()

	function_con:set_complete(pkt.type)

	local ret = function_con:get_net_info()
	g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_INFO_S, ret)
end

--每日必做
Clt_commands[1][CMD_B2M_FUNC_FINISH_C] = 
function(conn,pkt)
	if conn.char_id == nil then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local function_con = player:get_function_con()
	local pack_con = player:get_pack_con()

	local flag = 0

	if pack_con:check_item_lock_by_item_id(139000000020) or pack_con:check_item_lock_by_item_id(139000000021) then
		return
	end

	local bind_count = pack_con:get_item_count(139000000020) 
	local no_bind_count = pack_con:get_item_count(139000000021)
	local item_count = bind_count + no_bind_count 
	local non_finish = function_con:get_non_finish_count()
	if pkt.act_id == nil then
		if non_finish == 0 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_DAILY_S, {["result"] = 20351}) end
		if item_count < non_finish then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_DAILY_S, {["result"] = 20354}) end
		flag = 1
	else
		local result = function_con:is_single_finish(pkt.act_id)
		if result == 0 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_DAILY_S, {["result"] = 20351}) end
		if item_count == 0 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_DAILY_S, {["result"] = 20354}) end
		flag = 2
	end

	local result = function_con:quick_work(pkt.act_id)
	if result ~=0 and result ~=nil then 
		g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_DAILY_S, {["result"] = result})
	else
		local error_code = 1
		if flag == 2 then
			if bind_count > 0 then
				error_code = pack_con:del_item_by_item_id(139000000020,1,{['type'] = ITEM_SOURCE.FAST_FINISH})
			else
				error_code = pack_con:del_item_by_item_id(139000000021,1,{['type'] = ITEM_SOURCE.FAST_FINISH})
			end
		elseif flag == 1 then
			if bind_count >= non_finish then
				error_code = pack_con:del_item_by_item_id(139000000020, non_finish, {['type'] = ITEM_SOURCE.FAST_FINISH})
			elseif bind_count == 0 then					   			   
				error_code = pack_con:del_item_by_item_id(139000000021, non_finish, {['type'] = ITEM_SOURCE.FAST_FINISH})
			else										   			   
				error_code = pack_con:del_item_by_item_id(139000000020, bind_count, {['type'] = ITEM_SOURCE.FAST_FINISH})
				error_code = pack_con:del_item_by_item_id(139000000021, non_finish - bind_count, {['type'] = ITEM_SOURCE.FAST_FINISH})
			end
		end
		if error_code == 0 then
			function_con:do_work(pkt.act_id)
			local ret = function_con:get_daily_info()
			ret.result = 0
			g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_DAILY_S, ret)
		end
	end
end
--]]

--玩家参与答题
Sv_commands[0][CMD_M2C_ANSWER_SEND_STATE_S] = 
function(conn,pkt)
	if not pkt then return end
	local player = g_obj_mgr:get_obj(pkt)
	local function_con = player:get_function_con()
	function_con:anwser()
end

--领取必做奖励
Clt_commands[1][CMD_B2M_FUNC_REWARD_C] = 
function(conn,pkt)
	if conn.char_id == nil or not pkt.id then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	local function_con = player:get_function_con()
	local result = function_con:do_reward(pkt.id)
	local ret = {}
	if result == 0 then
	   ret = function_con:get_net_info()
	end
	ret.result = result
	g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FUNC_DAILY_S, ret)

end


