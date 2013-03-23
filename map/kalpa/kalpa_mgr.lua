
--local debug_print = print
local debug_print = function() end
local _random = crypto.random

_kalpa = require("config.kalpa_config")

-- 渡劫管理类
Kalpa_mgr = oo.class(nil, "Kalpa_mgr")

--
function Kalpa_mgr:__init()

	self.kalpa_list = {}	--参加过渡劫的玩家
	self.god = nil
end

--玩家渡劫后加入列表
function Kalpa_mgr:add_player(char_id, kalpa_level, time, fail, time_r, pro)
	if self.kalpa_list[char_id] == nil then
		local kalpa_item = {}
		kalpa_item.char_id = char_id	-- 玩家ID
		kalpa_item.level = kalpa_level	-- 当前渡劫的级别
		kalpa_item.time  = time			-- 得到当前渡劫的时间
		kalpa_item.fail	 = fail			-- 失败的次数
		kalpa_item.time_r= time_r		-- 刷新基础概率的时间
		kalpa_item.pro   = pro			-- 基础概率
		self.kalpa_list[char_id] = kalpa_item
	else
		self.kalpa_list[char_id].level = kalpa_level
		self.kalpa_list[char_id].time  = time
		self.kalpa_list[char_id].fail  = fail
		self.kalpa_list[char_id].time_r= time_r
		self.kalpa_list[char_id].pro   = pro
	end
end

function Kalpa_mgr:logout(char_id)
	self:serialize(char_id)
	self.kalpa_list[char_id] = nil
end

-- 返回渡劫的基本属性的加成
function Kalpa_mgr:get_effect(char_id, type)
	local val = self.kalpa_list[char_id]
	if val and  _kalpa._real_a[val.level] then
		return _kalpa._real_a[val.level][type] or 0
	end
	return 0
end

-- 参加渡劫 成功返回0，
function Kalpa_mgr:kalpa(char_id, fly_size, slot)
	local val = self.kalpa_list[char_id]
	local level = val and (val.level + 1) or _kalpa.KALPA_MIN_LEVEL
	local obj = g_obj_mgr:get_obj(char_id)
	local ret = self:can_kalpa(char_id, fly_size, slot)
	if ret ~= 0 then
		return ret
	end

	if fly_size > _kalpa.KALPA_PROP_MAX then
		fly_size = _kalpa.KALPA_PROP_MAX
	end
	-- 扣道具
	local pack_con = obj:get_pack_con()
	if _kalpa._need_a[level][10] > 0 then
		pack_con:del_item_by_item_id_inter_face(202002306020, _kalpa._need_a[level][10], {['type']=ITEM_SOURCE.KALPA_PROP}, 1)	end	if fly_size > 0 then		pack_con:del_item_by_item_id_inter_face(202002406020, fly_size, {['type']=ITEM_SOURCE.KALPA_FLY}, 1)	end	if slot ~= nil then		pack_con:del_item_by_bag_slot(SYSTEM_BAG, slot, 1, {['type']=ITEM_SOURCE.KALPA_PROP})	end
	local random = _random(0, 100)
	local r = (val.pro or 30) + math.min(val.fail, _kalpa.KALPA_FAIL_MAX) * _kalpa.KALPA_FAIL_POINT + fly_size
	--后台流水
	local str = string.format("replace log_dujie set char_id =%d, level = '%d', stage = %d, status=%d, time = %d",
							char_id, obj:get_level(), level,  random < r and 1 or 0, ev.time)
	f_multi_web_sql(str)
	--log
	local str_log = string.format("char_id: %d level: %d kalpa_level:%d succeed: %d ", 
		char_id, val.level, level, random < r and 1 or 0)
	g_player_log:write(str_log)

	
	if random < r then	-- 成功
		self:add_player(char_id, level, ev.time, 0, 0, 0)
		obj:update_all_attr()
		obj:on_update_attribute(1)
		self:broadcast(obj, level)
		self:serialize(char_id)
		--
		local event_args = {}
		event_args.level = level
		g_event_mgr:notify_event(EVENT_SET.EVENT_HOOK, char_id, event_args)

		return 0
	else
		self:add_player(char_id, level-1, ev.time, val.fail + 1, 0, 0)
		--装置耐久全为0
		local obj = g_obj_mgr:get_obj(char_id)
		local pack_con = obj and obj:get_pack_con()
		local _ = pack_con and pack_con:endure_set_to_zero()

		local impact_con = obj:get_impact_con()
		local impact_o_1502 = impact_con:find_impact(1502)
		if impact_o_1502 == nil then
			f_prop_change(obj, 200)
		end
		--[[
		if obj:add_hp(-1000000000) <= 0 then
			if self.god == nil then
				self.god = g_obj_mgr:create_monster(1080, {174,232}, {10000})
				--g_scene_mgr_ex:enter_scene(self.god)
			end
			obj:on_die(self.god)
		end]]
		self:serialize(char_id)
	end
	return 20970
