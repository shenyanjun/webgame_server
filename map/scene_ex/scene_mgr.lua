
local _random = crypto.random

Scene_mgr = oo.class(nil, "Scene_mgr")								--所有地图管理器的门面类，与地图管理器无关

local scene_sort_table = "scene_sort"
local scene_sort_index = "{'line_id':1}"
local sort_max = 10

local scene_builder_list = create_local("scene_ex.scene_config_mgr.scene_builder_list", {})

local main_city = {MAP_INFO_3, {316, 346}}
if f_is_line_faction() then
	main_city = {MAP_INFO_355, {166, 90}}
elseif f_is_pvp() then
	main_city = {MAP_INFO_371, {64, 58}}
elseif f_is_line_ww() then
	main_city = {MAP_COPY_INFO_37, {68, 54}}
end
--注册任务类的构建者，构建者可以是类（是类，不是对象除非是函数对象），函数对象，函数
function Scene_mgr.register_scene_class(type, builder)
	scene_builder_list[type] = builder
end

function Scene_mgr:__init()
	self.scene_list = {}
	self.instance_list = {}
	self.observer_list = {}
	
	self.type_list = {}
	
	self.tomorrow = f_get_tomorrow()
	
	self.exp_config = {}
	self.lost_config = {}
	
	self.exp_extend = Timer_queue()
	self.lost_extend = Timer_queue()
	self.schedule_list = Timer_queue()
	
	self.obj_event_heap = Min_heap()
	
	self.type_extend = {}
	self.frenzy_result = {}
end

function Scene_mgr:load()
	for id, config in pairs(g_scene_config_mgr:get_config_list()) do
		if g_scene_config_mgr:can_load(id) then
			local builder = scene_builder_list[config.type]
			if builder then
				local scene = builder(id)
				self.scene_list[id] = scene
				scene:instance()
				local type = scene:get_type()
				local list = self.type_list[type]
				if not list then
					list = {}
					self.type_list[type] = list
				end
				table.insert(list, scene)
			else
				f_scene_error_log("Scene_mgr:load(%s, %s) Not Builder."
					, tostring(id)
					, tostring(config.type))
			end
		end
	end
	self:on_new_day()
	
	return true
end

function Scene_mgr:get_type_list(type)
	return self.type_list[type]
end

function Scene_mgr:get_scene(scene_id)
	local map_id = scene_id[1]
	if not map_id then
		return nil
	end
	
	if not self.scene_list[map_id] then
		Debug():trace()
		return nil
	end
	
	return self.scene_list[map_id]:get_instance(scene_id)
end

function Scene_mgr:add_obj_evnet(timestamp, obj_id, method, args)
	local value = {
		["obj_id"] = obj_id
		, ["method"] = method
		, ["args"] = args
	}
	
	return self.obj_event_heap:push(timestamp, value)
end

--人物加入一个场景
function Scene_mgr:push_scene(scene_id, pos, obj)
	local scene = self.scene_list[scene_id]
	if not scene then
		return SCENE_ERROR.E_INVALID_ID 
	end
	
	return scene:push_scene(obj, pos)
end

--人物在同一场景内传送
function Scene_mgr:change_pos(scene_id, pos, obj)
	local scene = self.scene_list[scene_id]
	if not scene then
		return SCENE_ERROR.E_INVALID_ID 
	end
	
	return scene.change_pos and scene:change_pos(obj, pos)
end

--进入一个场景
function Scene_mgr:enter_scene(obj)
	local scene = obj and obj:get_scene_obj()
	if not scene then
		if OBJ_TYPE_BOX == obj:get_type() then
			f_scene_error_log("Scene_mgr:enter_scene(%s, %s) Box Not Scene."
				, tostring(obj:get_map_id())
				, Json.Encode(obj:get_scene()))
		end
		return SCENE_ERROR.E_INVALID_ID 
	end
	
	local e_code = scene:enter_scene(obj)
	
	if SCENE_ERROR.E_SUCCESS ~= e_code and OBJ_TYPE_BOX == obj:get_type() then
		f_scene_error_log("Scene_mgr:enter_scene(%s, %s) Box Not Scene."
			, tostring(obj:get_map_id())
			, Json.Encode(obj:get_scene()))
	end
	
	return e_code
