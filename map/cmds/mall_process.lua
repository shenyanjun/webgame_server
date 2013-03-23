local integral_func=require("mall.integral_func")


Clt_commands[1][CMD_MAP_MALL_GET_LIST_C] = 
function(conn, pkt)
	if not conn then return end 
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_MALL_GET_ITEM_LIST_C,pkt)
end


Sv_commands[0][CMD_MALL_GET_ITEM_LIST_S] = 
function (conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_MAP_MALL_GET_LIST_S, pkt)
end  

----测试玩家购买请求
--Clt_commands[1][CMD_G2M_QQ_CURENCY_TEST_B] =
--function(conn, pkt)
	--print("40 =", j_e(pkt))
	--if not pkt or not pkt.openid or not pkt.openkey or not pkt.serverid
		--or not pkt.pf or not pkt.pfkey or not pkt.item_id or not pkt.number then
		--
		--return 1
	--end
--
	--pkt.char_id = conn.char_id
	--pkt.price = "10"
	--pkt.item_name = "测试物品"
	--print("50 =", j_e(pkt))
	--g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_M2G_QQ_CURENCY_M, pkt)
--end

Clt_commands[1][CMD_MAP_MALL_BUY_ITEM_C] = 
function(conn, pkt)
	if not conn then return end
	if tonumber(pkt.catalog) == 11 then
		local ret = {}
		ret.page = pkt.page
		ret.pageSize = 6
		ret.number = pkt.number
		ret.currency = pkt.currency
		ret.day = pkt.day
		ret.item_id = pkt.item_id
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_GM_MALL_BUY_ITEM_REQ,ret)
		return 
	end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_MALL_BUY_ITEM_C,pkt)
end

--测试玩家购买请求
Clt_commands[1][CMD_G2M_QQ_CURENCY_TEST_B] =
function(conn, pkt)
	--print("40 =", j_e(pkt))
	if not pkt or not pkt.openid or not pkt.openkey or not pkt.serverid
		or not pkt.pf or not pkt.pfkey or not pkt.item_id or not pkt.number then
		
		return 1
	end

	if pkt.currency == 3 then
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_MALL_BUY_ITEM_GIFTJADE_M,pkt)
	else
		g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_MALL_BUY_ITEM_C,pkt)
	end
end

Sv_commands[0][CMD_MALL_BUY_ITEM_GIFTJADE_C] = 
function (conn, char_id, pkt)
	if not pkt.item_id or not pkt.number then 
		print("mall buy item pkt is nil")
		return 
	end

 	local item_id = pkt.item_id
	local number = pkt.number
	local item_currency = pkt.item_currency 
	local item_price = pkt.item_price
	local item_name = pkt.item_name

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local pack_con = player:get_pack_con()

	local money = pack_con:get_money()
	local money_type 
	local total_money = 0
	if item_currency == 3 then
		total_money = money.gift_jade 
		item_id  = tonumber(string.sub(tostring(item_id),1,11).."0")
		money_type = MoneyType.GIFT_JADE
	else
		return
	end
	if pack_con:check_money_lock(money_type) then return end--上锁 

	if pack_con then
		local ret = {}
		ret.result = 0
		--时装
		local item_obj,e_code
		if pkt.day and pkt.item_id then
			e_code,item_obj = Item_factory.create(tonumber(item_id))
			if not item_obj then return end
			--local e_code,price = item_obj:get_cost(tostring(pkt.day),1)
			--if e_code ~= 0 then 
				--return 
			--end	
			--item_price = price*number
		end

		if total_money < item_price then
			ret.result = 43027
			g_cltsock_mgr:send_client(char_id, CMD_MAP_MALL_BUY_ITEM_S, ret)
			return
		end
		--时装
		local item_list = {} 
		local e_code = 0
		if pkt.day and pkt.item_id then
			--if item_obj:set_last_time(tonumber(pkt.day)) ~= 0 then 
				--return 
			--end 
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
		if pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.MALL}) ~= 0 then
			ret.result = 43017
			g_cltsock_mgr:send_client(char_id, CMD_MAP_MALL_BUY_ITEM_S, ret)
			return
		end
		pack_con:dec_money(money_type, item_price, {['type']=MONEY_SOURCE.MALL})

		g_cltsock_mgr:send_client(char_id, CMD_MAP_MALL_BUY_ITEM_S, ret)

		local str = "insert into log_mall(account,char_id,char_name,level,\
			item_id,item_name,item_num,money_total,money_type,time) \
			values('%s',%d,'%s',%d, %d,'%s',%d,%d,%d,%d)"
		local str_log = string.format(str, player:get_account_id(), char_id, player:get_name(), player:get_level(),
		item_id, item_name, number, item_price, money_type, ev.time)

		g_mall_log:write(str_log)
		f_multi_web_sql(str_log)
	end
