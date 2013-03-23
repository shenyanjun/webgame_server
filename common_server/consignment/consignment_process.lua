--local debug_print=print
local debug_print=function() end

---------------------------------与map交互---------------------

--物品上架
Sv_commands[0][CMD_CONSIGNMENT_SALE_M] =
function(conn,char_id,pkt)
	if pkt==nil then return end

	if char_id ~= nil then
		local s_pkt = {}
		s_pkt.pkt = pkt
		s_pkt.counts = g_consignment:check_consignment(char_id)	or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_CONSIGNMENT_SALE_C,s_pkt)
		return
	end
end

Sv_commands[0][CMD_CONSIGNMENT_SALE_REQ_M] =
function(conn,char_id,pkt)
	if pkt==nil then return end
	local s_pkt = {}
	--向common服发信息
	s_pkt.item_id		= pkt.item_id		
	s_pkt.item_DB		= pkt.item_DB
	s_pkt.owner_id		= pkt.owner_id		
	s_pkt.owner_name	= pkt.owner_name	
	s_pkt.count 		= pkt.count 		
	s_pkt.money_type	= pkt.money_type	
	s_pkt.money_count	= pkt.money_count	
	s_pkt.server_id		= pkt.server_id
	local allows		= pkt.allows		

	if char_id ~= nil then
		local s_pkt = g_consignment:create_consignment(s_pkt, allows, char_id) or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_CONSIGNMENT_INFOR_C,s_pkt)
		return
	end
end

--玩家请求列表
Sv_commands[0][CMD_CONSIGNMENT_SEARCH_M] =
function(conn,char_id,pkt)
	if not pkt or not pkt.condition_list  then return end
	local s_pkt = g_consignment:get_list(pkt) or {}
	g_server_mgr:send_to_server(conn.id,char_id, CMD_CONSIGNMENT_SEARCH_C, s_pkt)
	return
end


--打开自己面板
Sv_commands[0][CMD_CONSIGNMENT_INFOR_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then	
		local s_pkt = g_consignment:get_owner_id_consignment(char_id) or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_CONSIGNMENT_INFOR_C,s_pkt)	
	end
	return
end

--下架
Sv_commands[0][CMD_CONSIGNMENT_DELETE_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then	
		local s_pkt = g_consignment:delete_owner_uuid_consignment(char_id,pkt.uuid) or {}
		g_server_mgr:send_to_server(conn.id,char_id, CMD_CONSIGNMENT_INFOR_C,s_pkt)	
	end
	return
end

--购买请求寄售品信息
Sv_commands[0][CMD_CONSIGNMENT_BUY_M] =
function(conn,char_id,pkt)
	if char_id ~= nil then	
		local s_pkt, server_id = g_consignment:get_buy_info(pkt.uuid, char_id)
		if server_id then
			--print("CMD_CONSIGNMENT_BUY_M", server_id, pkt.serverid)
			if server_id ~= pkt.serverid then
				s_pkt.result = 43342
			end
		end
		s_pkt.openid = pkt.openid
		s_pkt.openkey = pkt.openkey
		s_pkt.serverid = pkt.serverid
		s_pkt.pf = pkt.pf
		s_pkt.pfkey = pkt.pfkey

		g_server_mgr:send_to_server(conn.id,char_id, CMD_CONSIGNMENT_BUY_C,s_pkt)	
	end
	return
end
--扣完钱:pkt.money_type=1铜币  直接发物品；=2等腾讯扣款成功
Sv_commands[0][CMD_CONSIGNMENT_BUY_REQ_M] =
function(conn,char_id,pkt)
	print("89 =", Json.Encode(pkt))
	if char_id ~= nil then
		if pkt.money_type == 1 then
			if g_consignment:buy_consignment(char_id,pkt) then
				local t_pkt = {}
				t_pkt.pages		= 1
				t_pkt.pagesize 	= 5
				t_pkt.timestamp	= -1
				t_pkt.condition_list = {}
				t_pkt.condition_list.sub_type = 'total'
				local s_pkt = g_consignment:get_list(t_pkt) or {}
				g_server_mgr:send_to_server(conn.id,char_id, CMD_CONSIGNMENT_SEARCH_C, s_pkt)
				return
			end
		elseif pkt.money_type== 2 then
			local s_pkt = {}
			s_pkt.result = g_consignment:pre_buy_consignment(char_id, pkt)
			if s_pkt.result ~= 0 then
				g_server_mgr:send_to_server(conn.id,char_id, CMD_CONSIGNMENT_BUY_C,s_pkt)
			end
		end
	end
	return
end
