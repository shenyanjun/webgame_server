--local debug_print=print
local debug_print=function() end
local HOUR = 60*60

--创建帮派   (ok)
Sv_commands[0][CMD_M2P_FACTION_CREATE_REQ] =
function(conn,char_id,pkt)
	debug_print("-------create faction---------:",pkt,char_id)
	if pkt==nil or pkt.faction_name==nil or pkt.faction_badge==nil then return end

	if f_filter_world(pkt.faction_name) then
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_CREATE_REP, {["result"]=30013})
		return
	end
	if char_id ~= nil then		
		local result = g_faction_mgr:get_result(char_id,pkt.faction_name) 
		if result ~= 0 then
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_CREATE_REP, {["result"]=result})
			return
		end
		g_faction_mgr:begin_create(conn,pkt,char_id)
	end
end

--玩家上线请求

Sv_commands[0][CMD_M2P_GET_FACTION_REQ] =
function(conn,char_id,pkt)
	debug_print("-------玩家上线请求---------:",pkt,char_id)
	g_faction_mgr:online(conn,char_id,pkt.flag)
end


--下线
--[[Sv_commands[0][CMD_M2P_PLAYER_OUTLINE_REQ] =
function(conn,char_id,pkt)
	g_faction_mgr:outline(conn,char_id)
end]]

---申请加入帮派 result 0：    (ok)
Sv_commands[0][CMD_M2P_FACTION_JOIN_REQ] =
function(conn,char_id,pkt)
	debug_print("--------join faction req--------:",pkt,char_id)
	if char_id ~= nil then
		
		local result = g_faction_mgr:get_join_result(char_id, pkt.faction_id)
		if result ~= 0 then 
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_JOIN_REP, {["result"]=result})
			return
		end

		local faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
		if faction ~= nil then
			local is_join = faction:is_join_char(char_id)
			if is_join then 
				return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_JOIN_REP, {["result"]=26014})
			end

			local is_full = faction:is_member_full()
			if is_full then 
				return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_JOIN_REP, {["result"]=26008}) 
			end

			faction:add_join_link(char_id)
			g_faction_mgr:set_kick_time(char_id,0)

			--添加成功
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_JOIN_REP, {["result"]=0})
			--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_JOIN_LIST_S,faction:get_join_list_to_net())

			--同步信息
			local new_pkt ={}
			new_pkt.faction_id = faction:get_faction_id()
			new_pkt.cmd = 25643
			new_pkt.list={}
			new_pkt.list[1]= faction:syn_info(char_id,2,2)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

			--删除最久一个申请的
			local t_char_id,count = faction:get_join_count_char()
			if faction:is_join_full(count) then
				faction:del_join_link(t_char_id)

				--同步信息
				local new_pkt ={}
				new_pkt.faction_id = faction:get_faction_id()
				new_pkt.cmd = 25644
				new_pkt.list={}
				new_pkt.list[1]= faction:syn_info(t_char_id,3,2)
				g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
			end
		end
	end
end

---申请退出帮派 ok
Sv_commands[0][CMD_M2P_FACTION_OUT_REQ] =
function(conn,char_id,pkt)
	debug_print("-------out faction req---------:",pkt)
	if char_id ~=nil then

		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction == nil then 
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_OUT_REP, {["result"]=26009})
		end
		local index = faction:get_post(char_id)
		if index ~= 5 then
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_OUT_REP, {["result"]=26015})
		end
		
		local char_nm = faction.faction_player_list[char_id]["name"]
		local result = faction:out_faction(char_id)
		if result == nil then return end
		if result ~= 0 then 
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_OUT_REP, {["result"]=result})
		end
		local n_time = ev.time
		g_faction_mgr:set_leave_time(char_id,n_time)
		
		--同步信息
		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25644
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(char_id,3,1)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

		--历史信息
		local ret = {}
		ret[1] = 3
		ret[2] = ev.time
		ret[3] = char_id
		ret[4] = char_nm
		faction:set_history_info(ret)

		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_OUT_REP, {["result"]=0})
		--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_PLAYER_LIST_S,faction:get_player_list_to_net())
		local ret = {}
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_PLAYER_HEAD_INFO_S,ret)

		local faction_id = faction:get_faction_id()
		g_faction_dogz_mgr:del_char_id(faction_id, char_id) -- 帮派神兽

		--帮派庭院 屏蔽 121114 chendong
		-- 退帮清除拜祭标记
		--g_faction_courtyard_mgr:clear_baiji_flag(faction_id, char_id) -- 帮派烧香

		--同步退出时间
		local t_ret = {}
		t_ret[char_id]=n_time
		local pkt = g_faction_mgr:get_leave_time_ex(1,t_ret)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_LEAVE_TIME_S,Json.Encode(pkt), true)

		f_faction_log("faction CMD_M2P_FACTION_OUT_REQ" .. " -char_id: " .. char_id .."--" .. ev.time)
	end
end

---邀请人加入  (ok)
Sv_commands[0][CMD_M2P_FACTION_ADD_PLAYER_REQ] =
function(conn,char_id,pkt)
	debug_print("-------add player---------:",pkt)
	if char_id~=nil then
		local char_id_f=char_id

		local faction = g_faction_mgr:get_faction_by_cid(char_id_f)
		if faction ~= nil then
			local per_result = faction:is_permission_ok(1,char_id_f)
			if per_result ~=0 then 
				return g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_ADD_PLAYER_REP, {["result"]=per_result})
			end
			local char_name = pkt.char_name
			local rs = g_player_mgr:char_nm2id(char_name)    -----从name找出id
			local char_id = rs

			local result = g_faction_mgr:get_join_result(char_id)
			if result ~= 0 then 
				return g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_ADD_PLAYER_REP, {["result"]=result}) 
			end

			local flg=faction:is_member_full()
			if not flg then
				local new_pkt={}
				new_pkt.faction_id = faction:get_faction_id()
				new_pkt.faction_name = faction:get_faction_name()
				new_pkt.char_id = char_id
				new_pkt.result = 0
				g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_ADD_PLAYER_REP, new_pkt)

				local server_id = g_player_mgr:get_map_id(char_id)
				new_pkt.p_char_id = char_id_f
				g_server_mgr:send_to_server(server_id,char_id, CMD_P2M_PLAYER_ADD_AUTO_S, new_pkt)

			else
				return g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_ADD_PLAYER_REP, {["result"]=26008}) 
			end
		else
			return g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_ADD_PLAYER_REP, {["result"]=26009}) 
		end
	else
		return g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_ADD_PLAYER_REP, {["result"]=26001})
	end
