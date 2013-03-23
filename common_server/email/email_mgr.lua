--2010-01-07
--laojc
--邮件管理类
require("email/email_db")
require("email/email")
require("email/gm_email")

local MAX_EMAIL_COUNT = 50
local ONE_DAY = 60*60*24

local content_list = {}
content_list[1] = f_get_string(509)
content_list[2] = f_get_string(510)
content_list[3] = f_get_string(511)
content_list[4] = f_get_string(512)
content_list[5] = f_get_string(513)

Email_mgr = oo.class(nil, "Email_mgr")

--定时器
function Email_mgr:del_email_30day()
	local f = function()
		local list=self.email_list
		if list ~= nil then 
			for k,v in pairs(list) do
				if v:is_d_overtime() then
					self:del_email_data(k)
				end
			end
			ev:timeout(ONE_DAY, self:del_email_30day())
		else
			ev:timeout(ONE_DAY, self:del_email_30day())	
		end
	end
	return f
end

function Email_mgr:__init()
	self.email_list = {}
	self.email2char_l = {}

	self.player = g_player_mgr:get_all_player()

	--定时每天轮询一次 删除 30天的邮件
	ev:timeout(ONE_DAY, self:del_email_30day())	

	self.p_email = {}
	--self:load()
end

function Email_mgr:create_email(sender,recevier,title,content,gold,email_type,sys_type,item_list)
	local t_email = Email(sender,recevier,title,content,gold,email_type,sys_type,item_list)

	if t_email == nil then return end
	if self:add_email(t_email) then
		return t_email
	end
	return nil
end

function Email_mgr:add_email(email)
	if email ~= nil then
		--if InsertEmail(email) == true then
			local email_id = email.email_id
			local recevier = email.recevier

			self.email_list[email_id] = {}
			self.email_list[email_id] = email

			if self.email2char_l[recevier] == nil then
				self.email2char_l[recevier] = {}
			end
			self.email2char_l[recevier][email_id] ={}
			self.email2char_l[recevier][email_id] = email

			self.p_email[email_id] = email

			self:log_email_ex(email)
			--self:del_email50(recevier)
		--end
		return true
	end
	return false
end

function Email_mgr:log_email_ex(l_email)
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

		--后台流水
	local item_list = l_email.item_list or {}
	if table.size(item_list)>0 or t_email.gold >0 then	
		local send_gold = 0
		local tiqu_gold = 0
		if t_email.type == Email_type.type_annex then
			tiqu_gold = t_email.gold
		elseif t_email.type == Email_type.type_gold then
			send_gold = t_email.gold
		end
		
		local sender_id = t_email.sender
		local sender_name = g_player_mgr:char_id2nm(t_email.sender)
		if sender_id == 0 or sender_id == -1 then
			sender_name = f_get_string(509)
		end

	 	local str = string.format("insert into log_email set sender_id = %d,sender_name = '%s',receive_id= %d, receive_name ='%s',item_obj ='%s',send_gold =%d,tiqu_gold =%d,time = %d,type = %d",
	 				sender_id,sender_name,t_email.receiver,g_player_mgr:char_id2nm(t_email.receiver),Json.Encode(item_list),send_gold,tiqu_gold,ev.time,1)
	 	g_web_sql:write(str)
	end	
end

function Email_mgr:del_email(email_id)
	--if DeleteEmail(email_id) == true then
		if self.email_list[email_id] ~= nil then
			local recevier = self.email_list[email_id].recevier
			self.email_list[email_id] = nil

			if self.email2char_l[recevier] ~= nil then
				self.email2char_l[recevier][email_id] = nil
			end

			DeleteEmail(email_id)
		end
		self.p_email[email_id] = nil
		return true
end

function Email_mgr:update_email(email,status)
	local email_id = email.email_id
	local char_id = email.recevier
	email.isread = status
	update_email_ex(email)
	self.p_email[email_id] = nil
	self:del_email50(email.recevier)
