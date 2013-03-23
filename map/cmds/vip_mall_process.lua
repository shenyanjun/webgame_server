
local integral_func=require("mall.integral_func")

----***************************VIP商城***********************************

Clt_commands[1][CMD_MAP_VIP_MALL_BUY_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	local vip_type = g_vip_mgr:get_vip_info(conn.char_id)
	if vip_type < 0 then return end
	if vip_type == 5 then
		vip_type = 1
	end

	if pkt.catalog>vip_type then 
		return 
	end

	local ret = {}
	ret.item_id = pkt.item_id
	ret.number = pkt.number
	ret.currency = pkt.currency
	ret.catalog = pkt.catalog
	ret.day = pkt.day
	--print("25 =", j_e(pkt))
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_MALL_VIP_BUY_ITEM_REQ,pkt)
end


Sv_commands[0][CMD_MALL_VIP_BUY_ITEM_ANS] = 
function (conn, char_id, pkt)
	local ret = {}
	ret.result = 0
	if pkt.error and pkt.error~= 0 then
		ret.result = pkt.error
		g_cltsock_mgr:send_client(char_id, CMD_MAP_VIP_MALL_BUY_S,ret)
		return 
	end
	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	local money  = pack_con:get_money()

	local total_money = 0
	local total = pkt.total
	local number = tonumber(pkt.number)
	local item_id = tonumber(pkt.item_id)

	local money_type = 3
	if pkt.currency == 3 then
		total_money = money.gift_jade
		item_id  = tonumber(string.sub(tostring(item_id),1,11).."0")
		money_type = 4
	end

	--时装
	local item_list = {} 
	local e_code = 0
	if pkt.day and pkt.item_id then
		if item_obj:set_last_time(tonumber(pkt.day)) ~= 0 then 
			return 
		end 
		item_list[1] = {}
		item_list[1].number = tonumber(number)
		item_list[1].item = item_obj
		item_list[1].type = 2
	else
		item_list[1] = {}
		item_list[1].number = tonumber(number)
		item_list[1].item_id = tonumber(item_id)
		item_list[1].type = 1	
	end	
	if pack_con:add_item_l(item_list,{["type"] = ITEM_SOURCE.VIP_MALL_BUY}) ~= 0 then
		ret.result = 43017
		g_cltsock_mgr:send_client(char_id,CMD_MAP_VIP_MALL_BUY_S,ret)
		pkt.result = 43017
		g_svsock_mgr:send_server_ex(COMMON_ID, char_id,CMD_M2C_QQ_VIPMALL_REQ,pkt)
		return 
	end 
	--pack_con:dec_money(money_type,total,{["type"] = MONEY_SOURCE.VIP_MALL_BUY})
	--if money_type == 3 then
		--integral_func.add_bonus(char_id,total,{['type']=MONEY_SOURCE.VIP_MALL_BUY})
	--end
	pkt.result = 0
	g_svsock_mgr:send_server_ex(COMMON_ID, char_id,CMD_M2C_QQ_VIPMALL_REQ,pkt)

	g_cltsock_mgr:send_client(char_id, CMD_MAP_VIP_MALL_BUY_S, ret)


	--流水
	local str = "insert into log_mall(account,char_id,char_name,level,\
	item_id,item_name,item_num,money_total,money_type,time) \
	values('%s',%d,'%s',%d,%d,'%s',%d,%d,%d,%d)"
	local str_log = string.format(str, player:get_account_id(), char_id, player:get_name(), player:get_level(),
	pkt.item_id, pkt.name, pkt.number, total, money_type, ev.time)
	g_mall_log:write(str_log)
	g_web_sql:write(str_log)
end  



