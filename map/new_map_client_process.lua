
local debug_print = function () end;

--local gbk_utf8 = iconv:New("gbk", "utf-8")
local _sf = require("scene_ex.scene_process")
local _sk = require("skill.skill_process")
local _im = require("impact.impact_process")
local _cmd = require("map_cmd_func")
local _obj_ps = require("obj.obj_process")
local _collect = require("obj.npc.obj_npc_process")
local _pet_func = require("obj.pet.pet_process")

require("global")
require("global_function")
require("item_cache")
local _item_cache_mgr = create_local("map_client_process._item_cache_mgr", item_cache())

local pri_spirit_cost = function(pet_obj) --计算练魂的费用
	local lv = pet_obj:get_level()
	local factor = 1
	local color = 1
	local pullulate = pet_obj.db.pullulate
	if pullulate > 95 then
		color = 5
	elseif pullulate > 85 then
		color = 4
	elseif pullulate > 75 then
		color = 3
	elseif pullulate > 65 then
		color = 2
	end

	return 0, factor * color * lv
end
    

--玩家进入
Clt_commands[0][CMD_MAP_PLAYER_ENTER_C] =
function(conn, pkt)
	if pkt == nil or pkt.key == nil then return end
	local new_pkt = {}
	new_pkt.result = 20001
	local char_id,acc_id,sign = g_key_mgr:parse_key(pkt.key)
	if char_id ~= nil then
		conn.acc_id = acc_id
		conn.sign = sign
		conn.char_id = char_id
		conn.ip = pkt.ip
		g_key_mgr:del_key(char_id)
		
		local param = {}
		param.s_id = pkt.s_id
		new_pkt.result = _cmd.f_enter_map(conn, char_id, param)
		new_pkt.obj_id = pkt.obj_id
		g_cltsock_mgr:send_client_ex(conn, CMD_MAP_PLAYER_ENTER_S, new_pkt)
	else
		--_cmd.f_leave_map(conn, 1)
		g_cltsock_mgr:send_client_ex(conn, CMD_MAP_PLAYER_LEAVE_S, {["result"] = 0, ["obj_id"] = pkt.obj_id})
	end
end


--玩家离开
Clt_commands[1][CMD_MAP_PLAYER_LEAVE_C] =
function(conn, pkt)
	if conn.char_id ~= nil then
		local obj = g_obj_mgr:get_obj(conn.char_id)
		if obj ~= nil then
			g_cltsock_mgr:send_client_ex(conn, CMD_MAP_PLAYER_LEAVE_S, {["result"]=0})
		end
	end
end

--switch通知玩家离开
Clt_commands[1][CMD_MAP_PLAYER_EXIT_S] =
function(conn, pkt)
	if conn.char_id ~= nil then
		_cmd.f_switch_leave_map(conn)
	end
end

--获取玩家所在地图信息
Clt_commands[1][CMD_MAP_ASK_PLAYER_MAP_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local scene = obj:get_scene_obj()
		
		if not scene then
			f_scene_error_log("Clt_commands[1][CMD_MAP_ASK_PLAYER_MAP_C](obj_id = %d, map_id = %s) Not Scene."
				, conn.char_id
				, tostring(obj:get_map_id()))
			return
		end
		
		local count = scene:get_count_copy(conn.char_id)
		local new_pkt = {}
		new_pkt.scene_id = scene:get_id()
		new_pkt.x = obj:get_pos()[1]
		new_pkt.y = obj:get_pos()[2]
		new_pkt.char_info = obj:net_get_self_info()
		new_pkt.time = scene:get_last_time(obj)
		if 0 ~= count then
			new_pkt.count = count
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ASK_PLAYER_MAP_S, new_pkt)
	end
end

--获取地图所有信息
Clt_commands[1][CMD_MAP_ASK_MAP_INFO_C] =
function(conn, pkt)
	debug_print("CMD_MAP_ASK_MAP_INFO_C")
	_sf.get_map_info(conn.char_id)
end

--玩家切换地图
Clt_commands[1][CMD_MAP_CHANGE_MAP_C] =
function(conn, pkt)
	if pkt.map_id == nil then return end
	_sf.change_scene(conn.char_id, pkt.map_id)
