
local _scene = require("config.scene_config")
local extend_config = require("scene_ex.config.extend_loader")
local pvp_config = require("scene_ex.config.pvp_battle_loader")

--地图传送,其他模块调用(天盾令)
function f_scene_carry(obj_id, map_id, pos)
	if map_id == nil or pos == nil or pos[1] == nil or pos[2] == nil then
		return 21001
	end

	local obj = g_obj_mgr:get_obj(obj_id)
	if obj then
		local target_config = g_scene_config_mgr:get_config(map_id)
		if not target_config then
			return SCENE_ERROR.E_SCENE_CLOSE
		end
		
		if not target_config.level or target_config.level > obj:get_level() then
			return SCENE_ERROR.E_LEVEL_DOWN
		end

		return g_scene_mgr_ex:push_scene(map_id, pos, obj)
	end
	
	return 20034
end

--同地图传送
function f_scene_change_pos(obj_id, map_id, pos)
	if map_id == nil or pos == nil or pos[1] == nil or pos[2] == nil then
		return 21001
	end

	local obj = g_obj_mgr:get_obj(obj_id)
	if obj then
		return g_scene_mgr_ex:change_pos(map_id, pos, obj)
	end
	
	return 20034
end

--是否副本
function f_scene_is_copy(map_id)
	return MAP_TYPE_COMMON ~= _scene._config[map_id].type
end
--是否动态入口
function f_scene_is_action_carry(id)
	return id > 3000000000
end

--仙境召唤神兽
function _f_summon_dogz(char_id, level, stage)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj == nil or obj:get_scene()[1] ~= 2901000 then
		return 22275
	end
	return obj:get_scene_obj():summon_dogz(char_id, level, stage)
end


module("scene_ex.scene_process", package.seeall)