end


---踢人（ok）
Sv_commands[0][CMD_M2P_FACTION_KICK_PLAYER_REQ] =
function(conn,char_id,pkt)
	debug_print("-------kick player---------:",pkt)
	local char_id_f=char_id
	local char_id_s=pkt.char_id_s

	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local per_result = faction:is_permission_ok(1,char_id_f,1)
		if per_result ~=0 then 
			return g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_KICK_PLAYER_REP, {["result"]=per_result})
		end

		local item_list = {}
		local contribution = faction:get_contribution(char_id_s) or 0 --帮贡返还文书，取得被踢之人的帮贡
		contribution = math.floor(contribution * 0.8)
		if contribution == 0 then
			item_list = nil
		else
			local e_code, contribution_item = Item_factory.create(184000000020) --帮贡返还文书
			contribution_item:set_contribution(contribution)
			if e_code ~= 0 then
				return
			end
			item_list[1] = {}
			item_list[1]["item_id"] = 184000000020
			item_list[1]["item_obj"] = contribution_item:serialize_to_db()
			item_list[1]["number"] = 1
		end

		local char_nm_s = faction.faction_player_list[char_id_f]["name"]
		local char_nm_d = g_player_mgr.all_player_l[char_id_s]["char_nm"]
		local result, kick_time = faction:kick_member(char_id_f,char_id_s)
		if result ~= 0 then 
			local ret = {}
			ret.result = result
			ret.time = kick_time
			g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_KICK_PLAYER_REP, ret)
			return
		end

		local faction_id = faction:get_faction_id()
		g_faction_dogz_mgr:del_char_id(faction_id, char_id_s) -- 帮派神兽

		--帮派庭院 屏蔽 121114 chendong
		-- 退帮清除拜祭标记
		--g_faction_courtyard_mgr:clear_baiji_flag(faction_id, char_id_s) -- 帮派烧香

		g_faction_mgr:set_kick_time(char_id_s,ev.time)		
		g_server_mgr:send_to_server(conn.id,char_id_f, CMD_P2M_FACTION_KICK_PLAYER_REP, {["result"]=0})	
		
		--同步信息
		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25644
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(char_id_s,3,1)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)

		--历史信息
		local ret = {}
		ret[1] = 12
		ret[2] = ev.time
		ret[3] = char_id_f
		ret[4] = char_nm_s
		ret[5] = char_id_s
		ret[6] = char_nm_d
		faction:set_history_info(ret)

		--显示头上信息
		if g_player_mgr:is_online_char(char_id_s) then
			local server_id = g_player_mgr:get_map_id(char_id_s)
			local ret = {}
			g_server_mgr:send_to_server(server_id,char_id_s,CMD_P2M_PLAYER_HEAD_INFO_S,ret)
		end


		--同步退出时间
		local t_ret = {}
		t_ret[char_id_s] = ev.time
		local pkt = g_faction_mgr:get_leave_time_ex(1,nil,t_ret)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_LEAVE_TIME_S,Json.Encode(pkt), true)

		

		--被踢出邮件通知
		local title = f_get_string(2000)
		local content = f_get_string(2001) .. faction:get_faction_name() .. f_get_string(2002)
		g_email_mgr:create_email(-1,char_id_s,title,content,0,Email_type.type_common,Email_sys_type.type_normal, item_list)
		--g_email_mgr:create_email(-1,char_id_s,title,content,0,Email_type.type_common,Email_sys_type.type_normal,nil)
		--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_INFO_S,faction:get_all_info())
		--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_PLAYER_LIST_S,faction:get_player_list_to_net())
		f_faction_log("faction CMD_M2P_FACTION_KICK_PLAYER_REQ" .. " -char_id_s: " .. char_id .. "char_id_d:" .. char_id_s .. "--" .. ev.time)
	end
end

--帮派信息2   (ok)
Sv_commands[0][CMD_M2P_FACTION_INFO2_REQ] =
function(conn,char_id,pkt)
	debug_print("--------faction info2--------:",pkt.faction_id)
	if char_id ~=nil then
		local faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
		if faction ~=nil then 
			local new_pkt = faction:get_faction_info()
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_INFO2_REP, new_pkt)
		end
	end
end

--帮派列表   (ok)
Sv_commands[0][CMD_M2P_FACTION_LIST_REQ] =
function(conn,char_id,pkt)
	debug_print("--------faction list--------:",pkt)
	if char_id ~= nil then

		local new_pkt = g_faction_mgr:get_faction_list(char_id)
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_LIST_REP, new_pkt)
	end
end

--职务卸任 ok
Sv_commands[0][CMD_M2P_FACTION_POST_OUTGOING_REQ] =
function(conn,char_id,pkt)
	debug_print("------out going----------:",pkt)
	if char_id == pkt.other_id or pkt == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then	
		local result,obj_id = faction:outgoing(char_id,pkt.other_id)
		if result ~= 0 then 
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_POST_OUTGOING_REP, {["result"]=result})
		end
		if obj_id ~= nil then
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_POST_OUTGOING_REP, {["result"]=0})

			--显示头上信息
			local ret = faction:get_head_info(char_id)
			g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_PLAYER_HEAD_INFO_S,ret)

			--显示头上信息
			if g_player_mgr:is_online_char(obj_id) then
				local server_id = g_player_mgr:get_map_id(obj_id)
				local ret = faction:get_head_info(obj_id)
				g_server_mgr:send_to_server(server_id,obj_id,CMD_P2M_PLAYER_HEAD_INFO_S,ret)
			end

			--同步信息
			local t_ret = {}
			t_ret[1] = 8
			t_ret[2] = ev.time
			t_ret[3] = obj_id
			t_ret[4] = faction.faction_player_list[obj_id]["name"]
			t_ret[5] = char_id
			t_ret[6] = faction.faction_player_list[char_id]["name"]
			faction:set_history_info(t_ret,1)


			local new_pkt ={}
			new_pkt.faction_id = faction:get_faction_id()
			new_pkt.cmd = 25642
			new_pkt.list={}
			new_pkt.list[1] = faction:syn_info(obj_id,1,2)
			new_pkt.list[2] = faction:syn_info(char_id,1,2)
			new_pkt.list[3] = faction:syn_info(nil,1,10)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

		else
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_POST_OUTGOING_REP, {["result"]=0})
			--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_INFO_S,faction:get_all_info())

			--显示头上信息
			local ret = faction:get_head_info(char_id)
			g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_PLAYER_HEAD_INFO_S,ret)

			--同步信息
			local new_pkt ={}
			new_pkt.faction_id = faction:get_faction_id()
			new_pkt.cmd = 25642
			new_pkt.list={}
			new_pkt.list[1]= faction:syn_info(char_id,1,2)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
		end
		f_faction_log("faction CMD_M2P_FACTION_POST_OUTGOING_REQ" .. " -char_id: " .. char_id .. "---" .. ev.time)
	else
		return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_POST_OUTGOING_REP, {["result"]=26009})  ---该角色没有帮派
	end
