
--common_server 向 map faction 发送帮派人员列表
Sv_commands[0][CMD_P2M_FACTION_PLAYER_LIST_S] = 
function(conn,char_id,pkt)
	g_faction_mgr:serialize_player_list(pkt)
end

--common_server向 map faction 发送帮派招募列表
Sv_commands[0][CMD_P2M_FACTION_JOIN_LIST_S] = 
function(conn,char_id,pkt)
	g_faction_mgr:serialize_join_list(pkt)
end

--更新其他信息
Sv_commands[0][CMD_P2M_FACTION_OTHER_INFO_S] = 
function(conn,char_id,pkt)
	g_faction_mgr:serialize_other_list(pkt)
end

--同步信息
Sv_commands[0][CMD_P2M_FACTION_SYN_UPDATE_S] = 
function(conn,char_id,pkt)
	g_faction_mgr:syn_update(pkt)
end

Sv_commands[0][CMD_P2M_FACTION_INFO_S] =
function(conn,char_id,pkt)
	for k,v in pairs(pkt) do
		g_faction_mgr:serialize_from_common_server(v)
	end
end

--重新通知上线
Sv_commands[0][CMD_P2M_PLAYER_RESET_ONLINE_S] = 
function(conn, char_id, pkt)
	g_faction_mgr:reset_online(char_id)
end

--邀请人
Sv_commands[0][CMD_P2M_PLAYER_ADD_AUTO_S] =
function(conn,char_id,pkt)
	g_faction_mgr:add_player_auto(char_id,pkt)
end

---================================================================================================
--解散帮派通知
Sv_commands[0][CMD_P2M_FACTION_DISSOLVE_S] =
function(conn,char_id,pkt)
	local faction_id = pkt.faction_id
	local faction = g_faction_mgr:get_faction_by_fid(faction_id)
	if faction ~= nil then
		local player_list = faction:get_faction_player_list()
		for k,v in pairs(player_list or {}) do
			g_faction_mgr:del_member2faction(k)
		end
		g_faction_mgr:del_faction(faction_id)
		g_faction_impact_mgr:del_faction_impact_container(faction_id)
		f_cheak_faction_territory(faction_id)
	end
end

-- 玩家选中帮派副本等级
Sv_commands[0][CMD_P2M_FACTION_CHOOSE_FB_LEVEL_S] = 
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_CHOOSE_FACTION_FB_LEVEL_S, pkt)
end

--fb更新信息通知
Sv_commands[0][CMD_P2M_FACTION_FB_S] = 
function(conn,char_id,pkt)
	if pkt.faction_id == nil then return end
	local faction_id = pkt.faction_id
	local faction = g_faction_mgr:get_faction_by_fid(faction_id)
	if faction ~= nil then
		faction:set_fb(pkt.fb_info)
	end
end

--退出帮派时间变化通知
Sv_commands[0][CMD_P2M_FACTION_LEAVE_TIME_S] =
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_faction_mgr:set_leave_time(pkt.leave_time,pkt.flag,pkt.kick_time)
end

--查看别的帮派信息
Sv_commands[0][CMD_P2M_FACTION_INFO2_REP] =
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_cltsock_mgr:send_client(char_id, CMD_M2B_FACTION_INFO2_S, pkt)
end


--------------------------------------------------------------------------------------------------------
-- 玩家选中帮派副本等级
Clt_commands[1][CMD_CHOOSE_FACTION_FB_LEVEL_B] = 
function(conn, pkt)
	if conn and conn.char_id and pkt and pkt.choose_fb_level then
		g_faction_mgr:set_choose_fb_level(conn.char_id, pkt.choose_fb_level)
	end
end

