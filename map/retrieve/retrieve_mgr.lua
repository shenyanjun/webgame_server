local _builder_list = create_local("retrieve_mgr._builder_list", {})

local retrieve_loader = require("config.loader.retrieve_loader")

Retrieve_mgr = oo.class(nil, "Retrieve_mgr")

function Retrieve_mgr:__init()
	self.items_list = {}
	self.daily_list = {}
	self.scene_list = {}

	self.meta_list = {}

	self:load()
end

--注册任务类的构建者，构建者可以是类（是类，不是对象除非是函数对象），函数对象，函数
function Retrieve_mgr.register_class(type, builder)
	_builder_list[type] = builder
end

function Retrieve_mgr:load_prototype(meta)
	local quest_id = meta.id
	--local flag = meta.flag
	local type = meta.type
	
	local builder = _builder_list[type]
	if not builder then
		return 
	end

	local retrieve = builder(meta)

	return retrieve
end

function Retrieve_mgr:load()
	self.items_list = {}
	self.daily_list = {}
	self.scene_list = {}
	
	local tmp_table = retrieve_loader.get_total_info()
	self.meta_list = tmp_table

	for id, meta in ipairs(tmp_table) do
		local retrieve = self:load_prototype(meta)
		if retrieve then
			self.items_list[id] = retrieve

			if meta.type == 1 then
				table.insert(self.daily_list, id)
			elseif meta.type == 2 then
				table.insert(self.scene_list, id)
			end
		end
	end
	--for k, v in pairs(self.quest_finca) do
		--print("self.quest_finca =", j_e(k))
	--end
end

function Retrieve_mgr:load_retrieve(id, record)
	if not record then
		print("fsdaaa", record)
		return E_MISSION_INVALID_DATA
	end
	
	local prototype = id and self.items_list[id]
	if not prototype then
		print("fsda", id)
		return E_MISSION_INVALID_ID
	end
	
	return prototype:clone(record)
end

function Retrieve_mgr:build_retrieve(id)	
	local prototype = id and self.items_list[id]
	if not prototype then
		return E_MISSION_INVALID_ID
	end
	
	return prototype:clone(nil)
end

function Retrieve_mgr:get_all_items()
	
	return self.items_list
end

function Retrieve_mgr:get_meta_list()
	
	return self.meta_list
end

function Retrieve_mgr:get_meta(id)
	
	return self.meta_list[id]
end