end

function Email_mgr:update_email_item(email)
	email.gold = 0
	email.item_list = {}
	self.email_list[email.email_id] =email
	self.email2char_l[email.recevier][email.email_id] =email

	update_email_ex(email)
	self.p_email[email.email_id] = nil
	self:del_email50(email.recevier)
end

function Email_mgr:get_email_by_email_id(email_id)
	return self.email_list[email_id]
end

function Email_mgr:get_email_by_char_id(char_id)
	return self.email2char_l[char_id]
end

--删除单一邮件
function Email_mgr:del_email_data(email_id)
	local email = self.email_list[email_id]
	if email == nil then return end

	local sys_type = email:get_email_sys_type()
	local sender = email:get_sender()
	local email_type = email:get_email_type()

	if  sys_type == Email_sys_type.type_gm or sys_type == Email_sys_type.type_sys or sender == Email_sender.sender_gm or sender == Email_sender.sender_sys then
		self:del_email(email_id)
		local _serialized_item_list = f_serialize_itemlist(email.item_list)
		--local log =  email.recevier .. "删除了邮件" ..email_id .."附件："..Json.Encode(_serialized_item_list) .."也已经删除！"
		--g_chat_log:write(log)

		--流水
		self:log_email(email)
	elseif sys_type == Email_sys_type.type_normal and email_type ~= Email_type.type_common then
		if table.size(email.item_list) >0 or tonumber(email.gold) > 0 then
			local t_email = {}
			t_email.sender = Email_sender.sender_sys
			t_email.recevier = email.sender
			t_email.title = Email_title.title_sys_back
			t_email.email_type = email_type
			t_email.sys_type = Email_sys_type.type_sys
			t_email.gold = email.gold
			t_email.item_list = email.item_list

			if email_type ~= Email_type.type_gold then
				t_email.gold = 0
			end

			local gdkstr = Email_title.title_content
			local recv_nm = g_player_mgr:char_id2nm(email.recevier)
			local str = string.format(gdkstr, recv_nm, email.content)
			t_email.content = str

			if self:del_email(email_id) then
			   self:create_email(t_email.sender,t_email.recevier,t_email.title,t_email.content,t_email.gold,t_email.email_type,t_email.sys_type,t_email.item_list)
			end

			--流水
			self:log_email(email)
		else
			self:del_email(email_id)
			--流水
			self:log_email(email)
		end
	end	
	return 0
end

--流水
function Email_mgr:log_email(email)
	if type(email.item_list) == 'table' and table.size(email.item_list) >0 or tonumber(email.gold) > 0 then
		local send_gold = 0
		local tiqu_gold = 0
		if email.type == Email_type.type_annex then
			tiqu_gold = email.gold
		elseif email.type == Email_type.type_gold then
			send_gold = email.gold
		end
		
		local sender_id = email.sender
		local sender_name = g_player_mgr:char_id2nm(email.sender)
		if sender_id == 0 or sender_id == -1 then
			sender_name = f_get_string(509)
		end
		local str
		if type(email.item_list) == 'table' and table.size(email.item_list) >0 then
			str = string.format("insert into log_email set sender_id = %d,sender_name = '%s',receive_id= %d, receive_name ='%s',item_obj ='%s',send_gold =%d,tiqu_gold =%d,time = %d,type = %d",
		 			sender_id,sender_name,email.recevier,g_player_mgr:char_id2nm(email.recevier),Json.Encode(email.item_list),send_gold,tiqu_gold,ev.time, 2)
		elseif send_gold ~= 0 or tiqu_gold ~= 0 then
			str = string.format("insert into log_email set sender_id = %d,sender_name = '%s',receive_id= %d, receive_name ='%s',send_gold =%d,tiqu_gold =%d,time = %d,type = %d",
		 			sender_id,sender_name,email.recevier,g_player_mgr:char_id2nm(email.recevier),send_gold,tiqu_gold,ev.time, 2)
		end
		if str ~= nil then
	 		g_web_sql:write(str)
		end
	end	
