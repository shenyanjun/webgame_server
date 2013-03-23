local mission_table = "mission"
local mission_index = "{'char_id':1}"
local complete_table = "complete_mission"
local complete_index = "{'char_id':1}"
local daily_complete_table = "daily_complete_mission"
local daily_complete_index = "{'char_id':1}"

Mission_container = oo.class(Observable, "Mission_container")

local no_record_mission_tpye = {[MISSION_TYPE_AUTHORIZE] = true,
								[MISSION_TYPE_LOOP_NEW] = true,
								[MISSION_TYPE_MANOR] = true,
								[MISSION_TYPE_NO_MANOR] = true,
								[MISSION_TYPE_MIX] = true,
								[MISSION_TYPE_RANDOM] = true,
								[MISSION_TYPE_FINCA] = true,
								[MISSION_TYPE_FACTION_SCROLL] = true,
								[MISSION_TYPE_BATTLE_DAY_LOOP] = true,
								[MISSION_TYPE_BATTLE_LOOP] = true
								}
function Mission_container:__init(char_id)
	Observable.__init(self, 0)
	self.char_id = char_id
	self.accept_list = {}
	self.complete_list = {}
	self.complete_daily = {}
	self.quest_param = {}
	self.quest_flags = {}
	--self.loop_mission = {}
	--self.loop_faction_mission = {}		--任务环数step，quest_id，更新时间update_time，随机次数count

	self.on_complete = false		--防止任务完成中发生升级事件而通知客户端

	--待保存列表
	self.update_list = {}
end

function Mission_container:get_param(type)	--MISSION_TYPE
	return self.quest_param[type]
end

function Mission_container:set_param(type, value)
	self.quest_param[type] = value
end

function Mission_container:get_flags(type)
	return self.quest_flags[type]
end

function Mission_container:set_flags(type, value)
	self.quest_flags[type] = value
end

--获取角色ＩＤ
function Mission_container:get_owner()
	return self.char_id
end

--任务是否已经接受或完成
function Mission_container:is_exists(quest_id)
	return nil ~= self.accept_list[quest_id] or nil ~= self.complete_list[quest_id] or nil ~= self.complete_daily[quest_id]
end

--任务是否已经完成
function Mission_container:is_complete(quest_id)
	return nil ~= self.complete_list[quest_id] or nil ~= self.complete_daily[quest_id]
end

--得到接受的任务对象
function Mission_container:get_accept_mission(quest_id)
	return self.accept_list[quest_id]
end

function Mission_container:get_accept_list()
	return self.accept_list
end

---------------------------------------------------------------------------------------------------------------------
--角色升级通知
function Mission_container:notify_level_up_event(args)
	Observable.notify_level_up_event(self, args)
	if not self.on_complete then
		self:notity_available_quest()
	else
		self.on_complete = false
	end
end

function Mission_container:notify_new_day_event(args)
	local today = f_get_today()
	for k, v in pairs(self.complete_daily) do
		if v < today then
			self.complete_daily[k] = nil
		end
	end
	for quest_id , quest in pairs (self.accept_list) do
		if quest:get_type() == MISSION_TYPE_BATTLE_DAY_LOOP then
			self:delete_quest(quest_id)
		elseif quest:get_type() == MISSION_TYPE_BATTLE_LOOP then
			self:delete_quest(quest_id)
		end
	end
	--Observable.notify_new_day_event(self,args)
	self:notity_available_quest()
end

function Mission_container:accept_and_record(quest,update)
	e_code = quest:can_accept(self.char_id)
	if E_SUCCESS == e_code then
		self.accept_list[quest:get_id()] = quest
		e_code = quest:on_accept(self.char_id)
		if E_SUCCESS ~= e_code then
			self.accept_list[quest:get_id()] = nil
		else
			self:update_quest_record(quest)
			
			f_multi_web_sql(
				string.format(
					"replace into mission_receive set char_id=%d, quest_id='%s', type=%d, status=1, create_time=%d"
						, self.char_id
						, quest:get_id()
						, quest:get_type()
						, os.time()))
			if update then
				self:notify_accpet_quest(quest:get_id())
			end
		end

	end

	return e_code