end  

Sv_commands[0][CMD_MALL_BUY_ITEM_S] = 
function (conn, char_id, pkt)
	if not pkt.item_id or not pkt.number then 
		print("mall buy item pkt is nil")
		return 
	end

 	local item_id = pkt.item_id
	local number = pkt.number
	local item_currency = pkt.item_currency 
	local total_price = pkt.item_price
	local item_name = pkt.item_name

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_M2C_QQ_MALL_REQ, {result = 1}) end
	local pack_con = player:get_pack_con()

	local money = pack_con:get_money()
	local money_type = 3
	local total_money = 0

	if pack_con then
		local ret = {}
		ret.result = 0
		--时装
		local item_obj,e_code
		if pkt.day and pkt.item_id then
			e_code,item_obj = Item_factory.create(tonumber(item_id))
			if not item_obj then return end
			--local e_code,price = item_obj:get_cost(tostring(pkt.day),1)
			--if e_code ~= 0 then 
				--return 
			--end	
			--total_price = price*number
		end

		--时装
		local item_list = {} 
		local e_code = 0
		if pkt.day and pkt.item_id then
			--if item_obj:set_last_time(tonumber(pkt.day)) ~= 0 then 
				--return 
			--end 
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
		if pack_con:add_item_l(item_list, {['type']=ITEM_SOURCE.MALL}) ~= 0 then
			ret.result = 43017
			g_cltsock_mgr:send_client(char_id, CMD_MAP_MALL_BUY_ITEM_S, ret)
			g_svsock_mgr:send_server_ex(COMMON_ID, char_id,CMD_M2C_QQ_MALL_REQ, {result = 1})
			return
		end

		g_cltsock_mgr:send_client(char_id, CMD_MAP_MALL_BUY_ITEM_S, ret)
		pkt.result = 0
		g_svsock_mgr:send_server_ex(COMMON_ID, char_id,CMD_M2C_QQ_MALL_REQ, pkt)

		local str = "insert into log_mall(account,char_id,char_name,level,\
			item_id,item_name,item_num,money_total,money_type,time) \
			values('%s',%d,'%s',%d,%d,'%s',%d,%d,%d,%d)"
		local str_log = string.format(str, player:get_account_id(), char_id, player:get_name(), player:get_level(),
		item_id, item_name, number, total_price, money_type, ev.time)

		g_mall_log:write(str_log)
		f_multi_web_sql(str_log)
	end
end  

--功能：积分商城购买
--参数：客户端socket，数据包pkt
--返回：成功0/失败-1
Clt_commands[1][CMD_MAP_MALL_BUY_GOODS_C]=
function(conn,pkt)
    if not conn.char_id or not pkt then return end 
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_MALL_INTEGRAL_BUY_C,pkt)
end 


Sv_commands[0][CMD_MALL_INTEGRAL_BUY_S] = 
function (conn, char_id, pkt)
	if not pkt.item_id or not pkt.number then 
		print("integral mall buy item pkt is nil")
		return 
	end

	local item_id = tonumber(pkt.item_id)
	local item_name = pkt.item_name
	local number = tonumber(pkt.number)
	local total = tonumber(pkt.total)
	local price = tonumber(pkt.price)

	local retpkt = {} 
	local player=g_obj_mgr:get_obj(char_id) 
	local pack_con=player:get_pack_con() 
	local ret=pack_con:get_money() 
	if pack_con:check_money_lock(MoneyType.INTEGRAL) then return end--上锁 
	--时装
	local e_code,item_obj
	if pkt.day and pkt.item_id then
		e_code,item_obj = Item_factory.create(tonumber(pkt.item_id))
		if not item_obj then 
			return 
		end
		local e_code
		--e_code,price = item_obj:get_cost(tostring(pkt.day),2)
		--if e_code ~= 0 then 
			--return 
		--end	
		--total = price*number
	end
	local integ=ret.integral 
	if integ < total then 
		retpkt.result = 60003 
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_MALL_BUY_GOODS_S,retpkt) 
		return 
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
	local e_code=pack_con:add_item_l(item_list,{['type']=ITEM_SOURCE.MALL}) 
	if e_code ~= 0 then
		retpkt.result = 43004 
		g_cltsock_mgr:send_client(conn.char_id,CMD_MAP_MALL_BUY_GOODS_S,retpkt) 
		return 
	end 
	e_code=pack_con:dec_money(MoneyType.INTEGRAL,total,{['type']=MONEY_SOURCE.MALL}) 

	--商城流水
	local str = "insert into log_mall(account,char_id,char_name,level,\
	item_id,item_name,item_num,money_total,money_type,time) \
	values('%s',%d,'%s',%d,%d,'%s',%d,%d,%d,%d)"
	local str_log = string.format(str, player:get_account_id(), char_id, player:get_name(), player:get_level(),
	item_id, item_name, number, price, MoneyType.INTEGRAL, ev.time)
	g_mall_log:write(str_log)
	g_web_sql:write(str_log)
