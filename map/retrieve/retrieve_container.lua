--2011-12-13
--cqs

--经验找回

Retrieve_container = oo.class(Observable, "Retrieve_container")

local retrieve_loader = require("config.loader.retrieve_loader")

function Retrieve_container:__init(char_id)
	Observable.__init(self, 3)

	self.char_id = char_id

	self.items = {}
end

------------------------------------------------数据库读写-------------------------------------------
--加载找回系统信息
function Retrieve_container:load(first_login)
	local tmp_table = g_retrieve_mgr:get_all_items()
	local meta_list =  g_retrieve_mgr:get_meta_list()
	local today = f_get_today()

	if first_login then
		for k, v in ipairs(tmp_table) do
			local retrieve= v:clone(nil)
			retrieve:construct(self)

			self.items[k] = retrieve
		end
		self:init_serialize()
	else
		local row = Retrieve_db:Select_retrieve(self.char_id)

		if row == nil then
			for k, v in ipairs(tmp_table) do
				local retrieve= v:clone(nil)
				retrieve:construct(self)

				self.items[k] = retrieve
			end
			self:init_serialize()
		else
			self.update = row.update

			if self.update < today then
				local day = math.floor((today - self.update) / 86400)
				for k, v in ipairs(tmp_table) do
					if not row.items[k] then
						local retrieve= v:clone(nil)
						retrieve:construct(self)
						self.items[k] = retrieve
					else
						local retrieve = g_retrieve_mgr:load_retrieve(k, row.items[k])
						retrieve:construct(self)

						retrieve:update_days(day)

						self.items[k] = retrieve
					end
				end
			else
				for k, v in ipairs(tmp_table) do
					local retrieve
					if not row.items[k] then
						retrieve = v:clone(nil)
						retrieve:construct(self)
					else
						retrieve = g_retrieve_mgr:load_retrieve(k, row.items[k])
						retrieve:construct(self)
					end

					self.items[k] = retrieve
				end
			end

			self.record = 1
		end
	end

	self.update = today

	return true
end

--
function Retrieve_container:level_up_init()
	local tmp_table = g_retrieve_mgr:get_all_items()
	local today = f_get_today()

	for k, v in ipairs(tmp_table) do
		local retrieve= v:clone(nil)
		retrieve:construct(self)

		self.items[k] = retrieve
	end
	self:init_serialize()
	self.update = today

	return true
end

--整个入库
function Retrieve_container:init_serialize()
	local date = {} 
	date.char_id = self.char_id
	date.update = f_get_today()
	date.items = {}

	Retrieve_db:update_all(date)

	return true
end

--整个入库
function Retrieve_container:save(type)
	if type == 1 and self.record == nil then
		return
	end

	Retrieve_db:update_time(self.char_id, self.update)

	for k, v in ipairs(self.items) do
		v:serialize_to_db()
	end

	self.record = nil
	return true
end

--项目入库
function Retrieve_container:update_items()
	Retrieve_db:update_items(self.char_id, self.items)

	return true
end

--定时入库
function Retrieve_container:update_on_time()
	if self.record then
		self:save()
	else
		return true
	end

	self.record = nil

	return true
end

----------------------------------------mysql后台日志----------


-------------------------------------******内部接口******----------------------------
--按ID更新项目
function Retrieve_container:complete_items(id)
	if self.items[i] and self.items[i].flag == 0 then
		self.items[i].flag = 1
	end

	return true
end


-------------------------------------***外部接口***----------
--隔天更新
function Retrieve_container:newday_update_items()
	if self.char_id == 0 then
		return true
	end
	local today = f_get_today()
	if self.update < today then
		for k, v in ipairs(self.items) do
			v:update_days(1)
		end
	end

	self.update = today
	self.record = 1

	return true
end

----------------------------------------************与客户端交互***************-------
function Retrieve_container:get_all_info_net()
	local pkt = {}

	pkt.result = 0
	pkt.items = {}

	for k, v in ipairs(self.items) do
		local net = v:serialize_to_net()
		if net then
			table.insert(pkt.items, net)
		end
	end

	return pkt
end

function Retrieve_container:check_authorize(map_id)
	for k, v in ipairs(self.items) do
		if v:is_scene_type() and v:check_map_id(self, map_id) then
			break
		end
	end
end

function Retrieve_container:get_retrieve_reward(id, type)
	local pkt = {}

	pkt.result = 0
	if not self.items[id] then
		pkt.result = 22701
		return pkt
	end

	if self.items[id]:get_day() < 1 then
		pkt.result = 22704
		return pkt
	end
	 
	pkt.result = self.items[id]:do_reward(type)

	return pkt
end

--获取离线所需钱跟奖励  --副本全部的
function Retrieve_container:get_all_retrieve_reward(type)
	local money = 0
	local exp   = 0
	local allmoney = 0
	local allexp   = 0

	for i,v in pairs(self.items) do
		if self.items[v.id]:get_day() >= 1 then
			money,exp =  self.items[v.id]:offline_reward(type)
			allmoney = allmoney + money
			allexp   = allexp + exp
		end
	end
	return allmoney,allexp
end

function Retrieve_container:updaete_alldata()
	local pkt = {}
	pkt.items = {}
	for i,v in pairs(self.items) do
		self.items[v.id]:set_days(0)
		pkt.items[v.id] =  self.items[v.id]:get_update_data()
	end
	local m_db = f_get_db()
	local query = string.format("{char_id:%d}", self.char_id)
	m_db:update("retrieve", query, Json.Encode(pkt), true, false)
	return 0
end