end

function Scene_mgr:leave_scene(obj)
	local scene = obj and obj:get_scene_obj()
	if not scene then
		return SCENE_ERROR.E_INVALID_ID 
	end
	return scene:leave_scene(obj:get_id())
end

function Scene_mgr:on_timer(tm)
	for _, scene in pairs(self.scene_list) do
		scene:on_timer(tm)
	end
end

function Scene_mgr:on_slow_timer(tm)
	local now_time = ev.time
	
	if self.tomorrow < now_time then
		self:on_new_day()
	end
	
	self.exp_extend:exec(now_time)
	self.lost_extend:exec(now_time)
	self.schedule_list:exec(now_time)
	
	local obj_mgr = g_obj_mgr
	while not self.obj_event_heap:is_empty() do
		local o = self.obj_event_heap:top()
		if o.key > now_time then
			break
		end
		
		self.obj_event_heap:pop()
		
		local value = o.value
		
		local obj = obj_mgr:get_obj(value.obj_id)
		if obj then
			local method = obj[value.method]
			if method then
				method(obj, value.args)
			end
		end
	end
	
	for _, scene in pairs(self.scene_list) do
		scene:on_slow_timer(tm)
	end
end

function Scene_mgr:on_serialize_timer(tm)
	for _, scene in pairs(self.scene_list) do
		scene:on_serialize_timer(tm)
	end
end

function Scene_mgr:convey_to_relive(obj)
	local scene_id = obj:get_map_id()
	local info = g_scene_config_mgr:get_relive_config(scene_id)
	if info then
		---[[--
		if scene_id == 4201000 then
			local pos = {info[2], info[3]}
			local scene_o = obj:get_scene_obj()
			scene_o:transport_ex(obj, {81, 82})
		else
			self:push_scene(info[1], {info[2], info[3]}, obj)
		end
		--]]--
	end
end


function Scene_mgr:register_instance(instance_id, scene)
	if not self.instance_list[instance_id] then
		self.instance_list[instance_id] = scene
	end
end

function Scene_mgr:unregister_instance(instance_id, args)
	local scene = self.instance_list[instance_id]
	if scene then
		scene:unregister_instance(instance_id, args)
		self.instance_list[instance_id] = nil
	end
end

function Scene_mgr:exists_instance(instance_id)
	return self.instance_list[instance_id] and true or false
end

function Scene_mgr:get_human_in_instance(key)
	local inst = self:get_scene(key)
	return inst and inst:get_human_count()
end

function Scene_mgr:get_prototype(map_id)
	return self.scene_list[map_id]
end

function Scene_mgr:push_default(obj)
	return self:push_scene(main_city[1], main_city[2], obj)
end

function Scene_mgr:login_scene(map_id, pos, obj)
	local prototype = self:get_prototype(map_id)
	if prototype then
		local e_code, error_list = prototype:login_scene(obj, pos)
		if SCENE_ERROR.E_SUCCESS == e_code then
			return e_code, error_list
		end
	end

	return self:push_default(obj)
end

function Scene_mgr:change_scene(obj_id, carry_id)
	local obj = g_obj_mgr:get_obj(obj_id)
	if not obj then
		debug_print("obj")
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	
	local config = g_scene_config_mgr:get_carry_config(carry_id)
	if not config then
		debug_print("config", carry_id)
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	
	local current = obj:get_scene_obj()
	if not current then
		debug_print("current")
		return SCENE_ERROR.E_SCENE_CLOSE
	end

	local current_map = config[1]
	if current_map ~= current:get_id() then
		debug_print("current_map")
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	
	local prototype = self:get_prototype(config[4])
	if not prototype then
		debug_print("prototype")
		return SCENE_ERROR.E_SCENE_CLOSE
	end
	
	local e_code, error_list = prototype:carry_scene(obj, {config[5], config[6]})
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		debug_print("carry_scene", e_code)
	end
	return e_code, error_list
