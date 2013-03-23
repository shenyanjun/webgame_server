-- 帮派庭院

-- 玩家取摇钱树（铜券树）数据
Sv_commands[0][CMD_GET_MONEY_TREE_INFO_M] = 
function(conn, char_id, pkt)
	if conn and char_id then -- 检查参数
		g_faction_courtyard_mgr:on_line(conn, char_id, 1) -- 获取铜券树信息
	end
end



-- 玩家摇树
Sv_commands[0][CMD_ROCK_MONEY_TREE_M] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt and pkt.vip_level then -- 检查参数
		g_faction_courtyard_mgr:rock_money_tree(conn, char_id, pkt.vip_level)
	end
end

-------------------------帮派烧香--------------------
Sv_commands[0][CMD_GET_GANG_INFO_M] = 
function(conn, char_id, pkt)
	if conn and char_id then
		g_faction_courtyard_mgr:on_line(conn, char_id, 2) -- 获取香炉信息
	end
end

-- 上香或者祭拜
Sv_commands[0][CMD_WORSHIP_M] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt and pkt.act_type then
		g_faction_courtyard_mgr:worship(conn, char_id, pkt.act_type, pkt.id)
	end
end