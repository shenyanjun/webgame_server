-- CodeBy:cailizhong
-- 帮派仓库


-- 往仓库放入物品
Clt_commands[1][CMD_PUT_ITEM_INTO_WAREHOUSE_B] = 
function(conn, pkt)
	--print("in CMD_PUT_ITEM_INTO_WAREHOUSE_B")
	if conn.char_id == nil then return end
	g_faction_mgr:put_item_into_warehouse(conn.char_id,pkt)
end

-- 从仓库取出物品
Clt_commands[1][CMD_GET_ITEM_FROM_WAREHOUSE_B] = 
function(conn, pkt)
	--print("in CMD_GET_ITEM_FROM_WAREHOUSE_B")
	if conn.char_id == nil then return end
	g_faction_mgr:get_item_from_warehouse(conn.char_id, pkt)
end

-- 设置物品价格
Clt_commands[1][CMD_SET_ITEM_PRICE_WAREHOUSE_B] = 
function(conn, pkt)
	--print("in CMD_SET_ITEM_PRICE_WAREHOUSE_B")
	if conn.char_id == nil then return end
	g_faction_mgr:set_item_price_warehouse(conn.char_id, pkt)
end

-- 摧毁仓库物品
Clt_commands[1][CMD_DESTORY_ITEM_WAREHOUSE_B] = 
function(conn, pkt)
	--print("in CMD_DESTORY_ITEM_WAREHOUSE_B")
	if conn.char_id == nil then return end
	g_faction_mgr:destory_item_warehouse(conn.char_id, pkt)
end