end

--玩家行走
Clt_commands[1][CMD_MAP_PLAYER_MOVE_C] =
function(conn, pkt)
	--_sf.move(conn.char_id, pkt[1], pkt[2], pkt[3])
	_sf.move_st(conn.char_id, pkt)
end

--玩家镜像行走
Clt_commands[1][CMD_MAP_GHOST_MOVE_C] =
function(conn, pkt)
	--_sf.move(conn.char_id, pkt[1], pkt[2], pkt[3])
	_sf.ghost_move(conn.char_id, pkt)
end

--玩家停止包
Clt_commands[1][CMD_MAP_PLAYER_STOP_C] =
function(conn, pkt)
	_sf.stop(conn.char_id)
end

--心跳包
Clt_commands[1][CMD_MAP_PULSE_C] =
function(conn, pkt)
	local new_pkt = {}
	new_pkt.time = ev.time
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PULSE_S, new_pkt)
end

--获取自己基本属性
Clt_commands[1][CMD_MAP_ASK_SELF_ATT_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local new_pkt = obj:net_get_att_info(1)
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ASK_SELF_ATT_S, new_pkt)
	end
end

--获取副本进入次数信息
Clt_commands[1][CMD_MAP_OBJ_COPY_INFO_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local copy_con = obj:get_copy_con()
		local new_pkt = copy_con:net_get_list_copy()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OBJ_COPY_INFO_S, new_pkt)
	end
end

--设置时装外观
Clt_commands[1][CMD_MAP_OBJ_OUTLOOK_SET_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		obj:set_outlook_flag(pkt.flag)
		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.flag = obj:get_outlook_flag()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OBJ_OUTLOOK_SET_S, new_pkt)
	end
end



--获取其他玩家详细属性(在线或不在线)
--[[local callback_attr_func = function(obj, param, pkt)
	local char_id = param.obj_id
	g_cltsock_mgr:send_client(char_id, CMD_MAP_ASK_HUMAN_ATT_S, pkt)
end]]--
Clt_commands[1][CMD_MAP_ASK_HUMAN_ATT_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end

	local obj = g_obj_mgr:get_obj(pkt.obj_id)
	if obj ~= nil then                      --在线
		if obj:get_type() == OBJ_TYPE_HUMAN then
			local new_pkt = {}
			new_pkt.info = obj:net_get_info()
			new_pkt.attribute = obj:net_get_att_info(1)
			local pack_con = obj:get_pack_con()
			new_pkt.equip = pack_con:get_equip_ex()
			
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ASK_HUMAN_ATT_S, new_pkt)
		else
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ASK_HUMAN_ATT_S, {["result"]=20034})
		end
	else                                  --不在线
		--[[local param = {}
		param.obj_id = pkt.obj_id
		g_sock_event_mgr:add_event(conn.char_id, CMD_C2M_GET_HUMAN_ATTR_REP, nil, callback_attr_func, nil, param, 3)]]--
		g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_GET_HUMAN_ATTR_ACK, pkt)  
	end
end

--查看仙灵信息
Clt_commands[1][CMD_MAP_CHILD_RANK_INFO_B] =
function(conn, pkt)
	if pkt == nil or pkt.owner_id == nil or pkt.child_id == nil then return end
	--print("==>CMD_MAP_CHILD_RANK_INFO_B")
	local obj = g_obj_mgr:get_obj(pkt.obj_id)
	if obj ~= nil then                      --在线
		
		if obj:get_type() == OBJ_TYPE_HUMAN then
			local children_con = obj:get_children_con()
			if not children_con then return end

			local child_obj = children_con:get_child_obj(pkt.child_id)
			if not child_obj then return end

			local ret = {}
			ret[1] = {}
			ret[1][1] = g_char_mgr:get_child_info_from_line(pkt.owner_id, pkt.child_id)
			ret[2] = pkt.owner_id
			--print("CMD_MAP_CHILD_RANK_INFO_B==>", j_e(ret))
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHILD_RANK_INFO_S, ret)
		else
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHILD_RANK_INFO_S, {["result"]=20034})
		end
	else                                  --不在线
		--[[local param = {}
		param.obj_id = pkt.obj_id
		g_sock_event_mgr:add_event(conn.char_id, CMD_C2M_GET_HUMAN_ATTR_REP, nil, callback_attr_func, nil, param, 3)]]--
		g_svsock_mgr:send_server_ex(COMMON_ID, conn.char_id, CMD_M2C_GET_CHILD_ATTR_ACK, pkt)  
	end
