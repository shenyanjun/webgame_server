
local copy_detail_config = require("scene_ex.config.copy_detail_loader")

Scene_copy = oo.class(Scene_entry, "Scene_copy")

function Scene_copy:__init(map_id, status)
	Scene_entry.__init(self, map_id)
	self.instance_list = {}
	self.timer_heap = Timer_heap()
	self:on_new_day()
	self.status = status or SCENE_STATUS.OPEN
end

-----------------------------------------------子类实现--------------------------------------------

--副本出口
function Scene_copy:get_home_carry(obj)
	return nil, nil
end

--获取副本实例ID
function Scene_copy:get_instance_id(obj)
end

--副本创建权限检查
function Scene_copy:check_create_access(obj)
end

--副本进入权限检查
function Scene_copy:check_entry_access(obj)
end

--创建副本实例
function Scene_copy:create_instance(instance_id, obj)
end

-----------------------------------------------场景实例化---------------------------------------------

function Scene_copy:get_instance(scene_id)
	local instance_id = scene_id and scene_id[2]
	return instance_id and self.instance_list[instance_id]
end

function Scene_copy:unregister_instance(instance_id, args)
	local instance = self.instance_list[instance_id]
	if instance then
		instance:close()
		self.instance_list[instance_id] = nil
	end
end

-----------------------------------------------场景入口----------------------------------------------

function Scene_copy:login_scene(obj, pos)
	local scene_id, home_pos = self:get_home_carry(obj)
	if not scene_id then
		return g_scene_mgr_ex:push_default(obj)
	end
	return g_scene_mgr_ex:push_scene(scene_id, home_pos, obj)
end

function Scene_copy:carry_scene(obj, pos, args)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local instance_id, e_code = self:get_instance_id(obj)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return e_code, nil
	end
	
	local instance = self.instance_list[instance_id]
	if not instance then
		local e_code, error_describe = self:check_create_access(obj)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			return e_code, error_describe
		end
		
		instance = self:create_instance(instance_id, obj)
		self.instance_list[instance_id] = instance
		g_scene_mgr_ex:register_instance(instance_id, self)
		if args == nil then
			args = {}
			args.obj = obj
		end
		instance:instance(args)
		
		local args = {}
		args.map_id = self.id
		args.type = self:get_type()
		g_event_mgr:notify_event(EVENT_SET.EVENT_CREATE_COPY_SCENE, obj:get_id(), args)
	else
		local e_code, error_describe = self:check_entry_access(obj)
		if SCENE_ERROR.E_SUCCESS ~= e_code then
			return e_code, error_describe
		end
	end
	return instance:carry_scene(obj, pos)
end

function Scene_copy:push_scene(obj, pos)
	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end
	
	local instance_id, e_code = self:get_instance_id(obj)
	if SCENE_ERROR.E_SUCCESS ~= e_code then
		return e_code, nilwa
	end
	
	local instance = self.instance_list[instance_id]
	if not instance then
		return SCENE_ERROR.E_NOT_ON_SCENE, nil
	end

	return instance:carry_scene(obj, pos)
end

-------------------------------------------------时间轮询处理------------------------------------------

function Scene_copy:on_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_timer(tm)
	end
	
	self.timer_heap:exec(ev.time)
end

function Scene_copy:on_slow_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_slow_timer(tm)
	end
end

function Scene_copy:on_serialize_timer(tm)
	for _, instance in pairs(self.instance_list) do
		instance:on_serialize_timer(tm)
	end
end

---------------------------------------------------------------------------------------------------------

function Scene_copy:on_new_day()
	local today = os.date("*t")
	today.hour = 0
	today.min = 0
	today.sec = 0
	local today_time = os.time(today)
	
	self:load_today_event(today)
	
	local tomorrow = today_time + 86400
	self.timer_heap:push(tomorrow, nil, self, "on_new_day", nil)
end

function Scene_copy:load_today_event(today)
	local config = g_all_scene_config[self.id]
	local freq_list = config and config.day_list and config.day_list[today.wday]
	
	if not freq_list or not freq_list.open_time then
		return
	end
	
	local today_time = os.time(today)

	for _, time_span in pairs(freq_list.open_time) do
		local start_time = today_time + (time_span.hour or 0) * 3600 + (time_span.minu or 0) * 60
		local end_time = start_time + (time_span.interval or 0) * 60
		self.timer_heap:push(start_time, end_time, self, "open_event", nil)
		self.timer_heap:push(end_time, end_time + 5 * 60, self, "close_event", nil)
	end
end

function Scene_copy:open_event(args)
	self.status = SCENE_STATUS.OPEN
end

function Scene_copy:close_event(args)
	self.status = SCENE_STATUS.CLOSE
end

----------****副本细节优化 提示下一个副本****---------------

function Scene_copy:get_next_copy(team_obj)
	local config = copy_detail_config.copy
	local team_l, team_count = team_obj:get_team_l()
	local lv_max = 1
	local lv_min = 100
	local obj_mgr = g_obj_mgr
	local scene_cnt_l = {}
	for k, _ in pairs(team_l or {}) do
		local obj = obj_mgr:get_obj(k)
		local level = obj and obj:get_level() or 24
		if level < lv_min then 
			lv_min = level
		end
		if level > lv_max then 
			lv_max = level
		end
	end
	local self_cate = config.copy_list[self.id] and config.copy_list[self.id].cate
	--限制条件
	if not self_cate then
		self_cate = 0
	end
	local next_copy1 = nil
	--print("self_cate", self_cate)
	for k, v in pairs(config.copy_cate[self_cate] or {}) do
		--等级上下限 队伍人数， 副本未满次数副本
		--print("&&same_cate_info:", v.name, v.id, v.lv_up, v.lv_down, v.min_number, v.max_number, team_count, scene_cnt_l[v.id])
		if self.id ~= v.id and v.lv_up >= lv_max and v.lv_down <= lv_min and 
						v.min_number <= team_count and v.max_number >= team_count then
			local is_cycle = nil
			for obj_id, _ in pairs(team_l or {}) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj and obj:get_copy_con():get_count_copy(v.id) >= v.cycle then 
					is_cycle = true
					break
				end
			end
			if not is_cycle then
				next_copy1 = v.id
				break
			end
			
		end
	end
	
	if next_copy1 then
		return next_copy1
	end

	local next_copy2 = nil
	for k, v in pairs(config.copy_pre_rank or {}) do
		--等级上下限 队伍人数， 副本未满次数副本
		--print("&&dif_cate_info:", v.name, v.id, v.lv_up, v.lv_down, v.min_number, v.max_number, team_count, scene_cnt_l[v.id])
		if self.id ~= v.id and self_cate ~= v.cate and v.lv_up >= lv_max and v.lv_down <= lv_min and 
						v.min_number <= team_count and v.max_number >= team_count then
			local is_cycle = nil
			for obj_id, _ in pairs(team_l or {}) do
				local obj = obj_mgr:get_obj(obj_id)
				if obj and obj:get_copy_con():get_count_copy(v.id) >= v.cycle then 
					is_cycle = true
					break
				end
			end
			
			if not is_cycle then
				next_copy2 = v.id
				break
			end
		end
	end
	
	return next_copy2 or 0
end
