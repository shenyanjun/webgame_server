Dymanic_strategy = oo.class(nil, "Dymanic_strategy")

function Dymanic_strategy:__init()
	self.timer_heap = Timer_heap()
	self.factor = 0
end

function Dymanic_strategy:load_schedule(today, schedule_list)	
	self.timer_heap:push(
		today + 3600 * 5
		, nil
		, self
		, "load_data"
		, nil)
	
	for _, timespan in pairs(schedule_list) do
		local start_time = today + timespan.time
		self.timer_heap:push(
			start_time
			, start_time + 300
			, self
			, "invoke"
			, timespan.func.args)
	end	
end

function Dymanic_strategy:on_timer(now)
	self.timer_heap:exec(now)
end

function Dymanic_strategy:load_data()
	local dbh = get_dbh_web()
	local yesterday = os.date("%Y%m%d", f_get_today() - 86400)
	local row = dbh:selectrow_ex("select old_player as factor from stat_all where date = '20110725'")
	
	print(dbh.errcode, row, yesterday)
	
   	if row and dbh.errcode == 0 then
   		self.factor = tonumber(row.factor) or 1
	else
		self.factor = 1
	end
end

function Dymanic_strategy:invoke(args)
	local factor = args.factor
	local number = math.max(math.floor(self.factor * factor[1] + factor[2]), args.default)
	
	local total = 0
	for _, area in ipairs(args.area_list or {}) do
		local scene_id = {area.id}
		local scene = g_scene_mgr_ex:get_scene(scene_id)
		local map_obj = scene and scene:get_map_obj()
		if map_obj then
			for i = 1, area.number do
				if total >= number then
					return
				end
				total = total + 1
				local pos = map_obj:find_space(area.area, 20)
				if pos then
					local obj = g_dynamic_npc_mgr:create_dynamic_npc(
						args.occ
						, args.name
						, scene_id
						, pos
						, args.timeout
						, {['action_id'] = args.action_id})
				end
			end
		end
	end
end

Dynamic_npc_mgr.register_strategy(1, Dymanic_strategy)