end


--选定目标对象
Clt_commands[1][CMD_MAP_SELECT_OBJ_C] =
function(conn, pkt)
	if pkt == nil then return end

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		obj:set_select_obj_id(pkt.obj_id)

		--同步目标对象信息
		if pkt.obj_id ~= nil then
			local obj_d = g_obj_mgr:get_obj(pkt.obj_id)
			if obj_d ~= nil then
				local new_pkt = obj_d:net_get_instant_info()
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OBJ_ATT_SYN_S, new_pkt)
			end
		end
	end
end

--玩家复活
Clt_commands[1][CMD_MAP_OBJ_RELIVE_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local new_pkt = {}
		new_pkt.result = obj:relive(pkt.flag)
		if obj:get_map_id() == 4201000 and (pkt.flag == 3 or pkt.flag == 2)and new_pkt.result == 0 then
			local sce = 10
			f_prop_god(obj, sce)
			f_prop_silence(obj, sce)
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OBJ_RELIVE_S, new_pkt)
	end
end

--手动升级
Clt_commands[1][CMD_MAP_OBJ_MANUAL_UPGRADE_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local ret = obj:unauto_exp()
		if ret ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OBJ_MANUAL_UPGRADE_S, {["result"]=ret})
		end
	end
end

--修改玩家称号
Clt_commands[1][CMD_MAP_OBJ_SET_TITLE_C] =
function(conn, pkt)
	if pkt == nil or pkt.title == nil then return end

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.title = obj:set_title(pkt.title)
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OBJ_SET_TITLE_S, new_pkt)
	end
end

--修改玩家签名
Clt_commands[1][CMD_MAP_OBJ_SET_SIGN_C] =
function(conn, pkt)
	if pkt == nil or pkt.sign == nil then return end

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local new_pkt = {}
		new_pkt.result = 0
		new_pkt.sign = obj:set_sign(pkt.sign)
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_OBJ_SET_SIGN_S, new_pkt)
	end
end

--**********宠物*************
--获取宠物列表
Clt_commands[1][CMD_MAP_PET_GET_LIST_C] =
function(conn, pkt)
	_pet_func.get_list(conn.char_id)
end

--放生
Clt_commands[1][CMD_MAP_PET_DEL_OBJ_C] =
function(conn, pkt)
	if pkt.obj_id == nil then return end
	_pet_func.del_pet(conn.char_id, pkt.obj_id)
end

--获取宠物属性
Clt_commands[1][CMD_MAP_PET_GET_ATT_C] =
function(conn, pkt)
	if pkt.obj_id == nil then return end
	_pet_func.get_attr(conn.char_id, pkt.obj_id)
end

--宠物跳动
Clt_commands[1][CMD_MAP_PET_LEAP_C] =
function(conn, pkt)
	if pkt.obj_id == nil or pkt.x_end == nil or pkt.y_end == nil then return end
	_pet_func.leap(conn.char_id, pkt.obj_id, {pkt.x_end, pkt.y_end})
end

--设置状态
Clt_commands[1][CMD_MAP_PET_SET_STATUS_C] =
function(conn, pkt)
	if pkt.obj_id == nil or pkt.combat == nil then return end
	_pet_func.set_status(conn.char_id, pkt.obj_id, pkt.combat)
end

--行走
Clt_commands[1][CMD_MAP_PET_MOVE_C] =
function(conn, pkt)
	--_sf.pet_move(conn.char_id, pkt[1], pkt[2], pkt[3])
	_sf.pet_move_st(conn.char_id, pkt)
end

--停止包
Clt_commands[1][CMD_MAP_PET_STOP_C] =
function(conn, pkt)
	_sf.pet_stop(conn.char_id)
end

