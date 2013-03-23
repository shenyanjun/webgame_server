
Sv_commands[1][CMD_G2C_QQ_CONSIGNMENT_G] =
function(conn,char_id,pkt)
	--print("4 =", j_e(pkt))
	pkt.result = g_currency_mgr:check_exchange(pkt.item_id, pkt)

	g_svsock_mgr:send_server_ex ( WORLD_ID, 0, CMD_C2G_QQ_CONSIGNMENT_C, pkt)
end

Sv_commands[0][CMD_M2C_QQ_STALL_M] =
function(conn,char_id,pkt)
	if not g_currency_mgr:stall_id_exist(pkt.item_uuid) then
		g_currency_mgr:add_stall_id(pkt.item_uuid, pkt, pkt.buyer, pkt.seller, pkt.amt, pkt.fee)
	else
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2M_QQ_STALL_C,{result = 20509, char_id = pkt.buyer})	
		return 
	end
end

Sv_commands[0][CMD_M2C_QQ_STALL_REQ] =
function(conn,char_id,pkt)
	g_currency_mgr:exchange_stall(pkt)

end

----------------------------------------------
Sv_commands[1][CMD_G2C_QQ_GOODS_G] = 
function(conn, char_id, pkt)
	local ret = g_currency_mgr:currency_send_goods(tonumber(pkt.item_id), pkt)
	if ret ~= 0 then
		pkt.result = ret
		g_svsock_mgr:send_server_ex ( WORLD_ID, 0, CMD_C2G_QQ_GOODS_C, pkt)
	end
end

Sv_commands[0][CMD_M2C_QQ_MALL_REQ] =
function(conn,char_id,pkt)
	g_currency_mgr:currency_success(char_id, pkt)

end

--------------------------------招boss
Sv_commands[0][CMD_M2C_QQ_BOSS_M] =
function(conn,char_id,pkt)
	pkt.line = conn.id
	--g_currency_mgr:currency_success(char_id, pkt)

	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, pkt, char_id, 4)
	else
		
		g_server_mgr:send_to_server(conn.id,char_id, CMD_M2C_QQ_BOSS_C,{result = 20509})	
		return 

	end

end

Sv_commands[0][CMD_M2C_QQ_BOSS_REQ] =
function(conn,char_id,pkt)
	g_currency_mgr:currency_success(char_id, pkt)
end

-------------------一键领取
Sv_commands[0][CMD_M2C_QQ_OFFLINE_M] =
function(conn,char_id,pkt)
	pkt.line = conn.id
	--g_currency_mgr:currency_success(char_id, pkt)
	--print("70 =", j_e(pkt))
	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, pkt, char_id, 5)
	else
		
		g_server_mgr:send_to_server(conn.id,char_id, CMD_M2C_QQ_OFFLINE_C,{result = 20509})	
		return 

	end

end

Sv_commands[0][CMD_M2C_QQ_OFFLINE_REQ] =
function(conn,char_id,pkt)
	g_currency_mgr:currency_success(char_id, pkt)
end

------------------时装续费
Sv_commands[0][CMD_M2C_QQ_FASHION_M] =
function(conn,char_id,pkt)
	pkt.line = conn.id
	--g_currency_mgr:currency_success(char_id, pkt)

	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, pkt, char_id, 6)
	else
		
		g_server_mgr:send_to_server(conn.id,char_id, CMD_M2C_QQ_FASHION_C,{result = 20509})	
		return 

	end

end

----------------元宝直接开格
Sv_commands[0][CMD_M2C_QQ_BAG_SLOT_M] =
function(conn,char_id,pkt)
	--print("CMD_M2C_QQ_BAG_SLOT_M", j_e(pkt))
	pkt.line = conn.id
	--g_currency_mgr:currency_success(char_id, pkt)

	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, pkt, char_id, 8)
	else
		
		g_server_mgr:send_to_server(conn.id,char_id, CMD_M2C_QQ_BAG_SLOT_C, {result = 20509})	
		return 

	end
end

Sv_commands[0][CMD_M2C_QQ_BAG_SLOT_REQ] =
function(conn,char_id,pkt)
	g_currency_mgr:currency_success(char_id, pkt)
end

----------------降妖
Sv_commands[0][CMD_M2C_QQ_XIANG_YAO_M] =
function(conn,char_id,pkt)
	pkt.line = conn.id

	if not g_currency_mgr:currency_id_exist(char_id) then
		
		g_currency_mgr:add_currency_id(char_id, pkt, char_id, 9)
	else
		
		g_server_mgr:send_to_server(conn.id,char_id, CMD_M2C_QQ_XIANG_YAO_C, {result = 20509})	
		return 

	end
end

Sv_commands[0][CMD_M2C_QQ_XIANG_YAO_REQ] =
function(conn,char_id,pkt)
	g_currency_mgr:currency_success(char_id, pkt)
end


Sv_commands[0][CMD_M2C_QQ_FASHION_REQ] =
function(conn,char_id,pkt)
	g_currency_mgr:currency_success(char_id, pkt)
end

Sv_commands[0][CMD_M2C_QQ_VIPMALL_REQ] =
function(conn,char_id,pkt)
	g_currency_mgr:currency_success(char_id, pkt)
end

Sv_commands[1][CMD_W2C_TOKEN_CURRENCY_C] =
function(conn,char_id,pkt)
	g_currency_mgr:check_del_cur(pkt.item_id)
end

Sv_commands[1][CMD_W2C_TOKEN_CONSIGNMENT_C] =
function(conn,char_id,pkt)
	g_currency_mgr:check_del_con(pkt.item_id)
end