end

--删除多个邮件
function Email_mgr:del_email_l(char_id,pkt)
	if pkt == nil or pkt.email_group == nil then return end

	local email_list={}

	local c=1
	for k,v in pairs(pkt.email_group or {}) do
		if self.email_list[v] == nil then
			self:send_result(char_id, CMD_MAIL_DELETE_S, 50004)
			return
		else
			local ret= self:del_email_data(v) 
			if ret == 0 then
				table.insert(email_list,v)
			end
		end
	end
	local pkt={}
	pkt.delList=email_list
	g_svsock_mgr:send_server_ex(WORLD_ID,char_id, CMD_MAIL_DELETE_S, pkt)
end

--某个玩家够50条邮件，就自动删除
function Email_mgr:del_email50(char_id)
	if self.email2char_l[char_id] ~= nil then
		local num = 0
		local create_time1 = ev.time
		local create_time2 = ev.time
		local email_id_1 = nil
		local email_id_2 = nil
		for k,v in pairs(self.email2char_l[char_id] or {}) do
			num = num + 1
			local flags = false
			for kk, vv in pairs(v.item_list or {}) do
				flags = true
				break
			end
			if not flags then
				if create_time1 > v.create_time then
					create_time1 = v.create_time
					email_id_1 = k
				end
			else
				if create_time2 > v.create_time then
					create_time2 = v.create_time
					email_id_2 = k
				end
			end
		end

		if num > MAX_EMAIL_COUNT then
			if email_id_1 ~=nil then
				self:del_email(email_id_1)
			else
				if email_id_2 ~= nil then
					self:del_email(email_id_2)
				end
			end
		end
	end
end

--获取邮件列表
function Email_mgr:get_email_list(char_id)
	local email_list = self:get_email_by_char_id(char_id)
	if email_list == nil then 
		local ret_l={}
		ret_l.email_list = {}
		return g_svsock_mgr:send_server_ex(WORLD_ID,char_id, CMD_MAIL_GET_MAIL_S, ret_l) 
	end

	local ret ={}
	local num = 1
	for k,v in pairs(email_list or {}) do
		ret[num] = {}
		ret[num]["email_id"]=k
		ret[num]["title"]=v.title
		ret[num]["sys_type"]=v.email_sys_type
		ret[num]["create_time"]=v.create_time
		ret[num]["gold"]=v.gold
		ret[num]["isread"]=v.isread
		ret[num]["type"] = v.email_type
		if ret[num]["isread"] == Email_status.status_new then 
			ret[num]["isread"] = Email_status.status_noread
			self:update_email(v,Email_status.status_noread)
		end

		--sender_nm
		local send_nm = nil
		if v.sender == 0 then 
			send_nm = content_list[1]
			ret[num]["sys_type"] = 1
		elseif v.sender == -1 then
			send_nm = content_list[1]
			ret[num]["sys_type"] = 1
		else
			send_nm = g_player_mgr:char_id2nm(v.sender) or "null"
			ret[num]["sys_type"] = 0
		end
		ret[num]["send_nm"]=send_nm

		--item_list flag
		if Json.Encode(v.item_list) == "[]" or v.item_list == nil then
			ret[num]["flag"]=0
		else
			ret[num]["flag"]=1
		end
		num = num + 1
	end
	local ret_l={}
	ret_l.email_list=ret
	g_svsock_mgr:send_server_ex(WORLD_ID,char_id, CMD_MAIL_GET_MAIL_S, ret_l)
end

