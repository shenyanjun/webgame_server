



Sv_commands[0][CMD_C2M_ADD_CONGRA_EXP] = 
function(conn,char_id,pkt)
	if not char_id or not pkt then return end
	local ret = {}
	ret.result = 0
	ret.exp = pkt.exp
	ret.char_id = char_id
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	ret.result = player:add_exp(pkt.exp)
	g_svsock_mgr:send_server_ex(WORLD_ID,char_id,CMD_W2C_ADD_CONGRA_EXP,ret)
end