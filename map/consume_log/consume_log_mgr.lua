
--消费日志记录管理类
Consume_log_mgr = oo.class(nil, "Consume_log_mgr")

function Consume_log_mgr:__init()
	self.item_log_obj = Item_consume_log()
	self.money_log_obj = Money_consume_log()
end


function Consume_log_mgr:write_consume_log(char_id, flag, sub_flag, info)
	if not char_id or not flag then return end

	if flag == TYPE_ITEM_CONSUME then
		self.item_log_obj:write_item_log(char_id, sub_flag, info)
	elseif flag == TYPE_MONEY_CONSUME then
		self.money_log_obj:write_money_log(char_id, sub_flag, info)
	end
end