
local dbh
function get_dbh()
   if dbh ~= nil and dbh:ping() then
      return dbh
   end
   dbh = MySQL:New(DB_IP, DB_PORT, DB_USR, DB_PWD, DB_NAME)
   return dbh
end

local web_dbh
function get_dbh_web()
	if web_dbh ~= nil and web_dbh:ping() then
    	return web_dbh
   	end
   	web_dbh = MySQL:New(WEB_DB_IP, WEB_DB_PORT, WEB_DB_USR, WEB_DB_PWD, WEB_DB_NAME)
   	return web_dbh
end


--********** dbh  exampl*************

--[[说明：sql语句用提供？通配符的接口，不要string.format来生成sql语句
如：对： local row = dbh:selectrow("select id,name,level from where name = ?", "jam")
	避免：local str = string.format("select id,name,level from where name = '%s'", "jam")
		  local row = dbh:selectrow(str)

函数: selectall selectrow execute
--取多行数据 selectxx获取行数组，selectxx_ex获取行hash表
local dbh = get_dbh()

local rs = dbh:selectall("select id,name from characters characters where flag =?", 0)
if rs ~= nil or dbh.errcode == 0 then
	for k,row in pairs(rs) do
		local id = tonumber(row[1])
		local name = row[2]
	end
end

local rs = dbh:selectall_ex("select id,name,class,level from characters where flag =?", 0)
if rs ~= nil or dbh.errcode == 0 then
	for k,row in pairs(rs) do
		local id = row.id
		local name = row.name
	end
end

local row = dbh:selectrow("select id,name,level from characters where name = ?", "jam")
if row ~= nil or dbh.errcode == 0 then
	local name = row[2]
else
	print("DB_ERROR: errcode and errmsg:", dbh.errcode, dbh.errmsg )
end

local ret = dbh:execute("update characters set name = ? where id = ?", "jam", 100)

事务：begin,commit,rollback

local dbh = get_dbh()
dbh:begin()
if dbh.errcode ~= 0 then
	return false
end

dbh:excute("update characters set name = ? where id = ?", "jam", 100)
if dbh.errcode ~= 0 then
	dbh:rollback()
	return false
end

dbh:execute("update characters set name = ? where id = ?", "jam2", 200)
if dbh.errcode ~= 0 then
	dbh:rollback()
	return false
else
	dbh:commit()
	return true
end
]]

