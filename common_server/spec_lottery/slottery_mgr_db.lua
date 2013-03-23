
--2012-01-05
--cqs
--实物抽奖数据库操作

local database_n = "lottery_number"
local database_w = "lottery_winner"

Slottery_mgr_db = oo.class(nil, "Slottery_mgr_db")

--下注者信息
function Slottery_mgr_db:LoadNumbers(period)
	local db = f_get_db()

	local query = string.format("{period:%d}",period)

	local rows, e_code = db:select(database_n, nil, query)
	if 0 == e_code then
		return rows
	else
		print("LoadNumbers Error: ", e_code)
	end
	return nil
end

function Slottery_mgr_db:update_numbers(period, db_data)
	local db = f_get_db()
	local query = string.format("{period:%d}", period)

	local lottery = {}
	lottery.period	= period
	lottery.numbers	= db_data

	local e_code = db:update(database_n, query, Json.Encode(lottery), true)

	if 0 ~= e_code then
		print("update_numbers Error: ", e_code)
	end
end


--中奖者信息
function Slottery_mgr_db:LoadWinners(period)
	local db = f_get_db()

	local query = string.format("{period:%d}",period)

	local rows, e_code = db:select(database_w, nil, query)
	if 0 == e_code then
		return rows
	else
		print("LoadWinners Error: ", e_code)
	end
	return nil
end

function Slottery_mgr_db:update_winners(period, db_data, data_name)
	local db = f_get_db()
	local query = string.format("{period:%d}", period)

	local lottery = {}
	lottery.period	= period
	lottery.winners	= db_data
	lottery.winner_n = data_name

	local e_code = db:update(database_w, query, Json.Encode(lottery), true)

	if 0 ~= e_code then
		print("update_winners Error: ", e_code)
	end
end

