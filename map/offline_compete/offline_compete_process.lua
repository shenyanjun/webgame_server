
local config = require("scene_ex.config.compete_config_loader")
local update_list = {}
--报名
Clt_commands[1][CMD_MAP_OFFLINE_COMPETE_SIGNUP_C] =
function(conn, pkt)
	--print("CMD_MAP_OFFLINE_COMPETE_SIGNUP_C")
	if conn.char_id == nil then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end

	if player:get_level() < 40 then 
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OFFLINE_COMPETE_SIGNUP_S, {result = 31411})
		return 
	end
	
	local tmp_t = player:get_player_attr()
	player.db:player_attr_update(tmp_t)

	local ret = {}
	ret.info = {
		0, --排名
		conn.char_id, --id
		player:get_name(), --名字
		player:get_level(), --等级
		player:get_occ(), --职业
		player:get_sex(), --性别
		player:get_fighting(), --战斗力
	}
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_OFFLINE_COMPETE_SIGNUP_C, ret)

end

--更新
Clt_commands[1][CMD_MAP_OFFLINE_COMPETE_UPDATE_C] =
function(conn, pkt)
	print("CMD_MAP_OFFLINE_COMPETE_UPDATE_C")

end

--挑战
Clt_commands[1][CMD_MAP_OFFLINE_COMPETE_CHALLENGE_C] =
function(conn, pkt)
	--print("CMD_MAP_OFFLINE_COMPETE_CHALLENGE_C")
	local player = g_obj_mgr:get_obj(conn.char_id)
	if update_list[conn.char_id] ~= player:get_fighting() then
		update_list[conn.char_id] = player:get_fighting()
		
		local tmp_t = player:get_player_attr()
		player.db:player_attr_update(tmp_t)

		local ret = {}
		ret.info = {
			0, --排名
			conn.char_id, --id
			player:get_name(), --名字
			player:get_level(), --等级
			player:get_occ(), --职业
			player:get_sex(), --性别
			player:get_fighting(), --战斗力
		}
		g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_OFFLINE_COMPETE_UPDATE_C, ret)
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_OFFLINE_COMPETE_CHALLENGE_C, {id = pkt.id})

end


--打开主面板
Clt_commands[1][CMD_MAP_OFFLINE_COMPETE_INFO_C] =
function(conn, pkt)
	--print("CMD_MAP_OFFLINE_COMPETE_INFO_C")
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_OFFLINE_COMPETE_INFO_C, pkt)
end

--竞技排行榜
Clt_commands[1][CMD_MAP_OFFLINE_COMPETE_RANKING_C] =
function(conn, pkt)
	--print("CMD_MAP_OFFLINE_COMPETE_RANKING_C")
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_OFFLINE_COMPETE_RANKING_C, pkt)
end

--领取奖励
Clt_commands[1][CMD_MAP_OFFLINE_COMPETE_REWARD_C] =
function(conn, pkt)
	--print("CMD_MAP_OFFLINE_COMPETE_REWARD_C")
	--检查背包空格
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	if pack_con:get_bag_free_slot_cnt() < 1 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OFFLINE_COMPETE_REWARD_S, {["result"] = E_BAG_FULL})
		return
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_OFFLINE_COMPETE_REWARD_C, pkt)
end

--cd
Clt_commands[1][CMD_MAP_OFFLINE_COMPETE_CD_C] =
function(conn, pkt)
	--print("CMD_MAP_OFFLINE_COMPETE_CD_C")
	--检查背包空格
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()
	local money_list = {}
	money_list[MoneyType.GOLD] = config.config[4901000].cd.cost		-- 只扣铜币
	local src_log = {["type"] = MONEY_SOURCE.COMPETE}
	local ret_code = pack_con:dec_money_l_inter_face(money_list, src_log, nil, nil)
	if ret_code ~= 0 then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OFFLINE_COMPETE_CD_S, {["result"] = ret_code})
		return
	end
	g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_OFFLINE_COMPETE_CD_C, pkt)
end

----------------------------------------------------
--公共服交互
--报名
Sv_commands[0][CMD_C2M_OFFLINE_COMPETE_SIGNUP_S] =
function(conn,char_id,pkt)
	
	g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_SIGNUP_S, pkt)
