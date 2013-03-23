Summon_mgr = oo.class(nil, "Summon_mgr")

function Summon_mgr:__init(scene_o)
	self.is_doing = nil
	self.scene_o = scene_o
	self.coll_obj_list = {}
	self.coll_size = 0
end

function Summon_mgr:reset_config(config)
	self.config = config
	if not self.config then
		self.config = {}
	end
	self.coll_info = {}
	self.time_count = {}
	for k, v in ipairs(self.config) do
		self.coll_info[v[1]] = 0		--计数
		self.time_count[k] = 0			--计时
	end
	self:clear()
end


function Summon_mgr:start()
	self.is_doing = true
	local h_size = g_obj_mgr:get_size(OBJ_TYPE_HUMAN)
	self.coll_size = math.floor(30 + 20 * math.max(0, (h_size - 30) / 30))
	print("Summon_mgr:start:", h_size, self.coll_size)
end

function Summon_mgr:stop()
	self.is_doing = nil
	self.coll_size = 0
end

function Summon_mgr:clear()
	local obj_mgr = g_obj_mgr
	for k, v in pairs(self.coll_obj_list) do
		local obj = obj_mgr:get_obj(k)
		local _ = obj and obj:leave()
	end
	self.coll_obj_list = {}
end

function Summon_mgr:coll_leave(collect_id, id)
	--print("Summon_mgr:coll_leave", collect_id, id)
	if self.coll_info and self.coll_info[collect_id] then
		self.coll_info[collect_id] = self.coll_info[collect_id] - 1
	end
	self.coll_obj_list[id] = nil
end

function Summon_mgr:doing(now)
	
	if not self.is_doing then
		return
	end
	for k, time in ipairs(self.time_count) do
		local entry = self.config[k]
		if now >= time then
			local nu = math.floor(self.coll_size * entry[2]) - self.coll_info[entry[1]]
			if nu > 0 then
				self:create_collect_obj(entry[1], nu, entry[4])
			end
			self.time_count[k] = now + entry[3]
		end
	end
end

function Summon_mgr:create_collect_obj(collect_id, count, area)
	--print("Summon_mgr:create_collect_obj", collect_id, count, area)
	local map_o = self.scene_o:get_map_obj()
	local obj_mgr = g_obj_mgr

	for i = 1, count do
		--local cur_pos = {289, 273}
		--local pos_m = {cur_pos[1]-5,cur_pos[1]+5,cur_pos[2]-5,cur_pos[2]+5}
		--local pos = map_o:find_pos(pos_m) or cur_pos
		local pos = map_o:find_space(area, 20)
		if pos then
			local collect_obj = obj_mgr:create_npc(collect_id, "", pos, self.scene_o.key)
			if collect_obj and SCENE_ERROR.E_SUCCESS == self.scene_o:enter_scene(collect_obj) then
				self.coll_info[collect_id] = self.coll_info[collect_id] + 1
				self.coll_obj_list[collect_obj:get_id()] = 1
				--print("----->pos", i, pos[1], pos[2])
			end
		end
	end
end