end

function Mission_container:do_accept_quest(quest_id,update)
	if self:is_exists(quest_id) then
		return E_MISSION_ALREADY_ACCEPT
	end
	
	local quest, e_code = g_mission_mgr:build_quest(quest_id)
	if E_SUCCESS ~= e_code then
		return e_code
	end
	
	return self:accept_and_record(quest,update)
end

--接受任务
function Mission_container:accept_quest(quest_id)
	local e_code = self:do_accept_quest(quest_id,1)
	--if E_SUCCESS == e_code then
		--self:notify_accpet_quest(quest_id)
	--end
	return e_code
end

--删除任务
function Mission_container:delete_quest(quest_id)
	local e_code = E_SUCCESS
	local quest = quest_id and self.accept_list[quest_id]
	if quest then
		e_code = quest:on_delete(self)
		if E_SUCCESS == e_code then
			self:delete_accept_record(quest_id)
			self:notity_available_quest()
			f_multi_web_sql(
				string.format(
					"replace into mission_receive set char_id=%d, quest_id='%s', status=0"
						, self.char_id
						, quest_id))
		end
	end
	return e_code
end

--完成任务
function Mission_container:complete_quest(quest_id, select_list, param_l)
	local quest = quest_id and self.accept_list[quest_id]
	if not quest then
		return E_MISSION_INVALID_ID
	end
	
	self.on_complete = true
	
	local e_code, next_quest_chain = quest:on_complete(self.char_id, select_list, nil, param_l)
	if e_code and E_SUCCESS == e_code then
		local quest_type = quest:get_type()
		local quest_flag = quest:get_flag()
		if MISSION_TYPE_DAILY == quest_type or MISSION_TYPE_ESCORT == quest_type 
		or MISSION_TYPE_VIP_ESCORT == quest_type or MISSION_TYPE_BATTLE_DAY_LOOP == quest_type 
		or quest_flag == MISSION_FLAG_SPEAK and MISSION_TYPE_DAILY == quest_type 
		then
			self:update_daily_complete_record(quest_id,quest_type,quest_flag)			
		elseif no_record_mission_tpye[quest_type] then
			self:delete_accept_record(quest_id)
		else
			self:update_complete_record(quest_id)
		end
		
		if next_quest_chain then
			local quest_chain = {}
			for k, _ in pairs(next_quest_chain) do
				local e_code = self:do_accept_quest(k)
				if E_SUCCESS ~= e_code then
					local player = g_obj_mgr:get_obj(self.char_id)
					local level = player:get_level()
					f_quest_error_log("Next Quest Accept Occur Error, quest_id = %s, e_code = %s, level = %s.", tostring(k), tostring(e_code), tostring(level))
				else
					quest_chain[k] = true
				end
			end
			self:notify_accpet_quest_list(quest_chain)
		else
			self:notity_available_quest()
		end
		
		--日常环任务
		if quest_type == MISSION_TYPE_DAILY and quest_flag == MISSION_FLAG_KILL 
		or quest_type == MISSION_TYPE_DAILY and quest_flag == MISSION_FLAG_SPEAK
		then
			local player = g_obj_mgr:get_obj(self.char_id)
			local con	 = player:get_mission_mgr()
			local ret ,quest_id = g_mission_mgr:random_daily_quest(self.char_id)
			if ret == 0 then
				local loop_daily_mission = {}
				loop_daily_mission.quest_id 	= quest_id
				con:set_param(PARAM_TYPE_LOOP_DAILY,loop_daily_mission)
			end		
			player:set_misc(8)
			self:getandaccpet_loopdaily()
		end

		local args = {}
		args.id = quest_id
		args.type = quest_type
		args.flag = quest:get_flag()
		g_event_mgr:notify_event(EVENT_SET.EVENT_COMPLETE_QUEST, self.char_id, args)
		
		f_multi_web_sql(
			string.format(
				"delete from mission_receive where char_id=%d and quest_id='%s'"
					, self.char_id
					, quest_id))
		
		f_multi_web_sql(
			string.format(
				"replace into mission_complete set char_id=%d, quest_id='%s', type = %d, create_time=%d"
					, self.char_id
					, quest_id
					, quest:get_type()
					, os.time()))
	end
	
	self.on_complete = false
	return e_code
