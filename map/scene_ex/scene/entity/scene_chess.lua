local chess_config = require("scene_ex.config.chess_config_loader")

Scene_chess = oo.class(Scene_instance, "Scene_chess")
function Scene_chess:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.sequence = 0
	self.next_time = ev.time
	self.is_success = false
	self.close_time = nil
	self.start_time = ev.time
	self.must_clear = nil		-- 必须清理才刷下一波
	self.check_time = ev.time + 10
	self.step = 0				-- 当前打到第几波（以时间点为分界）
	self.step_time = 0			-- 当前波开始时间
end


function Scene_chess:get_self_config()
	return chess_config.config[self.id]
end

function Scene_chess:get_self_limit_config()
	return self:get_self_config().init.limit
end

--副本出口
function Scene_chess:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.init.home
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_chess:carry_scene(obj, pos)
	local config = self:get_self_config()
	local new_pos = config.init.entry
	return Scene_instance.carry_scene(self, obj, {new_pos[1], new_pos[2]})
end

function Scene_chess:next_sequence()
	if self.is_success then
		return
	end

	self.sequence = self.sequence + 1

	local config = self:get_self_config()
	local wild = config.wild
	if not wild then
		return
	end
	local freq = wild[self.sequence]
	if not freq then
		self.is_success = true
		return
	end
	self.next_time = ev.time + freq.interval
	if freq.time > 0 then
		self:set_finish_time()
		self:reset_end_time(ev.time + freq.time)
		self.step = self.step + 1
	end

	if freq.sequence then
		for _, item in pairs(freq.sequence) do
			for i = 1, item.number do
				local pos = self.map_obj:find_space(item.area, 20)
				if pos then
					local obj = g_obj_mgr:create_monster(item.id, pos, self.key)
					if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
						if item.type and item.type == 1 then
							if self.must_clear == nil then
								self.must_clear = {}
							end
							self.must_clear[obj:get_id()] = 1
						end
					end
				else
					break
				end
			end
		end
	end
end


function Scene_chess:on_timer(tm)
	local now = ev.time
	if (self.end_time and self.end_time <= now) then

		self:close()
		return
	end
	
	if self.next_time <= now and self.must_clear == nil then
		self:next_sequence()
	end

	if ev.time > self.check_time then
		con = self.obj_mgr:get_obj_con(OBJ_TYPE_MONSTER)
		if con == nil or table.is_empty(con:get_obj_list()) then
			self:next_sequence()
		end
		self.check_time = ev.time + 5
	end

	self.obj_mgr:on_timer(tm)

end

function Scene_chess:instance(args)
	local config = self:get_self_config()
	self.end_time = ev.time + config.init.limit.time
	self.start_time = ev.time
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())

	--
	if args and args.target then
		for obj_id, obj in pairs(args.members or {}) do
			local con = obj:get_copy_con()
			con:add_count_copy(self.id)
			self.owner_list[obj_id] = true
			f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
						, self.id
						, obj_id
						, ev.time
						, obj:get_name()))
		end
		--
		self.sequence = args.target
		self.step = 0
		local config = self:get_self_config()
		local wild = config.wild
		for k, v in ipairs(wild) do
			if k > self.sequence then
				break
			end
			if v.time > 0 then
				self.step = self.step + 1
			end
		end
		--print("self.sequenece:", self.sequence, self.step)
	end
end


function Scene_chess:on_obj_leave(obj)
	Scene_instance.on_obj_leave(self, obj)
	
	if self.must_clear ~= nil then
		self.must_clear[obj:get_id()] = nil
		if table.is_empty(self.must_clear) then
			self.must_clear = nil
			self.check_time = ev.time
		end
	end
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local args = obj:get_scene_args()
		local id = tostring(self.id)
		local max_layer = args[id] or 0
		if max_layer < self.sequence - 1 then
			args[id] = self.sequence - 1
		end
	end
end

-- 当前波数及完成时间
function Scene_chess:set_finish_time()
	if self.step > 0 and self.step_time > 0 then
		local time = ev.time - self.step_time
		local team_obj = g_team_mgr:get_team_obj(self.instance_id)
		if team_obj then
			local team_l = team_obj:get_team_l()
			if team_l then
				local data = {}
				local obj_mgr = g_obj_mgr
				for k, _ in pairs(team_l) do
					local obj = obj_mgr:get_obj(k)
					if obj then
						table.insert(data, {['id'] = k, ['name'] = obj:get_name()})
					end
				end

				g_public_sort_mgr:update_record(
					PUBLIC_SORT_TYPE.SCENE
					, time
					, {["scene_id"] = self.id, ["id"] = self.step, ["data"] = data}
					, PUBLIC_SORT_ORDER.ASC)
			end
		end
	end
	self.step_time = ev.time
end