--获取地图所有角色信息
get_map_info = function(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj then
		local e_code = g_scene_mgr_ex:enter_scene(obj)
		if SCENE_ERROR.E_SUCCESS == e_code then
			if not obj.map_flag then
				obj.map_flag = true
				--team
				g_team_mgr:online(obj:get_id(), obj:get_team())
				--buffer设置
				g_buffer_reward_mgr:online_char_buffer(obj:get_id())
				--离线修炼
				--g_off_mgr:online(obj:get_id())

			end
		end
	end
end


--玩家在地图中移动
--[[local move_pkt = {}
local move_pos = {}
move = function(obj_id, x_end, y_end, path_l)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:is_active() and obj:is_alive() and not obj:is_door() then
		local pos = obj:get_des_pos()
		move_pos[1] = x_end
		move_pos[2] = y_end

		local scene_o = obj:get_scene_obj()
		if not scene_o:is_validate_pos(move_pos) then
			return
		end

		move_pkt[1] = path_l
		move_pkt[2] = obj_id
		move_pkt[3] = obj:get_speed_t()

		obj:set_pos(pos)
		obj:set_des_pos(move_pos)

		scene_o:send_move_syn(obj_id, obj, pos, move_pos, move_pkt)

		--组位置同步
		obj:team_syn(3, nil)
	else
		print("------------ERROR:scene_func.move", obj, obj:is_active(), obj:is_alive(), obj:is_door())
		g_warning_log:write("ERROR:scene_func.move" .. tostring(obj:is_active()) .. tostring(obj:is_alive())
		 .. tostring(obj:is_door()))
	end
end]]--

move_st = function(obj_id, pkt)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:is_active() and obj:is_alive() and not obj:is_door() then
		--print("----------------1")
		local moveobj = CmdMove()
		if not moveobj:parse(pkt) then return end
		
		local pos = obj:get_des_pos()
		local move_pos = moveobj:getEndpos()

		--print("----------------2")
		local scene_o = obj:get_scene_obj()
		if not scene_o:is_validate_pos(move_pos) or scene_o:get_id() ~= moveobj:getScene() then
			return
		end

		obj:set_pos(pos)
		obj:set_des_pos(move_pos)
		
		--print("----------------3")
		local mvpkt = moveobj:getPkt()
		local movesyn = CmdMoveSyn()
		movesyn:setPathFromPkt(mvpkt)
		movesyn:setObjid(obj_id)
		movesyn:setSpeed(obj:get_speed_t())
		
		scene_o:send_move_syn(obj_id, obj, pos, move_pos, movesyn:serialize(), true)

		--组位置同步
		obj:team_syn(3, nil)
	else
		--print("------------ERROR:scene_func.move", obj, obj:is_active(), obj:is_alive(), obj:is_door())
		--g_warning_log:write("ERROR:scene_func.move" .. tostring(obj:is_active()) .. tostring(obj:is_alive())
		-- .. tostring(obj:is_door()))
	end
end

stop = function(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:is_moving() and not obj:is_door() then
		obj:modify_pos(obj:get_des_pos())
	end
end

ghost_move = function(obj_id, pkt)
	local obj = g_obj_mgr:get_obj(pkt.obj_id)
	if obj ~= nil then
		obj:set_pos(pkt.pos)
	end
end

--宠物行走
--[[pet_move = function(obj_id, x_end, y_end, path_l)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:is_alive() and not obj:is_door()then
		local pet_con = obj:get_pet_con()
		local pet_obj = pet_con:get_combat_pet()
		if pet_obj ~= nil and pet_obj:is_active() then
			local pos = pet_obj:get_des_pos()
			local des_pos = {x_end, y_end}

			local scene_o = pet_obj:get_scene_obj()
			if not scene_o:is_validate_pos(des_pos) then
				return
			end

			local new_pkt = {}
			new_pkt[1] = path_l
			new_pkt[2] = pet_obj:get_id()
			new_pkt[3] = obj:get_speed_t()

			pet_obj:set_pos(pos)
			pet_obj:set_des_pos(des_pos)

			scene_o:send_move_syn(pet_obj:get_id(), pet_obj, pos, des_pos, new_pkt)
		end
	end
end]]--

pet_move_st = function(obj_id, pkt)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and obj:is_alive() and not obj:is_door() then
		local pet_con = obj:get_pet_con()
		local pet_obj = pet_con:get_combat_pet()
		if pet_obj ~= nil and pet_obj:is_active() then
			local moveobj = CmdMove()
			if not moveobj:parse(pkt) then return end
			
			local pos = pet_obj:get_des_pos()
			local des_pos = moveobj:getEndpos()

			local scene_o = pet_obj:get_scene_obj()
			if scene_o == nil then
				local owner = obj:get_owner()
				owner = g_obj_mgr:get_obj(owner)
				print("scene is nil", Json.Encode(pet_obj.scene_d), Json.Encode(owner.scene_d))

			end
			if not scene_o:is_validate_pos(des_pos) or scene_o:get_id() ~= moveobj:getScene() then
				return
			end

			pet_obj:set_pos(pos)
			pet_obj:set_des_pos(des_pos)
			
			local mvpkt = moveobj:getPkt()
			local movesyn = CmdMoveSyn()
			movesyn:setPathFromPkt(mvpkt)
			movesyn:setObjid(pet_obj:get_id())
			movesyn:setSpeed(obj:get_speed_t())
			scene_o:send_move_syn(pet_obj:get_id(), pet_obj, pos, des_pos, movesyn:serialize(), true)
		end
	end
end

pet_stop = function(obj_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil and not obj:is_door() then
		local pet_con = obj:get_pet_con()
		local pet_obj = pet_con:get_combat_pet()
		if pet_obj ~= nil and pet_obj:is_moving() then
			pet_obj:modify_pos(pet_obj:get_des_pos())
		end
	end
end

--服务器切地图调用
change_scene_cm = function(obj_id, s_id, pos)
	local obj = g_obj_mgr:get_obj(obj_id)
	if obj ~= nil then 
		g_scene_mgr_ex:push_scene(s_id, pos, obj)
	end
end

--帮派庄园用于进入哪个副本采集
local mission_change_scene_l = {}
mission_change_scene_l[2904000] = {[2904000]=1, [2905000]=1, [2906000]=1, [2907000]=1, [2908000]=1}
mission_change_scene_l[2909000] = {[2909000]=1, [2910000]=1, [2911000]=1, [2912000]=1, [2918000]=1}
mission_change_scene_l[2913000] = {[2913000]=1, [2914000]=1, [2915000]=1}
mission_change_scene_l[2916000] = {[2916000]=1, [2917000]=1}

local mission_change_scene = function(obj_id, carry_id)
	--print("mission_change_scene", obj_id, carry_id)
	if mission_change_scene_l[carry_id] == nil then
		return carry_id
	end

	local obj = g_obj_mgr:get_obj(obj_id)
	local mission_con = obj and obj:get_mission_mgr()
	if not mission_con then 
		local new_pkt = {}
		new_pkt.result = 21309
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
		return -1 
	end
    local e_code, scene_id = mission_con:get_transport_s_id(mission_change_scene_l[carry_id])

	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local new_pkt = {}
		new_pkt.result = e_code
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
		return -1
	end

	return scene_id
end

--传送带切地图函数(详细判断) 注：动态副本carry_id为对象id
change_scene = function(obj_id, carry_id)
	if f_scene_is_action_carry(carry_id) then
		local carry_obj = g_obj_mgr:get_obj(carry_id)
		if carry_obj then
			local args = carry_obj:get_param()
			if args then
				carry_id = args.carry_id
				if not args.perpetual then
					carry_obj:leave()
				end
			end
		end
	end
	
	carry_id = mission_change_scene(obj_id, carry_id)
	if carry_id == -1 then 
		return 
	end

	--vip挂机场景根据队长等级传到不同副本
	if carry_id == 359 then
		local obj = g_obj_mgr:get_obj(obj_id)
		local team_o = obj and g_team_mgr:get_team_obj(obj:get_team())
		local teamer = team_o and g_obj_mgr:get_obj(team_o:get_teamer_id())
		if teamer then
			local level = teamer:get_level()
			if level < 50 then

			elseif level < 60 then
				carry_id = 360
			elseif level < 70 then
				carry_id = 361
			elseif level < 80 then
				carry_id = 362
			else
				carry_id = 366
			end
		end
	end

	local e_code, error_l = g_scene_mgr_ex:change_scene(obj_id, carry_id)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local new_pkt = {}
		new_pkt.result = e_code
		new_pkt.error_l = error_l
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
	end
end


--[[
函数功能：获取上钩的鱼的信息
参数：obj_id -- 角色ID
      hook -- 鱼钩类型
返回：空
--]]
local get_fishing_info = function( obj_id, hook )

  -- 获取场景实例
  local obj = g_obj_mgr:get_obj(obj_id)
  local instance = obj:get_scene_obj()

  if instance:get_type() ~= MAP_TYPE_FISH then
    --不在钓鱼副本中
    local pkt = {}
    pkt.result = 31361
    instance:send_human(obj_id, CMD_MAP_FISH_INRANGE_S, pkt )
    return
  end
    
  -- hook为0时，为获取可钓鱼次数
  if hook == 0 then
    local leftcount = instance:get_leftcount( obj_id )
    local pkt = {}
    pkt.leftcount = leftcount 
    pkt.result = 0 
    instance:send_human(obj_id, CMD_MAP_FISH_INRANGE_S, pkt )
    return
  end
   
    
  -- 产生鱼信息
  local res = instance:fish_inrange( obj_id, hook )
  -- print( "res:", res )
  if res ~= 0 then
    --发送失败信息
    local pkt = {}
    pkt.result = res 
    instance:send_human(obj_id, CMD_MAP_FISH_INRANGE_S, pkt )
    return
  end

  --发送鱼信息
  instance:send_fish_info( obj_id )
end

--[[
function: 处理大鱼上钩结果
@para:    obj_id -- 角色ID
          getflag -- 大鱼是否上钩，1：获取成功 2：获取失败
@ret:     nil
--]]
local get_bigfish = function( obj_id, getflag )
  -- 获取场景实例
  local obj = g_obj_mgr:get_obj(obj_id)
  local instance = obj:get_scene_obj()
  local pkt = {}

  if instance:get_type() ~= MAP_TYPE_FISH then
    --不在钓鱼副本中
    pkt.result = 31361
    instance:send_human(obj_id, CMD_MAP_FISH_GETBIG_S, pkt )
    return
  end
  
  local res,fishid = instance:handle_fish( obj_id, getflag )
  --print( res, fishid )
  pkt.result = res
  pkt.id = fishid
  instance:send_human(obj_id, CMD_MAP_FISH_GETBIG_S, pkt )
  return
  
end

--活动传送功能
Clt_commands[1][CMD_MAP_EXTEND_ACK] =
function(conn, pkt)
	if 0 == pkt.type then
		local args = g_scene_mgr_ex:get_extend(pkt.type)
		if args and args.timeout and ev.time < args.timeout then
			local info = args.args
			local scene = g_scene_mgr_ex:get_scene({info.id})
			if scene then
				local map_obj = scene:get_map_obj()
				local pos = map_obj:find_pos({info.min_x, info.max_x, info.min_y, info.max_y})
				change_scene_cm(conn.char_id, info.id, pos)
			end
		end
	elseif 1 == pkt.type then
		local scene_id = 30000
		local scene = g_scene_mgr_ex:get_scene({scene_id})
		if scene then
			local map_obj = scene:get_map_obj()
			--local pos = map_obj:find_pos({305, 335, 257, 300})
			local pos = map_obj:find_space(70, 20)
			change_scene_cm(conn.char_id, scene_id, pos)
		end
	end
end

Clt_commands[1][CMD_MAP_SCENE_LEAVE_ACK] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then 
		local scene = obj:get_scene_obj()
		if scene and scene.kickout then
			scene:kickout(conn.char_id)
		end
	end
end

Clt_commands[1][CMD_MAP_TD_USE_HELPER_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.TD == scene:get_type() then
			local new_pkt = {}
			new_pkt.result = 0
			if 1 == pkt.type then
				new_pkt.result = scene:summon_guard(conn.char_id, pkt.id)
			elseif 2 == pkt.type then
				new_pkt.result = scene:use_buff(conn.char_id, pkt.id)
			elseif 3 == pkt.type then
				new_pkt.result = scene:use_refresh(conn.char_id)
			end
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_TD_USE_HELPER_S, new_pkt)
		end
	end
end

Clt_commands[1][CMD_TD_EX_REFLASH_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.TD_EX == scene:get_type() then
			local new_pkt = {}
			new_pkt.result = scene:use_refresh(conn.char_id)
			g_cltsock_mgr:send_client(conn.char_id, CMD_TD_EX_REFLASH_S, new_pkt)
		end
	end
end

Clt_commands[1][CMD_TD_EX_GET_SKILL_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.TD_EX == scene:get_type() then
			local new_pkt = {}
			new_pkt.skill_l = scene:send_skill_list(conn.char_id)
			--g_cltsock_mgr:send_client(conn.char_id, CMD_TD_EX_GET_SKILL_S, new_pkt)
		end
	end
end

Clt_commands[1][CMD_TD_EX_USE_SKILL_C] =
function(conn, pkt)
	--print("CMD_TD_EX_USE_SKILL_C", CMD_TD_EX_USE_SKILL_C, j_e(pkt))
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		--print("scene_type", scene, SCENE_TYPE.TD_EX, scene:get_type() )
		if scene and SCENE_TYPE.TD_EX == scene:get_type() then
			local new_pkt = {}
			local item_id = pkt.item_id
			if not item_id then return end
			new_pkt.result = scene:use_skill(conn.char_id, item_id)
			--print("use_skill_result:", new_pkt.result)
			g_cltsock_mgr:send_client(conn.char_id, CMD_TD_EX_USE_SKILL_S, new_pkt)
		end
	end
end


Clt_commands[1][CMD_STORY_END_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.STORY == scene:get_type() then
			scene:end_play()
		end
	end
end

Clt_commands[1][CMD_MAP_FRENZY_RESULTS_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local result = {}
		result.type = pkt.type
		if pkt.type == nil or pkt.type == 1 then
			local t = obj:get_frenzy_param()
			result.info = {
				{t.kill or 0
				, obj:get_pack_con():get_money().honor or 0
				, (t.count or 0) + (t.win or 0) + (t.lost or 0)}
				, g_scene_mgr_ex:get_frenzy_result()
			}
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_FRENZY_RESULTS_S, result)
		elseif pkt.type == 3 then
			local t = obj:get_battlefield_param()
			result.info = {
				{t.kill or 0
				, obj:get_pack_con():get_money().honor or 0
				, (t.count or 0) + (t.win or 0) + (t.lost or 0)}
			}
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_FRENZY_RESULTS_S, result)
		end
		
	end
end

local jump_type_to_map_id = {
	2001001,	--幻境之塔
	2101000,	--神魔之井
	2601001,	--八阵图
	3101000,	--九宫棋局
	4001000,	--天狱之门
	3701001,	--云梦仙泽
}

Clt_commands[1][CMD_MAP_CHEATS_LIST_C] =
function(conn, pkt)
	if f_is_line_faction() or f_is_pvp() or f_is_line_ww() then
		local result = {}
		result.result = SCENE_ERROR.E_SUCCESS	
		result.type = pkt.type
		result.options = {}
		result.counter = {0, 0}
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHEATS_LIST_S, result)
		return
	end

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local args = obj:get_scene_args()
		local result = {}
		result.result = SCENE_ERROR.E_SUCCESS	
		result.type = pkt.type
		
		local map_id = jump_type_to_map_id[pkt.type]
		local config = g_scene_config_mgr:get_extend_config(map_id)
		if not config or not config.cheats then
			print("error: not config", map_id, conn.char_id)
			return
		end
		
		result.options = config.cheats.list
		result.counter = {0, 0}
		if 0 ~= g_vip_mgr:get_vip_info(conn.char_id) then
			local jump_limit = obj:get_addition(HUMAN_ADDITION.jump) or 0
			local jump_count = obj:get_copy_con():get_count_tower_jump(map_id) or 0
			result.counter[1] = math.max(jump_limit - jump_count, 0)
			result.counter[2] = jump_limit
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHEATS_LIST_S, result)
	end
end

Clt_commands[1][CMD_MAP_CHEATS_SET_C] =
function(conn, pkt)
	if f_is_line_faction() or f_is_pvp() or f_is_line_ww() then
		return
	end
	
	local obj = g_obj_mgr:get_obj(conn.char_id)

	if not pkt.type or not pkt.option or not obj then
		return
	end
	
	local map_id = jump_type_to_map_id[pkt.type]
	local config = g_scene_config_mgr:get_extend_config(map_id)
	if not config or not config.cheats or not config.cheats or not config.cheats.options[pkt.option + 1] then
		return
	end
	
	local cheats = config.cheats.options[pkt.option + 1]
	local cheats_limit = cheats.l_id
	local cheats_money = cheats.money
	local cheats_money_type = cheats.money_type
	
	local obj_id = obj:get_id()	
	
	local prototype = g_scene_mgr_ex:get_prototype(map_id)
	local e_code, e_desc = prototype:check_create_access(obj)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local new_pkt = {}
		new_pkt.result = e_code
		new_pkt.error_l = e_desc
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
		return
	end
	
	local team_id = obj:get_team()
	local team_obj = team_id and g_team_mgr:get_team_obj(team_id)
	if not team_obj then
		return
	end

	local team_l, team_count = team_obj:get_team_l()
	local member_error_l = {}
	local has_error = false
	local obj_mgr = g_obj_mgr
	local error_l = {}
	local team_members = {}

	for k, _ in pairs(team_l) do
		local obj = obj_mgr:get_obj(k)
		if obj then		
			local scene_args = obj:get_scene_args()
			local id = tostring(map_id)
			local max_layer = scene_args[id] or 0

			if  max_layer < cheats_limit then
				has_error = true
				local list = member_error_l[k]
				if not list then
					list = {}
					member_error_l[k] = list
				end
				table.insert(list, SCENE_ERROR.E_CHEATS_LIMIT)
				error_l[SCENE_ERROR.E_CHEATS_LIMIT] = true
			end
			
			team_members[k] = obj
		end
	end
	
	if has_error then
		local member_e_l = {}
		for k, v in pairs(member_error_l) do
			table.insert(member_e_l, {['obj_id'] = k, ['error_l'] = v})
		end

		g_cltsock_mgr:send_client(obj_id, CMD_MAP_TEAM_ENTER_COPY_S, member_e_l, false)
		local new_pkt = {}
		new_pkt.result = SCENE_ERROR.E_SCENE_CHANGE
		new_pkt.error_l = {}
		for k, _ in pairs(error_l) do
			table.insert(new_pkt.error_l, k)
		end
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
		return
	end

	local jump_limit = obj:get_addition(HUMAN_ADDITION.jump) or 0
	if 0 == g_vip_mgr:get_vip_info(obj_id) or obj:get_copy_con():get_count_tower_jump(map_id) >= jump_limit then
		local type_list = {MoneyType.GOLD, MoneyType.JADE, MoneyType.GIFT_JADE, MoneyType.GIFT_GOLD}
		local pack_con = obj:get_pack_con()
		local money_list = {}
		local money_index = type_list[cheats_money_type]
		money_list[money_index] = cheats_money

		local e_code = pack_con:dec_money_l_inter_face(money_list, {['type'] = MONEY_SOURCE.JUMP})
		
		if 0 ~= e_code then
			if 43067 ~= e_code then	--保护锁
				local new_pkt = {}
				new_pkt.result = e_code
				g_cltsock_mgr:send_client(obj_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
			end
			return			
		end
	else
		local copy_con = obj:get_copy_con()
		for k, v in ipairs(jump_type_to_map_id) do
			copy_con:add_count_tower_jump(v)
		end
	end
	
	local args = {}
	args.target = cheats.t_id
	args.mana = cheats.mana
	args.members = team_members
	args.obj = obj
	local e_code, e_desc = prototype:carry_scene(obj, nil, args)
	
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local new_pkt = {}
		new_pkt.result = e_code
		new_pkt.error_l = e_desc
		g_cltsock_mgr:send_client(obj_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
		
		f_scene_error_log("Error Scene Jump %s %s %d", tostring(obj_id), tostring(map_id), e_code) 
		return
	end
	
	local jump_addition = obj:get_addition(HUMAN_ADDITION.jump_add) or 0
	local exp_reward = (cheats.reward.exp or 0) * (1 + jump_addition + (team_count - 1) * 0.02)
	
	
	local has_reward_list = {}
	
	local applicant = conn.char_id
	local team_list = {applicant}
	for k, obj in pairs(team_members) do
		if k ~= applicant then
			table.insert(team_list, k)
		end
		
		local pack_con = obj:get_pack_con()
		local money_list = {}
		money_list[MoneyType.GOLD] 		=  cheats.reward.gold
		money_list[MoneyType.GIFT_GOLD] =  cheats.reward.gift_gold
		money_list[MoneyType.GIFT_JADE] =  cheats.reward.gift_jade
		money_list[MoneyType.JADE] 		=  cheats.reward.jade
		pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.JUMP})
	
		obj:add_exp(exp_reward)

		local email = {}
		email.sender = -1
		email.recevier = k
		email.title = f_get_string(2011)
		email.content = f_get_string(2012)
		email.box_title = f_get_string(2013)
		email.item_list = cheats.reward.item_list
		email.money_list = {}
		
		 --获取角色任务容器
		local mission_con = obj:get_mission_mgr()

		for _, quest_id in pairs(cheats.reward.quest_list or {}) do
			local quest = mission_con:get_accept_mission(quest_id)
			if quest then
				quest:set_status(MISSION_STATUS_COMMIT)
				mission_con:notity_update_quest(quest_id, true)
			end
		end
		
		 ----获取角色活动容器
		--local fun_con = obj:get_function_con()
--
		--for _, fun_id in pairs(cheats.reward.fun_list or {}) do
			--fun_con:set_skip_floor_finish(fun_id, 1)
		--end

		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_SEND_EMAIL_S, email)
		
		table.insert(has_reward_list, k)
	end	
	
	local sql = string.format("insert into log_skip set scene_id=%d, num=%d, time=%d, char1=%d, char2=%d, char3=%d, char4=%d, char5=%d"
				, map_id
				, cheats.target
				, ev.time
				, team_list[1] or 0
				, team_list[2] or 0
				, team_list[3] or 0
				, team_list[4] or 0
				, team_list[5] or 0)
				
	f_scene_info_log(sql)
	f_multi_web_sql(sql)
end


--取温泉帮派令信息
Clt_commands[1][CMD_TERRITORY_SPA_INFO_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.SPA == scene:get_type() then
			local new_pkt = scene:get_faction_append_info()
			g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_SPA_INFO_S, new_pkt)
		end
	end
end

--使用温泉帮派令  
Clt_commands[1][CMD_TERRITORY_SPA_USE_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.SPA == scene:get_type() then
			local new_pkt = {}
			new_pkt.result = scene:use_faction_append(conn.char_id, pkt.id)
			if new_pkt.result == -1 then return end
			g_cltsock_mgr:send_client(conn.char_id, CMD_TERRITORY_SPA_USE_S, new_pkt)
			if new_pkt.result == 0 then
				local faction = g_faction_mgr:get_faction_by_cid(conn.char_id)
				scene:notify_faction_append(faction:get_faction_id(), pkt.id)
			end
		end
	end
end

Clt_commands[1][CMD_MAP_SCENE_TRANSPORT_C] =
function(conn, pkt)
	local pos = extend_config.transport[pkt.map_id]
	if not pos then
		return
	end
	
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local e_code, error_l = g_scene_mgr_ex:carry_scene(pkt.map_id, pos, obj)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			local new_pkt = {}
			new_pkt.result = e_code
			new_pkt.error_l = error_l
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_CHANGE_MAP_S, new_pkt)
		end
	end
end

--进入结婚场景 
Clt_commands[1][CMD_MAP_SCENE_ENTER_MARRY_C] =
function(conn, pkt)
	--print("CMD_MAP_SCENE_ENTER_MARRY_C", j_e(pkt))
	--
	local marry = nil
	if pkt.marry_id ~= nil then
		marry = g_marry_mgr:get_marry_info_ex(pkt.marry_id)
	else
		marry = g_marry_mgr:get_marry_info(conn.char_id)
	end
	if marry == nil then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_ENTER_MARRY_S, {result=22581})
		return
	end

	if pkt.marry_id ~= nil and marry.m_y == 0 then
		local can_in = false  
		local apply = false
		for k, v in ipairs(marry.m_l or {}) do                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
			if v == conn.char_id then
				can_in = true
				break
			end
		end
		if not can_in then
			for k, v in ipairs(marry.m_p or {}) do
				if v == conn.char_id then
					apply = true
					break
				end
			end
		end
		if not can_in and not apply then
			g_marry_mgr:fb_quest_insert(pkt.marry_id, conn.char_id)
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_ENTER_MARRY_S, {result=22602})			
			return
		elseif not can_in then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_ENTER_MARRY_S, {result=22584})			
			return			
		end
	end
	
	--print("marry", j_e(marry))
	local map_id = marry.m_i
	local prototype = g_scene_mgr_ex:get_prototype(map_id)
	local obj = g_obj_mgr:get_obj(conn.char_id)

	if not prototype or not obj then
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_ENTER_MARRY_S, {result=22582})
		return
	end

	local pos = prototype:get_enter_pos()

	local e_code, line_id = prototype:carry_scene(obj, pos, {marry = marry})
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		local new_pkt = {}
		new_pkt.result = e_code
		new_pkt.line_id = line_id
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_ENTER_MARRY_S, new_pkt)
	end