--修改名称
Clt_commands[1][CMD_MAP_PET_ALTER_NAME_C] =
function(conn, pkt)
	if pkt.obj_id == nil or pkt.name == nil then return end
	_pet_func.alter_name(conn.char_id, pkt.obj_id, pkt.name)
end

--宠物洗髓
Clt_commands[1][CMD_MAP_PET_WASH_PITH_C] = 
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil or not pkt.slot_l or not pkt.count then return end
	_pet_func.wash_pulp(conn.char_id, pkt.obj_id, pkt.slot_l, pkt.count)
end

--选择洗髓属性
Clt_commands[1][CMD_MAP_PET_CHOICE_ATTR_B] = 
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil or not pkt.index then return end
	_pet_func.choice_wash_pulp(conn.char_id, pkt.obj_id, pkt.index)
end

--重新分配属性
Clt_commands[1][CMD_MAP_PET_RESET_ATTR_B] = 
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil or not pkt.type or 
		(pkt.type ~= 1 and pkt.type ~= 0) or not pkt.attr_l then return end
	_pet_func.reset_pulp(conn.char_id, pkt.obj_id, pkt.type, pkt.attr_l)
end

--宠物提升
Clt_commands[1][CMD_MAP_PET_ASCENSION_C] =  
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end
	_pet_func.ascension_pet(conn.char_id, pkt.obj_id, pkt.item_id)
end

--炼魂
Clt_commands[1][CMD_MAP_PET_TO_SPIRIT_C] =
function(conn, pkt)
	if not pkt or not pkt.obj_id then
		local s_pkt = {};
		s_pkt.result = 22005;							--该宠物不存在
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_S, s_pkt)
		return
	end

	local pet_id = pkt.obj_id
	local player = g_obj_mgr:get_obj(conn.char_id)
	local pack_con = player:get_pack_con()				--人物背包
	if pack_con:check_money_lock(MoneyType.GOLD) then
		return
	end
	local pet_con = player:get_pet_con()				--人物宠物栏
	local pet_obj = pet_con:get_pet_obj(pet_id)

	if not pet_obj then
		local s_pkt = {};
		s_pkt.result = 22005;
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_S, s_pkt)
		return
	end
	
	local lock_time = pet_obj:get_lock_time()
	if lock_time and lock_time > ev.time then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_S, {["result"] = 21070})
		return
	end

	if pet_obj:get_p_flag() == 1 then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_S, {["result"] = 20997})
	end

	if pet_obj:is_on_breed() then
		return g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_S, {["result"] = 22353})
	end

	local pet_equip = pet_obj:get_pack_con()
	if not pet_equip:is_empty() then
		local pkt = {}
		pkt.result = 22040
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_S, pkt)
		return
	end

	local ret_code = 22005;
	if pet_obj then
		ret_code = 22004								--宠物正在出战状态
		if PET_STATUS_REST == pet_obj:get_combat_status() then
			local cost = 0
			ret_code, cost = pri_spirit_cost(pet_obj)
			--扣钱
			local money = pack_con:get_money()
			if money.gold < cost then
				ret_code = 22014
			end

			if 0 == ret_code then
				
				local char_name = player:get_name()
				local pet_name = pet_obj:get_name()
				local pet_class = pet_obj:get_occ()
				local web_remark = f_get_je_pet_info(pet_obj)
				local skill_con = pet_obj:get_skill_con()
				web_remark.pet_skill_list = skill_con:get_skill_list()
				web_remark.pet_effective_list = skill_con:get_effective_list()

				--local pet_spirit = Pet_spirit()
				local pet_spirit = nil
				local pet_possess_obj = pet_obj:get_possess_obj()
				if not pet_possess_obj then return end
				if pet_obj:is_on_possess() then
					pet_possess_obj:set_possess_flag(0)
					local info = pet_con:get_possess_skill()
					player:update_appendage_skill(info)
					player:on_update_attribute(2)
				end

				ret_code, pet_spirit = Item_factory.create(113010000120)
				if 0 == ret_code and pet_spirit:load_pet(pet_obj) then
					ret_code = 10000
					local bag, slot = nil, nil
					ret_code = pack_con:add_by_item(pet_spirit, {['type']=ITEM_SOURCE.PET_SPIRIT})

					if 0 == ret_code then

						ret_code = 22005
						if pet_con:del_obj(pet_id) then
							pack_con:dec_money(MoneyType.GOLD, cost, {['type']=MONEY_SOURCE.PET_SPIRIT}) --加入成功,进行扣钱
							local new_pkt = {}
							new_pkt.result = 0
							new_pkt.obj_id = pet_id
							g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_DEL_OBJ_S, new_pkt)
							ret_code = 0

							local str = string.format("char_id: %d obj_id: %d spirit: %d", 
							conn.char_id or 0, pet_id or 0, pet_id or 0)
							g_pet_log:write(str)
	

							local io = 0
							local type = 8
							--后台流水记录
							local str = string.format("insert into log_pet set char_id=%d,pet_id=%d,char_name='%s',pet_name='%s',pet_class=%d,io=%d,type=%d,time=%d,remark='%s'", 
							conn.char_id,pet_id,char_name,pet_name,pet_class,io,type,ev.time,Json.Encode(web_remark))
							f_multi_web_sql(str)

						elseif bag and slot then
							pack_con:del_item_by_bag_slot(bag, slot)				--删除宠物失败则删除加入的物品
						end
					end
				end
			end
		end
	end

	local s_pkt = {};
	s_pkt.result = ret_code;
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_S, s_pkt)
end