end

--获取招募信息  (ok)
Sv_commands[0][CMD_M2P_FACTION_RECRUIT_REQ] =
function(conn,char_id,pkt)
	debug_print("--------faction recruit--------:",pkt)

	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local new_pkt = faction:get_recruit_info()	
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_RECRUIT_REP, new_pkt)
	else
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_RECRUIT_REP, {["result"]=26017})
	end
end

--批准加入帮派   ok
Sv_commands[0][CMD_M2P_FACTION_APPROVE_REQ] =
function(conn,char_id,pkt)
	debug_print("-------faction approve---------:",pkt)
	if char_id ~=nil then
		local char_list = pkt.char_list
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction == nil then return end
		local per_result = faction:is_permission_ok(1,char_id)
		if per_result ~=0 then 
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_APPROVE_REP, {["result"]=per_result})
		end

		local pkt_success={}
		pkt_success.char_list={}
		local pkt_unsuccess={}
		pkt_unsuccess.char_list={}

		local new_pkt_add={}
		new_pkt_add.list={}

		local new_pkt_refuse={}
		new_pkt_refuse.list={}

		local char_nm ={}

		if table.size(char_list) == 0 then
			for m,n in pairs(faction.join_l or {}) do
				table.insert(char_list,m)
			end
		end


		for k,v in pairs(char_list or {}) do	
			if g_faction_mgr:check_is_in_faction(v) then
				faction:del_join_link(v)
				table.insert(pkt_unsuccess.char_list,v)	
			else
				local result = faction:approve_join(char_id,v)
				if result == 0 then
					table.insert(pkt_success.char_list,v)

					local pkt_add = faction:syn_info(v,2,1)
					table.insert(new_pkt_add.list,pkt_add)

					--加入帮派的玩家的名称
					table.insert(char_nm,g_player_mgr.all_player_l[v]["char_nm"])
				else
					faction:del_join_link(v)
					table.insert(pkt_unsuccess.char_list,v)	
				end
			end
			local pkt_del_refuse =faction:syn_info(v,3,2)
			table.insert(new_pkt_refuse.list,pkt_del_refuse)
		end
		--招募信息列表中的同步更新信息
		local pkt={}
		pkt.pkt_success=pkt_success
		pkt.pkt_unsuccess=pkt_unsuccess
		pkt.result = 0
		--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_INFO_S,faction:get_all_info())
		g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_APPROVE_REP, pkt)

		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25643
		new_pkt.list=new_pkt_add.list
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25644
		new_pkt.list= new_pkt_refuse.list
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)

		for k,v in pairs(pkt.pkt_success.char_list or {})do
			if g_player_mgr:is_online_char(v) then
				local server_id = g_player_mgr:get_map_id(v)
				g_server_mgr:send_to_server(server_id,v,CMD_P2M_PLAYER_RESET_ONLINE_S,{})

				--显示头上信息
				local ret = faction:get_head_info(v)
				g_server_mgr:send_to_server(server_id,v,CMD_P2M_PLAYER_HEAD_INFO_S,ret)

				g_faction_dogz_mgr:on_line(nil, v) -- 获取帮派神兽信息
			end
		end

		--历史信息
		if table.size(char_nm) > 0 then
			--帮派庭院 屏蔽 121114 chendong
			--g_faction_courtyard_mgr:update_faction_money_tree(faction:get_faction_id())
			--g_faction_courtyard_mgr:update_censer_info(faction:get_faction_id())
			
			local ret = {}
			ret[1] = 2
			ret[2] = ev.time
			ret[3] = pkt_success.char_list
			ret[4] = char_nm
			ret[5] = char_id
			ret[6] = g_player_mgr.all_player_l[char_id]["char_nm"]
			faction:set_history_info(ret)
		end
	end
end

--拒绝加入帮派  ok
Sv_commands[0][CMD_M2P_FACTION_REFUSE_REQ] =
function(conn,char_id,pkt)
	debug_print("-------faction refuse---------:",pkt)
	if char_id ~=nil then

		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			local per_result = faction:is_permission_ok(1,char_id)
			if per_result ~=0 then 
				return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_REFUSE_REP, {["result"]=per_result})
			end
			--local index = faction:get_post(char_id)
			--if index == 5 then 
				--return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_REFUSE_REP, {["result"]=26010}) 
			--end

			local char_list = pkt.char_list

			local ret ={}
			ret.list={}
			local c = 1
			local new_pkt ={}
			new_pkt.char_id_list = {}
			for k,v in pairs (char_list or {}) do
				ret.list[c]= faction:syn_info(v,3,2)
				faction:del_join_link(v)

				table.insert(new_pkt.char_id_list,v)
				new_pkt.result=0 
				c = c + 1
			end
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_REFUSE_REP, new_pkt)
			if c ~= 1 then
				local new_pkt = {}
				new_pkt.faction_id = faction:get_faction_id()
				new_pkt.cmd =25644
				new_pkt.list= ret.list
				g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
			end
			--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_INFO_S,faction:get_all_info())
		end
	end
end


--获取帮派成员列表   (ok)
Sv_commands[0][CMD_M2P_FACTION_MEMBER_REQ] =
function(conn,char_id,pkt)
	debug_print("--------faction member--------:",pkt)
	if char_id ~=nil then

		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			local new_pkt = faction:get_player_info()
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_MEMBER_REP, new_pkt)
		else
			g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_MEMBER_REP, {["result"]=26017})
		end
	end
end

--保存管理公告   (ok) 有乱码
Sv_commands[0][CMD_M2P_FACTION_ANNOUNCEMENT_REQ] =
function(conn,char_id,pkt)
	debug_print("-------announcement---------:",pkt)
	if char_id ~=nil then

		local faction =  g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			local per_result = faction:is_permission_ok(2,char_id)
			if per_result ~=0 then 
				return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_ANNOUNCEMENT_REP, {["result"]=per_result})
			end
			--local index = faction:get_post(char_id)
			--if index < 3 then
				faction:set_announcement(pkt.announcement)
				g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_ANNOUNCEMENT_REP, {["result"]=0})
				--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_INFO_S,faction:get_all_info())

				local new_pkt = {}
				new_pkt.faction_id = faction:get_faction_id()
				new_pkt.cmd =25642
				new_pkt.list ={}
				new_pkt.list[1]= faction:syn_info(char_id,1,1)
				g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

				
				--测试接口
				--faction:add_exp(char_id)
			--else
				--g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_ANNOUNCEMENT_REP, {["result"]=26010})
			--end
		end
	end