end

---------------------------------------------------------------------------------------------------------------------

function Mission_container:load_accept()
	local query = string.format("{'char_id':%d}", self.char_id)
	local db = f_get_db()
	local row, e_code = db:select_one(mission_table, "{'_id':0}", query, nil, mission_index)
	if 0 == e_code then
		if row then
			local list = row.list
			if list then
				for quest_id, record in pairs(list) do
					local quest, e_code = g_mission_mgr:load_quest(quest_id, record)
					if E_SUCCESS == e_code then
						quest:construct(self)
						self.accept_list[quest_id] = quest
					else
						f_quest_error_log("Mission_container:db_load(obj_id = %s, quest = %s, record = %s) Load Quest Occur Error %s!"
							, tostring(self.char_id)
							, tostring(quest_id)
							, tostring(Json.Encode(record))
							, tostring(e_code))
					end
				end
			end
		else
			db:insert(mission_table, query)
		end
	end
end

function Mission_container:load_complete()
	local query = string.format("{'char_id':%d}", self.char_id)
	local db = f_get_db()
	local row, e_code = db:select_one(complete_table, "{'_id':0}", query, nil, complete_index)
	if 0 == e_code then
		if row then
			local list = row.list
			if list then
				for _, quest_id in ipairs(list) do	
					self.complete_list[quest_id] = true
				end
			end
		else
			db:insert(complete_table, query)
		end
	end
end

function Mission_container:load_complete_daily()
	local query = string.format("{'char_id':%d}", self.char_id)
	local db = f_get_db()
	local today = f_get_today()
	local row, e_code = db:select_one(daily_complete_table, "{'_id':0}", query, nil, daily_complete_index)
	if 0 == e_code then
		if row then
			local list = row.list
			if list then
				for quest_id, complete_time in pairs(list) do
					if today < complete_time then
						self.complete_daily[quest_id] = complete_time
					end
				end
			end
		else
			db:insert(daily_complete_table, query)
		end
	end
end

--从数据库加载
function Mission_container:db_load(first_login)
	local player = g_obj_mgr:get_obj(self.char_id)

	if not first_login then
		self.quest_param = player:get_quest_param()
		if not self.quest_param then
			player:set_quest_param({})
			self.quest_param = player:get_quest_param()
		end

		self:load_accept()
		self:load_complete()
		self:load_complete_daily()
	else
		player:set_quest_param({})
		self.quest_param = player:get_quest_param()
	end

	return true
end

------------------改为定时保存，加入需更新的任务ID
--仅需加入待更新列表
function Mission_container:update_quest_record(quest)
	--local query = string.format("{'char_id':%d}", self.char_id)
	--local values = string.format("{'list.%s':%s}", quest:get_id(), Json.Encode(quest:serialize_to_db()))
	--f_get_db():update(mission_table, query, values, true)
	self.update_list[quest:get_id()] = 1
end

--还需从待更新列表中删除
function Mission_container:delete_accept_record(quest_id)
	self.accept_list[quest_id] = nil
	self.update_list[quest_id] = nil
	local query = string.format("{'char_id':%d}", self.char_id)
	f_get_db():update(mission_table, query, string.format("{$unset:{'list.%s':1}}", quest_id))
	self:notify_delete_quest(quest_id)
end

function Mission_container:delete_accept_record_on_send(quest_id)
	self.accept_list[quest_id] = nil
	self.update_list[quest_id] = nil
	local query = string.format("{'char_id':%d}", self.char_id)
	f_get_db():update(mission_table, query, string.format("{$unset:{'list.%s':1}}", quest_id))
	--self:notify_delete_quest(quest_id)
end

function Mission_container:update_faction_loop_record(quest_id)
	self:delete_accept_record(quest_id)

end

