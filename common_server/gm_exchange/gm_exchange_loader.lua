
module("gm_exchange.gm_exchange_loader",package.seeall)

local database = "gm_exchange"
local proto_mgr = require("item.proto_mgr")
ExchangeTable = {}


function load_exchange_db()
	--清空列表
	ExchangeTable = {}
	local dbh = f_get_db()
	local row,error = dbh:select(database)
	local now = ev.time
	if row and error == 0 then
		for k,v in pairs(row or {}) do
			if ((string.len(tostring(v.des_id))==1 and tonumber(v.des_id)>=1 and tonumber(v.des_id)<=8 ) or proto_mgr.exist(tonumber(v.des_id))) and tonumber(v.des_count) > 0 
			and v.single and v.total and v.start_time and v.end_time and v.end_time>now then
				local obj = {}
				obj.des_id = tonumber(v.des_id)
				obj.des_name = v.des_name or ""
				obj.days = nil
				if v.extend and v.extend.days then
					obj.days = tonumber(v.extend.days)	--时装
				end
				obj.des_count = math.min(tonumber(v.des_count),100000)
				obj.start_time = tonumber(v.start_time)
				obj.end_time = tonumber(v.end_time)
				obj.total = tonumber(v.total)
				obj.single = tonumber(v.single)
				local item_l = {}
				local money_l = {}
				local count = 1
				for i,v in pairs(v.item_l or {}) do
					item_l[count] = {}
					item_l[count][1] = tonumber(v.item_id)
					item_l[count][2] = tonumber(v.count)
					item_l[count][3] = v.item_name or ""
					count = count+1
				end
				for i,v in pairs(v.money_l or {}) do
					money_l[i] = tonumber(v) or 0
				end
				obj.item_l = item_l
				obj.money_l = money_l
				obj.exc_id = v.exchange_id or ""
				table.insert(ExchangeTable,obj)
			end
		end
	end
end

--初始化列表
load_exchange_db()
