
Trade_mgr = oo.class(nil, "Trade_mgr")

function Trade_mgr:__init()
	self.trade_l = {}

	--时间计数
	self.time_count = 0         --时间计数
end

function Trade_mgr:create_trade(obj_s, obj_d)
	local trade_obj = Obj_trade(obj_s:get_id(), obj_d:get_id())
	local trade_id = trade_obj:get_id()
	self.trade_l[trade_id] = trade_obj

	--判断原先是否有交易，有的话删除
	local trade_id_s = obj_s:get_trade()
	local trade_id_d = obj_d:get_trade()
	local trade_obj_s = g_trade_mgr:get_trade_obj(trade_id_s)
	local trade_obj_d = g_trade_mgr:get_trade_obj(trade_id_d) 
	if trade_obj_s then
		g_trade_mgr:del_trade(trade_id_s)
	end
	if trade_obj_d then
		g_trade_mgr:del_trade(trade_id_d)
	end

	obj_s:set_trade(trade_id)
	obj_d:set_trade(trade_id)
	return trade_obj
end
function Trade_mgr:del_trade(trade_id)
	local trade_obj = self.trade_l[trade_id]
	self.trade_l[trade_id] = nil
	if trade_obj ~= nil then
		local list = trade_obj:get_member()
		for _,id in pairs(list) do
			local obj = g_obj_mgr:get_obj(id)
			if obj ~= nil then
				obj:set_trade(nil)
			end

			--通知关闭窗口
			local new_pkt = {}
			new_pkt.obj_id = id
			new_pkt.trade_id = trade_id
			g_cltsock_mgr:send_client(id, CMD_MAP_TRADE_CANCEL_S, new_pkt)
		end
	end
end

function Trade_mgr:get_trade_obj(trade_id)
	if trade_id ~= nil then
		return self.trade_l[trade_id]
	end
end