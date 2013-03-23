--2012-05-21
--zhengyg
-- cmds from map processor

-------------------------------------------

assert(Sv_commands[0][CMD_M2C_BAG_REQ_M]==nil)
Sv_commands[0][CMD_M2C_BAG_REQ_M] =
	function(conn,char_id,pkt)
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction==nil then 
			print('faction == nil')
			return 
		end
		--[[if faction:get_dissolve_flag() == 1 then
			local s_pkt = {}
			s_pkt.result = 31185
			g_server_mgr:send_to_server(conn.id,char_id, CMD_C2M_BAG_RES_C, s_pkt)
			return
		end
		--]]
		local ft_bag = g_faction_bag_mgr:get_bag_by_fid(faction:get_faction_id())
		local s_pkt = ft_bag:serialized_to_net()
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2M_BAG_RES_C, s_pkt)
	end


Sv_commands[0][CMD_M2C_BAG_OPERATE_REQ] =
	function(conn,char_id,pkt)
		local faction = g_faction_mgr:get_faction_by_cid(char_id)
		if faction==nil then 
			print('faction == nil')
			return 
		end
		
		local ft_bag = g_faction_bag_mgr:get_bag_by_fid(faction:get_faction_id())
		local s_pkt = ft_bag:get_op_record(pkt.page,pkt.page_size,pkt.op_type)
		g_server_mgr:send_to_server(conn.id,char_id, CMD_C2M_BAG_OPERATE_RES, s_pkt)
	end