--宠物炼魂价格查询
Clt_commands[1][CMD_MAP_PET_TO_SPIRIT_COST_C] =
function(conn, pkt)
	if not pkt or not pkt.obj_id then
		local s_pkt = {};
		s_pkt.result = 22005
		s_pkt.cost = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_COST_S, s_pkt)
		return
	end

	local player = g_obj_mgr:get_obj(conn.char_id)
	local pet_con = player:get_pet_con()				--人物宠物栏
	local pet_obj = pet_con:get_pet_obj(pkt.obj_id)

	if not pet_obj then
		local s_pkt = {};
		s_pkt.result = 22005
		s_pkt.cost = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_COST_S, s_pkt)
		return
	end

	local ret_code = 22005;
	local cost = 0
	if pet_obj then
		ret_code, cost = pri_spirit_cost(pet_obj)
	end

	local s_pkt = {};
	s_pkt.result = ret_code
	s_pkt.cost = cost
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PET_TO_SPIRIT_COST_S, s_pkt)
end

--删除宠物技能
Clt_commands[1][CMD_MAP_PET_DEL_SKILL_C] =	
function(conn, pkt)
	_pet_func.del_pet_skill(conn, pkt)
end

--宠物融合
Clt_commands[1][CMD_MAP_PET_FUSION_C] =	
function(conn, pkt)
	_pet_func.fusion_pet(conn, pkt.main_obj_id, pkt.deputy_obj_id, pkt.special_skill)
end

--查看指定宠物信息
Clt_commands[1][CMD_MAP_PET_GET_INFO_C] =			
function(conn, pkt)
	_pet_func.other_pet_info(conn.char_id, pkt.obj_id)
end

--宠物魂化
Clt_commands[1][CMD_MAP_PET_SOUL_C] =			
function(conn, pkt)
	_pet_func.soul_pet(conn.char_id, pkt.slot, pkt.item_id)
end

--宠物吸魂
Clt_commands[1][CMD_MAP_PET_EQUIP_SOUL_C] =			
function(conn, pkt)
	_pet_func.equip_soul(conn.char_id, pkt.pet_id,pkt.equip_slot, pkt.slot_list)
end

--[[
--宠物祝福
Clt_commands[1][CMD_MAP_PET_BLESS_C] =			
function(conn, pkt)
	_pet_func.accept_bless(conn.char_id, pkt.obj_id)
end
--]]

--宠物修炼打开面板
Clt_commands[1][CMD_MAP_PET_PRACTICE_OPEN_C] =			
function(conn, pkt)
	if conn.char_id == nil then return end
	_pet_func.pet_practice_open(conn.char_id)
end

