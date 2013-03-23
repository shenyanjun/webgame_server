-- CodeBy:cailizhong

-- 往仓库放入物品
Sv_commands[0][CMD_PUT_ITEM_INTO_WAREHOUSE_M] = 
function(conn, char_id, pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local ret = {}
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		local bag = g_faction_bag_mgr:get_bag_by_fid(faction_id)
		local item_l = {}
		item_l[1] = {}
		item_l[1].item_id = pkt.item_id
		item_l[1].item_db = pkt.item_db
		item_l[1].count = pkt.count
		ret.result = 0
		local e_code = bag:check_can_add(item_l) -- 检查背包能否放物品
		if e_code ~= 0 then
			ret.result = e_code
		--	return g_server_mgr:send_to_server(conn.id,char_id,CMD_PUT_ITEM_INTO_WAREHOUSE_C,ret)
		else
			local e_code, update_client = bag:add_item_bat(item_l, char_id, 1) -- 放物品放上去,并设置默认价格为1帮贡
			if e_code ~= 0 then
				ret.result = e_code
			--return g_server_mgr:send_to_server(conn.id,char_id,CMD_PUT_ITEM_INTO_WAREHOUSE_C,ret)
			end
		end
		if ret.result ~= 0 then -- 通过邮件返回物品
			local e_code, t_item = Item_factory.create(pkt.item_id)
			if e_code~= 0 then -- 创建物品失败
				ret.result = e_code
				return g_server_mgr:send_to_server(conn.id,char_id,CMD_PUT_ITEM_INTO_WAREHOUSE_C,ret)
			end
			t_item:clone(pkt.item_db) -- 从数据恢复
			local item_list = {}
			item_list[1] = t_item
			local title = f_get_string(2751)--g_u("系统邮件")
			local content = f_get_string(2752)--g_u("往帮派仓库放入物品失败，请重试。")
			local g_email = Email(-1,char_id,title,content,0,Email_type.type_annex,Email_sys_type.type_sys,item_list)
			if g_email ~= nil then
				local item = {}
				item[1] = {}
				item[1]["item_id"] = pkt.item_id
				item[1]["item_obj"] = pkt.item_db
				item[1]["number"] =	pkt.count
				g_email:set_item_list(item)
				g_email_mgr:add_email(g_email)
			end
			return g_server_mgr:send_to_server(conn.id,char_id,CMD_PUT_ITEM_INTO_WAREHOUSE_C,ret)
		end
		g_server_mgr:send_to_server(conn.id,char_id,CMD_PUT_ITEM_INTO_WAREHOUSE_C,ret)
	end
end

-- 设置物品价格
Sv_commands[0][CMD_SET_ITEM_PRICE_WAREHOUSE_M] = 
function(conn, char_id, pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		local bag = g_faction_bag_mgr:get_bag_by_fid(faction_id)
		local e_code , update_client = bag:set_item_price(pkt.uuid, pkt.price, char_id) -- 返回 0表示成功
		local ret = {}
		ret.result = e_code
		g_server_mgr:send_to_server(conn.id, char_id, CMD_SET_ITEM_PRICE_WAREHOUSE_C, ret)
	end
end

-- 摧毁仓库物品
Sv_commands[0][CMD_DESTORY_ITEM_WAREHOUSE_M] = 
function(conn, char_id, pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		local bag = g_faction_bag_mgr:get_bag_by_fid(faction_id)
		local e_code = bag:destroy_item_by_uuid(pkt.uuid, char_id)
		local ret = {}
		ret.result = e_code
		g_server_mgr:send_to_server(conn.id, char_id, CMD_DESTORY_ITEM_WAREHOUSE_C, ret)
	end
end

-- 从仓库取出物品
Sv_commands[0][CMD_GET_ITEM_FROM_WAREHOUSE_M] = 
function(conn, char_id, pkt)
	if char_id == nil then return end
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	local ret = {}
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		local bag = g_faction_bag_mgr:get_bag_by_fid(faction_id)
		local item, count = bag:get_item_by_uuid(pkt.uuid) -- 获取物品
		if item == nil then
			ret.result = 31173
			return g_server_mgr:send_to_server(conn.id, char_id, CMD_GET_ITEM_FROM_WAREHOUSE_C, ret)
		elseif count < pkt.count then -- 仓库背包物品数量不足
			ret.result = 31177
			return g_server_mgr:send_to_server(conn.id, char_id, CMD_GET_ITEM_FROM_WAREHOUSE_C, ret)
		end
		local money = bag:get_item_price(pkt.uuid) -- 获取物品单价价格
		
		if money == nil then
			ret.result = 31174
			return g_server_mgr:send_to_server(conn.id, char_id, CMD_GET_ITEM_FROM_WAREHOUSE_C, ret)
		end
		money = money * pkt.count -- 计算物品总价

		-- 扣除帮派贡献
		local result = faction:update_faction_level(char_id, 6, -money)
		if result ~= 0 then
			ret.result = 31175
			return g_server_mgr:send_to_server(conn.id, char_id, CMD_GET_ITEM_FROM_WAREHOUSE_C, ret)
		end
		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1]= faction:syn_info(char_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt),true)
		g_server_mgr:send_to_server(conn.id,char_id,CMD_P2M_FACTION_UPDATE_INFO_REP,{["result"] = 0,["flag"] = 6 })
		--------------------------------------------------------------------------------
		ret.item_id = item:get_item_id()
		ret.item_db = item:serialize_to_db()
		ret.count = pkt.count
		ret.uuid = pkt.uuid
		ret.result = 0
		ret.money = money

		local e_code , update_client = bag:del_item_by_uuid(pkt.uuid, pkt.count, char_id) -- 真正从帮派仓库扣除物品
		ret.result = e_code
		g_server_mgr:send_to_server(conn.id, char_id, CMD_GET_ITEM_FROM_WAREHOUSE_C, ret)
	end
end