Clt_commands[1][CMD_STORY_LIST_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player then
		local con = player:get_story_con()
		local list = con:get_chapter_list()
		g_cltsock_mgr:send_client(conn.char_id, CMD_STORY_LIST_S, list)
	end
end

Clt_commands[1][CMD_STORY_ENTRY_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player then
		local con = player:get_story_con()
		local e_code, map_id = con:can_access(pkt.map_id)
		g_cltsock_mgr:send_client(conn.char_id, CMD_STORY_ENTRY_S, {["result"] = e_code})
		if E_SUCCESS == e_code then
			local e_code, error_l = g_scene_mgr_ex:carry_scene(map_id, nil, player)
			if SCENE_ERROR.E_SUCCESS ~= e_code then
				local new_pkt = {}
				new_pkt.result = e_code
				new_pkt.error_l = error_l
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
			end
		end
	end
end


Clt_commands[1][CMD_STORY_REWARD_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if player then
		local con = player:get_story_con()
		local result = con:get_reward(pkt.chapter)
		
		g_cltsock_mgr:send_client(conn.char_id, CMD_STORY_REWARD_S, {["result"] = result})

		if 0 == result then	
			local list = con:get_chapter_list()
			g_cltsock_mgr:send_client(conn.char_id, CMD_STORY_LIST_S, list)
		end
	end
end