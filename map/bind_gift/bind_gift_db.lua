-- cailizhong

-- 数据库字段如下

--[[
	{
		char_id: 4096
		list:[ 1 ] --1代表手机绑定
	}
--]]

local bind_gift_table = "bind_gift"

Bind_gift_db = oo.class(nil,"Bind_gift_db")

function Bind_gift_db:load(char_id)
	local db = f_get_db()
	local query = string.format("{char_id:%d}", char_id)
	local rows, e_code = db:select_one(bind_gift_table, "{_id:0}", query)
	return e_code, rows
end

function Bind_gift_db:update_one(char_id, bind_list)
	local db = f_get_db()
--	local value = string.format("{\"list\":%s}", Json.Encode(bind_list))
	local ret = {}
	ret.list = bind_list
	local query = string.format("{char_id:%d}",char_id)
--	local err_code = db:update(bind_gift_table,query,value,true)
	local err_code = db:update(bind_gift_table,query,Json.Encode(ret),true)
	return err_code
end