end

-- 升级
function Kalpa_mgr:kalpa_upgrade(char_id, to_level)
	local val = self.kalpa_list[char_id]
	local level = val and (val.level + 1) or _kalpa.KALPA_MIN_LEVEL
	if level > to_level then
		return 20977
	end
	level = to_level
	local obj = g_obj_mgr:get_obj(char_id)
	local obj_level = obj:get_level()
	--级别不够
	if _kalpa._need_a[level] == nil or obj_level < _kalpa._need_a[level][13] then 
		return 20974
	end

	--后台流水
	local str = string.format("replace log_dujie set char_id =%d, level = '%d', stage = %d, status=%d, time = %d",
							char_id, obj_level, level, 1, ev.time)
	f_multi_web_sql(str)
	--log
	local str_log = string.format("kalpa_upgrade char_id: %d level: %d kalpa_level:%d succeed: %d ", 
		char_id, obj_level, level, 1)
	g_player_log:write(str_log)

	self:add_player(char_id, level, ev.time, 0, 0, 0)
	obj:update_all_attr()
	obj:on_update_attribute(1)
	self:broadcast(obj, level)
	self:serialize(char_id)
	--
	local event_args = {}
	event_args.level = level
	g_event_mgr:notify_event(EVENT_SET.EVENT_HOOK, char_id, event_args)
	return 0
end

-- 参加渡劫增的属性值
function Kalpa_mgr:get_kalpa_attr(char_id)
	local val = self.kalpa_list[char_id]
	local level = val and val.level or _kalpa.KALPA_MIN_LEVEL
	return _kalpa._a[level]
end

-- 取玩家当前的渡劫等级
function Kalpa_mgr:get_kalpa_level(char_id)
	local val = self.kalpa_list[char_id]
	return val and val.level or 0, 12 -- 80级满级等级
end

-- 是否达到渡劫等级满级, 返回true or false
function Kalpa_mgr:is_full_level(char_id)
	local val = self.kalpa_list[char_id]
	local next_level = (val and val.level or 0) + 1
	return _kalpa._need_a[next_level] == nil
end

-- 是否80级达到渡劫等级满级, 返回true or false
function Kalpa_mgr:is_full_80_level(char_id)
	local val = self.kalpa_list[char_id]
	local level = val and val.level or 0
	return level >= 12
end

-- 参加渡劫的名字
function Kalpa_mgr:get_kalpa_name(char_id)
	local val = self.kalpa_list[char_id]
	local level = val and val.level or _kalpa.KALPA_MIN_LEVEL
	return _kalpa._need_a[level][11] or ""
end

