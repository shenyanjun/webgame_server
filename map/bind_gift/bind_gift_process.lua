-- cailizhong
-- 手机绑定礼包

-- 获取手机绑定礼包
Clt_commands[1][CMD_C2M_SJ_BIND_GIFT_C] =
function(conn, pkt)
	-- 检查传入参数
	if conn.char_id==nil or conn.acc_id==nil or pkt.key==nil or pkt.bind_type==nil then return 31041 end
	
	local char_id = conn.char_id
	local acc_id = conn.acc_id
	local bind_type = pkt.bind_type
	local key = pkt.key

	local player = g_obj_mgr:get_obj(char_id)
	local bind_gift_con = player:get_bind_gift_con()
	if not bind_gift_con then return end

	local result = bind_gift_con:can_get_gift(acc_id, bind_type, key)
	local ret = {}
	if result ~= 0 then -- 异常
		ret.result = result
		g_cltsock_mgr:send_client(char_id, CMD_C2M_SJ_BIND_GIFT_S, ret)
		return
	else
		bind_gift_con:get_gift(bind_type) -- 获取手机绑定礼包
		ret.result = result
		g_cltsock_mgr:send_client(char_id, CMD_C2M_SJ_BIND_GIFT_S, ret) -- 通知客户端
		return
	end
end