end


--任命   (ok)
Sv_commands[0][CMD_M2P_FACTION_APPOINTMENT_REQ] =
function(conn,char_id,pkt)
	debug_print("-------faction appointment---------:",pkt)
	local char_id_s = char_id
	local char_id_d = pkt.char_id_s
	local post_index = pkt.post_index

	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local per_result = faction:is_permission_ok(1,char_id_s)
		if per_result ~=0 then 
			return g_server_mgr:send_to_server(conn.id,char_id_s, CMD_P2M_FACTION_APPOINTMENT_REP, {["result"]=per_result})
		end

		local result = faction:appointment(char_id_s,char_id_d,post_index)
		if result ~= 0 then return g_server_mgr:send_to_server(conn.id,char_id_s, CMD_P2M_FACTION_APPOINTMENT_REP, {["result"]=result}) end

		g_server_mgr:send_to_server(conn.id,char_id_s, CMD_P2M_FACTION_APPOINTMENT_REP, {["result"]=0})
		--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_INFO_S,faction:get_all_info())

		--历史信息
		local ret = {}
		ret[1] = 9
		ret[2] = ev.time
		ret[3] = char_id_d
		ret[4] = faction.faction_player_list[char_id_d]["name"]
		ret[5] = char_id_s
		ret[6] = faction.faction_player_list[char_id_s]["name"]
		ret[7] = post_index
		faction:set_history_info(ret,1)

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1]= faction:syn_info(char_id_d,1,2)
		new_pkt.list[2]= faction:syn_info(nil,1,10)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

		--显示头上信息
		if g_player_mgr:is_online_char(char_id_d) then
			local server_id = g_player_mgr:get_map_id(char_id_d)
			local ret = faction:get_head_info(char_id_d)
			g_server_mgr:send_to_server(server_id,char_id_d,CMD_P2M_PLAYER_HEAD_INFO_S,ret)
		end

		f_faction_log("faction CMD_M2P_FACTION_APPOINTMENT_REQ" .. " -char_id_s: " .. char_id .. "char_id_d:" .. char_id_d .. "post_index" .. post_index .. "---" .. ev.time)
	end
end


--玩家确定加入   ok
Sv_commands[0][CMD_M2P_FACTION_JOIN_CONF_REQ] =
function(conn,char_id,pkt)
	debug_print("------faction join confirm----------:",pkt)
	if char_id ~=nil then

		if g_faction_mgr:check_is_in_faction(char_id) then return end
		local faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
		if faction ~= nil then
			local result = faction:add_member_ex_f(char_id)
			if result ~= nil then 
				g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_JOIN_CONF_REP, {["result"]=0})

				local new_pkt = {}
				new_pkt.faction_id = faction:get_faction_id()
				new_pkt.cmd =25643
				new_pkt.list ={}
				new_pkt.list[1]= faction:syn_info(char_id,2,1)
				g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)

				local ret = {}
				ret[1] = 2
				ret[2] = ev.time
				ret[3] = {char_id}
				ret[4] = {g_player_mgr.all_player_l[char_id]["char_nm"]}
				ret[5] = pkt.p_char_id
				ret[6] = g_player_mgr.all_player_l[pkt.p_char_id]["char_nm"]
				faction:set_history_info(ret)

				--通知别的玩家
				--local player_list = faction:get_player_list()
				--local char_nm ={}
				--char_nm[1] = player_list["name"]
--
				--char_nm = Json.Encode(char_nm or {})
				--for k,v in pairs(player_list or {})do
					--if v["status"] == "0" then
						--local server_id = g_player_mgr:get_map_id(k)
						--if server_id == nil then return end
						--g_server_mgr:send_to_server(server_id,k,CMD_P2M_FACTION_JOIN_CONF_REP,char_nm,true)
					--end
				--end

				--显示头上信息
				if g_player_mgr:is_online_char(char_id) then
					local ret = faction:get_head_info(char_id)
					g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_PLAYER_HEAD_INFO_S,ret)
					--帮派庭院 屏蔽 121114 chendong
					--[[
					--g_faction_courtyard_mgr:on_line(conn, char_id, 1) -- 获取铜券树信息
					--g_faction_courtyard_mgr:on_line(conn, char_id, 2) -- 获取香炉信息
					--]]
					g_faction_dogz_mgr:on_line(nil, char_id) -- 获取帮派神兽信息
				end
				f_faction_log("faction CMD_M2P_FACTION_JOIN_CONF_REQ" .. " -char_id_s: " .. char_id .. "pkt.faction_id:" .. pkt.faction_id .. "---" .. ev.time)
			end
		end
	end
end

--招募广告
Sv_commands[0][CMD_M2P_FACTION_BROADCAST_REQ] =
function(conn,char_id,pkt)
	debug_print("------faction broadcast---------:",pkt)
	if char_id ~=nil then
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			local faction_name = faction:get_faction_name()
			faction:create_bdc(char_id,pkt.broadcast_content,faction_name)
		end
	end
end

--获取任免职务信息
Sv_commands[0][CMD_M2P_FACTION_POST_INFO_REQ] =
function(conn,char_id,pkt)
	debug_print("------faction post info---------:",pkt)
	if char_id ~=nil then

		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			local new_pkt ={}
			new_pkt.post_info ={}
			for i =2 ,5 do
				new_pkt.post_info[i-1]={}
				new_pkt.post_info[i-1].post_name= faction:get_post_name(i)
				new_pkt.post_info[i-1].level=i
				new_pkt.post_info[i-1].count = faction.post_num[i]
			end
			g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_POST_INFO_REP,new_pkt)
		end
	end
end

--获取职务名
Sv_commands[0][CMD_M2P_FACTION_POST_NAME_REQ] =
function(conn,char_id,pkt)
	if char_id ~=nil then
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction ~= nil then
			local new_pkt = {}
			new_pkt.bangzhu = faction:get_post_name(1)
			new_pkt.fubangzhu = faction:get_post_name(2)
			new_pkt.zhanglao = faction:get_post_name(3)
			new_pkt.hufa = faction:get_post_name(4)
			new_pkt.bangzhong = faction:get_post_name(5)
			g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_POST_NAME_REP,new_pkt)
		end 
	end