end

--离开结婚场景
Clt_commands[1][CMD_MAP_SCENE_LEAVE_MARRY_C] =
function(conn, pkt)

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MARRY == scene:get_type() then
			scene:leave(conn.char_id)
		end
	end
end

--主人开始婚礼
Clt_commands[1][CMD_MAP_SCENE_MASTER_START_MARRY_C] =
function(conn, pkt)
	--print("CMD_MAP_SCENE_MASTER_START_MARRY_C")
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MARRY == scene:get_type() then
			local new_pkt = {}
			new_pkt.result = scene:start_marry(conn.char_id)
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MASTER_START_MARRY_S, new_pkt)
		end
	end
end

--取结婚场景玩家列表
Clt_commands[1][CMD_MAP_SCENE_MARRY_GET_HUMAN_LIST_C] =
function(conn, pkt)

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MARRY == scene:get_type() then
			local new_pkt = {}
			new_pkt.list = scene:get_human_list()
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MARRY_GET_HUMAN_LIST_S, new_pkt)
		end
	end
end

--驱逐结婚场景玩家列表
Clt_commands[1][CMD_MAP_SCENE_MARRY_KICKOUT_HUMAN_LIST_C] =
function(conn, pkt)
	--print("CMD_MAP_SCENE_MARRY_KICKOUT_HUMAN_LIST_C", j_e(pkt))
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MARRY == scene:get_type() then
			local new_pkt = {}
			new_pkt.result = scene:kickout_human_list(conn.char_id, pkt.list)
			--g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MARRY_KICKOUT_HUMAN_LIST_S, new_pkt)
			if new_pkt.result == 0 then
				local new_pkt2 = {}
				new_pkt2.list = scene:get_human_list()
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MARRY_GET_HUMAN_LIST_S, new_pkt2)
			end
		end
	end