end

function Scene_mgr:carry_scene(map_id, pos, obj)
	local prototype = self:get_prototype(map_id)
	if not prototype then
		return SCENE_ERROR.E_SCENE_CLOSE
	end

	return prototype:carry_scene(obj, pos)
end
----------------------------------------------------------------------------------------------------------

--注册事件监听
function Scene_mgr:register_event(event, key, obj, method)
	if not event or not obj or not method or not key then
		return
	end
	
	local observer_list = self.observer_list[event]
	if not observer_list then
		observer_list = {}
		self.observer_list[event] = observer_list
	end
	
	local observer = {}
	observer.obj = obj
	observer.method = method
	observer_list[key] = observer 
end

--取消事件监听
function Scene_mgr:unregister_event(event, key)
	if not event or not key then
		return
	end
	
	local observer_list = self.observer_list[event]
	if not observer_list then
		return
	end

	observer_list[key] = nil
end

--杀怪通知
function Scene_mgr:notify_kill_event(args, char_id)
	local monster_id = args and args.monster_id
	local id = args and args.id
	local list = self.observer_list[EVENT_SET.EVENT_KILL_MONSTER]
	if monster_id and list then
		local ob = list[char_id]
		if ob then
			ob.method(ob.obj, monster_id, char_id, id)
		end
	end
end

--杀镜像通知
function Scene_mgr:notify_kill_ghost(args, char_id)
	local ghost_id = args and args.char_id
	local id = args and args.id
	local list = self.observer_list[EVENT_SET.EVENT_KILL_GHOST]
	if ghost_id and list then
		local ob = list[char_id]
		if ob then
			ob.method(ob.obj, ghost_id, char_id, id)
		end
	end
end

--人物离开帮派通知
function Scene_mgr:notify_out_faction_event(args, char_id)
	local list = self.observer_list[EVENT_SET.EVENT_OUT_FACTION]
	if list then
		local ob = list[char_id]
		if ob then
			ob.method(ob.obj, char_id)
		end
	end
end

--人物离开队伍通知
function Scene_mgr:notify_del_team_event(args, char_id)
	local team_id = args.team_id
	local list = self.observer_list[EVENT_SET.EVENT_DEL_TEAM]
	if list then
		local ob = list[char_id]
		if ob then
			ob.method(ob.obj, team_id, char_id)
		end
	end
end

--人物死亡通知
function Scene_mgr:notify_die_event(args, char_id)
	local list = self.observer_list[EVENT_SET.EVENT_DIE]
	if list then
		local ob = list[char_id]
		if ob then
			ob.method(ob.obj, args, char_id)
		end
	end
end

--人物成为队长
function Scene_mgr:notify_team_caption_event(args, char_id)
	local list = self.observer_list[EVENT_SET.EVENT_TEAM_CAPTAIN]
	if list then
		local ob = list[char_id]
		if ob then
			ob.method(ob.obj, char_id)
		end
	end
end

----------------------------------------------------------------------------------------------------------

function Scene_mgr:get_exp_addition(obj_id, map_id)
	local addition = 0
	if obj_id and map_id then
		local info = self.exp_config[map_id]			--时间加成
		addition = info and (info.rate or 0) or 0
		local config = g_scene_config_mgr:get_extend_config(map_id)		--次数加成
		local limit = config and config.exp and config.exp.count and config.exp.count.number
		if limit then
			local obj = g_obj_mgr:get_obj(obj_id)
			local con = obj:get_copy_con()
			local count = con and con:get_count_copy(map_id) or 0
			if count > 0 and count <= limit then
				addition = addition + (config.exp.count.rate or 0)
			end
		end
	end
	return addition
end