end

--获取帮派成员列表
Sv_commands[0][CMD_M2P_FACTION_MEMBER_REQ] =
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local new_pkt = faction:get_player_info()
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_MEMBER_REP,new_pkt)
	end
end

--改变帮派关系
Sv_commands[0][CMD_M2P_FACTION_RELATE_UPDATE_REQ] =
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local per_result = faction:is_permission_ok(4,char_id)
		if per_result ~=0 then 
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_RELATE_UPDATE_REP, {["result"]=per_result})
		end
		if pkt.flag ~= 3 then
			local result = g_faction_mgr:add_relation(faction:get_faction_id(),pkt.faction_id,pkt.flag)
			if result ~= 0 then
				return g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_RELATE_UPDATE_REP,{["result"] = result})
			end
		else
			g_faction_mgr:del_relation(faction:get_faction_id(),pkt.faction_id)
		end
		--历史信息
		local ret = {}
		ret[1] = 10
		ret[2] = ev.time
		ret[3] = char_id
		ret[4] = faction.faction_player_list[char_id]["name"]
		ret[5] = g_faction_mgr:get_faction_by_fid(pkt.faction_id):get_faction_name()
		ret[6] = pkt.flag
		faction:set_history_info(ret,1)

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1]= faction:syn_info(char_id,1,3,pkt.faction_id)
		new_pkt.list[2]= faction:syn_info(nil,1,10)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_RELATE_UPDATE_REP,{["result"] = 0})
	end
end

--帮派升级（演武厅，观星阁，金库，建设点，科技点，帮贡,帮派等级，帮派资金）统一接口
Sv_commands[0][CMD_M2P_FACTION_UPDATE_INFO_REQ] =
function(conn,char_id,pkt)
	debug_print("-------帮派升级---------:",pkt,char_id)
	--[[帮派仓库测试
	pkt.flag = 10 --]]
	if char_id == nil then return end

	--if pkt.flag == 10 then return end -- 屏蔽帮派仓库升级

	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local flag = pkt.flag
		local param = pkt.param

		if flag == 1 or flag == 2 or flag == 3 or flag == 7 or flag == 10 then -- 添加帮派仓库flag=10
			local per_result = faction:is_permission_ok(2,char_id)
			if per_result ~=0 then 
				return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_UPDATE_INFO_REP, {["result"]=per_result})
			end
		end

		local unrecord = pkt.unrecord -- 不加入历史帮贡标记
		local result = faction:update_faction_level(char_id,flag,param, unrecord)
		if result == 0 then
			local new_pkt = {}
			new_pkt.faction_id = faction:get_faction_id()
			new_pkt.cmd =25642
			new_pkt.list ={}
			

			if flag == 1 or flag ==2 or flag == 3 or flag == 7 or flag == 10 then -- 添加帮派仓库flag=10
				new_pkt.list[1]= faction:syn_info(char_id,1,6)
				new_pkt.list[2]= faction:syn_info(nil,1,10)
			elseif flag == 4 or flag == 5 or flag == 8 then
				new_pkt.list[1]= faction:syn_info(char_id,1,7)
			elseif flag == 6 then
				new_pkt.list[1]= faction:syn_info(char_id,1,2)
			end

			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
			g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_UPDATE_INFO_REP,{["result"] = 0,["flag"] =flag })


			--流水
			faction:log_faction(pkt,char_id)
		end
	end
end

--技能升级
Sv_commands[0][CMD_M2P_FACTION_SKILL_UPDATE_REQ] =
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local per_result = faction:is_permission_ok(5,char_id)
		if per_result ~=0 then 
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_SKILL_UPDATE_REP, {["result"]=per_result})
		end
		local result = faction:update_action_practice(char_id,pkt.flag)
		if result == 0 then
			local new_pkt = {}
			new_pkt.faction_id = faction:get_faction_id()
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1]= faction:syn_info(char_id,1,5)
			new_pkt.list[2]= faction:syn_info(nil,1,10)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
		end
		local ret = {}
		ret.flag = pkt.flag
		ret.result = result
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_SKILL_UPDATE_REP,ret)

		--流水
		if result == 0 then
			faction:log_skill(pkt,char_id)
		end
	end
end

--buf升级
Sv_commands[0][CMD_M2P_FACTION_BUF_UPDATE_REQ] =
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local per_result = faction:is_permission_ok(5,char_id)
		if per_result ~=0 then 
			return g_server_mgr:send_to_server(conn.id,char_id, CMD_P2M_FACTION_BUF_UPDATE_REP, {["result"]=per_result})
		end
		local result = faction:update_book_practice(char_id,pkt.flag)
		if result == 0 then
			local new_pkt = {}
			new_pkt.faction_id = faction:get_faction_id()
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1]= faction:syn_info(char_id,1,4)
			new_pkt.list[2]= faction:syn_info(nil,1,10)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
		end
		local ret = {}
		ret.flag = pkt.flag
		ret.result = result
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_BUF_UPDATE_REP,ret)

		--流水
		if result == 0 then
			faction:log_buf(pkt,char_id)
		end
	end
end


--设置权限
Sv_commands[0][CMD_M2P_FACTION_PERMISSION_REQ] =
function(conn,char_id,pkt)
	if char_id == nil then return end

	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		if faction:get_factioner_id() ~= char_id then
			return g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_PERMISSION_REP,{["result"] = 26036})
		end
		faction:set_permission(pkt)
		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1]= faction:syn_info(char_id,1,8)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_PERMISSION_REP,{["result"] = 0})

		f_faction_log("faction CMD_M2P_FACTION_PERMISSION_REQ" .. " -char_id_s: " .. char_id  .. "---" .. ev.time)
	end
end

--领取工资
Sv_commands[0][CMD_M2P_FACTION_OBTAINSALARY_REQ] = 
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		if faction:is_fetch_salary_ok(char_id) == 0 then 
			return g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_OBTAINSALARY_REP,{["result"] = 26043})
		end
		local contribution = faction:get_contribution(char_id)
		if contribution < 2 then return end

		local money = faction:get_money()
		if money > pkt.salary then
			contribution = contribution -2 
			faction:set_contribution(char_id, contribution)
			faction:set_money(money - pkt.salary)
			faction:set_salary_flag(char_id,ev.time)
			--历史消息
			local t_ret = {}
			t_ret[1] = 7
			t_ret[2] = ev.time
			t_ret[3] = char_id
			t_ret[4] = faction.faction_player_list[char_id]["name"]
			t_ret[5] = pkt.salary
			faction:set_history_info(t_ret,1)


			local new_pkt = {}
			new_pkt.faction_id = faction:get_faction_id()
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1]= faction:syn_info(char_id,1,2)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
			local ret = {}
			ret.result = 0
			ret.salary = pkt.salary
			ret.obj_id = char_id
			g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_OBTAINSALARY_REP,ret)
		else
			g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_OBTAINSALARY_REP,{["result"] = 26025})
		end
	end
