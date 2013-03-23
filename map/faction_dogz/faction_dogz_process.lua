-- 帮派神兽
-- CodeBy:cailizhong
-- 2012/8/10

local faction_dogz_config = require("config.xml.faction_dogz.faction_dogz_config")

Clt_commands[1][CMD_GET_FACTION_DOGZ_INFO_B] = 
function(conn, pkt)
	if conn and conn.char_id then
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_GET_FACTION_DOGZ_INFO_M, pkt)
	end
end

Sv_commands[0][CMD_GET_FACTION_DOGZ_INFO_C] = 
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_GET_FACTION_DOGZ_INFO_S, pkt)
end

-- 领养神兽
Clt_commands[1][CMD_ADOPT_DOGZ_B] = 
function(conn, pkt)
	if conn and conn.char_id and pkt and pkt.dogz_id then
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_ADOPT_DOGZ_M, pkt)
	end
end

Sv_commands[0][CMD_ADOPT_DOGZ_C] = 
function(conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_ADOPT_DOGZ_S, pkt)
end

-- 神兽互动
Clt_commands[1][CMD_ACT_DOGZ_B] = 
function(conn, pkt)
	if conn==nil or conn.char_id==nil or pkt==nil or pkt.dogz_id==nil or pkt.act_type==nil then return end
	if pkt.act_type==3 and pkt.soul==nil then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_ACT_DOGZ_M, pkt)
end

-- 神兽互动检查(喂养操作检查)
Sv_commands[0][CMD_CHECK_ACT_DOGZ_C] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt and pkt.soul then
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		-- 扣除多个
		local soulVal = 0
		local t_list = {}
		local t_slot_list = {}
		for _, v in pairs(pkt.soul or {}) do
			if type(v) == "table" then
				local bag = v.bag
				local slot = v.slot
				local count = v.count
				if count ~= 1 then return end -- 魂魄不能叠加
				if t_slot_list[bag] == nil then
					t_slot_list[bag] = {}
				end
				if t_slot_list[bag][slot] ~= nil then return end
				t_slot_list[bag][slot] = true
				local t_item = pack_con:get_item_by_bag_slot(bag, slot)
				local soul_item = t_item and t_item.item
				if not soul_item then return end
				if soul_item:get_m_class()~=1 or soul_item:get_s_class()~=43 then return end -- 检查是否是魂魄
				soulVal = soulVal + (f_calc_quality(soul_item:change_attr()) or 0) * (count or 0)
				local tmp_item = {bag, slot, count}
				table.insert(t_list, tmp_item)
			else return
			end
		end
		local e_code = pack_con:del_item_by_bags_slots(t_list, {['type']=ITEM_SOURCE.FACTION_DOGZ}, 1)
		local ret = pkt
		ret.soulVal = soulVal
		g_sock_event_mgr:set_event_id(char_id, pkt, ret)
		if e_code ~= 0 then
			local ret = {}
			ret.result = e_code
			return g_cltsock_mgr:send_client(char_id, CMD_ACT_DOGZ_S, ret)
		end
		g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_CHECK_ACT_DOGZ_S, ret)
	end
end

Sv_commands[0][CMD_ACT_DOGZ_C] = 
function(conn, char_id, pkt)
	if conn and char_id then
		if pkt and pkt.result==0 then
			if pkt.act_type == 1 then
				local player = g_obj_mgr:get_obj(char_id)
				if not player then return end
				player:add_exp(player:get_level() * faction_dogz_config.TRAIN_ADD_EXP) -- 增加经验
			elseif pkt.act_type == 2 then -- 玩耍增加帮贡
				local val = crypto.random(faction_dogz_config.play_add_contribution_range[1], faction_dogz_config.play_add_contribution_range[2])
				local t_pkt = {}
				t_pkt.flag = 6
				t_pkt.param = val
				g_faction_mgr:update_faction_level(char_id, t_pkt)
			elseif pkt.act_type == 3 then -- 喂养增加帮贡
				local val = faction_dogz_config.FEED_ADD_CONTRIBUTION * pkt.cnt
				local t_pkt = {}
				t_pkt.flag = 6
				t_pkt.param = val
				g_faction_mgr:update_faction_level(char_id, t_pkt)
			end
		end
		local ret = {}
		ret.act_type = pkt.act_type
		ret.val = pkt.add_val
		ret.result = pkt.result
		g_cltsock_mgr:send_client(char_id, CMD_ACT_DOGZ_S, ret)
	end
end

-- 神兽召唤
Clt_commands[1][CMD_CALL_DOGZ_B] = 
function(conn, pkt)
	if conn and conn.char_id and pkt and pkt.dogz_id then
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_CALL_DOGZ_M, pkt)
	end
end

Sv_commands[0][CMD_CHECK_CALL_DOGZ_C] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt and pkt.dogz_id and pkt.stage then
		local e_code = _f_summon_dogz(char_id, pkt.dogz_id, pkt.stage) -- 开启神兽副本入口
		local ret = pkt
		g_sock_event_mgr:set_event_id(char_id, pkt, ret)
		if e_code ~= 0 then
			local ret = {}
			ret.result = e_code
			return g_cltsock_mgr:send_client(char_id, CMD_CALL_DOGZ_S, ret)
		end
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_CHECK_CALL_DOGZ_S, ret)
	end
end

Sv_commands[0][CMD_CALL_DOGZ_C] = 
function(conn, char_id, pkt)
	if conn and char_id then
		if pkt and pkt.result==0 then
		-- 发放奖励
			print(j_e(pkt.top_n_list))
			local top_n = faction_dogz_config.TOP_N
			for i = 1, top_n do
				if pkt.top_n_list[i] == nil then break end
				local reward_list = faction_dogz_config.get_the_n_reawrd(i)
				local item_list = {}
				for k, v in pairs(reward_list) do
					local item_id = v[1]
					local count = v[2]
					local e_code, item = Item_factory.create(item_id)
					local name = item:get_name() or ""
					local new_item = {}
					new_item.id = item_id
					new_item.count = count
					new_item.name = name
					table.insert(item_list, new_item)
				end
				for k, v in pairs(pkt.top_n_list[i] or {}) do
					local t_pkt = {}
					t_pkt.sender = -1
					t_pkt.recevier = v
					t_pkt.title = f_get_string(2929)
					t_pkt.content = f_get_string(2930)
					t_pkt.box_title = f_get_string(2929)
					t_pkt.item_list = item_list
					t_pkt.money_list = {}
					g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, t_pkt)
				end
			end
		end
		local ret = {}
		ret.result = pkt.result
		g_cltsock_mgr:send_client(char_id, CMD_CALL_DOGZ_S, ret)
	end
end

