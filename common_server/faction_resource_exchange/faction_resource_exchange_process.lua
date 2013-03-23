-- CodeBy:cailizhong
-- 帮派资源互换,该功能仅帮主拥有

-- 帮派资源互换

Sv_commands[0][CMD_FACTION_RESOURCE_EXCHANGE_M] =
function(conn, char_id, pkt)
	--print("in CMD_GET_RECORD_WAREHOUSE_M")
	--print(j_e(pkt))
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local ret = {}
	if faction ~= nil then
		if pkt.type == 1 then
			ret.result = 0
		elseif pkt.type == 2 then
			local per_result = faction:is_permission_ok(7,char_id)
			if per_result ~=0 then 
				return g_server_mgr:send_to_server(conn.id,char_id, CMD_FACTION_RESOURCE_EXCHANGE_C, {["result"]=per_result})
			end
			local e_code = faction:resource_exchange(pkt.sell_type, pkt.sell_cnt, pkt.buy_type, pkt.buy_cnt) -- 资源互换
			ret.result = e_code
			if e_code == 0 then
				-- 添加帮派资源互换后台流水
				local str = string.format("insert log_faction_exchange set faction_id='%s', faction_name='%s', char_id=%d, char_name='%s', out_type=%d, out_num=%d, in_type=%d, in_num=%d, today_return=%d, time=%d",
					faction:get_faction_id(), faction:get_faction_name(), char_id, pkt.char_name, pkt.sell_type, pkt.sell_cnt, pkt.buy_type, pkt.buy_cnt, faction:get_resource_have_exchange(pkt.buy_type), ev.time)
				--print(str)
				g_web_sql:write(str)

				local new_pkt = {}
				new_pkt.faction_id = faction:get_faction_id()
				new_pkt.cmd =25642
				new_pkt.list ={}
				new_pkt.list[1]= faction:syn_info(char_id,1,7)
				g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
			end
		end
		ret.remain_num_list = faction:get_reamin_num_list()
		--print(j_e(ret))
		g_server_mgr:send_to_server(conn.id, char_id, CMD_FACTION_RESOURCE_EXCHANGE_C, ret)
	end
end
