

----------------------------------------*******************************处理从common返回命令接口（广播等）
--BUF
Sv_commands[0][CMD_COLLECTION_ACTIVITY_BUF_C] = 
	function(conn, char_id, pkt)
		if not pkt then return end
		if pkt.type == 1 then
			for k, v in pairs(pkt.param) do
				g_buffer_reward_mgr:buffer_reward_start_ex(v)
			end

			if pkt.lvl then		--需要更新lvl数据
				g_activity_reward_mgr:reward_level_up(pkt.lvl)

				--更新雕像
				g_activity_reward_mgr:change_statue(pkt.lvl)
			end
		elseif pkt.type == 2 then
			for k, v in pairs(pkt.param) do
				g_buffer_reward_mgr:buffer_reward_stop_ex(v.type)
			end
		end
	end


--活动开关
Sv_commands[0][CMD_COLLECTION_ACTIVITY_SWITCH_C] = 
	function(conn, char_id, pkt)
		if not pkt or not pkt.swicth then return end

		g_activity_reward_mgr:activity_swicth(pkt.swicth)
		return
	end

--后台活动通知 1 消费返回 2 强化奖励 3 神龙活动 4 大富翁活动 5 庄园配方
Sv_commands[0][CMD_GM_ACTIVITY_NOTICE_C] = 
	function(conn, char_id, pkt)
		if not pkt or not pkt.type or not pkt.flags then return end

		if pkt.type == 1 then
			if pkt.flags == 1 then
				g_gm_function_con:load_gm_function_info(pkt.param and pkt.param.id)
			elseif pkt.flags == 2 then
				g_gm_function_con:clear_function_info(pkt.param and pkt.param.id)
			end
		elseif pkt.type == 2 then
			if pkt.flags == 1 then
				g_activity_goal_mgr:start_activity(pkt.param.id, pkt.param.start_t, pkt.param.end_t, pkt.param.param)
			elseif pkt.flags == 2 then
				g_activity_goal_mgr:close_activity()
			end
		elseif pkt.type == 3 then
			if pkt.flags == 1 then
				g_gm_function_con:open_long(pkt.param and pkt.param.id)
			elseif pkt.flags == 2 then
				g_gm_function_con:close_long(pkt.param and pkt.param.id)
			end
		elseif pkt.type == 4 then
			if pkt.flags == 1 then
				g_gm_function_con:load_active(pkt.param and pkt.param.id)
			elseif pkt.flags == 2 then
				g_gm_function_con:close_zillonaire_function_info(pkt.param and pkt.param.id)
			end
		elseif pkt.type == 5 then
			if pkt.flags == 1 then
				g_gm_function_con:add_home_peifang(pkt.param and pkt.param.param.list)
			elseif pkt.flags == 2 then
				g_gm_function_con:clear_home_peifang(pkt.param and pkt.param.param.list)
			end
		elseif pkt.type == 6 then
			if pkt.flags == 1 then
				g_achi_tree_mgr:show_activity_icon(pkt.param.start_t,pkt.param.end_t)
			elseif pkt.flags ==2 then
				g_achi_tree_mgr:hide_activity_icon()
			end
		elseif pkt.type == 7 then
			if pkt.flags == 1 then
				g_activity_rank_mgr:show_icon_turn_on()
			elseif pkt.flags == 2 then
				g_activity_rank_mgr:cancel_icon_turn_on()
			end
		end
		return
	end


--元宝消费累计
Sv_commands[0][CMD_C2M_CONSUME_INFO] = 
	function(conn, char_id, pkt)
		if not pkt or not pkt.money then return end
		local obj = g_obj_mgr:get_obj(char_id)
		if obj then
			local fun_con = obj:get_gm_function_con()
			fun_con:add_integral(pkt.type, pkt.money)
		else
			print("error CMD_C2M_CONSUME_INFO", char_id, Json.Encode(pkt))
		end
	end

--世界等级通知
Sv_commands[0][CMD_NOTICE_WORLD_LEVEL_C] = 
	function(conn, char_id, pkt)
		if not pkt or not pkt.lvl then return end
		
		g_world_lvl_mgr:change_level(pkt.lvl)

		return
	end

