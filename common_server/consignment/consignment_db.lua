local database = "consignment"
local record_db = "consignment_record"

Consignment_db = oo.class(nil, "Consignment_db")

local content_list = f_get_string(509)
--初始化  load所有寄售品
function Consignment_db:LoadAllConsignment()
	local db = f_get_db()

	local rows, e_code = db:select(database)
	if 0 == e_code then
		return rows
	else
		print("LoadAllConsignment Error: ", e_code)
	end
	return nil
end
--load所有记录
function Consignment_db:LoadAllConsignment_record()
	local db = f_get_db()

	local rows, e_code = db:select(record_db)
	if 0 == e_code then
		return rows
	else
		print("LoadAllConsignment_record Error: ", e_code)
	end
	return nil
end

--增加寄售品
function Consignment_db:SaleConsignment(consignment_goods)
	local db = f_get_db()

	local consignment = {}
	consignment.uuid			= consignment_goods.uuid		--寄售品UID
	consignment.item_id 		= consignment_goods.item_id 	--寄售品物品ID
	consignment.item_DB 		= consignment_goods.item_DB 	--寄售品物品ID
	consignment.count			= consignment_goods.count		--数量
	consignment.owner_id	 	= consignment_goods.owner_id	--寄售者ID
	consignment.owner_name		= consignment_goods.owner_name	--寄售者名字
	consignment.expired_time	= consignment_goods.expired_time--下架时间
	consignment.money_type		= consignment_goods.money_type	--购买所需货币类型
	consignment.money_count 	= consignment_goods.money_count --所需货币数量
	consignment.server_id 		= consignment_goods.server_id 	--
	
	local e_code = db:insert(database, Json.Encode(consignment))
	if 0 ~= e_code then
		print("Error: ", e_code)
		return false
	end
	return true
end

--删除寄售品
function Consignment_db:DeleteConsignment(uuid)
	debug_print("Begin DeleteConsignment uuid =",uuid)
	
	local db = f_get_db()
	local query = string.format("{uuid:'%s'}",uuid)
	local e_code = db:delete(database, query)
	if 0 ~= e_code then
		print("Error: ", e_code)
		return false
	end

	return true
end


function Consignment_db:update_consignment(consignment_goods)
	if not consignment_goods or not consignment_goods.uuid then
		return
	end

	local db = f_get_db()
	local query = string.format("{uuid:'%s'}", consignment_goods.uuid)

	local consignment = {}
	consignment.uuid			= consignment_goods.uuid		
	consignment.item_id 		= consignment_goods.item_id 	
	consignment.count			= consignment_goods.count		
	consignment.owner_id	 	= consignment_goods.owner_id	
	consignment.owner_name		= consignment_goods.owner_name	
	consignment.expired_time	= consignment_goods.expired_time
	consignment.money_type		= consignment_goods.money_type	
	consignment.money_count 	= consignment_goods.money_count 
	consignment.server_id 		= consignment_goods.server_id 	--

	local e_code = db:update(database, query, Json.Encode(consignment))

	if 0 ~= e_code then
		print("Error: ", e_code)
	end

end

function Consignment_db:update_record(char_id, record)
	if not char_id or not record then
		return
	end

	local db = f_get_db()
	local query = string.format("{char_id:%d}",char_id)

	local consignment_record = {}
	consignment_record.char_id = char_id
	consignment_record.record  = record

	local e_code = db:update(record_db, query, Json.Encode(consignment_record), true, false)

	if 0 ~= e_code then
		print("Error: ", e_code)
	end

end
