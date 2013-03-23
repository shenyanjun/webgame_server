
local qq_quest_market_loader = require("qq_quest_market.qq_quest_market_loader")

QQ_quest_market_con = oo.class(Observable,"QQ_quest_market_con")

function QQ_quest_market_con:__init(char_id, acc_id, ser_id)
	 Observable.__init(self, 0)
	 self.char_data = {}
	 self.char_data.char_id = char_id
	 self.char_data.openid = acc_id
	 self.char_data.zoneid = ser_id

     self.qq_quest = nil
end

function QQ_quest_market_con:db_load()
	local dbh = f_get_db() 

	local str_char = "{openid:\""..self.char_data.openid .."\",zoneid:\"".. self.char_data.zoneid.."\"}"
	local qq_quest, e_code = dbh:select_one("qq_quest_market", nil, str_char)
	if 0 ~= e_code then
		print("Error:QQ_quest_market :",e_code)
		return
	end
	if qq_quest ~= nil then
		if not qq_quest.task_id or not qq_quest_market_loader.get_quest(qq_quest.task_id) or qq_quest.status ~= 0 then
			return true
		end
		self:example(qq_quest)
	end
	return true
end


function QQ_quest_market_con:example(data)
	local quest_type = qq_quest_market_loader.get_type_quest(data.task_id)
	if quest_type == 1 then
		self.qq_quest = QQ_quest_level(self.char_data, data)
	elseif quest_type == 2 then
		self.qq_quest = QQ_quest_kill(self.char_data, data)
	elseif quest_type == 3 then
		self.qq_quest = QQ_quest_scene(self.char_data, data)
	else
		print("type undefinition")
		return
	end
	if self.qq_quest then
		self.qq_quest:construct(self)
	end
end

function QQ_quest_market_con:get_quest()
	return self.qq_quest
end