end

--更新
Sv_commands[0][CMD_C2M_OFFLINE_COMPETE_UPDATE_S] =
function(conn,char_id,pkt)
	
	g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_UPDATE_S, pkt)
end

--挑战
Sv_commands[0][CMD_C2M_OFFLINE_COMPETE_CHALLENGE_S] =
function(conn,char_id,pkt)
	--print("CMD_C2M_OFFLINE_COMPETE_CHALLENGE_S", j_e(pkt))
	if pkt.result ~= 0 then
		g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_CHALLENGE_S, pkt)
		return
	end
	--
	local char_id = conn.char_id
	local obj = g_obj_mgr:get_obj(char_id)
	local prototype = g_scene_mgr_ex:get_prototype(4901000)
	if not prototype or not obj then
		print("CMD_C2M_OFFLINE_COMPETE_CHALLENGE_S prototype")
		g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_CHALLENGE_S, {result = 10020})
		return 
	end
	--收起宠物
	local pet_con = obj:get_pet_con()
	local pet_id = pet_con:get_combat_pet_id()
	if pet_id then
		pet_con:set_combat_pet_id(pet_id, PET_STATUS_REST)
		local new_pkt = {}
		new_pkt.obj_id = pet_id
		new_pkt.combat = PET_STATUS_REST
		g_cltsock_mgr:send_client(char_id, CMD_MAP_PET_SET_STATUS_S, new_pkt)
	end
	local e_code, error_list = prototype:carry_scene(obj, {0, 0}, {be_challenge_id = pkt.be_challenge_id})
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		print("CMD_C2M_OFFLINE_COMPETE_CHALLENGE_S carry_scene", e_code)
		g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_CHALLENGE_S, {result = e_code})
		return 
	end
end

--打开主面板
Sv_commands[0][CMD_C2M_OFFLINE_COMPETE_INFO_S] =
function(conn,char_id,pkt)
	
	g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_INFO_S, pkt)
end

--竞技排行榜
Sv_commands[0][CMD_C2M_OFFLINE_COMPETE_RANKING_S] =
function(conn,char_id,pkt)
	
	g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_RANKING_S, pkt)
end

--领取奖励
Sv_commands[0][CMD_C2M_OFFLINE_COMPETE_REWARD_S] =
function(conn,char_id,pkt)
	--print("CMD_C2M_OFFLINE_COMPETE_REWARD_S", j_e(pkt))
	if not pkt.entry or not pkt.sp then 
		--print("error CMD_C2M_OFFLINE_COMPETE_REWARD_S")
		g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_REWARD_S, {["result"] = 31416})
		return 
	end
	local player = g_obj_mgr:get_obj(char_id)
	if not player then
		print("error CMD_C2M_OFFLINE_COMPETE_RANKING_S:", char_id, pkt.rank)
		g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_REWARD_S, {["result"] = 10001})
		g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2C_OFFLINE_COMPETE_REWARD_C, pkt)
		return
	end

	local new_item_list = {}
	local count = 1
	for k,v in pairs(pkt.entry) do
		new_item_list[count] = {}
		new_item_list[count]["item_id"]     = v[1]
		new_item_list[count]["type"]   		= 1
		new_item_list[count]["number"] 		= v[2]
		count = count + 1
	end
	local pack_con = player:get_pack_con()	
	if pack_con then
		local result = pack_con:add_item_l(new_item_list, {['type']=ITEM_SOURCE.COMPETE})
		if result ~= 0 then
			print("error CMD_C2M_OFFLINE_COMPETE_RANKING_S:", char_id, pkt.rank)
			g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_REWARD_S, {["result"] = result})
			g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2C_OFFLINE_COMPETE_REWARD_C, pkt)
			return
		end
	end
	player:add_sp(pkt.sp)
	g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_REWARD_S, {["result"] = 0})
end

--cd
Sv_commands[0][CMD_C2M_OFFLINE_COMPETE_CD_S] =
function(conn,char_id,pkt)
	
	g_cltsock_mgr:send_client(char_id, CMD_MAP_OFFLINE_COMPETE_CD_S, pkt)
end