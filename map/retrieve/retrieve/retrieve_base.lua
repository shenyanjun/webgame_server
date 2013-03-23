
--local misson_loader = require("mission_ex.mission_loader")

Retrieve_base = oo.class(nil, "Retrieve_base")

local database = "retrieve"

function Retrieve_base:__init(meta)
	self.id = meta.id
	self.type = meta.type

	self.day = 0
	self.flag = 0
end

function Quest_base:get_id()
	return self.quest_id
end

function Retrieve_base:get_id()
	return self.id
end

function Retrieve_base:get_type()
	return self.type
end

function Retrieve_base:is_scene_type()
	return false
end

function Retrieve_base:get_day()
	return self.day
end

function Retrieve_base:clone(record)
	if record then
		if not record.id then
			return nil
		end
	else
		record = self
	end
	local obj = self:load_fields(record)
	setmetatable(obj, getmetatable(self))

	return obj
end

function Retrieve_base:load_fields(record)
	local obj = {}
	--obj.id = record.id
	obj.flag = record.flag
	obj.day = record.day
	obj.id = record.id
	obj.type = record.type

	return obj
end

function Retrieve_base:ppp()
	print("53 ==========")

	return 
end

function Retrieve_base:serialize_to_net()
	local meta = g_retrieve_mgr:get_meta(self.id)
	local player = g_obj_mgr:get_obj(self.char_id)
	local lvl = player and player:get_level() or 1

	if meta and meta.min_level <= lvl then
		local result = {}
		result.id = self.id
		result.day = self.day
		result.flag = self.flag

		return result
	end

	return false
	
end

function Retrieve_base:serialize_to_db()
	
	local m_db = f_get_db()
	local query = string.format("{char_id:%d}", self.char_id)

	local result = {}
	result.id = self.id
	result.day = self.day
	result.flag = self.flag
	result = Json.Encode(result)

	local info = string.format([[{"items.%d":%s}]], self.id - 1, result)

	m_db:update(database, query, info, true, false)

	return 0
end

---------------------------------------------------------------------------------------
function Retrieve_base:construct(con)
	self.char_id = con.char_id
	if self.flag == 1 then
		return
	end
	self:register_event(con)
end

function Retrieve_base:instance(con)
	self:register_event(con)
end

function Retrieve_base:register_event(con)
	if self.flag and self.flag == 0 then 
		local meta = g_retrieve_mgr:get_meta(self.id)
		local player = g_obj_mgr:get_obj(self.char_id)
		local lvl = player and player:get_level() or 1

		if meta and meta.min_level <= lvl then
			return true
		else
			return false
		end
	end

	return false
end

function Retrieve_base:unregister_event(con)
end

function Retrieve_base:deconstruct(con)
	self:unregister_event(con)
end
---------------------------------------------------------------------------------------
function Retrieve_base:change_flag(con)
	self.flag = 1

	self:unregister_event(con)

	self:serialize_to_db()
end

function Retrieve_base:update_days(days)
	local meta = g_retrieve_mgr:get_meta(self.id)
	local player = g_obj_mgr:get_obj(self.char_id)
	local lvl = player:get_level()

	if meta and meta.min_level <= lvl then
		if self.flag ~= 0 then
			self.day = self.day + days - 1
		else
			self.day = self.day + days
		end

		if self.day > 7 then
			self.day = 7
		end

		self.flag = 0
	end
end

function Retrieve_base:do_reward(type)
	local meta = g_retrieve_mgr:get_meta(self.id)
	local player = g_obj_mgr:get_obj(self.char_id)
	local lvl = player:get_level()

	if meta.min_level > lvl then
		return 22702
	end
	local add_exp = (meta.exp[lvl] or 0) * self.day

	local pack_con = player:get_pack_con()
	
	local money_list = {}
	local need_money = 0

	if type == 1 then
		if self.flag == 0 then
			return 22703
		end

		add_exp = math.floor(add_exp * 0.6)
	elseif type == 2 then
		need_money = meta.gold * self.day
		money_list[MoneyType.GOLD] = need_money
		local e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.RETRIEVE}, nil, 1)
		if e_code ~= 0 then
			return e_code
		end
		add_exp = math.floor(add_exp * 0.8)
	elseif type == 3 then
		need_money = meta.jade * self.day
		money_list[MoneyType.JADE] = need_money
		local e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.RETRIEVE}, nil, 1)
		if e_code ~= 0 then
			return e_code
		end
	end

	local sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, type=%d, num=%d,exp=%d, days=%d, time=%d",
				self.char_id, player:get_name(), 5, type, need_money, add_exp, self.day, os.time())
	f_multi_web_sql(sql_str)

	self.day = 0
	self:serialize_to_db()

	--增加经验值
	player:add_exp(add_exp)

	return 0
end

-- 获取离线所需的钱跟奖励
function Retrieve_base:offline_reward(type)
	local meta = g_retrieve_mgr:get_meta(self.id)
	local player = g_obj_mgr:get_obj(self.char_id)
	local lvl = player:get_level()
	local need_money,add_exp = 0,0

	if meta.min_level > lvl then
		return need_money,add_exp
	end
	local add_exp = (meta.exp[lvl] or 0) * self.day	
	local need_money = 0

	if type == 2 then
		need_money = meta.gold * self.day
		add_exp = math.floor(add_exp * 0.8)
		return need_money,add_exp
	elseif type == 3 then
		need_money = meta.jade * self.day
		return need_money,add_exp
	end	
	return need_money,add_exp
end
function Retrieve_base:set_days(num)
	self.day = num
end
function Retrieve_base:get_update_data()

end
----------------------------------------------------事件------------------------------------------------------
