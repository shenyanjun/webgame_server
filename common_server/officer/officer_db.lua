--2012-4-24
--chenxidu
--战场官职系统数据库操作

--服务器战场官职数据库表(竞投列表)
--[[
	off_id  : 官职id
	over    : 是否已经结束
	t_st    : 开始时间
	list = {} :竞拍该官职的角色id列表 数组 char_id money
]]

--服务器战场官职数据库表(官职列表)
--[[
	off_id    : 官职id
	e_st      : 结束时间
	list = {} : 获得官职人员列表 char_id 
	visi = {} : 参拜记录
]]

local database_1 = "bid_list"
local database_2 = "officer_list"


Officer_db = oo.class(nil, "Officer_db")


function Officer_db:LoadBid()
	local db = f_get_db()
	local rows, e_code = db:select(database_1)
	return e_code,rows
end

function Officer_db:UpdateBidList(id,list)
	list.off_id = id
	local db = f_get_db()
	local query = string.format("{off_id:%d}",id)
	local err_code = db:update(database_1,query,Json.Encode(list),true,false,true)
	if err_code == 0 then
		return true
	end
	return false
end

function Officer_db:LoadOfficer()
	local db = f_get_db()
	local rows, e_code = db:select(database_2)
	return e_code,rows
end

function Officer_db:UpdateOfficerList(id,list)
	list.off_id = id
	local db = f_get_db()
	local query = string.format("{off_id:%d}",id)
	local err_code = db:update(database_2,query,Json.Encode(list),true,false,true)
	if err_code == 0 then
		return true
	end
	return false
end