-- 能否参加渡劫 能返回0，否则返回错误码
function Kalpa_mgr:can_kalpa(char_id, fly_size, slot)
	--print("Kalpa_mgr:can_kalpa()", obj, level)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj == nil then return 20961 end
	local val = self.kalpa_list[char_id]
	local level = val and (val.level + 1) or _kalpa.KALPA_MIN_LEVEL
	--场景不对
	local scene_id = obj:get_scene_obj():get_id()
	if _kalpa.KALPA_SCENE_ID and scene_id ~= _kalpa.KALPA_SCENE_ID then
		return 20961
	end
	--时间间隔不够
	if val and val.time + _kalpa.KALPA_NEXT_TIME > ev.time then
		return 20962
	end
	
	--hp不够
	if obj:get_max_hp() < _kalpa._need_a[level][3] then return 20963 end
	--mp不够
	if obj:get_max_mp() < _kalpa._need_a[level][4] then return 20964 end
	--攻击不够
	local attack_s = obj:get_s_attack_t()
	local attack_m = obj:get_m_attack_t()
	if attack_s < _kalpa._need_a[level][5] and attack_m < _kalpa._need_a[5] then
		return 20965
	end
	--防御不够
	local defense_s = obj:get_s_defense_t()
	local defense_m = obj:get_m_defense_t()
	if defense_s < _kalpa._need_a[level][6] and defense_m < _kalpa._need_a[6] then
		return 20966
	end
	--命中不够
	if obj:get_point_t() < _kalpa._need_a[level][7] then return 20967 end
	--暴击不够
	if obj:get_critical_t() < _kalpa._need_a[level][8] then return 20968 end
	--闪避不够
	if obj:get_dodge_t() < _kalpa._need_a[level][9] then return 20969 end
	--渡劫符道具数不够
	local pack_con = obj:get_pack_con()
	local prop_s = pack_con:get_all_item_count(202002306020)
	if prop_s < _kalpa._need_a[level][10] then
		return 20971
	end
	--飞升符道具数不够
	local prop_f = pack_con:get_all_item_count(202002406020)
	if prop_f < fly_size then
		return 20972
	end
	-- 使用道具减
	local reduse_rate = 0
	if slot ~= nil then
		local s_slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG, slot)		if s_slot.number < 1 then			return 43002		end		local s_item = s_slot and s_slot.item		if s_item:get_m_class() ~= 1 or s_item:get_s_class() ~= 54 then			return 43064		end
		reduse_rate = s_item:get_reduse_rate()
	end
	--战斗力不够
	if obj:get_fighting() < math.floor(_kalpa._need_a[level][12] * (1 - reduse_rate)) then 
		return 20973 
	end
	--级别不够
	if _kalpa._need_a[level] == nil or obj:get_level() < math.floor(_kalpa._need_a[level][13] * (1 - reduse_rate)) then 
		return 20974
	end

	return 0
end

-- 打开渡劫面板返回相关属性
function Kalpa_mgr:open_kalpa(char_id)
	local obj = g_obj_mgr:get_obj(char_id)
	if obj:get_level() < f_get_feature_min_level("g_kalpa_mgr") then
		local ret = {}
		ret.level = 1
		ret.pro = 0
		ret.fail = 50
		ret.time = 0
		ret.time_b = 1
		ret.time_r = 1
		ret.jade = _kalpa.KALPA_REFRESH_JADE
		ret.max_pro = 100
		ret.add_at = _kalpa._a[1][18]
		return ret
	end
	local val = self.kalpa_list[char_id]
	local level = val and (val.level + 1) or _kalpa.KALPA_MIN_LEVEL
	if _kalpa._need_a[level] == nil then 
		return
	end
	if val == nil then
		self:add_player(char_id, level-1, 0, 0, ev.time, 0)
		val = self.kalpa_list[char_id]
	end
	if val.pro == 0 or val.time_r + _kalpa.KALPA_REFRESH_TIME < ev.time then
		self:set_new_pro(char_id, level)		
		val.time_r = ev.time
	end
	local ret = {}
	ret.level = level
	ret.pro = val.pro
	ret.fail = math.min(val.fail, _kalpa.KALPA_FAIL_MAX) * _kalpa.KALPA_FAIL_POINT
	ret.time = math.max(val.time + _kalpa.KALPA_NEXT_TIME - ev.time, 0)
	ret.time_b = _kalpa.KALPA_REFRESH_TIME
	ret.time_r = val.time_r + _kalpa.KALPA_REFRESH_TIME - ev.time
	ret.jade = _kalpa.KALPA_REFRESH_JADE
	ret.max_pro = _kalpa._need_a[level][2]
	ret.add_at = _kalpa._a[level][18]
	return ret