end

--摇钱树 屏蔽摇钱树消息处理 chendong 121114
--[[
--摇钱树灌溉或摇一下
Sv_commands[0][CMD_M2P_FACTION_MONEY_TREE_REQ] = 
function(conn,char_id,pkt)
	--print("in CMD_M2P_FACTION_MONEY_TREE_REQ")
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local money_tree_flag = faction:get_money_tree_flag(char_id)
		if money_tree_flag == 1 then			--代表已领取   灌溉
			local is_irrigation_ok = faction:is_irrigation_time_ok(char_id)
			if is_irrigation_ok then
				local irrigation = faction:get_irrigation()
				irrigation = irrigation + 1
				faction:set_irrigation(irrigation)  --设置灌溉值
				faction:set_irrigation_time(char_id,ev.time)  --设置灌溉时间

				local ret = {}
				ret.result = 0
				ret.flag = money_tree_flag
				ret.irrigation_time_span = HOUR
				ret.count = faction:get_money_tree_count(char_id)
				g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_MONEY_TREE_REP,ret)

				--同步通知各个在线的帮派成员
				local new_pkt = {}
				new_pkt.faction_id = faction:get_faction_id()
				new_pkt.cmd =25642
				new_pkt.list ={}
				new_pkt.list[1]= faction:syn_info(char_id,1,9)
				g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)

				if faction:is_irrigation_full() then
					faction:set_all_money_tree_flag(0)
					faction:set_irrigation(0)
				end
			else
				local ret = {}
				ret.result = 26045
				g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_MONEY_TREE_REP,ret)
			end
		elseif money_tree_flag == 0 then		--摇一下
			local count = faction:get_money_tree_count(char_id)
			faction:set_money_tree_flag(char_id,1)
			if count >= 3 then
				local ret = {}
				ret.result = 26054
				g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_MONEY_TREE_REP,ret)
				return 
			end
			faction:set_money_tree_count(char_id)
			local ret = {}
			ret.result = 0
			ret.flag = money_tree_flag
			ret.count = faction:get_money_tree_count(char_id)
			g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_MONEY_TREE_REP,ret)
		end
	end
end
--]]
--历史信息
Sv_commands[0][CMD_M2P_FACTION_HISTORY_INFO_REQ] = 
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then 
		local ret = faction:get_history_info()
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_HISTORY_INFO_REP,ret)
	end
end

--使用道具加速升级
Sv_commands[0][CMD_M2P_FACTION_SPEED_TIME_REQ] = 
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then 
		local result,t_flag = faction:update_speed_time(pkt.build_id,pkt.all_time)
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_SPEED_TIME_REP,{["result"] = result})

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1]= faction:syn_info(char_id,1,6)
		if t_flag == 1 then
			new_pkt.list[2]= faction:syn_info(nil,1,10)
		end
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
	end
end

--帮派主动解散
Sv_commands[0][CMD_M2P_FACTION_DISSOLVE_REQ] = 
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then 
		local ret = {}
		ret.result = 0
		local factioner_id = faction:get_factioner_id()
		if factioner_id ~= char_id then 
			ret.result = 26050
			return g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_DISSOLVE_REP,ret)
		end
		local member_count = faction:get_member_count()
		if member_count > 1 then 
			ret.result = 26051
			return g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_DISSOLVE_REP,ret)
		end

		-- 帮派解散，添加帮派仓库限制，cailizhong添加，如果帮派仓库有物品，不能解散帮派
		local faction_id = faction:get_faction_id()
		local bag = g_faction_bag_mgr:get_bag_by_fid(faction_id) -- 获取帮派仓库
		if bag ~= nil then -- 拥有帮派仓库
			if bag:is_empty() ~= true then -- 帮派仓库不为空，不能解散帮派
				ret.result = 31171
				return g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_DISSOLVE_REP,ret)
			end
		end
		
		-- 帮派解散，删除帮派神兽
		g_faction_dogz_mgr:del(faction_id)

		--帮派庭院 屏蔽 121114 chendong
		-- 删除帮派庭院
		--g_faction_courtyard_mgr:del_courtyard(faction_id)

		g_faction_mgr:del_faction(faction:get_faction_id())
		g_faction_mgr:del_member(char_id)

		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_DISSOLVE_REP,ret)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_DISSOLVE_S,Json.Encode({["faction_id"]=faction:get_faction_id()}),true)

		--设置解散时间
		g_faction_mgr:set_dissolve_time(char_id,ev.time)
		--同步退出时间
		local t_ret = {}
		t_ret[char_id]=ev.time
		local pkt = g_faction_mgr:get_leave_time_ex(1,t_ret)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_LEAVE_TIME_S,Json.Encode(pkt),true)

		--流水
		f_faction_log("faction CMD_M2P_FACTION_DISSOLVE_REQ " .. "-" .. char_id .. "-" .. ev.time)

	end
end

--设置副本次数
Sv_commands[0][CMD_M2P_FACTION_FB_SET_REQ] = 
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		faction:set_fb_info(pkt.scene_id)
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_GET_REP,{})

		--local new_pkt = {}
		--new_pkt.faction_id = faction:get_faction_id()
		--new_pkt.cmd =25642
		--new_pkt.list ={}
		--new_pkt.list[1] = faction:syn_info(char_id,1,10)
		--g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,new_pkt)

		local ret = {}
		ret.faction_id = faction:get_faction_id()
		ret.fb_info = faction:get_fb_info()
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_FB_S,Json.Encode(ret), true)
	end
end

