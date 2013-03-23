--2011-05-16
--cqs
--抽奖号码基类

--local faction_update_loader = require("item.faction_update_loader")

Slottery_number = oo.class(nil, "Slottery_number")

function Slottery_number:__init(data)
	if data then
		self.player_count	= data.player_count	
		self.count			= data.count	
		self.list	 		= data.list
	else
		self.player_count	= 0			--购买该号码的玩家数量
		self.count			= 0			--购买该号码的注数
		self.list	 		= {}		--玩家ID表，保存选取改号码玩家tostring(ID)，该ID买该号码的数量。
	end
end

function Slottery_number:choice_number(char_id_)
	local char_id = tostring(char_id_)
	if self.list[char_id] then
		self.list[char_id] = self.list[char_id] + 1
	else
		self.list[char_id] = 1
		self.player_count = self.player_count + 1
	end
	self.count = self.count + 1
	return
end

--

function Slottery_number:get_player_count()
	return self.player_count
end

function Slottery_number:get_count()
	return self.count
end

function Slottery_number:get_player_name_info()
	local number = {}
	for k, v in pairs(self.list) do
		local  tmp_name = g_player_mgr.all_player_l[tonumber(k)]["char_nm"]
		number[tmp_name] = v
	end
	return number
end

function Slottery_number:get_player_info()
	local number = {}
	for k, v in pairs(self.list) do
		number[k] = v
	end
	return number
end

function Slottery_number:spec_serialize_to_db()
	return self.list
end