end

--结婚场景加时
Clt_commands[1][CMD_MAP_SCENE_MARRY_ADD_TIME_C] =
function(conn, pkt)

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MARRY == scene:get_type() then
			local new_pkt = {}
			new_pkt.result = scene:add_time(conn.char_id, pkt.time)
			if new_pkt.result >= 0 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MARRY_ADD_TIME_S, new_pkt)
			end
		end
	end
end

--结婚场景客户端状态改变通知
Clt_commands[1][CMD_MAP_SCENE_MARRY_STATE_NOTIFY_C] =
function(conn, pkt)

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MARRY == scene:get_type() then
			local new_pkt = {}
			new_pkt.result = scene:state_notify_c(conn.char_id, pkt.state)
			--if new_pkt.result >= 0 then
			--	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MARRY_STATE_NOTIFY_S, new_pkt)
			--end
		end
	end
end

--结婚场景仪式对话通知
Clt_commands[1][CMD_MAP_SCENE_MARRY_DIALOGUE_C] =
function(conn, pkt)

	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MARRY == scene:get_type() then
			local new_pkt = {}
			new_pkt.result = scene:select_dialogue(conn.char_id, pkt.id)
			--if new_pkt.result >= 0 then
			--	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MARRY_DIALOGUE_S, new_pkt)
			--end
		end
	end
