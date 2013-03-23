
local misson_loader = require("mission_ex.mission_loader")
--战场非循环任务，一天一次
local Quest_wrapper_battle_day_loop = oo.class(Quest_wrapper_base, "Quest_wrapper_battle_day_loop")

function Quest_wrapper_battle_day_loop:__init(meta, core)
	Quest_wrapper_base.__init(self, meta, core)
	self.char_id = 0
	self.accept_time = 0
end
--[[
function Quest_wrapper_battle_day_loop:instance(con)
	print('Quest_wrapper_battle_day_loop:instance status : '..self:get_status())
	if MISSION_STATUS_COMMIT == self:get_status() then return end
	con:register_event(MISSION_EVENT_NEW_DAY, self:get_id(), self, self.new_day_event)
end

function Quest_wrapper_battle_day_loop:construct(con)
	Quest_wrapper_base.construct(self,con)
	print('Quest_wrapper_battle_day_loop:construct')
	self:instance(con)
end
--remember return 0
function Quest_wrapper_battle_day_loop:on_delete(con)
	Quest_wrapper_base.on_delete(self,con)
	con:unregister_event(MISSION_EVENT_NEW_DAY, self:get_id())
	print('Quest_wrapper_battle_day_loop:on_delete quest_id:'..self:get_id() )
	return 0
end

function Quest_wrapper_battle_day_loop:new_day_event(con)
	print('Quest_wrapper_battle_day_loop:new_day_event')
	con:delete_quest(self:get_id())
end
--]]
function Quest_wrapper_battle_day_loop:can_accept(char_id)	
	--print('Quest_wrapper_battle_day_loop:can_accept '..self:get_id())
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end
	
	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end
	
	local con = player:get_mission_mgr()

	local old_quest = con:get_accept_mission(self:get_id())
	if old_quest then
		if old_quest.accept_time < f_get_today() then
			con:delete_quest(self:get_id())
		else
			return false
		end
	end
	--[[
	local param = con:get_param(PARAM_TYPE_BATTLE_DAY_LOOP)
	print('param:'..j_e(param))
	if param then
		if param[self:get_id()] and param[self:get_id()] > f_get_today() then
			return false -- one day one time
		end
	end
	--]]
	--print('Quest_wrapper_battle_day_loop:can_accept '..self:get_id()..' e_code'..self.core:can_accept(char_id))
	return self.core:can_accept(char_id)
	
end

function Quest_wrapper_battle_day_loop:on_accept(char_id)
	self.char_id = char_id

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local con = player:get_mission_mgr()
	
	local ret = self.core:on_accept(char_id)
	if E_SUCCESS == ret then
		self.accept_time = ev.time
		--self:instance(con)
	end
	
	return ret
end

function Quest_wrapper_battle_day_loop:on_complete(char_id, select_list)	
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return false end

	local meta = misson_loader.get_meta(self:get_id())
	if not meta then
		return E_MISSION_INVALID_ID, nil
	end
	--[[
	local con = player:get_mission_mgr()
	local param = con:get_param(PARAM_TYPE_BATTLE_DAY_LOOP)
	if not param then
		param = {}
		con:set_param(PARAM_TYPE_BATTLE_DAY_LOOP,param)
	end
	param[self:get_id()] = ev.time
	--]]
	return self.core:on_complete(char_id, select_list)
end

function Quest_wrapper_battle_day_loop:serialize_to_net()
	local result = Quest_wrapper_base.serialize_to_net(self)

	return result
end

function Quest_wrapper_battle_day_loop:serialize_to_db()
	local result = Quest_wrapper_base.serialize_to_db(self)
	result.accept_time = self.accept_time
	return result
end

function Quest_wrapper_battle_day_loop:load_fields(record)
	local obj, e_code = Quest_wrapper_base.load_fields(self, record)
	obj.accept_time = record.accept_time
	--print('Quest_wrapper_battle_day_loop:load_fields , accept_time : '..obj.accept_time)
	return obj, E_SUCCESS
end

function Quest_wrapper_battle_day_loop:need_delete_on_load()
	if self.accept_time < f_get_today() then return true end
end

function Quest_wrapper_battle_day_loop:on_send(con)
	if self.accept_time < f_get_today() then
		con:delete_accept_record_on_send(self:get_id())
		return false
	end
	return Quest_wrapper_base.on_send(self)
end
Mission_mgr.register_wrapper(MISSION_TYPE_BATTLE_DAY_LOOP, Quest_wrapper_battle_day_loop)