end  





--*************************************限时限量购买*******************************************
Clt_commands[1][CMD_MAP_MALL_SPECIAL_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_MALL_GET_LIMIT_ITEM_C,pkt)
end



Sv_commands[0][CMD_MALL_GET_LIMIT_ITME_S] = 
function (conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_MAP_MALL_SPECIAL_S, pkt)
end  



Clt_commands[1][CMD_MAP_MALL_BUY_SPECIAL_C] = 
function(conn,pkt)
	if not conn.char_id then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_MALL_BUY_LIMIT_ITEM_C,pkt)
end


Sv_commands[0][CMD_MALL_BUY_LIMIT_ITEM_S] = 
function (conn, char_id, pkt)

	if pkt.error ~= 0 then
		g_cltsock_mgr:send_client(char_id,CMD_MAP_MALL_BUY_SPECIAL_S,{["result"]=pkt.error})
		return 
	end

	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()

	local ret = {}
	ret.error = 0
	local number = pkt.number
	local price = pkt.price
	local currency = pkt.currency
	local total = price*number
	local total_money = pack_con:get_money()
	local money = 0
	local item_id = pkt.item_id
	local money_type
	if currency == 3 then
		money = total_money.gift_jade  --礼券
		money_type = 4
		item_id  = tonumber(string.sub(tostring(item_id),1,11).."0")
	elseif currency == 2 then
		money = total_money.jade  --元宝
		money_type = 3
	elseif 4 == currency then
		money = total_money.integral 
		money_type = 6
	end 

	--时装
	local e_code,item_obj
	if pkt.day and pkt.item_id then
		e_code,item_obj = Item_factory.create(tonumber(item_id))
		if not item_obj then 
			g_cltsock_mgr:send_client(char_id,CMD_MAP_MALL_BUY_SPECIAL_S,{["result"]=11112})
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_MALL_BUY_LIMIT_ITEM_REQ,{["result"]=11112})						
			return 
		end
		--local e_code
		--e_code,price = item_obj:get_cost(tostring(pkt.day),3)
		--if e_code ~= 0 then 
			--g_cltsock_mgr:send_client(char_id,CMD_MAP_MALL_BUY_SPECIAL_S,{["result"]=e_code})
			--g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_MALL_BUY_LIMIT_ITEM_REQ,{["result"]=e_code})			
			--return 
		--end	
		--total = price*number
	end

	--时装
	local item_l = {}
	local e_code = 0
	if pkt.day and pkt.item_id then
		--if item_obj:set_last_time(tonumber(pkt.day)) ~= 0 then 
			--g_cltsock_mgr:send_client(char_id,CMD_MAP_MALL_BUY_SPECIAL_S,{["result"]=43004})
			--g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_MALL_BUY_LIMIT_ITEM_REQ,{["result"]=43004})			
			--return 
		--end 
		item_l[1] = {}
		item_l[1].number = tonumber(number)
		item_l[1].item = item_obj
		item_l[1].type = 2
	else
		item_l[1] = {}
		item_l[1].number = tonumber(number)
		item_l[1].item_id = tonumber(item_id)
		item_l[1].type = 1	
	end
	e_code = pack_con:add_item_l(item_l,{['type']=ITEM_SOURCE.MALL})
	if e_code ~= 0 then
		ret.error = 43004
		g_cltsock_mgr:send_client(char_id,CMD_MAP_MALL_BUY_SPECIAL_S,{["result"]=43004})
		g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_MALL_BUY_LIMIT_ITEM_REQ,{["result"]=43004})
		return 
	end	
	
	ret.item_id = tonumber(pkt.item_id)
	ret.number = number
	ret.result = 0
	g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_MALL_BUY_LIMIT_ITEM_REQ,ret)


	--商城流水
	local str = "insert into log_mall(account,char_id,char_name,level,\
	item_id,item_name,item_num,money_total,money_type,time) \
	values('%s',%d,'%s',%d,%d,'%s',%d,%d,%d,%d)"
	local str_log = string.format(str, player:get_account_id(), char_id, player:get_name(), player:get_level(),
	item_id, pkt.name, number, total, money_type, ev.time)
	g_mall_log:write(str_log)
	g_web_sql:write(str_log)