end

--连斩副本传送
Clt_commands[1][CMD_MAP_SCENE_MORE_KILL_TRANSPORT_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MORE_KILL == scene:get_type() then
			local result = scene:transport_to(pkt.pos)
			if result > 0 then
				local new_pkt = {}
				new_pkt.result = result
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MORE_KILL_TRANSPORT_S, new_pkt)
			end
		end
	end
end

--连斩副本手动刷新buff
Clt_commands[1][CMD_MAP_SCENE_MORE_KILL_REFRESH_BUFF_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.MORE_KILL == scene:get_type() then
			local result = scene:refresh_buff()
			if result > 0 then
				local new_pkt = {}
				new_pkt.result = result
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SCENE_MORE_KILL_REFRESH_BUFF_S, new_pkt)
			end
		end
	end
end

--单人副本发奖励
Clt_commands[1][CMD_MAP_SCENE_TOWER_EX_REWARD_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.TOWER_EX == scene:get_type() then
			local result = scene:get_reward(pkt.replay)
		end
	end
end

--新战场 改变身份
Clt_commands[1][CMD_BATTLEFIELD_CHANGE_RANK_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.BATTLEFIELD == scene:get_type() then
			local result = scene:change_rank(conn.char_id, pkt.type)
			if result > 0 then
				local new_pkt = {}
				new_pkt.result = result
				g_cltsock_mgr:send_client(conn.char_id, CMD_BATTLEFIELD_CHANGE_RANK_S, new_pkt)
			end
		end
	end
end

--新战场 缴纳资源
Clt_commands[1][CMD_BATTLEFIELD_PAYMENT_RESOURCE_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.BATTLEFIELD == scene:get_type() then
			local new_pkt = {}
			new_pkt.result, new_pkt.score = scene:payment_resource(conn.char_id)
			if new_pkt.result < 3 then
				new_pkt.type = new_pkt.result
				new_pkt.result = 0
			end
			g_cltsock_mgr:send_client(conn.char_id, CMD_BATTLEFIELD_PAYMENT_RESOURCE_S, new_pkt)
		end
	end
end

--新帮派副本增加buff
Clt_commands[1][CMD_FACTION_COPY_ADD_BUFF_B] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.FACTION == scene:get_type() then
			local new_pkt = {}
			new_pkt.result, new_pkt.buff = scene:add_buff(conn.char_id, pkt.type)
			if new_pkt.result >= 0 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_FACTION_COPY_ADD_BUFF_S, new_pkt)
			end
		end
	end
end



--pvp系统切换副本
Clt_commands[1][CMD_MAP_PVP_BATTLE_CHANGE_COPY_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj and pkt then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.PVP_BATTLE == scene:get_type() then
			local prototype = g_scene_mgr_ex:get_prototype(4201000)
			if not prototype then
				print("Error:scene_process line 1037 no map")
				return
			end
			local result = prototype:select_instance(conn.char_id, pkt.copy_id) 
			local pkt = {["result"] = result}
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PVP_BATTLE_CHANGE_COPY_S, pkt)
		end
	end
end

--pvp系统获取人数信息
Clt_commands[1][CMD_MAP_PVP_BATTLE_COPY_INFO_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj and pkt then
		local scene = obj:get_scene_obj()
		if scene and SCENE_TYPE.PVP_BATTLE == scene:get_type() then
			local prototype = g_scene_mgr_ex:get_prototype(4201000)
			if not prototype then
				print("Error:scene_process line 1056 no map")
				return
			end
			local pkt = {}
			pkt.limit, pkt.copy_info, pkt.copy_id = prototype:pri_get_status_info() 
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PVP_BATTLE_COPY_INFO_S, pkt)
		end
	end
end

--传送至神秘老人
Clt_commands[1][CMD_MAP_PVP_TO_NPC_C] =
function(conn, pkt)
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then
		return
	end
	
	 --获取角色任务容器
	local result = f_scene_carry(conn.char_id, 35000 , {215, 139})
	local pkt = {["result"] = result}
	g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PVP_TO_NPC_S, pkt)
end

--pvp系统判断开始时间
Clt_commands[1][CMD_MAP_PVP_CHECK_OPEN_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local week = tonumber(os.date("%w" ,ev.time))
		local err = pvp_config.check_open_time(week + 1)
		if 0 == err then
			if obj:get_level() < 60 then
				err = SCENE_ERROR.E_LEVEL_DOWN
			end
		end
		pkt.result = err
	
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_PVP_CHECK_OPEN_S, pkt)
	end
end

--新手大招技能学习
Clt_commands[1][CMD_MAP_SKILL_AUTO_LEARN_C] =
function(conn, pkt)
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj then
		local skill = 990101
		if 0 == f_skill_book_is_study(obj, skill) then
			--local ret = {}
			--ret.result = 0
			--ret.skill_id = skill
			--g_cltsock_mgr:send_client(player:get_id(), CMD_NPC_ACTION_LEARN_SKILL_S, ret)
			
			local e_code = f_skill_book_study(obj, skill)

			local action_con = obj:get_action_con()
			local skill_o = g_skill_mgr:get_skill(skill)
			action_con:add_skill_shortcut(skill_o:get_cmd_id())
			--print("CMD_MAP_SKILL_AUTO_LEARN_C su")
		end

		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_SKILL_AUTO_LEARN_S, {})
	end