--看邮件
function Email_mgr:open_email(char_id,pkt)
	if pkt == nil or pkt.email_id == nil  then return end
	
	local email_id = pkt.email_id
	local email = self.email_list[email_id]
	if email == nil then return end

	if email.isread ~= Email_status.status_read then
		self:update_email(email,Email_status.status_read)
	end

	local new_pkt = {}
	new_pkt.type = email.email_type
	new_pkt.gold = email.gold
	new_pkt.content = email.content
	
	--local ret = {}
	--for k,v in pairs(email.item_list) do
		--ret[k] = {}
		--ret[k].item_id = v.item_id
		--ret[k].count = v.number
		--ret[k].item = v.item_obj
		--print("ggggggggggggggggggg",j_e(ret),j_e(v.item_obj))
	--end
	if email.item_list ~= nil and table.size(email.item_list) > 0 then
		local item_list ={}
		item_list[1] = table.copy(email.item_list[1])
		if table.size(item_list[1]) > 0  and item_list[1].item_obj ~= nil and table.size(item_list[1].item_obj) > 0 then
			local errcode, item = Item_factory.clone(item_list[1].item_id,item_list[1].item_obj)
			item_list[1].item_obj = item:serialize_to_net()
		end
		new_pkt.item_list = item_list
	else
		new_pkt.item_list = email.item_list or {}
	end
	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAIL_CHAR_READ_EMAIL_S, new_pkt)
end

---------------------------------------------领取邮件物品-----------------------------------------------------

function Email_mgr:fetch_email(char_id,email_id)
	if email_id == nil then return end

	local email = self.email_list[email_id]
	if not email then return end

	if email.flags then return end 

	if email.gold == 0 and table.size(email.item_list) <=0 then return end

	local new_pkt = {}
	new_pkt.gold = email.gold
	new_pkt.item_list = {}
	--new_pkt.item_obj = node.item_list
	new_pkt.mail_type = email.email_type
	for k,v in pairs(email.item_list or {}) do
		new_pkt.item_list[k] = {}
		new_pkt.item_list[k].item_id = v.item_id
		new_pkt.item_list[k].count = v.number
		new_pkt.item_list[k].item = v.item_obj
	end

	email.flags = true

	g_sock_event_mgr:add_event_count(char_id, CMD_M2C_ADD_ATTACHMENT_REP, self, self.call_back_fetch, self.time_out_fetch, email, 10, new_pkt)
	g_svsock_mgr:send_server_ex(WORLD_ID,char_id,CMD_C2M_ADD_ATTACHMENT_REQ,new_pkt)

end


function Email_mgr:call_back_fetch(email,pkt)
	email.flags = false

	if pkt == nil or email == nil then return end

	if pkt.result ~= 0 then
		g_svsock_mgr:send_server_ex(WORLD_ID,email.recevier,CMD_MAIL_GET_ATTACKMENT_S,pkt)
		return 
	end

	if email.sender == -1 or email.email_sys_type ~= Email_sys_type.type_normal then
		local str=string.format("update reward_list set receive_time = %d where id='%s'",ev.time,email.email_id)
		g_web_sql:write(str)
	elseif email.email_type == Email_type.type_annex and email.gold > 0 then
		local t_node = {}
		t_node.send_id = Email_sender.sender_sys
		t_node.recevier = email.sender
		t_node.content = g_player_mgr:char_id2nm(email.recevier)..content_list[2].. email.gold ..content_list[3] .. content_list[4]
		t_node.type = Email_type.type_gold
		t_node.gold = email.gold
		t_node.title = g_player_mgr:char_id2nm(email.recevier)..content_list[5]
		t_node.item_list = {}
		t_node.sys_type = Email_sys_type.type_sys

		self:create_email(t_node.send_id,t_node.recevier,t_node.title,t_node.content,t_node.gold,t_node.type,t_node.sys_type,t_node.item_list)

	end
	if email.isread ~= Email_status.status_read then
		self:update_email(email,Email_status.status_read)
	end
	self:update_email_item(email)
	pkt.id = email.email_id
	g_svsock_mgr:send_server_ex(WORLD_ID,email.recevier,CMD_MAIL_GET_ATTACKMENT_S,pkt)
end

function Email_mgr:time_out_fetch(email)
	--email.flags = false
	print("Error:catch email item failed!")
