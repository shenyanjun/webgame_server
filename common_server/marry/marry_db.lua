--2011-10-26
--chenxidu
--婚姻系统数据库操作

--征婚数据库表
--[[
char_id : 征婚人
tm : 发布征婚时间
ts : 征婚誓言
tz : 战斗力

]]

--结婚数据库表
--[[
uuid 婚姻id
char_id: 申请者
char_tm: 离线时间
mate_id: 结合者
mate_tm: 离线时间
char_uq: 升级花费亲密度
mate_uq: 升级花费亲密度
m_t: 结婚时间
m_h: 是否已经离婚(离婚字段 1 正常婚姻状态 2 离婚状态)
m_k: 房间ID(策划预留接口)
m_q: 夫妻亲密度
m_b: 是否举办过婚礼

--后来加的
m_i: 结婚场景副本ID
m_n: 结婚场景副本时长

--角色
m_j: 保存在人物身上

--以下字段不入库，放入内存
c_tt: 提醒是否
m_tt: 提醒是否

m_f: 是否开启副本
--m_i: 结婚场景副本ID
m_x: 副本是在哪条线开启
m_y: 是否允许所有人都进入场景副本 0 批准 1 所有人可进
--m_n: 结婚场景副本时长
m_o: 结婚场景开始时间
m_w = {} :结婚场景物品列表(所选择购买的结婚物品)
m_l = {}: 允许进入场景列表
m_p = {}: 申请人列表
m_a = {}: 夫妻副本的id count 记录

]]

local database = "marry"
local database_ex = "marry_ex"

Marry_db = oo.class(nil, "Marry_db")

--初始化  load所有结婚信息
function Marry_db:LoadAllMarry()
	local db = f_get_db()

	local rows, e_code = db:select(database)
	if 0 == e_code then
		return rows
	else
		print("LoadAllMarry Error: ", e_code)
	end
	return nil
end

function Marry_db:LoadAllMarryEx()
	local db = f_get_db()

	local rows, e_code = db:select(database_ex)
	if 0 == e_code then
		return rows
	else
		print("LoadAllMarryEx Error: ", e_code)
	end
	return nil
end

--增加结婚条目
function Marry_db:SaleMarry(marry_item)
	local dbh = f_get_db()
	local item = {}
	item.uuid      = marry_item.uuid
	item.char_id   = marry_item.char_id
	item.mate_id   = marry_item.mate_id
	item.char_tm   = marry_item.char_tm
	item.char_uq   = marry_item.char_uq
	item.mate_tm   = marry_item.mate_tm
	item.mate_uq   = marry_item.mate_uq
	item.m_t 	   = marry_item.m_t
	item.m_h 	   = marry_item.m_h
	item.m_k       = marry_item.m_k
	item.m_q       = marry_item.m_q
	item.m_b       = marry_item.m_b

	--副本两个字段要入库
	item.m_i       = marry_item.m_i
	item.m_n       = marry_item.m_n

	local err_code = dbh:insert(database,Json.Encode(item))  
	if err_code == 0 then
		return true
	end

	return false
end

--增加征婚条目
function Marry_db:SaleMarryEx(marry_item)
	local dbh = f_get_db()
	local item = {}
	item.char_id = marry_item.char_id
	item.tm = marry_item.tm
	item.ts = marry_item.ts
	item.tz = marry_item.tz
	local err_code = dbh:insert(database_ex,Json.Encode(item))  
	if err_code == 0 then
		return true
	end

	return false
end

--更新征婚条目
function Marry_db:UpdateMarry(marry_item)
	local dbh = f_get_db()
	local item = {}
	item.uuid      = marry_item.uuid
	item.char_id   = marry_item.char_id
	item.mate_id   = marry_item.mate_id
	item.char_tm   = marry_item.char_tm
	item.char_uq   = marry_item.char_uq
	item.mate_tm   = marry_item.mate_tm
	item.mate_uq   = marry_item.mate_uq
	item.m_t 	   = marry_item.m_t
	item.m_h 	   = marry_item.m_h
	item.m_k       = marry_item.m_k
	item.m_q       = marry_item.m_q
	item.m_b       = marry_item.m_b

	--副本两个字段要入库
	item.m_i       = marry_item.m_i
	item.m_n       = marry_item.m_n

	local query = string.format("{char_id:%d}",item.char_id )
	local err_code = dbh:update(database,query,Json.Encode(item))  
	if err_code == 0 then
		return true
	end

	return false
end

--更新征婚条目
function Marry_db:UpdateMarryEx(marry_item)
	local dbh = f_get_db()
	local item = {}
	item.char_id = marry_item.char_id
	item.tm = marry_item.tm
	item.ts = marry_item.ts
	item.tz = marry_item.tz
	local query = string.format("{char_id:%d}",item.char_id )
	local err_code = dbh:update(database_ex,query,Json.Encode(item))  
	if err_code == 0 then
		return true
	end

	return false
end

--删除征婚信息(过期或者其他原因，如玩家自己删掉)
function Marry_db:DeleteMarry( char_id )
	local db = f_get_db()
	local query = string.format("{char_id:%d}",char_id)
	local e_code = db:delete(database, query)
	if 0 ~= e_code then
		print("Error: ", e_code)
		return false
	end
	return true
end

function Marry_db:DeleteMarryEx( char_id )
	local db = f_get_db()
	local query = string.format("{char_id:%d}",char_id)
	local e_code = db:delete(database_ex, query)
	if 0 ~= e_code then
		print("Error: ", e_code)
		return false
	end
	return true
end
