
local children_base_config = require("config.xml.children.children_base_config")
local MAX_MOOD = 120

Char_obj = oo.class(nil, "Char_obj")

function Char_obj:__init(char_id)
	self.char_id = char_id 
	self.mood = 50
	self.name = f_get_string(2711)
	self.expr = 0
	self.level = 1

	self.child_id = crypto.uuid()
end

function Char_obj:set_child_id(child_id)
	self.child_id = child_id
end

function Char_obj:get_child_id()
	return self.child_id
end

function Char_obj:set_mood(mood)
	if mood < 0 then mood = 0 end
	if mood > children_base_config.max_mood then mood = children_base_config.max_mood end
	self.mood = mood
end

function Char_obj:get_mood()
	return self.mood
end

function Char_obj:set_name(name)
	self.name = name
end

function Char_obj:get_name()
	return self.name
end

function Char_obj:add_exp(exp)
	if exp == nil then return end

	local player_level = g_player_mgr.all_player_l[self.char_id].level
	if self.level >= 10 then
		if player_level - 60 <= self.level then
			return
		end
	end

	self.expr = self.expr + exp
	local max_level = table.size(children_base_config.exp)

	while true do
		if self.level >= max_level then
			self.expr = 0
			break
		end
		local max_exp = children_base_config.exp[self.level]
		if self.expr >= max_exp then
			self.level = self.level + 1
			self.expr = self.expr - max_exp
		else
			break
		end
	end
end

function Char_obj:get_update_exp()
	local max_level = table.size(children_base_config.exp)
	if self.level < max_level then
		return children_base_config.exp[self.level]
	else
		return children_base_config.exp[max_level]
	end
end

function Char_obj:serialize_to_net()
	local ret = {}
	ret[1] = self.child_id
	ret[2] = self.name 
	ret[3] = self.mood
	ret[4] = self.expr
	ret[5] = self.level

	return ret
end

function Char_obj:serialize_to_net_ex()
	local ret = {}
	ret[1] = self.child_id
	ret[2] = self.name 
	ret[3] = self.mood
	ret[4] = {self.expr, self:get_update_exp()}
	ret[5] = self.level

	return ret
end

function Char_obj:serialize_to_db()
	local ret = {}
	ret[1] = self.child_id
	ret[2] = self.name 
	ret[3] = self.mood
	ret[4] = self.expr
	ret[5] = self.level

	return ret
end

function Char_obj:unserialize_to_db(pack)
	if not pack then return end
	self.child_id = pack[1]
	self.name = pack[2]
	self.mood = pack[3]
	self.expr = pack[4]
	self.level = pack[5]
end