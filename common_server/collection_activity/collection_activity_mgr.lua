
--2012-01-09
--cqs
--收集活动

-----------------------------------收集活动-----------------------------
require("collection_activity.collection_activity_db")

local collection_activity_loader = require("config.loader.collection_activity_loader")


Collection_activity_mgr = oo.class(nil, "Collection_activity_mgr")

--定时存盘时间
local update_items = 150
local update_records = 350

function Collection_activity_mgr:__init()
	self.swicth = 1
	--self:init_activity_id()
	self.active_info = {}
	--self:load_active_info()
end


--计算活动id
--self.change_t非空需倒计时		self.id非空  处于活动期  定时存盘
function Collection_activity_mgr:init_activity_id()

	--self.change_t, self.id = collection_activity_loader.get_recently_id()
--
	--self:init_activity()
end

--外部启动
function Collection_activity_mgr:load_active_info(uuid, end_t, start_t, id)
	if collection_activity_loader.check_activity_id(id) then
		self.id = id
		self.uuid = uuid
		self.change_t = end_t
		self.active_info.end_t = end_t
		self.active_info.start_t = start_t	
		self:init_activity()
	end
end

function Collection_activity_mgr:close_active_info()
	if self.uuid then
		Collection_activity_db:clear(self.uuid)
		self:activity_finish()
		self.active_info = {}
		self.id = nil
		self.change_t = nil
	end
end

function Collection_activity_mgr:init_activity()
	self.update_items = nil
	self.update_records = nil

	if self.id then
		self.update_items = ev.time + update_items
		self.update_records = ev.time + update_records
	
		local rs= Collection_activity_db:LoadAll(self.uuid)
		if rs == nil then 
			self.record = {}
			self.collection = Collection_activity_item(self.id,nil,self.active_info.start_t,self.active_info.end_t)
			return
		else
			for k , v in pairs(rs) do
				self.record = v.record or {}
				self.collection = Collection_activity_item(self.id, v.collection,self.active_info.start_t,self.active_info.end_t)
				break
			end
		end
	end
end

----------------计时器--------------
function Collection_activity_mgr:get_click_param()
	return self, self.on_timer,3,nil
end

function Collection_activity_mgr:on_timer()
	if self.change_t and ev.time > self.change_t then	--改变时间到
		--if self.id then		--活动结束
			----存盘
			--self:update_all()
			----结束广播,去buf
			--self:activity_finish()
			----重算
			--self:init_activity_id()
		--else				--活动开始
			--self:init_activity_id()
		--end
	end 

	if self.update_items and ev.time > self.update_items then	--改变时间到
		self.update_items = self.update_items + update_items

		self:update_collection_items()
	end 

	if self.update_records and ev.time > self.update_records then	--改变时间到
		self.update_records = self.update_records + update_records

		self:update_record_info()
	end 
end

-------------------------------------***数据库接口***------------
function Collection_activity_mgr:update_all()
	if self.id then
		Collection_activity_db:update_all(self.uuid, self.collection:spec_serialize_to_db(), self.record)
	end
end

function Collection_activity_mgr:update_collection_items()
	if self.id then
		Collection_activity_db:update_collections(self.uuid, self.collection:spec_serialize_to_db())
	end
end

function Collection_activity_mgr:update_record_info()
	if self.id then
		Collection_activity_db:update_record(self.uuid, self.record)
	end
end

function Collection_activity_mgr:add_record_item(content)
	if table.getn(self.record) >= 50 then
		table.remove(self.record, 1)
	end
	table.insert(self.record, content)
	local s_pkt = Json.Encode(content)
	if content[5] then
			g_svsock_mgr:send_server_ex(WORLD_ID, content[5], CMD_C2W_COLLECTION_ACTIVITY_EXP_S, s_pkt, true)
	else
		for k , v in pairs(g_player_mgr.online_player_l) do
			g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_COLLECTION_ACTIVITY_EXP_S, s_pkt, true)
		end
	end
	return
end
-------------------------------------***内部接口***------------
--结束广播,去buf
function Collection_activity_mgr:activity_finish(flags)
	--if not self.swicth then
		--return
	--end
	if self.uuid then
		self.collection:delete_all_map_buf()
		if not flags then
			self.collection = nil
		end
	end
	return
end

--广播map开关
function Collection_activity_mgr:map_activity_swicth(swicth)
	g_server_mgr:send_to_all_map(0, CMD_COLLECTION_ACTIVITY_SWITCH_C, {["swicth"] = swicth})
	return
end

------------------------------------***外部接口***------------
function Collection_activity_mgr:get_items_info()
	if not self.swicth then
		return
	end
	local pkt = {}

	if self.id then
		pkt = self.collection:get_items_info()
	end

	return pkt
end

function Collection_activity_mgr:add_collection_item(index, count)
	if not self.swicth then
		return
	end
	if self.id then
		pkt = self.collection:add_item_id(index, count)
	end
end

function Collection_activity_mgr:broadcast_items(pkt)
	if not self.swicth then
		return
	end
	if self.id then
		for k, v in ipairs(pkt) do
			self:add_record_item(v)
		end
	end
end

function Collection_activity_mgr:get_records_info()
	if not self.swicth then
		return
	end
	if self.id then
		return self.record
	end
end

function Collection_activity_mgr:check_swicth(swicth)
	--if swicth == 1 and not self.swicth then		--活动打开
		--self.swicth = 1
		--self:init_activity_id()
		--self:map_activity_swicth(1)
	--elseif swicth == 0 and self.swicth then		--活动关闭
		--self.swicth = nil
		--self:update_all()
		--self:activity_finish(1)
		--self:map_activity_swicth(0)
	--end
end

--------------------------------------发送到map-------
--新线同步全服buf
function Collection_activity_mgr:syn_all_buf(server_id)
	if not self.swicth then
		return
	end
	if self.id then
		self.collection:update_map_buf(server_id, 1)
	end
end

