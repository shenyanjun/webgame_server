-- CodeBy:cailizhong
-- 帮派资源互换功能,该功能只有帮主能使用

Clt_commands[1][CMD_FACTION_RESOURCE_EXCHANGE_B] = 
function(conn, pkt)
	--print("in	CMD_FACTION_RESOURCE_EXCHANGE_B")
	--print(j_e(pkt))
	if conn.char_id==nil or pkt.type==nil then return end
	if pkt.type == 1 then
		g_faction_mgr:open_resource_exchange(conn.char_id, pkt)
	elseif pkt.type == 2 then
		g_faction_mgr:resource_exchange(conn.char_id, pkt)
	end
end
