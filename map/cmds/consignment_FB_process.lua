--local debug_print = print
local debug_print = function() end

--local src_log = {}
--src_log.type = ITEM_SOURCE.EMAIL

--上架
Clt_commands[1][CMD_CONSIGNMENT_SALE_B] = 
	function(conn, pkt)
		if not pkt then return end
		local player = g_obj_mgr:get_obj(conn.char_id)
		if not player then return end
		pkt.server_id = player:get_server_id()
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_CONSIGNMENT_SALE_M, pkt)
	end

--下架
Clt_commands[1][CMD_CONSIGNMENT_DELETE_B] = 
	function(conn, pkt)
		if not pkt or not pkt.uuid then return end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_CONSIGNMENT_DELETE_M, pkt)
	end

--打开自己界面
Clt_commands[1][CMD_CONSIGNMENT_INFOR_B] = 
	function(conn, pkt)
		--if not pkt then return end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_CONSIGNMENT_INFOR_M, pkt)--CMD_CONSIGNMENT_INFOR_M,pkt)
	end

--请求列表
Clt_commands[1][CMD_CONSIGNMENT_SEARCH_B] = 
	function(conn, pkt)
		if not pkt then return end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_CONSIGNMENT_SEARCH_M, pkt)
	end

--购买
Clt_commands[1][CMD_CONSIGNMENT_BUY_B] = 
	function(conn, pkt)	
		if not pkt or not pkt.uuid then return end
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id, CMD_CONSIGNMENT_BUY_M, pkt)
	end
