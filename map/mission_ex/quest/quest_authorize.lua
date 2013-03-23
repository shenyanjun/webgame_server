
local misson_loader = require("mission_ex.mission_loader")
local authorize_loader = require("config.loader.authorize_loader")

--杀怪任务
Quest_authorize = oo.class(Quest_base, "Quest_authorize")

function Quest_authorize:__init(meta,authorize)
	Quest_base.__init(self, meta)
	self.kill_monster = {}
	self.accept_time = ev.time + authorize_loader.get_authorize_complete_time(self:get_id())	--其实是过期时间
	if authorize then
		self.authorize = 1
	end
end

function Quest_authorize:register_event(con)
	assert(con)
	con:register_event(MISSION_EVENT_KILL, self.quest_id, self, self.kill_event)
end

function Quest_authorize:unregister_event(con)
	con:unregister_event(MISSION_EVENT_KILL, self.quest_id)
end

function Quest_authorize:can_accept(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return  end
	local count_con  = player:get_copy_con()
	if not count_con then return end
	local scene_id = authorize_loader.get_authorize_scene(self:get_id())
	if scene_id then
		 if g_scene_config_mgr:get_copy_limit(scene_id) <= count_con:get_count_copy(scene_id) then
			return 200109
		 end
	end

	return Quest_base.can_accept(self,char_id)
end

function Quest_authorize:on_accept(char_id)
	self.char_id = char_id

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return 20527 end

	local eco = Quest_base.on_accept(self,char_id)
	
	return eco
end

function Quest_authorize:on_complete(char_id, select_list)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end

	local pkt = {}
	pkt.authorize_id = self:get_id()

	local e_code, next_quest_chain
	if not self.complete_time or self.accept_time <= self.complete_time then
		ret, list = Quest_base.on_complete(self,char_id, select_list, 0)
	else
		ret, list = Quest_base.on_complete(self,char_id, select_list)
	end

	if self.complete_time and self.accept_time > self.complete_time then
		if self.authorize then
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_C2W_AUTHORIZE_COMPLETE_M, pkt)
		end
	end

	local pledge = authorize_loader.get_authorize_pledge(self:get_id())
	if pledge and pledge > 0 then
		pack_con:add_money(MoneyType.GOLD, pledge, {['type']=MONEY_SOURCE.COMPLETE_AUTHORIZE})
	end

	return ret ,list
end

function Quest_authorize:on_delete(con)
	local expired = self.accept_time
	local authorize = self.authorize
	local pkt = {}
	pkt.authorize_id = self:get_id()

	local e_code = Quest_base.on_delete(self, con)
	if E_SUCCESS == e_code then
		if expired > ev.time and authorize then
			g_svsock_mgr:send_server_ex(COMMON_ID,con:get_owner(), CMD_C2W_AUTHORIZE_COMPLETE_M, pkt)
		end
	end
	return e_code
end

function Quest_authorize:load_fields(record)
	local obj, e_code = Quest_base.load_fields(self, record)
	
	obj.kill_monster = {}
	if record.kill_monster then
		for k, v in pairs(record.kill_monster) do
			obj.kill_monster[tonumber(k)] = v
		end
	end
	obj.authorize	= record.authorize
	obj.accept_time = record.accept_time
	if record.complete_time then
		obj.complete_time = record.complete_time
	elseif obj.accept_time < ev.time then
		obj.status = MISSION_STATUS_COMMIT
		obj.complete_time = ev.time
	end
	return obj, E_SUCCESS
end

function Quest_authorize:serialize_to_net()
	local result = Quest_base.serialize_to_net(self)
	result.base[3] = self.accept_time - ev.time
	local kill_monster = {}
	for k, v in pairs(self.kill_monster) do
		local item = {}
		table.insert(item, k)
		table.insert(item, v)
		table.insert(kill_monster, item)
	end
	result.kill_monster = kill_monster
	return result
end

function Quest_authorize:serialize_to_db()
	local result = Quest_base.serialize_to_db(self)
	result.kill_monster = {}
	for k, v in pairs(self.kill_monster) do
		result.kill_monster[tostring(k)] = v
	end
	result.authorize   = self.authorize
	result.accept_time = self.accept_time
	if self.complete_time then
		result.complete_time = self.complete_time
	end
	return result
end

function Quest_authorize:kill_event(con, monster_id)
	local meta = misson_loader.get_meta(self.quest_id)
	if not meta then
		return
	end
	
	local monster_list = meta.postcondition and meta.postcondition.monster_list
	if not monster_list or not monster_id or not monster_list[monster_id]then
		return
	end

	if not self.kill_monster[monster_id] then
		self.kill_monster[monster_id] = 1
	elseif self.kill_monster[monster_id] < monster_list[monster_id].number then
		self.kill_monster[monster_id] = self.kill_monster[monster_id] + 1 
	else
		--之前已经达到目标上限
		return
	end
	
	--未达到条件上限
	if self.kill_monster[monster_id] < monster_list[monster_id].number then
		con:notity_update_quest(self.quest_id, true)
		return
	end
	
	--检查是否全部完成
	for k, v in pairs(monster_list) do
		if not self.kill_monster[k] or self.kill_monster[k] < v.number then
			--没有全部完成则通知更新并返回
			con:notity_update_quest(self.quest_id, true)
			return
		end
	end
	
	self:unregister_event(con)
	self.status = MISSION_STATUS_COMMIT
	self.complete_time = ev.time
	con:notity_update_quest(self.quest_id, true)
end

Mission_mgr.register_class(MISSION_FLAG_AUTHORIZE, Quest_authorize)