--宠物修炼
Clt_commands[1][CMD_MAP_PET_PRACTICE_C] =			
function(conn, pkt)
	if pkt == nil or pkt.time == nil or pkt.money_type == nil or pkt.obj_id == nil then return end
	_pet_func.pet_practice(conn.char_id,pkt.obj_id,pkt.time,pkt.money_type)
end

--结束修炼
Clt_commands[1][CMD_MAP_PET_PRACTICE_OVER_C] =			
function(conn, pkt)
	if pkt == nil or pkt.flag == nil or pkt.obj_id == nil then return end
	_pet_func.pet_practice_over(conn.char_id,pkt.flag,pkt.obj_id)
end

--快速完成
Clt_commands[1][CMD_MAP_PET_PRACTICE_FAST_FINISH_C] =			
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil or pkt.count == nil then return end
	_pet_func.pet_practice_fast_finish(conn.char_id,pkt.obj_id,pkt.count)
end

--延时
Clt_commands[1][CMD_MAP_PET_PRACTICE_DELAY_C] =			
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil or pkt.time == nil or pkt.money_type == nil then return end
	_pet_func.pet_practice_delay(conn.char_id,pkt.obj_id,pkt.time,pkt.money_type)
end

--宠物技能融合
Clt_commands[1][CMD_MAP_PET_SKILL_FUSION_C] =			
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil or pkt.skill_main == nil or pkt.skill_other == nil then return end
	_pet_func.pet_skill_fusion(conn.char_id, pkt.obj_id, pkt.skill_main, pkt.skill_other, pkt.item_id)
end

--宠物融合技能预览
Clt_commands[1][CMD_MAP_PET_SKILL_FUSION_SHOW_C] =			
function(conn, pkt)
	if pkt == nil or pkt.main_id == nil or pkt.deputy_id == nil then return end
	_pet_func.pet_fusion_show(conn.char_id, pkt.main_id, pkt.deputy_id)
end

--宠物融合技能拆分
Clt_commands[1][CMD_MAP_PET_SKILL_SPLIT_C] =			
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil or pkt.skill_id == nil then return end
	_pet_func.pet_fusion_split(conn.char_id, pkt.obj_id, pkt.skill_id)
end

