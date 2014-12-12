--2011-03-25
--laojc
--打坐修炼

local TIME_SPAN = 10

local meditation_expr = require("config.meditation_config")

Meditation_container = oo.class(nil,"Meditation_container")

function Meditation_container:__init(obj_id)
	self.char_id = obj_id
	self.meditation_flag = 0   --打坐状态 0 为没打坐 1是单人打坐 2是双人打坐
	self.start_time = 0
	self.uuid = crypto.uuid()
end

function Meditation_container:get_flag()
	return self.meditation_flag
end

function Meditation_container:set_flag(flag)
	self.meditation_flag = flag
	if flag == 0 then
		self.start_time = 0
		g_meditation_mgr:del_heap_obj(self.char_id)
	else
		self.start_time = ev.time
		g_meditation_mgr:add_heap_obj(self.char_id)
	end
end

function Meditation_container:get_start_time()
	return self.start_time + 10
end

function Meditation_container:get_uuid()
	return self.uuid
end

function Meditation_container:set_uuid(uuid)
	self.uuid = uuid
end

function Meditation_container:get_expr()
	local player = g_obj_mgr:get_obj(self.char_id)
	local lvl = math.floor(player:get_level() / 10)
	if lvl == 0 then 
		lvl = 1
	else
		lvl = lvl * 10
	end
	if self.meditation_flag == 1 then
		return meditation_expr.expr[lvl]
	elseif self.meditation_flag == 2 then
		return meditation_expr.expr[lvl] * 2
	end
	return 0
end

function Meditation_container:get_percent()
	local player = g_obj_mgr:get_obj(self.char_id)
	local map_id = player:get_map_id()
	return meditation_expr.map_list[map_id]
end

function Meditation_container:add_expr()
	if self.meditation_flag ~= 0 then
		local time_span = ev.time - self.start_time
		if time_span >= 10 then
			self.start_time = ev.time		
			local player = g_obj_mgr:get_obj(self.char_id)
			local exta = self:get_percent() or 0
			local addition = player:get_addition(HUMAN_ADDITION.mediation)
			local expr = math.floor(((50 + player:get_level()) * (1 + exta)) * (1 + addition))
			if self.meditation_flag == 2 then
				expr = 2 * expr
			end
			player:add_exp(expr)
		end
	end
end

function Meditation_container:get_net_info(char_id_d)
	local ret = {}
	ret[1] = self.meditation_flag
	ret[2] = char_id_d
	return ret
end

------------------------------------事件------------------------------------------------------
function Meditation_container:set_status()
	--self:set_flag(0)
	g_meditation_mgr:del_container(self.char_id)
end




