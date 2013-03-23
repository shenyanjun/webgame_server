
require("team.obj_team")
require("team.team_copy_container")
require("team.team_mgr")

local _sf = require("scene_ex.scene_process")

local err_fun = function(obj_id, err)
	local new_pkt = {}
	new_pkt.result = err
	g_cltsock_mgr:send_client(obj_id, CMD_MAP_TEAM_ERROR_S, new_pkt)
end

--组员集合(type: 1正常集合 2副本集合)
function f_team_gather(obj_s, type)
	if obj_s == nil or obj_s:get_team() == nil then
		return 20106
	end
	
	return g_team_mgr:gather(obj_s:get_id(), obj_s:get_team(), nil, type)
end

--踢出成员
function f_team_kickout(obj_s)
	if obj_s ~= nil and obj_s:get_team() ~= nil then
		local char_id = obj_s:get_id()
		local team_id = obj_s:get_team()
		local team_obj = g_team_mgr:get_team_obj(team_id)
		if team_obj ~= nil and team_obj:is_member(char_id) then
			local change_captain = char_id == team_obj:get_teamer_id()
			if team_obj:del_obj(char_id) then
				g_team_mgr:del_char_id(char_id)
				team_obj:syn()

				g_cltsock_mgr:send_client(char_id, CMD_MAP_TEAM_LEAVE_SYN_S, {})
				if change_captain then
					g_event_mgr:notify_event(EVENT_SET.EVENT_TEAM_CAPTAIN, team_obj:get_teamer_id(), nil)
				end

				if team_obj:get_line_count() <= 0 then
					g_team_mgr:del_team(team_obj:get_id())
					team_obj:remove()
				end
			end
		end
	end
end

function f_team_fun_ack(team_id, obj_id, type, timeout, callback, failed_closure)
	local team_obj = g_team_mgr:get_team_obj(team_id)
	if not team_obj then
		return false
	end
	
	local pkt = {}
	pkt.type = type
	pkt.timeout = timeout
	
	local has_other = false
	local team_l, team_count = team_obj:get_team_l()
	for k, _ in pairs(team_l) do
		if k ~= obj_id then
			has_other = true
			g_cltsock_mgr:send_client(k, CMD_MAP_TEAM_FUN_ACK_S, pkt)
		end
	end
	
	--if has_other then
		team_obj:add_ack(type, timeout, callback, failed_closure)
		team_obj:ack_request(type, obj_id, 1)
	--end
	
	return true
end

