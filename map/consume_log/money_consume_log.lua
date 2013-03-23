--金钱消费流水记录

Money_consume_log = oo.class(nil, "Money_consume_log")

function Money_consume_log:__init()
end

function Money_consume_log:write_money_log(char_id, sub_ctype, money_info)
	if not char_id or not sub_ctype then return end
	if table.is_empty(money_info) then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local player_name = player:get_name()

	local str_log = string.format(" insert into consume_log(char_id,char_name,timer,type,fromto,jade,gift_jade,gift_gold,gold) values(%d,'%s',%d,%d,%d,%d,%d,%d,%d)",
		char_id, player_name, ev.time, sub_ctype, money_info.fromto, 
		money_info.jade or 0, money_info.gift_jade or 0, money_info.gift_gold or 0, money_info.gold or 0)

	--print("Money_consume_log str_log", str_log)

	g_item_log:write(str_log)
end