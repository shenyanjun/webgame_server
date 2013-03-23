-- 帮派神兽
-- CodeBy:cailizhong
-- 2012/8/10

Sv_commands[0][CMD_GET_FACTION_DOGZ_INFO_M] = 
function(conn, char_id, pkt)
	if conn and char_id then -- 检查参数
		g_faction_dogz_mgr:on_line(conn, char_id)
	end
end

Sv_commands[0][CMD_ADOPT_DOGZ_M] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt and pkt.dogz_id then
		g_faction_dogz_mgr:adopt_dogz(conn, char_id, pkt.dogz_id)
	end
end

Sv_commands[0][CMD_ACT_DOGZ_M] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt and pkt.act_type then
		g_faction_dogz_mgr:act_dogz(conn, char_id, pkt.dogz_id, pkt.act_type, pkt.soul)
	end
end

Sv_commands[0][CMD_CALL_DOGZ_M] = 
function(conn, char_id, pkt)
	if conn and char_id and pkt and pkt.dogz_id then
		g_faction_dogz_mgr:call_dogz(conn, char_id, pkt.dogz_id)
	end
end