end


---------------------------------------------批量领取邮件物品-----------------------------------------------------

function Email_mgr:fetch_email_list(char_id,pkt)
	if not pkt or not pkt.list then return end

	local email_id_l = {}
	local new_pkt = {}
	new_pkt.gold = 0
	new_pkt.item_list = {}

	for k, email_id in pairs(pkt.list) do
		local email = self.email_list[email_id]
		if email and not email.flags then
			if email.email_type ~= Email_type.type_annex or email.email_sys_type ~= Email_sys_type.type_normal
				or email.gold == 0 then
				if email.gold ~= 0 or table.size(email.item_list or {}) > 0 then 
					table.insert(email_id_l, email_id)

					new_pkt.gold = new_pkt.gold + email.gold
					for k,v in pairs(email.item_list or {}) do
						local tmp_t = {}
						tmp_t.item_id = v.item_id
						tmp_t.count = v.number
						tmp_t.item = v.item_obj

						table.insert(new_pkt.item_list, tmp_t)
					end

					email.flags = true
				end
			end 
		end
	end

	g_sock_event_mgr:add_event_count(char_id, CMD_M2C_ADD_ATTACHMENT_L_REP, self, self.call_back_fetch_list, self.time_out_fetch_list, email_id_l, 10, new_pkt)
	g_svsock_mgr:send_server_ex(WORLD_ID,char_id,CMD_C2M_ADD_ATTACHMENT_L_REQ,new_pkt)

end


function Email_mgr:call_back_fetch_list(email_l, pkt)
	for k, email_id in ipairs(email_l) do
		local email = self.email_list[email_id]
		if email then
			email.flags = false
			if pkt.result == 0 or pkt.result == 43095 then
				if email.sender == -1 or email.email_sys_type ~= Email_sys_type.type_normal then
					local str=string.format("update reward_list set receive_time = %d where id='%s'",ev.time,email.email_id)
					g_web_sql:write(str)
				end
				if email.isread ~= Email_status.status_read then
					self:update_email(email, Email_status.status_read)
				end
				self:update_email_item(email)
			end
		end
	end

	g_svsock_mgr:send_server_ex(WORLD_ID, pkt.char_id, CMD_MAIL_GET_ATTACKMENT_L_S, {["result"] = pkt.result})
end

function Email_mgr:time_out_fetch_list(email_l)
	--for k, email_id in ipairs(email_l) do
		--local email = self.email_list[email_id]
		--if email then
			--email.flags = false
		--end
	--end
	print("Error:time_out_fetch_list email item failed!")
end


----------------------------------------发邮件-----------------------------------------------------------------

function Email_mgr:send_email(char_id,pkt)
	if not(pkt and pkt.type and pkt.title and pkt.recv_nm and pkt.sys_type) then 
		--print("ERROR:",Json.Encode(pkt))
		return 
	end

	local recevier = self.player[pkt.recv_nm]
	if recevier == nil then
		self:send_result( char_id, CMD_MAIL_CHAR_SEND_S,  10001)
		return
	elseif recevier == char_id then
		self:send_result( char_id, CMD_MAIL_CHAR_SEND_S,  50103)
		return
	end

	local node ={}
	node.send_id = char_id
	node.recevier = recevier
	node.title = pkt.title
	node.content = pkt.content
	node.type = pkt.type
	node.sys_type = pkt.sys_type
	node.gold = pkt.gold
	if pkt.type == Email_type.type_common then
		local email = self:create_email(char_id,recevier,pkt.title,pkt.content,pkt.gold,pkt.type,pkt.sys_type,pkt.item_list)
		if email ~= nil then
			f_email_ad(Email_send_status.send_success,char_id)
		else
			f_email_ad(Email_send_status.send_failed,char_id)
		end
	elseif pkt.type == Email_type.type_gold then
		if pkt.gold < 0  then return end
		local new_pkt ={}
		new_pkt.line = g_player_mgr:get_char_line(char_id)
		new_pkt.item_list = pkt.item_list
		new_pkt.mail_type = pkt.type
		new_pkt.gold = pkt.gold
		
		g_svsock_mgr:send_server_ex(WORLD_ID,char_id,CMD_C2M_QUERY_ITEM_REQ,new_pkt)

		if pkt.item_list then 
			node.item_list = pkt.item_list
		else
			node.item_list = {}
		end
		g_sock_event_mgr:add_event(char_id, CMD_M2C_QUERY_ITEM_REP, self, self.load_process, self.load_time_out, node, 3)
	elseif pkt.type == Email_type.type_annex then
		if pkt.gold < 0 then return end
		if pkt.item_list == nil then return end

		local new_pkt ={}
		new_pkt.line = g_player_mgr:get_char_line(char_id)
		new_pkt.item_list = pkt.item_list
		g_svsock_mgr:send_server_ex(WORLD_ID,char_id,CMD_C2M_QUERY_ITEM_REQ,new_pkt)

		node.item_list = pkt.item_list
		g_sock_event_mgr:add_event(char_id, CMD_M2C_QUERY_ITEM_REP, self, self.load_process, self.load_time_out, node, 3)
	end
