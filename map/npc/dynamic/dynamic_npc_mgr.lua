Dynamic_npc_mgr = oo.class(nil, "Dynamic_npc_mgr")

local config = require("npc.dynamic.dynamic_npc_loader")
local action_config = require("npc.config.action_loader")

local strategy_list = create_local("dynamic_npc_mgr.strategy_list", {})

function Dynamic_npc_mgr:__init()
	self.obj_heap = Min_heap()
	self:on_new_day()
	self.schedule = {}
	self.tomorrow = 0
end

function Dynamic_npc_mgr.register_strategy(type, builder)
	strategy_list[type] = builder
end

function Dynamic_npc_mgr:create_dynamic_npc(occ, name, scene_id, pos, livetime, param)
	local obj = f_npc_create_enter(occ, name, pos, scene_id, param)
	if obj and livetime then
		self.obj_heap:push(ev.time + livetime, obj:get_id())
	end
	return obj
end

function Dynamic_npc_mgr:on_new_day()
	local today_time = f_get_today()
	self.tomorrow = today_time + 86400
	self:load_schedule(today_time)
end

function Dynamic_npc_mgr:on_timer()
	local now = ev.time
	
	if self.tomorrow < now then
		self:on_new_day()
	end
	
	while not self.obj_heap:is_empty() do
		local o = self.obj_heap:top()
		if o.key > now then
			break
		end
		
		self.obj_heap:pop()
		
		f_npc_leave(o.value)
	end
	
	for _, schedule in pairs(self.schedule) do
		schedule:on_timer(now)
	end
end

function Dynamic_npc_mgr:load_schedule(today)
	if f_is_pvp() or f_is_line_faction() or f_is_line_ww() then
		return
	end
	
	local schedule_list = config.schedule
	if not schedule_list then
		return
	end
	
	local date = os.date("*t", today)
	local schedule = schedule_list[date.wday]
	if not schedule then
		return
	end
	
	self.schedule = {}
	
	for type, timespan in pairs(schedule) do
		local builder = strategy_list[type]
		if builder then
			local strategy = builder()
			if strategy then
				strategy:load_schedule(today, timespan)
				table.insert(self.schedule, strategy)
			end
		else
			print("-----", type)
		end
	end
end

function Dynamic_npc_mgr:get_npc_actions(npc_id)
	local obj = g_obj_mgr:get_obj(npc_id)
	if obj and f_is_dynamic_npc(obj:get_occ()) then
		local args = obj:get_param()
		if args and args.action_id then
			return action_config.ActionTable[args.action_id]
		end
	end
end