--npc卖买物品流水记录

Item_consume_log = oo.class(nil, "Item_consume_log")

function Item_consume_log:__init()
end

function Item_consume_log:write_item_log(char_id, sub_ctype, item_info)
	if not char_id then return end
	if table.is_empty(item_info) then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local player_name = player:get_name()

	local str_log = string.format(" insert into consume_log(char_id,char_name,timer,type,fromto,item_id,item_name,count) values(%d,'%s',%d,%d,%d,%d,'%s',%d)",
		char_id, player_name, ev.time, sub_ctype, item_info.fromto, item_info.item_id, item_info.item_name, item_info.count)

	--print("Item_consume_log str_log", str_log)
	g_item_log:write(str_log)
end