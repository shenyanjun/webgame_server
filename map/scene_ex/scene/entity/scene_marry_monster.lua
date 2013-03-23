
local marry_config = require("scene_ex.config.marry_config_loader")

Scene_marry_monster = oo.class(Scene_instance, "Scene_marry_monster")

function Scene_marry_monster:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.hero_id = nil
	self.heroine_id = nil
	self.marry_id = nil
	--print("self.marry_id", instance_id, self.marry_id)
end

function Scene_marry_monster:get_self_config()
	return marry_config.config[self.id]
end

function Scene_marry_monster:carry_scene(obj, pos, args)

	if not obj then
		return SCENE_ERROR.E_NOT_ON_SCENE
	end

	local obj_id = obj:get_id()
	if obj_id ~= self.hero_id and obj_id ~= self.heroine_id then
		return 22600
	end
	if not self.owner_list[obj_id] then
		local config = self:get_self_config()
		local cycle_limit = config.cycle
		local con = obj:get_copy_con()
		if cycle_limit and con:get_count_copy(self.id) >= cycle_limit then
			return SCENE_ERROR.E_CYCLE_LIMIT
		end
		con:add_count_copy(self.id)
		
		self.owner_list[obj_id] = true
		
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	
	return self:push_scene(obj, pos)
end

function Scene_marry_monster:on_timer(tm)
	if ev.time > self.end_time then
		self:close()
	end

	self.obj_mgr:on_timer(tm)
end

function Scene_marry_monster:instance(args)
	--
	local marry = args.marry
	g_marry_mgr:add_fb_count(marry.uuid, self.id, 1)
	self.marry_id = marry.uuid
	if marry.sex == 0 then
		self.hero_id = marry.char_id
		self.heroine_id = marry.mate_id
	else
		self.heroine_id = marry.char_id
		self.hero_id = marry.mate_id
	end
	local config = self:get_self_config()
	self.end_time = ev.time + (config.timeout or 100)
	local sequence_list = nil
	local level = args.obj:get_level()
	local intimacy = marry.m_q
	for k, v in ipairs(config.monster) do
		sequence_list = v.item		
		if level >= v.level and intimacy >= v.intimacy then
			break
		end
	end
	
	self.obj_mgr = Scene_obj_mgr_ex(Scene_monster_layout(self.key, true), Scene_monster_copy_mgr())
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())

	self:create_monster(sequence_list)
end

function Scene_marry_monster:create_monster(sequence_list)
	
	for k, v in ipairs(sequence_list or {}) do
		for i = 1, v[2] do
			local pos = self.map_obj:find_space(v[3], 20)
			if pos then
				local obj = g_obj_mgr:create_monster(v[1], pos, self.key)
				if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then

				end
			else
				break
			end
		end
	end
end