local database = "email"
local database_gift = "gift_set"

local content_list = f_get_string(509)
function LoadAllEmail()
	debug_print("load all email!")
	local db = f_get_db()

	local rows, e_code = db:select(database)
	if 0 == e_code then
		return rows
	else
		print("Error: ", e_code)
	end
	return nil
end

function InsertEmail(l_email)
	debug_print("Insert one email")
	if not l_email.email_id or not l_email.sender then
		local log = ev.time_str .."Not email_id or sender!"
		g_chat_log:write(log)
		return false
	end
	local db = f_get_db()

	local t_email = {}
	t_email.id = l_email.email_id
	t_email.sender = l_email.sender
	t_email.receiver = l_email.recevier
	t_email.content = l_email.content
	t_email.type = l_email.email_type
	t_email.gold = l_email.gold
	t_email.create_time = l_email.create_time
	t_email.del_time = l_email.del_time
	t_email.isread = l_email.isread
	t_email.title = l_email.title
	t_email.item_list = l_email.item_list
	t_email.sys_type = l_email.email_sys_type
	
	local e_code = db:insert(database, Json.Encode(t_email))
	if 0 ~= e_code then
		print("Error: ", e_code)
		return false
	end

	--后台流水
	local item_list = l_email.item_list or {}
	--if table.size(item_list)>0 or t_email.gold >0 then	
		--local send_gold = 0
		--local tiqu_gold = 0
		--if t_email.type == Email_type.type_annex then
			--tiqu_gold = t_email.gold
		--elseif t_email.type == Email_type.type_gold then
			--send_gold = t_email.gold
		--end
		--
		--local sender_id = t_email.sender
		--local sender_name = g_player_mgr:char_id2nm(t_email.sender)
		--if sender_id == 0 or sender_id == -1 then
			--sender_name = content_list
		--end
--
	 	--local str = string.format("insert into log_email set sender_id = %d,sender_name = '%s',receive_id= %d, receive_name ='%s',item_obj ='%s',send_gold =%d,tiqu_gold =%d,time = %d,type = %d",
	 				--sender_id,sender_name,t_email.receiver,g_player_mgr:char_id2nm(t_email.receiver),Json.Encode(item_list),send_gold,tiqu_gold,ev.time,1)
	 	--g_web_sql:write(str)
	--end	

	local log = ev.time_str .." ".. l_email.sender .. "发送给:" .. l_email.recevier .. "。邮件内容为：" .. l_email.content .. "附件内容为:" .. Json.Encode(item_list) .. "email.gold:" .. l_email.gold 
	g_chat_log:write(log)
	return true
	
	--local ret = dbh:execute("insert into email(id,sender,receiver,content,type,gold,create_time,del_time,isread,title,item_list,sys_type) values(?,?,?,?,?,?,?,?,?,?,?,?)",
		--email.email_id,email.sender,email.recevier,email.content,email.email_type,email.gold,email.create_time,email.del_time,email.isread,email.title,Json.Encode(email.item_list),email.email_sys_type)
	--if not(ret) then 
		--debug_print("ERROR:insert into email error!")
		--return false
	--else
		--local log = ev.time_str .." ".. email.sender .. "发送给:" .. email.recevier .. "。邮件内容为：" .. email.content .. "附件内容为:" .. Json.Encode(email.item_list) .. "email.gold:" .. email.gold 
		 --g_chat_log:write(log)
	--end
	--return true
end

function update_email_ex(l_email)
	debug_print("update one email")
	if not l_email.email_id or not l_email.sender then
		local log = ev.time_str .."Not email_id or sender!"
		g_chat_log:write(log)
		return false
	end
	local db = f_get_db()

	local t_email = {}
	t_email.id = l_email.email_id
	t_email.sender = l_email.sender
	t_email.receiver = l_email.recevier
	t_email.content = l_email.content
	t_email.type = l_email.email_type
	t_email.gold = l_email.gold
	t_email.create_time = l_email.create_time
	t_email.del_time = l_email.del_time
	t_email.isread = l_email.isread
	t_email.title = l_email.title
	t_email.item_list = l_email.item_list
	t_email.sys_type = l_email.email_sys_type

	local query = string.format("{id:'%s'}",l_email.email_id)
	
	local e_code = db:update(database,query,Json.Encode(t_email),true)
	if 0 ~= e_code then
		print("Error: ", e_code)
		return false
	end
end

--
--function update_state(el_id,state)
	--debug_print("Begin update_state")
	--local db = f_get_db()
	--local query = string.format("{id:'%s'}",el_id)
	--local data = string.format("{isread:%d}",state)
--
	--local e_code = db:update(database, query, data)
	--if 0 ~= e_code then
		--print("Error: ", e_code)
	--end
--
--
	----if dbh:execute("update email set isread = ? where email.id = ?",state,el_id) then
		----debug_print("SUCCESS:update the email state!")
	----else
		----debug_print("ERROR:update the email state!")
	----end
--end

function DeleteEmail(email_id)
	debug_print("Begin delete email")

	local db = f_get_db()
	local query = string.format("{id:'%s'}",email_id)
	local e_code = db:delete(database, query)
	if 0 ~= e_code then
		print("Error: ", e_code)
		return false
	end

	return true

	--local dbh = get_dbh()
	--if dbh:execute("delete from email where email.id = ?",email_id) then
		--debug_print("SUCCESS:delete the email!")
		--return true
	--else
		--debug_print("ERROR:delete the email!")
	--end
	--return false
end

--function update_item(email_id)
	--debug_print("Begin update_item")
--
	--local db = f_get_db()
	--local query = string.format("{id:'%s'}",email_id)
	--local data = {}--string.format("{gold:'0',item_list:'%s'}",Json.Encode({}))
	--data.gold = 0
	--data.item_list = {}
	--local e_code = db:update(database, query, Json.Encode(data))
	--if 0 ~= e_code then
		--print("Error: ", e_code)
	--end
--
--
	----local dbh = get_dbh()
	----if dbh:execute("update email set gold = 0 ,item_list=? where email.id = ?",Json.Encode({}),email_id) then
		----debug_print("SUCCESS:update the email item!")
	----else
		----debug_print("ERROR:update the email item!")
	----end
--end


function selectallgift()
	debug_print("load all gift!")
	local db = f_get_db()
	local data = [[{"$or":[{flag:0}, {flag:2}]}]]
	local rows, e_code = db:select(database_gift,nil,data)
	if 0 == e_code then
		return rows
	else
		print("Error: ", e_code)
	end
	return nil



	--local dbh = get_dbh()
--
	--local rs = dbh:selectall_ex("select * from gift_set where flag = 0")
	--if rs ~= nil and dbh.errcode == 0 then
		--return rs
	--end
	--return nil
end