if 2 ~= ENABLE_GATE then
	--创建组
	Clt_commands[1][CMD_MAP_TEAM_CREATE_C] =
	function(conn, pkt)
		--print("-----------_command[CMD_MAP_TEAM_CREATE_C]", conn.char_id)
		if conn.char_id ~= nil then
			local obj = g_obj_mgr:get_obj(conn.char_id)
			if obj ~= nil then
				local scene_o = obj:get_scene_obj()
				if scene_o and (scene_o:get_mode() == MAP_MODE_SIDE or scene_o:get_type() == MAP_TYPE_SHEEP) then			--竞技场禁止队伍操作
					return
				end
			
				if obj:get_team() ~= nil then
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_CREATE_S, {["result"]=20102})
				else
					local team_obj = g_team_mgr:create_team(conn.char_id)
					local new_pkt = team_obj:net_get_info()
					new_pkt.result = 0
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_CREATE_S, new_pkt)
				end
			end
		end
	end
	
	--邀请
	Clt_commands[1][CMD_MAP_TEAM_REQUEST_C] =
	function(conn, pkt)
		--print("-----------_command[CMD_MAP_TEAM_REQUEST_C]", conn.char_id)
		if conn.char_id ~= nil and pkt.obj_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			local obj_d = g_obj_mgr:get_obj(pkt.obj_id)
	
			if obj_s ~= nil then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
			
				--被邀请人判断
				local err = 0
				if obj_d == nil then
					err = 20101
				elseif obj_d:get_team() ~= nil then 
					err = 20102
				end
	
				if err ~= 0 then
					err_fun(conn.char_id, err)
					return
				end
	
				--组长判断
				local team_id = obj_s:get_team()
				local team_obj
				if team_id == nil then 
					team_obj = g_team_mgr:create_team(conn.char_id)
					local new_pkt = team_obj:net_get_info()
					new_pkt.result = 0
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_CREATE_S, new_pkt)
				else
					team_obj = g_team_mgr:get_team_obj(team_id)
				end
	
				if team_obj ~= nil and 
					(team_obj:get_teamer_id() == conn.char_id or team_obj:get_setting(1) == 1) and  --组长或开启成员邀请标志
					not team_obj:is_full() then
	
					team_obj:add_request(pkt.obj_id, conn.char_id)
					local new_pkt = {}
					new_pkt.obj_id = conn.char_id
					new_pkt.name = obj_s:get_name()
					new_pkt.team_id = team_obj:get_id()
					g_cltsock_mgr:send_client(pkt.obj_id, CMD_MAP_TEAM_REQUEST_ANSWER_S, new_pkt)
					
					--邀请已经发送
					err_fun(conn.char_id, 20124)
				end
			end
		end
	end
	
	--邀请确认
	Clt_commands[1][CMD_MAP_TEAM_REQUEST_ANSWER_C] =
	function(conn, pkt)
		--print("-----------_command[CMD_MAP_TEAM_REQUEST_ANSWER_C]", conn.char_id, pkt.flag)
		if conn.char_id ~= nil and pkt.team_id ~= nil and pkt.flag ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			if obj_s ~= nil then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
	
				--已经有组
				if obj_s:get_team() ~= nil then
					err_fun(conn.char_id, 20102)
					return
				end
			
				local team_obj = g_team_mgr:get_team_obj(pkt.team_id)
				if team_obj ~= nil and team_obj:is_request(conn.char_id) then
					if pkt.flag == 0 then
						if team_obj:is_full() then
							err_fun(conn.char_id, 20103)
							--err_fun(team_obj:get_request_src_obj_id(conn.char_id), 20103)
							return
						end
	
						team_obj:del_request(conn.char_id)
						team_obj:add_obj(conn.char_id)
						g_team_mgr:add_char_id(conn.char_id, team_obj:get_id())
					else
						team_obj:del_request(conn.char_id)
						err_fun(team_obj:get_request_src_obj_id(conn.char_id), 20119)
					end
				else                           --邀请确认失败
					err_fun(conn.char_id, 20112)
					return
				end
			end
		end
	end
	
	--组长删除成员
	Clt_commands[1][CMD_MAP_TEAM_DEL_MEMBER_C] =
	function(conn, pkt)
		if conn.char_id ~= nil and pkt.obj_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			if obj_s ~= nil then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
			
				local team_id = obj_s:get_team()
				local team_obj = g_team_mgr:get_team_obj(team_id)
				if team_obj ~= nil and team_obj:get_teamer_id() == conn.char_id then
					if team_obj:del_obj(pkt.obj_id) then
						team_obj:syn()
						g_team_mgr:del_char_id(pkt.obj_id)
						g_cltsock_mgr:send_client(pkt.obj_id, CMD_MAP_TEAM_LEAVE_SYN_S, {})
	
						err_fun(pkt.obj_id, 20120)
						if conn.char_id == pkt.obj_id then
							g_event_mgr:notify_event(EVENT_SET.EVENT_TEAM_CAPTAIN, pkt.obj_id, nil)
						end
					end
				end
			end
		end
	end
	
	--移交组长
	Clt_commands[1][CMD_MAP_TEAM_TRANSFER_C] =
	function(conn, pkt)
		if conn.char_id ~= nil and pkt.obj_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			local obj_d = g_obj_mgr:get_obj(pkt.obj_id)
			if obj_s ~= nil and obj_d ~= nil then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
			
				local team_id = obj_s:get_team()
				local team_obj = g_team_mgr:get_team_obj(team_id)
				if team_obj ~= nil and team_obj:get_teamer_id() == conn.char_id and obj_d:get_team() == team_id then
					local new_pkt = {}
					new_pkt.result = team_obj:transfer(pkt.obj_id)
					if new_pkt.result == 0 then
						team_obj:syn()
	
						obj_s:on_dress_update(3)
						obj_d:on_dress_update(3)
						g_event_mgr:notify_event(EVENT_SET.EVENT_TEAM_CAPTAIN, pkt.obj_id, nil)
					end
				end
			end
		end
	end
	
	--获取申请人列表
	Clt_commands[1][CMD_MAP_TEAM_ASK_INFO_C] =
	function(conn, pkt)
		--print("-----------_command[CMD_MAP_TEAM_ASK_INFO_C]", conn.char_id)
		if conn.char_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			if obj_s ~= nil then
				local team_id = obj_s:get_team()
				local team_obj = g_team_mgr:get_team_obj(team_id)
				if team_obj ~= nil and team_obj:get_teamer_id() == conn.char_id then
					local new_pkt= team_obj:net_get_ask_info()
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_ASK_INFO_S, new_pkt)
				end
			end
		end
	end
	
	--申请入组
	Clt_commands[1][CMD_MAP_TEAM_ASK_C] =
	function(conn, pkt)
		--print("-----------_command[CMD_MAP_TEAM_ASK_C]", conn.char_id)
		if conn.char_id ~= nil and pkt.obj_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			local obj_d = g_obj_mgr:get_obj(pkt.obj_id)
			if obj_s ~= nil and obj_d ~= nil then
				if obj_s:get_team() ~= nil then
					err_fun(conn.char_id, 20102)
					return
				end
	
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
			
				local team_id = obj_d:get_team()
				local team_obj = g_team_mgr:get_team_obj(team_id)
				if team_obj ~= nil and team_obj:get_teamer_id() == pkt.obj_id then
					if team_obj:is_full() then 
						err_fun(conn.char_id, 20103)
						return
					end
	
					if team_obj:get_setting(2) == 0 then    --关闭自由进入, 发送申请给组长
						local new_pkt = {}
						new_pkt.obj_id = conn.char_id
						team_obj:add_ask(conn.char_id)
						g_cltsock_mgr:send_client(pkt.obj_id, CMD_MAP_TEAM_ASK_ANSWER_S, new_pkt)
					else
						team_obj:add_obj(conn.char_id) 
						g_team_mgr:add_char_id(conn.char_id, team_id)
	
						--local new_pkt= team_obj:net_get_ask_info()
						--g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_ASK_INFO_S, new_pkt)
					end
				end
			else
				err_fun(conn.char_id, 20101)
			end
		end
	end
	
	--组长确认申请
	Clt_commands[1][CMD_MAP_TEAM_ASK_ANSWER_C] =
	function(conn, pkt)
		--print("-----------_command[CMD_MAP_TEAM_ASK_ANSWER_C]", conn.char_id, pkt.flag)
		if conn.char_id ~= nil and pkt.obj_id ~= nil and pkt.flag ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			local obj_d = g_obj_mgr:get_obj(pkt.obj_id)
			if obj_s ~= nil then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
			
				local team_id = obj_s:get_team()
				local team_obj = g_team_mgr:get_team_obj(team_id)
				if team_obj ~= nil and team_obj:get_teamer_id() == conn.char_id  then
					if pkt.flag == 0 then
						if team_obj:is_full() then    --组满
							err_fun(pkt.obj_id, 20103)
							err_fun(conn.char_id, 20103)
							team_obj:del_ask(pkt.obj_id)
							return 
						elseif team_obj:is_ask(pkt.obj_id) then
							--申请人判断
							local err = 0
							if obj_d == nil then
								err = 20101
							elseif obj_d:get_team() ~= nil then 
								err = 20102
							end
	
							if err ~= 0 then
								err_fun(conn.char_id, err)
								return
							end
	
							team_obj:del_ask(pkt.obj_id)
							team_obj:add_obj(pkt.obj_id) 
							g_team_mgr:add_char_id(pkt.obj_id, team_obj:get_id())
	
							local new_pkt= team_obj:net_get_ask_info()
							g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_ASK_INFO_S, new_pkt)
						end
					else
						err_fun(pkt.obj_id, 20118)
						team_obj:del_ask(pkt.obj_id)
					end
				end
			end
		end
	end
	
	--删除申请记录
	Clt_commands[1][CMD_MAP_TEAM_DEL_ASK_C] =
	function(conn, pkt)
		if pkt == nil or pkt.ask_l == nil then return end
	
		if conn.char_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			if obj_s ~= nil then
				local team_id = obj_s:get_team()
				local team_obj = g_team_mgr:get_team_obj(team_id)
				if team_obj ~= nil and team_obj:get_teamer_id() == conn.char_id then
					for k,v in pairs(pkt.ask_l) do
						team_obj:del_ask(v)
					end
					
					local new_pkt= team_obj:net_get_ask_info()
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_ASK_INFO_S, new_pkt)
				end
			end
		end
	end
	
	--组员离开组
	Clt_commands[1][CMD_MAP_TEAM_LEAVE_C] =
	function(conn, pkt)
		if conn.char_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			if obj_s then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
				f_team_kickout(obj_s)
			end
		end
	end
	
	--删除组
	Clt_commands[1][CMD_MAP_TEAM_DEL_TEAM_C] =
	function(conn, pkt)
		if conn.char_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			if obj_s ~= nil and obj_s:get_team() ~= nil then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
			
				local team_id = obj_s:get_team()
				local team_obj = g_team_mgr:get_team_obj(team_id)
				if team_obj ~= nil and team_obj:get_teamer_id() == conn.char_id then
					g_team_mgr:del_team(team_obj:get_id())
					team_obj:remove()
				end
			end
		end
	end
	
	--组长集合组员
	Clt_commands[1][CMD_MAP_TEAM_GATHER_C] =
	function(conn, pkt)
		--print("CMD_MAP_TEAM_GATHER_C")
		if conn.char_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			if obj_s ~= nil and obj_s:get_team() ~= nil then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
			
				local ret = g_team_mgr:gather(conn.char_id, obj_s:get_team(), 1, 1)
				local new_pkt = {}
				new_pkt.result = ret
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_GATHER_S, new_pkt)
			end
		end
	end
	
	--组员集合确认
	Clt_commands[1][CMD_MAP_TEAM_GATHER_ANSWER_C] =
	function(conn, pkt)
		--print("CMD_MAP_TEAM_GATHER_ANSWER_C")
		if conn.char_id ~= nil then
			local obj_s = g_obj_mgr:get_obj(conn.char_id)
			if obj_s ~= nil and obj_s:get_team() ~= nil then
				local scene_o = obj_s:get_scene_obj()
				if scene_o and scene_o:get_mode() == MAP_MODE_SIDE then			--竞技场禁止队伍操作
					return
				end
			
				local team_id = obj_s:get_team()
				local team_obj = g_team_mgr:get_team_obj(team_id)
				if team_obj ~= nil then
					local teamer = g_obj_mgr:get_obj(team_obj:get_teamer_id())
					if teamer ~= nil and team_obj:is_gather_flag(conn.char_id, teamer:get_map_id()) 
						and obj_s:is_carry(teamer:get_map_id()) == 0 and scene_o:can_carry(obj_s) then
						--集合队员
						local scene_id = teamer:get_map_id()
						local pos = teamer:get_pos()
						--九幽封印
						if teamer:get_scene_obj():get_type() == MAP_TYPE_PVP_BATTLE then
							local prototype = g_scene_mgr_ex:get_prototype(4201000)
							local copy_id = prototype:obj_get_copy_id(teamer:get_id())
							local err = prototype:select_instance(obj_s:get_id(), copy_id, pos)
							if err ~= nil then
								g_cltsock_mgr:send_client(obj_s:get_id(), CMD_MAP_TEAM_GATHER_ANSWER_S, {["result"]=err})
							end
						else
						--切换地图
							_sf.change_scene_cm(obj_s:get_id(), scene_id, pos)
						end
					end
				end
			end
		end
	end
	
	--队伍分配模式
	Clt_commands[1][CMD_MAP_TEAM_MODIFY_ALLOC_MODE_C] =
	function (conn, pkt)
		if not conn.char_id then
			return
		end
	
		local obj_s = g_obj_mgr:get_obj(conn.char_id)
		if not obj_s then
			return 
		end
	
		local team_id = obj_s:get_team()
		if not team_id then
			return
		end
	
		local team_obj = g_team_mgr:get_team_obj(team_id)
		if not team_obj then
			return
		end
	
		local new_pkt = {}
		new_pkt.result = team_obj:set_alloc_mode(conn.char_id, pkt.mode) and 0 or 20109		--当非队长调用时会返回false
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_MODIFY_ALLOC_MODE_C, new_pkt)
		team_obj:syn(nil)
	end
	
	--组设置
	Clt_commands[1][CMD_MAP_TEAM_SETING_C] =
	function (conn, pkt)
		if pkt.type == nil or pkt.flag == nil then return end
	
		local obj_s = g_obj_mgr:get_obj(conn.char_id)
		if not obj_s then
			return 
		end
	
		local team_id = obj_s:get_team()
		if not team_id then
			return
		end
	
		local team_obj = g_team_mgr:get_team_obj(team_id)
		if not team_obj or team_obj:get_teamer_id() ~= conn.char_id then
			return
		end
	
		local new_pkt = {}
		new_pkt.result = team_obj:set_setting(pkt.type, pkt.flag) and 0 or 20113		--当非队长调用时会返回false
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_SETING_S, new_pkt)
		team_obj:syn(nil)
	end
	
	--申请挑战
	Clt_commands[1][CMD_MAP_TEAM_CHALLENG_COPY_C] =
	function (conn, pkt)
		if pkt.copy_id == nil then return end
	
		local obj = g_obj_mgr:get_obj(conn.char_id)
		if obj ~= nil then
			local copy_con = g_team_mgr:get_copy_container()
			local new_pkt = {}
			if obj:get_team() ~= nil then
				new_pkt.result = copy_con:add_team(conn.char_id, pkt.copy_id)
			else
				new_pkt.result = copy_con:add_obj(conn.char_id, pkt.copy_id)
			end
	
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_CHALLENG_COPY_S, new_pkt)
		end
	end
	
	--获取申请列表
	Clt_commands[1][CMD_MAP_TEAM_GET_CHALLENG_LIST_C] =
	function (conn, pkt)
		if pkt.copy_id == nil then return end
	
		local copy_con = g_team_mgr:get_copy_container()
		local new_pkt = copy_con:net_get_list(pkt.copy_id)
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_GET_CHALLENG_LIST_S, new_pkt)
	end
	
	--重置副本
	Clt_commands[1][CMD_MAP_TEAM_RESET_COPY_C] =
	function (conn, pkt)
		local obj_s = g_obj_mgr:get_obj(conn.char_id)
		if not obj_s then
			return 
		end
	
		local team_id = obj_s:get_team()
		local team_obj = g_team_mgr:get_team_obj(team_id)
		if not team_obj or team_obj:get_teamer_id() ~= conn.char_id then
			err_fun(conn.char_id, 20121)
			return
		end
	
		g_scene_mgr_ex:unregister_instance(team_id)
	
		--[[--清除神秘商人列表
	for k,_ in pairs(team_obj:get_team_l()) do
		g_random_script:event_del_team({["char_id"]=k}, k)
	end]]
	end