end

Clt_commands[1][CMD_MAP_WOLF_USE_SKILL_C] =
function(conn, pkt)
	--print("CMD_MAP_WOLF_USE_SKILL_C", j_e(pkt))
	local obj = g_obj_mgr:get_obj(conn.char_id)
	if obj and (pkt and pkt.skill_id) then
		local err = 0
		local scene_o = obj:get_scene_obj()
		if not scene_o then return end
		if SCENE_TYPE.SHEEP == scene_o:get_type() then
			err = scene_o:use_skill(obj:get_id(), pkt.skill_id)
			--print("err", err)
			local new_pkt = {}
			new_pkt.result = err
			new_pkt.id = pkt.skill_id
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_WOLF_USE_SKILL_S, new_pkt)
		end
	end
end

--鱼上钩
Clt_commands[1][CMD_MAP_FISH_INRANGE_C] = 
function(conn,pkt)
        local player = g_obj_mgr:get_obj(conn.char_id) 
        local hook = pkt.hookid;
        if not pkt.hookid then print( "no hook" ) return end

        if not player then return end
        get_fishing_info(conn.char_id, hook)
end

-- 通知大鱼连击结果
Clt_commands[1][CMD_MAP_FISH_GETBIG_C] = 
function(conn,pkt)
        local player = g_obj_mgr:get_obj(conn.char_id) 
        local getflag = pkt.isget
        if not player or not getflag then return end
        get_bigfish(conn.char_id, getflag)
end

