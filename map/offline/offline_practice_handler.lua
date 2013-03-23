--2010-12-3
--laojc
--离线修炼处理事件
require("offline.offline_practice_mgr")

local integral_func=require("mall.integral_func");

local HOUR_TIME = 60*60
local GOLD = 10000
local THIRTY_JADE = 30
local SIXTY_JADE = 60


local err_fun = function(conn, err)
	local new_pkt = {}
	new_pkt.result = err
	g_cltsock_mgr:send_client_ex(conn, CMD_M2C_OFFLINE_ERROR_S, new_pkt)
end
--打开面板
Clt_commands[1][CMD_C2M_OFFLINE_OPEN_C] = 
function(conn, pkt)
	--print("-----------CMD_C2M_OFFLINE_OPEN_C-----------",j_e(pkt))
	--剩余修炼时间
	--预计可得经验
	--累计获得经验
	local char_id = conn.char_id

	local ret = g_off_mgr:get_net_info(char_id)
	g_cltsock_mgr:send_client_ex(conn,CMD_M2C_OFFLINE_OPEN_S, ret)

end

--领取经验
Clt_commands[1][CMD_C2M_OFFLINE_FETCH_EXP_C] = 
function(conn, pkt)
	if pkt.type == nil then return end
	--print("-----------CMD_C2M_OFFLINE_FETCH_EXP_C-----------",j_e(pkt))
	local char_id = conn.char_id 
	local type = pkt.type

	--获取累计经验
	local e_code = g_off_mgr:can_be_fetch(char_id)
	if e_code == nil then return end

	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end
	local pack_con = player:get_pack_con()
	local obj = g_off_mgr:get_obj(conn.char_id)
	if not obj then return end
	local obj_day = obj:get_point() / 8

	local sql_str
	local str = " char_id:".. char_id
	if type == 1 then
		str =str .." 获取了"
		sql_str = string.format("insert log_free set char_id = %d, char_name='%s', project=%d, type=%d, days=%d, exp=%d, time=%d",
					char_id, player:get_name(), 3, 1, obj_day, obj:get_fetch_expr(),os.time())
		f_multi_web_sql(sql_str)
	elseif type == 2 then
		if pack_con:check_money_lock(MoneyType.GOLD) then			return		end
		if pack_con:get_money().gold < GOLD then err_fun(conn,43333) return end	
		pack_con:dec_money(MoneyType.GOLD, GOLD, {['type']=MONEY_SOURCE.OFFLINE_FETCH_EXP})
		str = str .. " 花费了 " .. GOLD .." 铜币,获取了 "

	elseif type == 3 then
		if pack_con:check_money_lock(MoneyType.JADE) then			return		end
		if pack_con:get_money().jade < THIRTY_JADE then err_fun(conn,43333) return end	
		pack_con:dec_money(MoneyType.JADE, THIRTY_JADE, {['type']=MONEY_SOURCE.OFFLINE_FETCH_EXP})
		str = str .. " 花费了 " .. THIRTY_JADE .." 元宝,获取了 "
		integral_func.add_bonus(char_id,THIRTY_JADE,{['type']=MONEY_SOURCE.OFFLINE_FETCH_EXP})

	elseif type == 4 then
		if pack_con:check_money_lock(MoneyType.JADE) then			return		end
		if pack_con:get_money().jade < SIXTY_JADE then err_fun(conn,43333) return end	
		pack_con:dec_money(MoneyType.JADE, SIXTY_JADE, {['type']=MONEY_SOURCE.OFFLINE_FETCH_EXP})
		str = str .. " 花费了 " .. SIXTY_JADE .." 元宝,获取了 "
		integral_func.add_bonus(char_id,SIXTY_JADE,{['type']=MONEY_SOURCE.OFFLINE_FETCH_EXP})
	end

	local acc_expr = g_off_mgr:fetch_point(char_id,type)

	local ret = g_off_mgr:get_net_info(char_id)
	g_cltsock_mgr:send_client_ex(conn,CMD_M2C_OFFLINE_FETCH_EXP_S, ret)

	str = str .. acc_expr .."经验"
	g_offline_log:write(str)
end