function Scene_mgr:get_lost_addition(obj_id, map_id)
	local addition = 0
	if obj_id and map_id then
		local info = self.lost_config[map_id]
		addition = info and (info.rate or 0) or 0
		local config = g_scene_config_mgr:get_extend_config(map_id)		--次数加成
		local limit = config and config.lost and config.lost.count and config.lost.count.number
		if limit then
			local obj = g_obj_mgr:get_obj(obj_id)
			local con = obj:get_copy_con()
			local count = con and con:get_count_copy(map_id) or 0
			if count > 0 and count <= limit then
				addition = addition + (config.lost.count.rate or 0)
			end
		end
	end
	return addition
end

function Scene_mgr:get_frenzy_result()
	return self.frenzy_result
end

function Scene_mgr:on_new_day()
	local today_time = f_get_today()
	self.tomorrow = today_time + 86400
	self:load_timer_event(today_time)
	self:load_schedule(today_time)
	
	
	local fields = "{detail:1}"
	local query = "{date:0, scene_id:37000}"
	local index = "{date:1, scene_id:1}"
	local row, e_code = f_get_db():select_one("result_record", fields, query, nil, index)
	if 0 == e_code and row then
		self.frenzy_result = row.detail or {}
	end
end

function Scene_mgr:build_info_node(map_id, today, config, v, exec, timeout)
	local info = {}
	info.map_id = map_id
	info.rate = v.rate
	info.start_time = today + (v.hour or 0) * 3600 + (v.minu or 0) * 60
	info.end_time = info.start_time + v.interval * 60
	info.exec = exec
	info.timeout = timeout
	info.config = config
	return info
end

function Scene_mgr:set_extend(type, args)
	self.type_extend[type] = args
end

function Scene_mgr:get_extend(type)
	return self.type_extend[type]
end

function Scene_mgr:load_schedule(today)
	if f_is_pvp() or f_is_line_faction() or f_is_line_ww() then
		return
	end
	
	local schedule_list = g_scene_config_mgr:get_schedule_list()
	if not schedule_list then
		return
	end
	
	local date = os.date("*t", today)
	local schedule = schedule_list[date.wday]
	if not schedule then
		return
	end
	
	local list = {}
	
	local mgr = self
	
	local exec =
		function (o)
			local cmd = CMD_MAP_EXTEND_NOTIFY
			local pkt = string.format([[{"type":%d}]], o.type)
			
			if 0 == o.type then
				local args = {}
				args.args = table.copy(o.args)
				args.timeout = o.end_time
				mgr:set_extend(o.type, args)
			end
			
			local level = o.args.level
			for obj_id, obj in pairs(g_obj_mgr:get_list(OBJ_TYPE_HUMAN) or {}) do
				if level <= obj:get_level() then
					g_cltsock_mgr:send_client(obj_id, cmd, pkt, true)
				end
			end
		end
	
	local timeout =
		function (o)
		end
	
	for _, timespan in pairs(schedule) do
		for _, func in pairs(timespan.func or {}) do
			local info = {}
			info.start_time = today + timespan.time
			info.end_time = info.start_time + 360
			info.exec = exec
			info.timeout = timeout
			info.type = func.type
			info.args = func.args
			table.insert(list, info)
		end
	end
	
	self.schedule_list:reset(list)
end

function Scene_mgr:load_timer_event(today)
	self.exp_config = {}
	self.lost_config = {}

	local exp = {}
	local lost = {}
	
	local exec =
		function (o)
			o.config[o.map_id] = o
			return true
		end
		
	local timeout =
		function (o)
			o.config[o.map_id] = nil
		end

	for map_id, config in pairs(g_scene_config_mgr:get_extend_config_list()) do
		if config.exp and config.exp.time then
			for _, v in pairs(config.exp.time) do
				table.insert(exp, self:build_info_node(map_id, today, self.exp_config, v, exec, timeout))
			end
		end
		if config.lost and config.lost.time then
			for _, v in pairs(config.lost.time) do
				table.insert(lost, self:build_info_node(map_id, today, self.lost_config, v, exec, timeout))
			end
		end
	end
	
	self.exp_extend:reset(exp)
	self.lost_extend:reset(lost)
end