----统一添加帮贡，建设度，科技点，帮派资金
Sv_commands[0][CMD_M2P_FACTION_ADD_CONTENT_REQ] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	local faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then
		
		local t_point = pkt.technology_point or 0
		local c_point = pkt.construct_point or 0
		local money = pkt.money or 0
		local list = pkt.contribution
		local type_log = pkt.type_log or 12   --流水字段
		local type = pkt.type   --历史消息字段
		local io = pkt.io or 1  --流水标志位 1为添加 

		local cnst_point = faction:get_construct_point()
		local tst_point = faction:get_technology_point()
		faction:set_construct_point(c_point	+ cnst_point)
		faction:set_technology_point(t_point + tst_point)
		local o_money = faction:get_money()
		local n_money = o_money + money
		if n_money >= 0 then
			faction:set_money(n_money)
		end

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1] = faction:syn_info(char_id,1,7)

		--历史消息
		if type == 14 then
			local t_ret = {}
			t_ret[1] = type
			t_ret[2] = ev.time
			t_ret[3] = math.abs(money)
			t_ret[4] = math.abs(t_point)
			t_ret[5] = math.abs(c_point)
			t_ret[6] = tostring(pkt.scene_id)
			faction:set_history_info(t_ret,1)
			new_pkt.list[2] = faction:syn_info(nil,1,10)
		elseif type == 30 then
			local t_ret = {}
			t_ret[1] = type
			t_ret[2] = ev.time
			t_ret[3] = math.abs(money)
			t_ret[4] = math.abs(t_point)
			t_ret[5] = math.abs(c_point)
			t_ret[6] = pkt.contribution and pkt.contribution[1][2] or 0 
			t_ret[6] = pkt.color
			t_ret[7] = pkt.char_id
			t_ret[8] = g_player_mgr.all_player_l[pkt.char_id].char_nm
			faction:set_history_info(t_ret,1)
			new_pkt.list[2] = faction:syn_info(nil,1,10)
		end

		for k,v in pairs(pkt.contribution or {}) do
			local contribution = faction:get_contribution(v[1])
			local t_contribution = contribution + v[2]--.contribution
			faction:set_contribution(v[1],t_contribution)
			if type ~= nil then
				new_pkt.list[k+2]= faction:syn_info(v[1],1,2)
			else
				new_pkt.list[k+1]= faction:syn_info(v[1],1,2)
			end
		end
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

		local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d, io = %d,contribution='%s'",
							faction:get_faction_id(), faction:get_faction_name(), pkt.char_id or 0, type_log,money,c_point,t_point,ev.time,io,Json.Encode(pkt.contribution))
			g_web_sql:write(str)
	end
end


--设置副本开关
Sv_commands[0][CMD_M2P_FACTION_SWITCH_REQ] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	local faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then
		faction:switch_fb(pkt.switch_flag,pkt.scene_id)
		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1] = faction:syn_info(nil,1,12)
		new_pkt.list[2] = faction:syn_info(nil,1,10)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)

		local ret = {}
		ret.faction_id = faction:get_faction_id()
		ret.fb_info = faction:get_fb_info()
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_FB_S,Json.Encode(ret),true)
	end
end

--后台添加帮派资金
Sv_commands[1][CMD_M2P_FACTION_ADD_C] = 
function(conn,char_id,pkt)
	if pkt == nil then return end
	local faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then
		local t_point = pkt.technology_point or 0
		local c_point = pkt.construct_point or 0
		local money = pkt.money or 0
		local list = pkt.contribution

		local cnst_point = faction:get_construct_point()
		local tst_point = faction:get_technology_point()
		faction:set_construct_point(c_point	+ cnst_point)
		faction:set_technology_point(t_point + tst_point)
		local o_money = faction:get_money()
		local n_money = o_money + money
		if n_money >= 0 then
			faction:set_money(n_money)
		end

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1] = faction:syn_info(char_id,1,7)
		for k,v in pairs(pkt.contribution or {}) do
			local contribution = faction:get_contribution(v[1])
			local t_contribution = contribution + v[2]--.contribution
			faction:set_contribution(v[1],t_contribution)

			new_pkt.list[k+1]= faction:syn_info(v[1],1,2)
		end
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
		
		--local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d, io = %d",
							--faction:get_faction_id(), faction:get_faction_name(), 0, 12,money,c_point,t_point,ev.time,1)
			--g_web_sql:write(str)
	end
end

--清除退出帮派时间
Sv_commands[0][CMD_M2P_FACTION_SET_LEAVE_TIME_REQ] = 
function(conn,char_id,pkt)
	if char_id == nil then return end
	g_faction_mgr:set_leave_time(char_id,0)
	g_faction_mgr:set_kick_time(char_id,0)
	--同步退出时间
	local leave_ret = {}
	leave_ret[char_id] = 0

	local kick_ret = {}
	kick_ret[char_id] = 0
	local pkt = g_faction_mgr:get_leave_time_ex(1,leave_ret,kick_ret)
	g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_LEAVE_TIME_S,Json.Encode(pkt),true)

	f_faction_log("faction delete leave_time" .. "-" .. char_id .. "-" .. ev.time)
end

--帮派弹劾令
Sv_commands[0][CMD_M2P_FACTION_IMPEACH_REQ] = 
function(conn,char_id,pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local factioner = faction:get_factioner_id()
		if factioner == char_id then return end
		local player_list = faction:get_player_list()
		local status = player_list[factioner].status
		if status == "0" then
			return
		else
			local ret = {}
			ret.year = string.sub(status,1,4)
			ret.month = string.sub(status,6,7)
			ret.day = string.sub(status,9,10)

			ret.hour = string.sub(status,12,13)
			ret.min = string.sub(status,15,16)
			ret.second = string.sub(status,18,19)

			local time_old = os.time(ret)
			if time_old + 24*3600*3 > ev.time then
				return
			end
		end

		
		local item_list = {}
		local contribution = faction:get_contribution(factioner) or 0 --帮贡返还文书，取得被踢之人的帮贡
		contribution = math.floor(contribution * 0.8)
		if contribution == 0 then
			item_list = nil
		else
			local e_code, contribution_item = Item_factory.create(184000000020) --帮贡返还文书
			contribution_item:set_contribution(contribution)
			if e_code ~= 0 then
				return
			end
			item_list[1] = {}
			item_list[1]["item_id"] = 184000000020
			item_list[1]["item_obj"] = contribution_item:serialize_to_db()
			item_list[1]["number"] = 1
		end

		faction:transfer(char_id)

		--历史消息
		local t_ret = {}
		t_ret[1] = 16
		t_ret[2] = ev.time
		t_ret[3] = char_id
		t_ret[4] = faction.faction_player_list[char_id]["name"]
		t_ret[5] = factioner
		t_ret[6] = faction.faction_player_list[factioner]["name"]
		faction:set_history_info(t_ret,1)

		local faction_id = faction:get_faction_id()
		g_faction_dogz_mgr:del_char_id(faction_id, factioner) -- 帮派神兽

		--帮派庭院 屏蔽 121114 chendong
		-- 退帮清除拜祭标记
		--g_faction_courtyard_mgr:clear_baiji_flag(faction_id, factioner) -- 帮派烧香

		--向被弹劾的帮主发送邮件和帮贡返还文书
		local title = f_get_string(2000)
		local content = f_get_string(2001) .. faction:get_faction_name() .. f_get_string(2002)
		g_email_mgr:create_email(-1,factioner,title,content,0,Email_type.type_common,Email_sys_type.type_normal, item_list)

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1] = faction:syn_info(char_id,1,2)
		new_pkt.list[2] = faction:syn_info(factioner,1,2)
		new_pkt.list[3] = faction:syn_info(nil,1,10)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)

		--显示头上信息
		local ret = faction:get_head_info(char_id)
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_PLAYER_HEAD_INFO_S,ret)

		f_faction_log("faction CMD_M2P_FACTION_IMPEACH_REQ" .. " -char_id_s: " .. char_id  .. "---" .. ev.time)
	end