end

--获取组成员即时信息
Clt_commands[1][CMD_MAP_TEAM_GET_INSTANT_C] =
function(conn, pkt)
	if conn.char_id ~= nil and pkt.obj_id ~= nil then
		local obj_s = g_obj_mgr:get_obj(conn.char_id)
		if obj_s ~= nil and obj_s:get_team() ~= nil then
			local team_id = obj_s:get_team()
			local team_obj = g_team_mgr:get_team_obj(team_id)
			if team_obj ~= nil then
				local new_pkt = team_obj:net_get_instant_info(pkt.obj_id)
				if new_pkt ~= nil then
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_INSTANT_SYN_S, new_pkt)
				end
			end
		end
	end
end

--获取组信息
Clt_commands[1][CMD_MAP_TEAM_INFO_C] =
function(conn, pkt)
	if conn.char_id ~= nil then
		local obj_s = g_obj_mgr:get_obj(conn.char_id)
		if obj_s ~= nil then
			local team_id = obj_s:get_team()
			local team_obj = g_team_mgr:get_team_obj(team_id)
			if team_obj ~= nil then
				local new_pkt = team_obj:net_get_info()
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TEAM_INFO_S, new_pkt)
			end
		end
	end
end

Clt_commands[1][CMD_MAP_TEAM_FUN_ACK_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local team_id = obj:get_team()
		local team_obj = g_team_mgr:get_team_obj(team_id)
		if team_obj then
			team_obj:ack_request(pkt.type, conn.char_id, pkt.flag)
		end
	end
end