end



function Email_mgr:load_process(node,pkt)
	if pkt.result ~= 0 or node == nil then
		self:send_result(node.send_id, CMD_MAIL_CHAR_SEND_S, pkt.result)
		return
	end

	local list = {}
	if table.size(pkt.item_list) > 0 then		
		list[1] = {}
		list[1]["item_id"] = pkt.item_list.item_id
		list[1]["item_obj"] = pkt.item_list.item
		list[1]["number"] = node.item_list[1].number
	end
	node.item_list = list

	local email =  self:create_email(node.send_id,node.recevier,node.title,node.content,node.gold,node.type,node.sys_type,node.item_list)
	if email ~= nil then
		--print("Email_send_status.send_success = ",Email_send_status.send_success)
		f_email_ad(Email_send_status.send_success,node.send_id)
	else
		f_email_ad(Email_send_status.send_failed,node.send_id)
	end
end

function Email_mgr:load_time_out(node)
	f_email_ad(Email_send_status.send_failed,node.send_id)
end



--有新邮件的提示
function Email_mgr:prompt_newmail(conn,char_id,pkt)
	--debug_print("EmailMgr:prompt_newmail!",char_id)
	
	if char_id==nil then return end
	
	if self.email2char_l[char_id]==nil then return end

	for k,v in pairs(self.email2char_l[char_id])do
		if v["isread"]==Email_status.status_new then
			self:send_result(char_id,CMD_MAIL_CHAR_PROMPT_NEWMAIL_S,0)
			break
		end
	end
		
end

--检查邮件是否超过40封
function Email_mgr:check_email_count(conn, char_id, pkt)
	if char_id==nil then return end
	
	if self.email2char_l[char_id]==nil then return end

	local cnt = 0
	for k,v in pairs(self.email2char_l[char_id])do
		cnt = cnt + 1
	end

	if cnt >= 40 then
		local s_pkt = {}
		s_pkt.result = 0 
		s_pkt.full = 1
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_MAIL_CHECK_FULL_S, s_pkt)
	end
		
end

function Email_mgr:send_result(char_id, cmd, result)
	local pkt = {}
	pkt.result = result
	g_svsock_mgr:send_server_ex(WORLD_ID,char_id, cmd, pkt)
end