function Mission_container:update_complete_record(quest_id)
	self.complete_list[quest_id] = true
	self:delete_accept_record(quest_id)
	
	local query = string.format("{'char_id':%d}", self.char_id)
	local values = string.format("{'$push':{'list':'%s'}}", quest_id)
	f_get_db():update(complete_table, query, values, true)
end

function Mission_container:update_daily_complete_record(quest_id,q_type,q_flag)
	self:delete_accept_record(quest_id)
	if MISSION_TYPE_DAILY == q_type and  MISSION_FLAG_KILL == q_flag 
		or MISSION_TYPE_DAILY == q_type and MISSION_FLAG_SPEAK == q_flag
	then return end
	local now = os.time()
	self.complete_daily[quest_id] = now
	local query = string.format("{'char_id':%d}", self.char_id)
	local values = string.format("{'$set':{'list.%s':%d}}", quest_id, now)
	f_get_db():update(daily_complete_table, query, values, true)
end

function Mission_container:serialize()
	for k, v in pairs(self.update_list) do
		local quest = self.accept_list[k]
		if quest then
			local query = string.format("{'char_id':%d}", self.char_id)
			local values = string.format("{'list.%s':%s}", quest:get_id(), Json.Encode(quest:serialize_to_db()))
			f_get_db():update(mission_table, query, values, true)
		end
	end

	self.update_list = {}
	return
end

---------------------------------------------------------------------------------------------------------------------

--更新客户端任务状态
function Mission_container:notity_update_quest(quest_id, is_status_update)
	local quest = self.accept_list[quest_id]
	if quest then
		if is_status_update then
			self:update_quest_record(quest)
			NpcContainerMgr:GetMapNpcStatus(self.char_id, g_mission_mgr:get_wait_accept_list(self.char_id))
		end
		g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_UPDATE_S, quest:serialize_to_net())
	end
end

--更新客户端可接任务列表
function Mission_container:notity_available_quest()
	local list = g_mission_mgr:get_wait_accept_list(self.char_id)
	NpcContainerMgr:GetMapNpcStatus(self.char_id, list)
	local s_pkt = {}
	for k, _ in pairs(list) do
		table.insert(s_pkt, k)
	end
	g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_AVAILABLE_S, s_pkt)
end

--通知客户端删除指定的任务
function Mission_container:notify_delete_quest(quest_id)
	if quest_id then
		local s_pkt = {}
		s_pkt.quest_id = quest_id
		g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_DELETE_S, s_pkt)
	end
end

--通知客户端新增的任务
function Mission_container:notify_accpet_quest(quest_id)
	local quest = self.accept_list[quest_id]
	if quest then
		local s_pkt = {}
		table.insert(s_pkt, quest:serialize_to_net())
		g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_ADD_S, s_pkt)
		NpcContainerMgr:GetMapNpcStatus(self.char_id, g_mission_mgr:get_wait_accept_list(self.char_id))
	end
end

--通知客户端新增的任务列表
function Mission_container:notify_accpet_quest_list(quest_list)
	local s_pkt = {}
	for k, _ in pairs(quest_list) do
		local quest = self.accept_list[k]
		if quest then
			table.insert(s_pkt, quest:serialize_to_net())
		end
	end
	g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_ADD_S, s_pkt)
	self:notity_available_quest()
	--NpcContainerMgr:GetMapNpcStatus(self.char_id, g_mission_mgr:get_wait_accept_list(self.char_id))
end

--通知客户端接受的全部任务
function Mission_container:notify_all_accpet_quest()
	local s_pkt = {}
	for _, quest in pairs(self.accept_list) do
		if true == quest:on_send(self) then
			table.insert(s_pkt, quest:serialize_to_net())
		end
	end
	g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_ADD_S, s_pkt)
end--获取传送目标帮派ID
function Mission_container:get_transport_f_id()
	local finca_mission = self:get_param(PARAM_TYPE_FINCA)
	if not finca_mission then
		return 200101
	end

	local quest = self.accept_list[finca_mission.quest_id]
	if quest then
		return quest:get_faction_id()
	else
		return 25022
	end
end