--*********** 战斗 ***********
--获取技能
Clt_commands[1][CMD_MAP_GET_SKILL_LIST_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end
	_sk.get_list(conn.char_id, pkt.obj_id)
end

--获取宠物技能列表
Clt_commands[1][CMD_MAP_PET_SKILL_INFO_C] = 
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end
	_sk.get_pet_list(conn.char_id, pkt.obj_id)
end

--使用技能
Clt_commands[1][CMD_MAP_USE_SKILL_C] =
function(conn, pkt)
	if pkt == nil or pkt.skill_cmd == nil or pkt.obj_id == nil then
		return
	end
	local param = {}
	if pkt.x ~= nil and pkt.y ~= nil then
		param.pos = {pkt.x, pkt.y}
	end
	param.des_id = pkt.des_id
	_sk.use(conn.char_id, pkt.skill_cmd, pkt.obj_id, param)
end

--获取cd时间
Clt_commands[1][CMD_MAP_GET_CD_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end
	_sk.get_cd_time(conn.char_id, pkt.obj_id, pkt.skill_id)
end

--获取效果列表
Clt_commands[1][CMD_MAP_GET_IMPACT_LIST_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end
	_im.get_list(conn.char_id, pkt.obj_id)
end

--取消效果
Clt_commands[1][CMD_MAP_DEL_IMPACT_C] =
function(conn, pkt)
	if pkt == nil or pkt.id ~= 1502 then return end
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		f_del_impact(obj, pkt.id)
	end
end

--获取掉落包信息
Clt_commands[1][CMD_MAP_GET_BOX_INFO_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then
		return 
	end
	_obj_ps.get_box_info(conn.char_id, pkt.obj_id)
end

--取掉落包物品
Clt_commands[1][CMD_MAP_GET_BOX_STUFF_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then
		return 
	end
	_obj_ps.get_box_stuff(conn.char_id, pkt.obj_id, pkt.list)
end

-------pk--------
--获取pk模式
Clt_commands[1][CMD_MAP_GET_PK_MODE_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local mode = obj:get_pk_mode():get_mode()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GET_PK_MODE_S, {["mode"]=mode})
	end
end

--改变pk模式
Clt_commands[1][CMD_MAP_CHANGE_PK_MODE_C] =
function(conn, pkt)
	--print("--------Clt_commands[1][CMD_MAP_CHANGE_PK_MODE_C]", conn.char_id)
	if pkt == nil or pkt.mode == nil then return end

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local pk_mode = obj:get_pk_mode()
		local new_pkt = {}
		new_pkt.result = pk_mode:is_change(pkt.mode)
		if new_pkt.result == 0 then
			new_pkt.mode = pkt.mode
			pk_mode:set_mode(pkt.mode)
		else
			new_pkt.mode = pk_mode:get_mode()
		end
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHANGE_PK_MODE_S, new_pkt)
	end
end

--获取pk模式修改时间
Clt_commands[1][CMD_MAP_GET_PK_TIME_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local tm = obj:get_pk_mode():get_last_time()
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GET_PK_TIME_S, {["time"]=tm})
	end
end

--***************怪物**************

--**************聊天**************

--附近聊天
Clt_commands[1][CMD_MAP_AROUND_SAY_C] =
function(conn, pkt)
	--print("Clt_commands[1][CMD_MAP_AREA_SAY_C]", CMD_MAP_AERA_SAY_S, Json.Encode(pkt))
	if pkt == nil or pkt.say == nil then return end

	--if not pkt.say or type(pkt.say) ~= "string" then
		--return
	--end
--
	--if string.len(pkt.say) >= 70 then
		--return
	--end
--
	--if pkt.props and type(pkt.props) == "table" and table.getn(pkt.props) > 2 then
		--return
	--end

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		if true == obj:get_officer_con():is_need_ban() then return end --官职系统需要禁言
		--pkt.char_nm = obj:get_name()
		--pkt.obj_id = conn.char_id
		local scene_o = obj:get_scene_obj()
		scene_o:send_screen(conn.char_id, CMD_MAP_AROUND_SAY_S, pkt, 1)
	end

	--物品
	for k ,v in pairs(pkt.props or {})do	
		local item ={}
		item.item_data = v.item_data
		item.id = v.id
		--加入缓存
		_item_cache_mgr.value:do_work(v.id, item, 6)
	end
end

--组队聊天
Clt_commands[1][CMD_MAP_TEAM_SAY_C] =
function(conn, pkt)
	--print("Clt_commands[1][CMD_MAP_TEAM_SAY_C]", CMD_MAP_TEAM_SAY_S, Json.Encode(pkt))
	if pkt == nil or pkt.say == nil then return end

	--if not pkt.say or type(pkt.say) ~= "string" then
		--return
	--end
--
	--if string.len(pkt.say) >= 70 then
		--return
	--end
--
	--if pkt.props and type(pkt.props) == "table" and table.getn(pkt.props) > 2 then
		--return
	--end

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		local team_o = g_team_mgr:get_team_obj(obj:get_team())
		if team_o ~= nil then
			local s_pkt = pkt
			--s_pkt.char_nm = obj:get_name()
			--s_pkt.obj_id = conn.char_id

			s_pkt = Json.Encode(s_pkt or {})
			local l = team_o:get_team_l()
			for o_id,_ in pairs(l) do
				g_cltsock_mgr:send_client(o_id, CMD_MAP_TEAM_SAY_S, s_pkt, true)
			end
		end

		--物品
		for k ,v in pairs(pkt.props or {})do	
			local item ={}
			item.item_data = v.item_data
			item.id = v.id
			--加入缓存
			_item_cache_mgr.value:do_work(v.id, item, 3)
		end
	end
end


--大喇叭
Clt_commands[1][CMD_C2M_SEND_HORM_C] =
	function(conn, pkt)
		if not pkt then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end

		if true == player:get_officer_con():is_need_ban() then return end --官职系统需要禁言
		
		local pack_con = player:get_pack_con()

		local item = pack_con:get_item_by_item_id(131000000110)
		if not item then
			item = pack_con:get_item_by_item_id(131000000111)
		end

		if not item then 
			return --g_cltsock_mgr:send_client(conn.char_id, CMD_M2C_SEND_HORM_S, s_pkt)
		end

		local param ={}
		param.content = pkt
		local result = pack_con:use_item(player, item, param)

	end

--查看聊天物品
Clt_commands[1][CMD_MAP_CHAT_LOOK_ITEM_C] =
function(conn, pkt)
	if pkt == nil or pkt.id == nil or pkt.type == nil then return end
	local uuid = pkt.id
	local type = pkt.type
	if type ~= 3 and type ~= 6 and type ~= 5 then return end
	local item_data = _item_cache_mgr.value:get_item(uuid, type)
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHAT_LOOK_ITEM_S, item_data)
end

Clt_commands[1][CMD_MAP_SIDE_SAY_C] =
function(conn, pkt)
	--print("----", Json.Encode(pkt))
	if pkt == nil or pkt.say == nil then return end

	--if not pkt.say or type(pkt.say) ~= "string" then
		--return
	--end
--
	--if string.len(pkt.say) >= 70 then
		--return
	--end
--
	--if pkt.props and type(pkt.props) == "table" and table.getn(pkt.props) > 2 then
		--return
	--end

	g_chat_channal_mgr:say(conn.char_id, pkt.say)

	--物品
	for k ,v in pairs(pkt.props or {})do	
		local item ={}
		item.item_data = v.item_data
		item.id = v.id
		--加入缓存
		_item_cache_mgr.value:do_work(v.id, item, 5)
	end
end

--*******************防沉迷************************
--修改经验倍数
Clt_commands[1][CMD_MAP_ADDICTION_SET_SCALE_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if not obj or type(pkt.type) ~= "number" then return end
	local scale = pkt.type or 1
	scale = scale > 1 and 1 or scale	
	obj:set_misc(9,scale)
end

--**********在线领经验***********
Clt_commands[1][CMD_MAP_REWARD_EXP_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj ~= nil then
		--切换地图
		_sf.change_scene_cm(obj:get_id(), MAP_INFO_3, {316,346})
	end
end

--***************采集物品****************
Clt_commands[1][CMD_MAP_COLLECT_ITEM_START_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end 
	_collect.collect_start(conn.char_id, pkt.obj_id)
end

Clt_commands[1][CMD_MAP_COLLECT_ITEM_CANCEL_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end 
	_collect.collect_cancel(conn.char_id, pkt.obj_id)
end

Clt_commands[1][CMD_MAP_COLLECT_ITEM_END_C] =
function(conn, pkt)
	if pkt == nil or pkt.obj_id == nil then return end 
	_collect.collect_end(conn.char_id, pkt.obj_id)
end

--****************批量添加好友****************
--获取批量添加好友当前次数
Clt_commands[1][CMD_MAP_ADDFRIEND_COUNT_C] =
function(conn,pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	local ret = {}
	ret.result = 0
	ret.count = player:get_misc(2)
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ADDFRIEND_COUNT_S, ret)
end

--批量添加好友
Clt_commands[1][CMD_MAP_ADDFRIENDLIST_C] =
function(conn,pkt)
	if not pkt or not pkt.list then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	local ret = {}
	ret.result = player:is_can_add()
	ret.count = player:get_misc(2)
	if ret.result == 0 then
		player:set_misc(2)	
		ret.count = player:get_misc(2)
		g_svsock_mgr:send_server_ex(WORLD_ID, conn.char_id, CMD_MAP_CHAT_ADDFRIENDLIST_S, pkt)
	end	
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_ADDFRIEND_COUNT_S, ret)
end

--激活暴走状态
Clt_commands[1][CMD_ACTIVATE_RAGE_STATE_B] =
function(conn,pkt)

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	player:activate_rage()
end

--询问是否可领升级礼包
Clt_commands[1][CMD_CHECK_LEVEL_GIFT_B] =
function(conn,pkt)

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end

	g_cltsock_mgr:send_client(conn.char_id, CMD_CHECK_LEVEL_GIFT_S, {lvl = player:get_level_gift_lvl()})
end

--领取升级礼包
Clt_commands[1][CMD_GET_LEVEL_GIFT_B] =
function(conn,pkt)

	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	player:get_level_gift_item()
end