--------------------发邮件接口--------------------------
--钱和物品塞到礼包发出
--pkt.sender发送者，系统为-1
--item_list发送物品列表  item_list[i]:[count],[id],[name],[item_db]
function Email_mgr:send_email_interface(pkt)
	local sender = pkt.sender
	local recevier = pkt.recevier
	local title = pkt.title or ""
	local content = pkt.content or ""
	local item_list = pkt.item_list
	local money_list = pkt.money_list	local box_title	 = pkt.box_title		local list = {} 	local _,g_bag = Item_factory.create(104002000130)	g_bag:set_item_list(item_list)	g_bag:set_money(money_list)	g_bag:set_name(box_title)	g_bag.item_id = 104002000130	list[1] = g_bag	local item = {}	for k,v in pairs(list or {}) do		item[1] ={}		item[1]["item_id"] = v:get_item_id()		item[1]["item_obj"] = v		item[1]["number"] = 1		end	local email = self:create_email(sender, recevier, title, content, 0, 1, 0, item)				
end


--单独发一个物品
--item_db物品的特殊属性
function Email_mgr:send_email_interface_no_box(pkt)
	local sender 	= pkt.sender
	local recevier 	= pkt.recevier
	local title 	= pkt.title or ""
	local content 	= pkt.content or ""
	local item_id	= pkt.item_id
	local item_db 	= pkt.item_db	local number	= pkt.number	local item = {}	if item_id then		local e_code ,item_l = Item_factory.clone(item_id,item_DB)
		if e_code ~= 0 then
			return
		end		local list = {} 		list[1] = item_l		for k,v in pairs(list or {}) do			item[1] ={}			item[1]["item_id"] 	= v:get_item_id()			item[1]["item_obj"] = v			item[1]["number"] 	= number		end	end	local email = self:create_email(sender, recevier, title, content, 0, 1, 0, item)			
end


------------------------------滴答 计时器 -------------------------------------------------------------


--货到付款，到了30分钟不提取的就自动退回
function Email_mgr:on_timer(time_sp)
	for k,v in pairs(self.email_list or {}) do
		if v:is_m_over_time() then

			local recevier = v["recevier"]
			self:del_email_data(k)
			local pkt={}
			pkt.delList={}
			pkt.delList[1]=k
			g_svsock_mgr:send_server_ex(WORLD_ID,recevier, CMD_MAIL_DELETE_S, pkt)
		end
	end
end

function Email_mgr:get_click_param()
	return self,self.on_timer,60,nil
end

----------------------------数据持久化----------------------------
function Email_mgr:load()
	local rs= LoadAllEmail()
	if rs == nil then return end

	for k,v in pairs(rs) do
		local email_id = v.id
		local recevier = v.receiver
		if not email_id or not recevier then
			local log = ev.time_str .."Not email_id or receiver!"
			g_chat_log:write(log)
		else 

			local t_email = Email(v.sender,v.receiver,v.title,v.content,v.gold,v.type,v.sys_type,v.item_list)
			t_email.email_id = email_id
			t_email.isread = tonumber(v.isread)
			t_email.create_time = tonumber(v.create_time)
			t_email.del_time = tonumber(v.del_time)
			self.email_list[email_id]={}
			self.email_list[email_id] = t_email

			if self.email2char_l[recevier] == nil then
				self.email2char_l[recevier]={}
			end

			self.email2char_l[recevier][email_id] ={}	
			self.email2char_l[recevier][email_id] = t_email
		end
	end
end

function Email_mgr:on_time_insert_email()
	local count = 0
	for k,v in pairs(self.p_email or {}) do
		InsertEmail(v)
		local recevier = v.recevier
		count = count + 1
		self:del_email50(recevier)
		self.p_email[k] = nil
		if count >= 300 then
			return
		end
	end
end

function Email_mgr:get_click_param_email_ex()
	return self,self.on_time_insert_email,35,nil
end

function Email_mgr:serialize_to_db()
	for k,v in pairs(self.p_email or {}) do
		InsertEmail(v)
		local recevier = v.recevier
		self:del_email50(recevier)
		self.p_email[k] = nil
	end

	Gm_email:gm_gift_on_timer()
end

--礼品设置
--function Email_mgr:on_timer_gift()
	 --return Gm_email:on_timer_gift()
--end
--
--function Email_mgr:get_click_param_gift()
	--Gm_email:get_click_param_gift()
--end


