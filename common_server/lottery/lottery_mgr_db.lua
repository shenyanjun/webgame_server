
--2011-05-16
--cqs
--抽奖数据库操作

local database = "lottery"

Lottery_mgr_db = oo.class(nil, "Lottery_mgr_db")

--初始化  load所有
function Lottery_mgr_db:Loadlottery(period)
	local db = f_get_db()

	local query = string.format("{period:%d}",period)

	local rows, e_code = db:select(database,nil,query)
	if 0 == e_code then
		return rows
	else
		print("Loadlottery Error: ", e_code)
	end
	return nil
end

--增加寄售品
--function Lottery_mgr_db:SaleConsignment(consignment_goods)
	--local db = f_get_db()
--
	--local consignment = {}
	--consignment.uuid			= consignment_goods.uuid		--寄售品UID
	--consignment.item_id 		= consignment_goods.item_id 	--寄售品物品ID
	--consignment.item_DB 		= consignment_goods.item_DB 	--寄售品物品ID
	--consignment.count			= consignment_goods.count		--数量
	--consignment.owner_id	 	= consignment_goods.owner_id	--寄售者ID
	--consignment.owner_name		= consignment_goods.owner_name	--寄售者名字
	--consignment.expired_time	= consignment_goods.expired_time--下架时间
	--consignment.money_type		= consignment_goods.money_type	--购买所需货币类型
	--consignment.money_count 	= consignment_goods.money_count --所需货币数量
	--
	--local e_code = db:insert(database, Json.Encode(consignment))
	--if 0 ~= e_code then
		--print("Error: ", e_code)
		--return false
	--end
	--return true
--end

----删除寄售品
--function Lottery_mgr_db:DeleteConsignment(uuid)
	--debug_print("Begin DeleteConsignment uuid =",uuid)
	--
	--local db = f_get_db()
	--local query = string.format("{uuid:'%s'}",uuid)
	--local e_code = db:delete(database, query)
	--if 0 ~= e_code then
		--print("Error: ", e_code)
		--return false
	--end
--
	--return true
--end
--

function Lottery_mgr_db:update_Lottery(period,db_data)
	local db = f_get_db()
	local query = string.format("{period:%d}",period)

	local lottery = {}
	lottery.period	= db_data.period
	lottery.numbers	= db_data.numbers
	lottery.winners	= db_data.winners
	lottery.bonus	= db_data.bonus

	local e_code = db:update(database, query, Json.Encode(lottery), true)

	if 0 ~= e_code then
		print("Error: ", e_code)
	end


	--local dbh = get_dbh()
	--if dbh:execute("update email set gold = 0 ,item_list=? where email.id = ?",Json.Encode({}),email_id) then
		--debug_print("SUCCESS:update the email item!")
	--else
		--debug_print("ERROR:update the email item!")
	--end
end