end

-- 刷新基本概率
function Kalpa_mgr:refresh_kalpa(char_id, type)
	local val = self.kalpa_list[char_id]
	local level = val and (val.level + 1) or _kalpa.KALPA_MIN_LEVEL
	if type == 1 then
		--扣元宝
		local obj = g_obj_mgr:get_obj(char_id)
		local need_jade = _kalpa.KALPA_REFRESH_JADE
		if need_jade > 0 and obj ~= nil then
			local pack_con = obj:get_pack_con()
			local money_list = {}
			money_list[MoneyType.JADE] = need_jade		-- 只扣元宝
			local src_log = {["type"] = MONEY_SOURCE.KALPA}
			local ret_code = pack_con:dec_money_l_inter_face(money_list, src_log, nil, 1)
			if ret_code ~= 0 then
				ret_code = ret_code == 43067 and -1 or ret_code
				--local ret = {}
				--ret.pro = val.pro
				--ret.result = ret_code
				return ret_code, nil
			end
		end
		self:set_new_pro(char_id, level)
		val.time_r = ev.time
	elseif type == 0 and val.time_r + _kalpa.KALPA_REFRESH_TIME < ev.time then
		self:set_new_pro(char_id, level)
		val.time_r = ev.time
	end
	local ret = {}
	ret.pro = val.pro
	--ret.result = 0
	return 0, ret
end

-- 广播
function Kalpa_mgr:broadcast(obj, level)
	local msg = {}
	f_construct_content(msg, obj:get_name(), 53)
	f_construct_content(msg, f_get_string(2071), 12)
	f_construct_content(msg, _kalpa._need_a[level][11], 53)
	f_construct_content(msg, f_get_string(2072), 12)
	f_cmd_sysbd(msg)
end

-- 保存
function Kalpa_mgr:serialize(char_id)
	if Obj_mgr.obj_type(char_id) == OBJ_TYPE_HUMAN then
		--serialize
		local info = self.kalpa_list[char_id]
		if info ~= nil then
			local m_db = f_get_db()
			local query = string.format("{char_id:%d}", char_id)
			m_db:update("kalpa", query, Json.Encode(info), true)
		end
	end
end

function Kalpa_mgr:login(char_id)
	if Obj_mgr.obj_type(char_id) == OBJ_TYPE_HUMAN then
		local m_db = f_get_db()
		--local fields = Json.Encode({_id=0})
		local query = string.format("{char_id:%d}", char_id)
		local rows, e_code = m_db:select_one("kalpa", nil, query, nil, "{char_id:1}")
		if rows ~= nil then
			self:add_player(rows.char_id, rows.level, rows.time, rows.fail, rows.time_r, rows.pro or 0)
		end
	end
end

function Kalpa_mgr:set_new_pro(char_id, level)
	local old_pro =  self.kalpa_list[char_id].pro
	local new_pro = old_pro
	for i = 1, 20 do
		new_pro = _random(_kalpa._need_a[level][1], _kalpa._need_a[level][2] + 1)
		if new_pro ~= old_pro then
			break
		end
	end
	self.kalpa_list[char_id].pro = new_pro
end

-- 清除CD时间
function Kalpa_mgr:reset_cd_time(char_id)
	local val = self.kalpa_list[char_id]
	if val == nil then return 20975 end

	local pack_con = obj:get_pack_con()
	local prop_s = pack_con:get_all_item_count(202002506020)
	if prop_s < 1 then
		return 20976
	end

	pack_con:del_item_by_item_id_inter_face(202002506020, 1, {['type']=ITEM_SOURCE.KALPA_CD}, 1)

	val.time = 0
	return 0
end

-- 
function Kalpa_mgr:get_db_info(char_id)
	return self.kalpa_list[char_id]
end