end


--帮派合并
Sv_commands[0][CMD_M2P_FACTION_MERGE_C] = 
function(conn,char_id,pkt)
	if pkt == nil then return end

	local obj_s = pkt[1]
	local obj_d = pkt[2]

	local my_faction = g_faction_mgr:get_faction_by_cid(obj_s)
	if not my_faction then return end

	local other_faction = g_faction_mgr:get_faction_by_cid(obj_d)
	if not other_faction then return end

	local my_faction_name = my_faction:get_faction_name()
	local other_faction_name = other_faction:get_faction_name()

	local my_factioner = g_player_mgr.all_player_l[obj_s].char_nm
	local other_factioner = g_player_mgr.all_player_l[obj_d].char_nm


	local result = g_faction_mgr:can_be_faction_merge(obj_s, obj_d)
	if result ~= 0 then return end

	-- 帮派仓库合并检测
	local faction_a_id = my_faction:get_faction_id()
	local faction_b_id = other_faction:get_faction_id()
	local e_code = g_faction_bag_mgr:can_merge(faction_a_id,faction_b_id)
	if e_code ~= 0 then
		local t_pkt = {}
		t_pkt.result = e_code
		t_pkt.obj_id_s = obj_s
		t_pkt.obj_id_d = obj_d
		return g_server_mgr:send_to_server(conn.id,0,CMD_P2M_FACTION_MERGE_S,t_pkt)
	end

	local result, ret, faction_id = g_faction_mgr:faction_merge(obj_s,obj_d)
	if result == 0 then

		-- 帮派仓库合并
		g_faction_bag_mgr:merge(faction_a_id, faction_b_id)

		-- 帮派合并，删除帮派神兽
		--g_faction_dogz_mgr:del(faction_b_id)
		g_faction_dogz_mgr:merge(faction_a_id, faction_b_id)
		
		f_faction_log("faction faction_merge" .. " -obj_s: " .. obj_s .. " -obj_d: " .. obj_d .. " faction_name_s: " .. my_faction_name .. " faction_name_d: " .. other_faction_name .. " -- " .. ev.time)
		
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_DISSOLVE_S,Json.Encode({["faction_id"]= faction_id}),true)

		--广播
		local t_new_pkt = {}
		for k, v in pairs(ret) do
			local list = my_faction:syn_info(v,2,1)
			table.insert(t_new_pkt, list)
		end

		local new_pkt ={}
		new_pkt.faction_id = my_faction:get_faction_id()
		new_pkt.cmd = 25643
		new_pkt.list= t_new_pkt
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)

		-- 帮派庭院 屏蔽 121114 chendong
		-- 帮派合并，合并摇钱树(铜券树)
		-- 帮派合并，庭院合并
		--g_faction_courtyard_mgr:merge(faction_a_id, faction_b_id)

		--历史消息
		local t_ret = {}
		t_ret[1] = 17
		t_ret[2] = ev.time
		t_ret[3] = other_faction_name
		my_faction:set_history_info(t_ret)

		--返回通知map
		local t_pkt = {}
		t_pkt.result = 0
		t_pkt.obj_id_s = obj_s
		t_pkt.obj_id_d = obj_d
		g_server_mgr:send_to_server(conn.id,0,CMD_P2M_FACTION_MERGE_S,t_pkt)

		--显示头上信息
		for k,v in pairs(ret) do
			if g_player_mgr:is_online_char(v) then
				local ret = my_faction:get_head_info(v)
				g_server_mgr:send_to_server(conn.id,v,CMD_P2M_PLAYER_HEAD_INFO_S,ret)

				local server_id = g_player_mgr:get_map_id(v)
				g_server_mgr:send_to_server(server_id,v,CMD_P2M_PLAYER_RESET_ONLINE_S,{})
			end
		end

		--邮件通知
		local title = f_get_string(644)
		local content = f_get_string(635) .. other_factioner .. f_get_string(640) .. my_faction_name .. f_get_string(641) .. my_factioner .. f_get_string(642) .. my_faction_name .. f_get_string(643)
		for m, n in pairs(ret) do
			g_email_mgr:create_email(-1,n,title,content,0,Email_type.type_common,Email_sys_type.type_normal,nil)
		end
	else
		--返回通知map
		local t_pkt = {}
		t_pkt.result = 0
		t_pkt.obj_id_s = obj_s
		t_pkt.obj_id_d = obj_d
		g_server_mgr:send_to_server(conn.id,0,CMD_P2M_FACTION_MERGE_S,t_pkt)
	end
	
end
	

--帮派副本等级设置
Sv_commands[0][CMD_M2P_FACTION_FB_LEVEL_C] = 
function(conn,char_id,pkt)
	if char_id == nil or pkt.level == nil or pkt.faction_id == nil then return end

	local faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
	if faction then
		faction:set_fb_level(pkt.level)

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1] = faction:syn_info(nil,1,16)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
	end
end

-- 玩家选中帮派副本等级设置
Sv_commands[0][CMD_M2P_FACTION_CHOOSE_FB_LEVEL_C] = 
function(conn,char_id,pkt)
	if char_id == nil or pkt.choose_fb_level == nil or pkt.faction_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_fid(pkt.faction_id)
	if faction then
		local e_code = faction:set_choose_fb_level(pkt.choose_fb_level)
		if e_code == 0 then
			local new_pkt = {}
			new_pkt.faction_id = faction:get_faction_id()
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1] = faction:syn_info(nil,1,16)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
		end
		local ret = {}
		ret.result = e_code
		g_server_mgr:send_to_server(conn.id, char_id, CMD_P2M_FACTION_CHOOSE_FB_LEVEL_S,ret)
	end
end
