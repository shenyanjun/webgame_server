
local misson_loader = require("mission_ex.mission_loader")

--外包类基类
Quest_wrapper_base = oo.class(Quest_base, "Quest_wrapper_base")

function Quest_wrapper_base:__init(meta, core)
	self.core = core
end

function Quest_wrapper_base:get_id()
	return self.core:get_id()
end

function Quest_wrapper_base:get_f_id()
	return self.core:get_f_id()
end

function Quest_wrapper_base:get_type()
	return self.core:get_type()
end

function Quest_wrapper_base:set_status(status)
	self.core:set_status(status)
end

function Quest_wrapper_base:get_status()
	return self.core:get_status()
end

function Quest_wrapper_base:get_reward(player)
	return self.core:get_reward(player)
end

function Quest_wrapper_base:clone(record)
	if record then
		if not record.core_record then
			return nil, E_MISSION_INVALID_DATA
		end
	else
		record = self
	end
	
	local obj, e_code = self:load_fields(record)
	if E_SUCCESS == e_code then
		obj.core, e_code = self.core:clone(record.core_record)
		if E_SUCCESS == e_code then
			setmetatable(obj, getmetatable(self))
		end
	end
	
	return obj, e_code
end

function Quest_wrapper_base:load_fields(record)
	local obj = {}
	return obj, E_SUCCESS
end

function Quest_wrapper_base:serialize_to_net()
	return self.core:serialize_to_net()
end

function Quest_wrapper_base:serialize_to_db()
	local result = {}
	result.core_record = self.core:serialize_to_db()
	return result
end

---------------------------------------------------------------------------------------

function Quest_wrapper_base:construct(con)
	self.core:construct(con)
end

function Quest_wrapper_base:instance(con)
	self.core:instance(con)
end

function Quest_wrapper_base:register_event(con)
	self.core:register_event(con)
end

function Quest_wrapper_base:unregister_event(con)
	self.core:unregister_event(con)
end

function Quest_wrapper_base:deconstruct(con)
	self.core:deconstruct(con)
end

---------------------------------------------------------------------------------------

function Quest_wrapper_base:can_accept(char_id)
	return self.core:can_accept(char_id)
end

function Quest_wrapper_base:do_reward(player, reward, select_list, bonus)
	return self.core:do_reward(player, reward, select_list, bonus)
end

----------------------------------------------------事件------------------------------------------------------

function Quest_wrapper_base:on_accept(char_id)
	return self.core:on_accept(char_id)
end

function Quest_wrapper_base:on_delete(con)
	return self.core:on_delete(con)
end

function Quest_wrapper_base:on_complete(char_id, select_list)
	return self.core:on_complete(char_id, select_list)
end

function Quest_wrapper_base:on_send(con)
	return self.core:on_send()
end