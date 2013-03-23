local proto_mgr = require("item.proto_mgr")



--获取列表
Clt_commands[1][CMD_MAP_GET_GM_EXCHANGE_LIST_C] = 
function(conn,pkt)
	if not conn.char_id or not pkt.page or not pkt.pageSize then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_GM_EXC_GET_LIST_REQ,pkt)
end

Sv_commands[0][CMD_M2C_GM_EXC_GET_LIST_ANS] = 
function(conn,char_id,pkt)
	g_cltsock_mgr:send_client(char_id,CMD_MAP_GET_GM_EXCHANGE_LIST_S,pkt)
end

--兑换
Clt_commands[1][CMD_MAP_GM_EXCHANGE_C] = 
function(conn,pkt)
	if not conn.char_id or not pkt.exchange_id or not pkt.page or not pkt.pageSize then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_GM_EXC_ITEM_REQ,pkt)
end

Sv_commands[0][CMD_C2M_GM_EXC_TIME_ANS] = 
function(conn,char_id,pkt)
	--有错误
	if pkt.result ~= 0 then
		g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_EXCHANGE_S,pkt)
		return 
	end
	local item = pkt.item
	local ret = {}
	local money_flage = false
	for k,v in pairs(item.money_l or {}) do
		if k and item.money_l[k]>0 then
			money_flage = true
		end
	end
	local item_flage = false
	local item_count = 0
	for k,v in pairs(item.item_l or {}) do
		if v[1] and proto_mgr.exist(v[1]) and v[2]>0 then
			item_count = item_count+1
		end
	end

	if item.item_l and item_count == #item.item_l and #item.item_l~=0 then
		item_flage = true
	end
	if not item_flage and not money_flage then
		ret.result = 22306
		g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_EXCHANGE_S,ret)
		return 
	end

	
	--背包操作
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	local item_l = item.item_l
	local item_valid = true
	local del_l = {}
	for i,v in pairs(item_l or {}) do
		if pack_con:get_all_item_count(v[1]) < v[2] then
			item_valid = false
			break
		end
		local obj ={}
		obj.number = v[2]
		obj.item_id = v[1]
		obj.type = 1
		table.insert(del_l,obj)
	end
	--数量不够
	if not item_valid then
		ret.result = 22305
		g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_EXCHANGE_S,ret)
		return 
	end 
	--钱不够
	local money = pack_con:get_money()
	if money.jade < item.money_l[1] or money.gift_jade < item.money_l[2]
	or money.gold < item.money_l[3] or money.gift_gold < item.money_l[4] 
	or money.integral < item.money_l[5] or money.bonus/100 < item.money_l[6] then
		ret.result = 43340
		g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_EXCHANGE_S,ret)
		return 		
	end

	local add_l ={}
	add_l[1] = {}
	if item.days then
		local error,item_obj = Item_factory.create(item.des_id)
		if not item_obj then return end
		if 0 ~= item_obj:set_last_time(item.days) then return end
		add_l[1].item = item_obj
		add_l[1].number = item.des_count --注意
		add_l[1].type = 2
	else
		add_l[1].item_id = item.des_id
		add_l[1].number = item.des_count --注意
		add_l[1].type = 1
	end

	if tonumber(item.des_id)>=1 and tonumber(item.des_id)<=8 and string.len(tostring(item.des_id)) then		--兑换钱
		pack_con:add_money(tonumber(item.des_id),math.min(item.des_count,100000),{['type'] = MONEY_SOURCE.GM_EXCHANGE})
	else	--兑换物品
		if pack_con:add_item_l(add_l,{["type"] = ITEM_SOURCE.GM_EXCHANGE}) ~= 0 then
			ret.result = 43017
			g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_EXCHANGE_S,ret)
			return 
		end
	end
		 	
	--删除
	for i,v in pairs(del_l or {}) do
		pack_con:del_item_by_item_id_bind_first(v.item_id,v.number,{["type"] = ITEM_SOURCE.GM_EXCHANGE})
	end
	
	--减钱
	pack_con:dec_money(MoneyType.JADE,item.money_l[1] or 0,{['type'] = MONEY_SOURCE.GM_EXCHANGE})
	pack_con:dec_money(MoneyType.GIFT_JADE,item.money_l[2] or 0,{['type'] = MONEY_SOURCE.GM_EXCHANGE})
	pack_con:dec_money(MoneyType.GOLD,item.money_l[3] or 0,{['type'] = MONEY_SOURCE.GM_EXCHANGE})
	pack_con:dec_money(MoneyType.GIFT_GOLD,item.money_l[4] or 0,{['type'] = MONEY_SOURCE.GM_EXCHANGE})
	pack_con:dec_money(MoneyType.INTEGRAL,item.money_l[5] or 0,{['type'] = MONEY_SOURCE.GM_EXCHANGE})
	pack_con:dec_money(MoneyType.BONUS,100*(item.money_l[6] or 0),{['type'] = MONEY_SOURCE.GM_EXCHANGE})

	--通知公共服
	local ret = {}
	g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_M2C_GM_EXC_NOTIFY_ANS,ret)
end