end  


Sv_commands[0][CMD_MALL_BUY_LIMIT_ITEM_ANS] = 
function (conn, char_id, pkt)
	g_cltsock_mgr:send_client(char_id, CMD_MAP_MALL_SPECIAL_S, pkt)
end  


--**********************************后台商城************************************
--获取商城列表
Clt_commands[1][CMD_MAP_GM_MALL_GET_ITME_LIST_C] = 
function(conn,pkt)
	if not conn then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_GET_GM_MALL_REQ,pkt)
end

Sv_commands[0][CMD_C2M_GET_GM_MALL_ANS] = 
function(conn,char_id,pkt)
	if not pkt or not char_id then return end
	g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_MALL_GET_ITME_LIST_S,pkt)
end

--购买物品
Clt_commands[1][CMD_MAP_GM_MALL_BUY_ITME_C] =
function(conn,pkt)
	if not conn or not conn.char_id or not pkt then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,conn.char_id,CMD_M2C_GM_MALL_BUY_ITEM_REQ,pkt)
end 

Sv_commands[0][CMD_C2M_GM_MALL_BUY_ITEM_ANS] = 
function(conn,char_id,pkt)
	--print("CMD_C2M_GM_MALL_BUY_ITEM_ANS pkt", j_e(pkt))
	if not char_id then return end
	local ret = {}
	ret.result = 0
	if pkt.error ~= 0 then 
		ret.result = pkt.error
		g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_MALL_BUY_ITME_S,ret)
		return 
	end	

	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	local item_id = pkt.item_id
	local number = pkt.number
	local price = pkt.price
	local currency = pkt.currency
	local total = price*number
	local total_money = pack_con:get_money()
	local money = 0
	local money_type = 3

	--时装
	local e_code,item_obj
	if pkt.day and pkt.item_id then
		e_code,item_obj = Item_factory.create(tonumber(item_id))
		if not item_obj then return end
		--local e_code
		--e_code,price = item_obj:get_cost(tostring(pkt.day),1)
		--if e_code ~= 0 then 
			--return 
		--end	
		--total = price*number
	end


	--时装
	local item_l = {}
	local e_code = 0
	if pkt.day and pkt.item_id then
		--if item_obj:set_last_time(tonumber(pkt.day)) ~= 0 then 
			--return 
		--end 
		item_l[1] = {}
		item_l[1].number = tonumber(number)
		item_l[1].item = item_obj
		item_l[1].type = 2
	else
		item_l[1] = {}
		item_l[1].number = tonumber(number)
		item_l[1].item_id = tonumber(item_id)
		item_l[1].type = 1	
	end
	e_code = pack_con:add_item_l(item_l,{['type']=ITEM_SOURCE.GM_MALL_BUY})
	if e_code ~= 0 then
		ret.result = 43004
		g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_MALL_BUY_ITME_S,ret)
		return 
	end	

	local new_pkt = {}
	new_pkt.item_id = tonumber(pkt.item_id)
	new_pkt.number = number
	g_svsock_mgr:send_server_ex(COMMON_ID,char_id,CMD_M2C_GM_MALL_DEC_TIME_REQ,new_pkt)

	--商城流水
	local str = "insert into log_mall(account,char_id,char_name,level,\
	item_id,item_name,item_num,money_total,money_type,time) \
	values('%s',%d,'%s',%d,%d,'%s',%d,%d,%d,%d)"
	local str_log = string.format(str, player:get_account_id(), char_id, player:get_name(), player:get_level(),
	item_id, pkt.name, number, total, money_type, ev.time)
	g_mall_log:write(str_log)
	g_web_sql:write(str_log)
end


Sv_commands[0][CMD_C2M_GM_MALL_DEC_ITEM_ANS] = 
function(conn,char_id,pkt)
	if not pkt or not char_id then return end
	g_cltsock_mgr:send_client(char_id,CMD_MAP_GM_MALL_GET_ITME_LIST_S,pkt)	
end