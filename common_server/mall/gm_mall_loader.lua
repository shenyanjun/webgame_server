

local database = "gm_mall"
local proto = require("item.proto_mgr")
module("mall.gm_mall_loader", package.seeall)
GmMallTable = {}
function update_gm_mall()
	GmMallTable = {}
	local dbh = f_get_db()
	local fields = "{index_id:1,list:1}"
	local query = string.format("{index_id:%d}",1)
	local row,e_code = dbh:select_one(database,fields,query)
	local now = ev.time
	if row and e_code == 0 then
		for _,v in pairs(row.list or {}) do
			if v and v.item_id and proto.exist(tonumber(v.item_id)) and v.price and tonumber(v.price)>0 
			and v.currency and tonumber(v.currency)>0 and v.total_count and tonumber(v.total_count) 
			and v.single_count and tonumber(v.single_count) and v.start_time and tonumber(v.start_time) 
			and v.end_time and tonumber(v.end_time) and now<v.end_time then
				local obj = {}
				obj.item_id = v.item_id
				obj.name = tostring(v.name or "")
				obj.price = v.price
				obj.currency = v.currency
				obj.total_count = v.total_count
				obj.single_count = v.single_count
				obj.start_time = v.start_time
				obj.end_time = v.end_time
				obj.type = v.type
				obj.ori_price = v.ori_price
				table.insert(GmMallTable,obj)
			end
		end
	end
end


update_gm_mall()