Clt_commands[1][CMD_MAP_DYMANIC_NPC_GET_ACTION_LIST_C] =
function(conn, pkt)
	local action = g_dynamic_npc_mgr:get_npc_actions(pkt.obj_id)
	if action then
		g_cltsock_mgr:send_client(
			conn.char_id
			, CMD_MAP_DYMANIC_NPC_GET_ACTION_LIST_S
			, {
				["result"] = 0
				, ["obj_id"] = pkt.obj_id
				, ["action_l"] = {{action.id, action.name, action.type}}
			})
	end
end

Clt_commands[1][CMD_MAP_DYMANIC_NPC_ACTION_INVOKE_C] =
function(conn, pkt)
	local action = g_dynamic_npc_mgr:get_npc_actions(pkt.obj_id)
	local npc = g_obj_mgr:get_obj(pkt.obj_id)

	if npc and action and action.id == pkt.action_id then

		if 52 == action.type then
			local info = action.transfer_list[1]
			if info then
				local is_npc_leave = true
				if info.map_id == 2903000 then
					local obj = g_obj_mgr:get_obj(conn.char_id)
					local scene_fid = obj:get_scene_obj():get_manor_owner()
					local faction = g_faction_mgr:get_faction_by_cid(conn.char_id)
					local faction_id = faction and faction:get_faction_id()
					if faction_id == nil or faction_id ~= scene_fid then
						local new_pkt = {}
						new_pkt.result = 22256
						g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
						return
					end
					local team_o = g_team_mgr:get_team_obj(obj:get_team())
					if team_o then
						if team_o:get_teamer_id() ~= conn.char_id then
							local new_pkt = {}
							new_pkt.result = 22257
							g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
							return
						end
						if g_scene_mgr_ex:exists_instance(team_o:get_id()) then
							is_npc_leave = false
						end
					end
				end
				local prototype = g_scene_mgr_ex:get_prototype(info.map_id)
				if prototype then
					local e_code, error_l = 
						prototype:carry_scene(g_obj_mgr:get_obj(conn.char_id), {info.pos_x, info.pos_y})
	
					if SCENE_ERROR.E_SUCCESS ~= e_code then
						local new_pkt = {}
						new_pkt.result = e_code
						new_pkt.error_l = error_l
						g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
					elseif is_npc_leave then
						npc:leave()
					end
				end
			end
		end
		
		g_cltsock_mgr:send_client(
			conn.char_id
			, CMD_MAP_DYMANIC_NPC_ACTION_INVOKE_S
			, {
				["result"] = 0
				, ["obj_id"] = pkt.obj_id
				, ["action_id"] = pkt.action_id
				, ["args"] = {}
			})
	end
end