--检查任务对应的场景ID
function Mission_container:get_transport_s_id(s_id_list)
	local finca_mission = self:get_param(PARAM_TYPE_FINCA)
	if not finca_mission then
		return 25022
	end

	local quest = self.accept_list[finca_mission.quest_id]
	if quest then
		return quest:get_scene_id(self.char_id, s_id_list)
	else
		return 25022
	end
end

--用在场景NPC头上表示判断,f_id为所在场景拥有帮派ID
function Mission_container:get_sns_mission_status(player, f_id)
	local finca_mission = self:get_param(PARAM_TYPE_FINCA)
	if not finca_mission then
		return 0
	end

	local quest = self.accept_list[finca_mission.quest_id]
	if quest then
		return quest:get_sns_mission_status(f_id)
	else
		return 0
	end
end

--日常环任务 得到and接受
function Mission_container:getandaccpet_loopdaily()
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end
	local s_pkt  = {}	
	s_pkt.result = 0
	local m_count = player:get_misc(8)
	if DAILY_COMPLETE_TIME < m_count then
		s_pkt.result = 200016
		s_pkt.count 	= DAILY_COMPLETE_TIME  -- 次数
		s_pkt.setp	 	= DAILY_COMPLETE_TIME  -- 环数
		g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_GET_DAILY_S, s_pkt)
		return 
	end
	local loop_daily_mission = self:get_param(PARAM_TYPE_LOOP_DAILY)

	if loop_daily_mission then  -- 之前有没做完的任务
		local quest = self:get_accept_mission(loop_daily_mission.quest_id)	
		s_pkt.state	=  quest and quest:get_status() or MISSION_STATUS_AVAILABLE
		if s_pkt.state == MISSION_STATUS_AVAILABLE then
			local quest, e_code = g_mission_mgr:build_quest(loop_daily_mission.quest_id)
			local e_error = 1
			if E_SUCCESS == e_code then
				e_error = quest:can_accept(self.char_id)
			end		
			if E_SUCCESS ~= e_error then	--如果升级等导致原任务不可接，不可完成，重随机一个
				local ret ,quest_id = g_mission_mgr:random_daily_quest(self.char_id)
				if ret ~= 0 then
					s_pkt.result = ret
					g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_GET_DAILY_S, s_pkt)
					return 
				end
				loop_daily_mission.quest_id 	= quest_id
				self:set_param(PARAM_TYPE_LOOP_DAILY,loop_daily_mission)
			end
			--e_code = self:accept_quest(loop_daily_mission.quest_id)
			--if E_SUCCESS ~= e_code then
				--s_pkt.result = e_code
				--g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_GET_DAILY_S, s_pkt)
				--return 
			--end
			--s_pkt.result = e_code
		end	
		s_pkt.quest_id 	= loop_daily_mission.quest_id 
		s_pkt.count 	= m_count > DAILY_COMPLETE_TIME and DAILY_COMPLETE_TIME or m_count -- 次数
		s_pkt.setp	 	= DAILY_COMPLETE_TIME  -- 环数
		g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_GET_DAILY_S, s_pkt)
	else                      
		--原来没任务，随一个出来
		loop_daily_mission = {}
		s_pkt.result = 0
		local ret ,quest_id = g_mission_mgr:random_daily_quest(self.char_id)
		if ret ~= 0 then
			s_pkt.result = ret
			g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_GET_DAILY_S, s_pkt)
			return
		end
		loop_daily_mission.quest_id 	= quest_id 
--
		--local e_code = self:accept_quest(loop_daily_mission.quest_id)
--
		--if E_SUCCESS ~= e_code then
			--s_pkt.result = e_code
			--g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_GET_DAILY_S, s_pkt)
			--return 
		--end
		self:set_param(PARAM_TYPE_LOOP_DAILY,loop_daily_mission)
		s_pkt.quest_id 	= quest_id
		s_pkt.count 	= player:get_misc(8)  -- 次数
		s_pkt.setp	 	= DAILY_COMPLETE_TIME  -- 环数
		s_pkt.state		= MISSION_STATUS_AVAILABLE
		g_cltsock_mgr:send_client(self.char_id, CMD_MISSION_GET_DAILY_S, s_pkt)
	end
end