--玩家上线
Clt_commands[1][CMD_B2M_FACTION_PLAYER_INFO_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:online(conn.char_id)
end

--创建帮派 ok
Clt_commands[1][CMD_B2M_FACTION_CREATE_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:create_faction(conn.char_id,pkt)
end

--帮派列表信息 ok
Clt_commands[1][CMD_B2M_FACTION_LIST_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:get_faction_list(conn.char_id)
end

--帮派信息 ok
Clt_commands[1][CMD_B2M_FACTION_INFO_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	--g_faction_mgr:get_faction_info(conn.char_id,pkt)
end

--帮派信息2
Clt_commands[1][CMD_B2M_FACTION_INFO2_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:get_faction_info(conn.char_id,pkt)
end

--申请加入帮派
Clt_commands[1][CMD_B2M_FACTION_JOIN_C] =
function(conn,pkt)
	if conn.char_id == nil or pkt == nil then return end
	g_faction_mgr:join(conn.char_id,pkt)
end

--申请退出帮派
Clt_commands[1][CMD_B2M_FACTION_OUT_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:out(conn.char_id,pkt)
end

--邀请人加入
Clt_commands[1][CMD_B2M_FACTION_ADD_PLAYER_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:add_player(conn.char_id,pkt)
end

--踢人
Clt_commands[1][CMD_B2M_FACTION_KICK_PLAYER_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:kick_player(conn.char_id,pkt)
end

--职务卸任
Clt_commands[1][CMD_B2M_FACTION_POST_OUTGOING_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:post_outing(conn.char_id,pkt)
end

--批准加入帮派
Clt_commands[1][CMD_B2M_FACTION_APPROVE_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:approve(conn.char_id,pkt)
end

--拒绝加入帮派
Clt_commands[1][CMD_B2M_FACTION_REFUSE_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:refuse(conn.char_id,pkt)
end

--保存管理公告 
Clt_commands[1][CMD_B2M_FACTION_ANNOUNCEMENT_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:save_announcement(conn.char_id,pkt)
end

--任命
Clt_commands[1][CMD_B2M_FACTION_APPOINTMENT_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:appointment(conn.char_id,pkt)
end

--玩家确定加入
Clt_commands[1][CMD_B2M_FACTION_JOIN_CONF_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:join_conf(conn.char_id,pkt)
end


--招募广告
Clt_commands[1][CMD_B2M_FACTION_BROADCAST_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:broadcast(conn.char_id,pkt)
end

--获取招募信息
Clt_commands[1][CMD_B2M_FACTION_RECRUIT_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:recruit(conn.char_id,pkt)
end

--获取任免职务信息 ok
Clt_commands[1][CMD_B2M_FACTION_POST_INFO_C] =
function(conn,pkt)
	if conn.char_id ~=nil then
		g_faction_mgr:post_info(conn.char_id,pkt)
	end
end

--获取职务名 ok
Clt_commands[1][CMD_B2M_FACTION_POST_NAME_C] =
function(conn,pkt)
	if conn.char_id ~=nil then
		g_faction_mgr:get_post_name_ex(conn.char_id,pkt)
	end
end

--获取帮派成员列表
Clt_commands[1][CMD_B2M_FACTION_MEMBER_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:get_faction_member(conn.char_id,pkt)
end


--帮派升级（演武厅，观星阁，金库，建设点，科技点，帮贡）统一接口
Clt_commands[1][CMD_B2M_FACTION_UPDATE_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:update_faction_level(conn.char_id,pkt)
end

--技能升级
Clt_commands[1][CMD_B2M_FACTION_SKILL_C] =
function(conn,pkt)
--	print("in CMD_B2M_FACTION_SKILL_C")
--	print(j_e(pkt))
	if conn.char_id == nil then return end
	g_faction_mgr:update_action_practice(conn.char_id,pkt)
end

--BUF升级
Clt_commands[1][CMD_B2M_FACTION_BUF_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:update_buf_practice(conn.char_id,pkt)
end

--帮派关系
Clt_commands[1][CMD_B2M_FACTION_RELATE_INFO_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:get_faction_relate(conn.char_id,pkt)
end

--修改帮派关系
Clt_commands[1][CMD_B2M_FACTION_RELATE_UPDATE_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:update_relate(conn.char_id,pkt)
end

--权限设置
Clt_commands[1][CMD_B2M_FACTION_PERMISSION_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:permission(conn.char_id,pkt)
end


--获取工资单
Clt_commands[1][CMD_B2M_FACTION_SALARY_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:get_salary(conn.char_id,pkt)
end

--获取工资单
Clt_commands[1][CMD_B2M_FACTION_OBTAINSALARY_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:fetch_salary(conn.char_id,pkt)
end

--摇钱树 屏蔽摇钱树消息处理 121114 chendong
--[[
--摇钱树
Clt_commands[1][CMD_B2M_FACTION_MONEY_TREE_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:irrigation(conn.char_id,pkt)
end
--]]

--获取历史信息
Clt_commands[1][CMD_B2M_FACTION_HISTORY_INFO_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:get_history_info(conn.char_id,pkt)
end

--使用道具加速升级
Clt_commands[1][CMD_B2M_FACTION_SUB_TIME_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:use_faction_subtime_item(conn.char_id,pkt)
end

--主动解散
Clt_commands[1][CMD_B2M_FACTION_DISSOLVE_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	g_faction_mgr:faction_dissolve(conn.char_id, pkt)
end

--帮派合并
Clt_commands[1][CMD_B2M_FACTION_MERGE_C] =
function(conn,pkt)
	if conn.char_id == nil then return end
	local obj_s = g_obj_mgr:get_obj(conn.char_id)
	if obj_s == nil then return end
	if not obj_s:is_alive() then return end

	local team_id = obj_s:get_team()

	local team_obj = g_team_mgr:get_team_obj(team_id)
	if not team_obj then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = 26058}) end
	local team_l ,team_count = team_obj:get_team_l()
	if team_count > 2 or team_count <= 1 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = 26059}) end

	if team_obj:get_teamer_id() ~= conn.char_id then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = 26060}) end

	for k, v in pairs(team_l) do
		if k ~= conn.char_id and v["status"] == LINE_ON then
			local obj_d = g_obj_mgr:get_obj(k)
			if not obj_d:is_alive() then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = 26062}) end
			local result = g_faction_mgr:can_be_faction_merge(conn.char_id, k)
			if result ~= 0 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = result}) end

			g_cltsock_mgr:send_client(k, CMD_M2B_FACTION_MERGE_REQ_S, {})
			break
		end
	end
end

--确定合并与否
Clt_commands[1][CMD_B2M_FACTION_MERGE_CONF_C] =
function(conn,pkt)
	if conn.char_id == nil or pkt == nil then return end
	
	local obj_d = g_obj_mgr:get_obj(conn.char_id)
	if obj_d == nil then return end
	if not obj_d:is_alive() then return end

	local team_id = obj_d:get_team()

	local team_obj = g_team_mgr:get_team_obj(team_id)
	if not team_obj then return end
	local team_l ,team_count = team_obj:get_team_l()
	if team_count > 2 or team_count <= 1 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = 26059}) end

	if team_obj:get_teamer_id() == conn.char_id then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = 26061}) end
	if pkt.flag == 1 then
		for k,v in pairs(team_l) do
			if k ~= conn.char_id and v["status"] == LINE_ON then
				local obj_s = g_obj_mgr:get_obj(k)
				if obj_s == nil then return end
				if not obj_s:is_alive() then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = 26062}) end

				local result = g_faction_mgr:can_be_faction_merge(k, conn.char_id)
				if result ~= 0 then return g_cltsock_mgr:send_client(conn.char_id, CMD_M2B_FACTION_MERGE_S, {["result"] = result}) end
				g_faction_mgr:faction_merge(k, conn.char_id)
				break
			end
		end
	else
		for k,v in pairs(team_l) do
			if k ~= conn.char_id and v["status"] == LINE_ON then
				g_cltsock_mgr:send_client(k, CMD_M2B_FACTION_MERGE_S, {["result"] = 26063})
				break
			end
		end
	end
end

--帮派合并公共服返回g_cltsock_mgr:send_client(k, CMD_M2B_FACTION_MERGE_S, {["result"] = 0})

Sv_commands[0][CMD_P2M_FACTION_MERGE_S] =
function(conn,char_id,pkt)
	if pkt == nil then return end
	g_cltsock_mgr:send_client(pkt.obj_id_s, CMD_M2B_FACTION_MERGE_S, {["result"] = pkt.result})
	g_cltsock_mgr:send_client(pkt.obj_id_d, CMD_M2B_FACTION_MERGE_S, {["result"] = pkt.result})
end













