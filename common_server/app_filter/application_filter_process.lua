


--打开面板需要信息
Sv_commands[0][CMD_M2P_APPLICATION_OPEN_C] = 
function(conn,char_id,pkt)
	if char_id == nil then return end
	local ret = Application_filter:get_open_info(char_id)
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_APPLICATION_OPEN_S, ret)
end

--报名
Sv_commands[0][CMD_M2P_APPLICATION_FILTER_C] =
function(conn,char_id,pkt)

	if pkt == nil or pkt.vip ==nil or pkt.money == nil or pkt.fight == nil or char_id == nil then return end
	
	local result = Application_filter:is_application_ok(char_id, pkt.money)
	if result ~= 0 then 
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_APPLICATION_FILTER_S, {["result"] = result})
	end

	local result = Application_filter:application_on(char_id,pkt)
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_APPLICATION_FILTER_S, {["result"] = 0})

	-- 同步
	local ret = Application_filter:syn_info()
	g_server_mgr:send_to_all_map(0, CMD_P2M_APPLICATION_SYN_S, Json.Encode(ret),true)

	if result then
	--被踢出邮件通知
	local title = f_get_string(2030)
	local content = f_get_string(2031)
	local e_code ,item_l = Item_factory.create(132000001440)
	if e_code ~= 0 then
		return
	end

	local list = {}
	list[1] = {}
	list[1]["item_id"] = item_l:get_item_id()
	list[1]["item_obj"] = item_l:serialize_to_db()
	list[1]["number"] = 1

	g_email_mgr:create_email(-1,char_id,title,content,0,Email_type.type_gold,Email_sys_type.type_sys,list)
	end
	
end


--查看列表
Sv_commands[0][CMD_M2P_APPLICATION_INFO_C] =
function(conn,char_id,pkt)
	if char_id == nil then return end
	local ret = Application_filter:get_net_info(char_id)
	g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_APPLICATION_INFO_S, ret)
end

--进战场一分钟后排序
Sv_commands[0][CMD_M2P_APPLICATION_SORT_C] =
function(conn,char_id,pkt)
	if pkt == nil or char_id == nil then return end
	Application_filter:clear_war()
	for k,v in pairs(pkt) do
		Application_filter:set_war_flag(v,1)
	end
	Application_filter:sort()

	-- 同步
	local ret = Application_filter:syn_info()
	g_server_mgr:send_to_all_map(0, CMD_P2M_APPLICATION_SYN_S, Json.Encode(ret), true)
end

--玩家离线一分钟
Sv_commands[0][CMD_M2P_APPLICATION_LEAVE_C] =
function(conn,char_id,pkt)
	if pkt == nil or pkt.char_id == nil then return end
	--Application_filter:sort_leave(pkt.char_id)
--
	---- 同步
	--local ret = Application_filter:syn_info()
	--g_server_mgr:send_to_all_map(0, CMD_P2M_APPLICATION_SYN_S, ret)

	--Application_filter:insert_char(pkt.char_id)
end

--战场结束
Sv_commands[0][CMD_M2P_APPLICATION_WAR_OVER_C] =
function(conn,char_id,pkt)
	local old_faction_id = Application_filter:get_faction_id()

	Application_filter:clear(pkt.owner_id)

	-- 同步
	local ret = Application_filter:syn_info()
	g_server_mgr:send_to_all_map(0, CMD_P2M_APPLICATION_SYN_S, Json.Encode(ret), true)

	if old_faction_id == "" or old_faction_id == nil then
		if pkt.owner_id == nil or pkt.owner_id == "" then
			return
		else
			--新帮派通知
			local new_faction = g_faction_mgr:get_faction_by_fid(pkt.owner_id)
			local new_pkt = {}
			new_pkt.faction_id = pkt.owner_id
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1] = new_faction:syn_info(nil,1,13)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
		end
	else
		if pkt.owner_id == nil or pkt.owner_id == "" then
			--旧帮派通知
			local old_faction = g_faction_mgr:get_faction_by_fid(old_faction_id)
			local new_pkt = {}
			new_pkt.faction_id = old_faction_id
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1] = old_faction:syn_info(nil,1,13)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
		elseif pkt.owner_id ~= old_faction_id then
			--旧帮派通知
			local old_faction = g_faction_mgr:get_faction_by_fid(old_faction_id)
			local new_pkt = {}
			new_pkt.faction_id = old_faction_id
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1] = old_faction:syn_info(nil,1,13)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)

			--新帮派通知
			local new_faction = g_faction_mgr:get_faction_by_fid(pkt.owner_id)
			local new_pkt = {}
			new_pkt.faction_id = pkt.owner_id
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1] = new_faction:syn_info(nil,1,13)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
		end
	end
end

--广播
Sv_commands[0][CMD_M2P_APPLICATION_WAR_C] = 
function(conn, char_id, pkt)
	g_server_mgr:send_to_all_map(0, CMD_P2M_APPLICATION_WAR_S, Json.Encode(pkt),true)

	local sort_list = Application_filter:get_sort_list()
	local char_size = table.size(sort_list)

	local time_t = ev.time

	local db = f_get_db()
	local t = {}
	t.member_count = char_size
	t.date = tonumber(os.date("%y%m%d",time_t,time_t,time_t))
	t.scene_id = 2401001

	local e_code = db:insert("result_record", Json.Encode(t))
	if 0 ~= e_code then
		print("Error CMD_M2P_FACTION_WAR_BEGIN_C: ", e_code)
	end
end

