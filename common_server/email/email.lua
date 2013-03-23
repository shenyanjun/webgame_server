--2010-01-05
--laojc
--email基本类

local THIRTY_DAY = 30*24*60*60
local THIRTY_MINUTE = 30*60

Email = oo.class(nil, "Email")

function Email:__init(sender,recevier,title,content,gold,email_type,sys_type,item_list)
	self.email_id = crypto.uuid()
	self.sender = sender
	self.recevier = recevier

	self.title = title
	self.content = content

	self.create_time = ev.time
	self.email_type = email_type       --文本，货到付款，寄送

	self.email_sys_type = sys_type
	self.del_time = self.create_time + THIRTY_DAY

	self.gold = gold
	self.item_list = item_list or {}
	self.isread = Email_status.status_new
end

function Email:set_email_id(email_id)
	self.email_id = email_id
end

function Email:get_isread()
	return self.isread
end

function Email:set_isread(status)
	self.isread = status
end

function Email:set_gold(gold)
	self.gold = gold
end

function Email:set_item_list(item_list)
	self.item_list = item_list
end

function Email:set_email_type(email_type)
	self.email_type =email_type
end
function Email:get_email_type()
	return self.email_type
end

function Email:get_email_sys_type()
	return self.email_sys_type
end

function Email:get_content()
	return self.content
end

function Email:get_title()
	return self.title
end

function Email:get_sender()
	return self.sender
end

function Email:get_recevier()
	return self.recevier
end

--邮件是否到了时间删除  30 天
function Email:is_d_overtime()
	local l_time = ev.time
	if self.del_time < l_time then
	--if self.create_time + THIRTY_DAY < l_time then
		return true
	end
	return false
end


--有附件并要付钱提取的邮件 30分钟不提取返回
function Email:is_m_over_time()
	local l_time = ev.time
	if self.email_type == Email_type.type_annex and self.email_sys_type == Email_sys_type.type_normal and
		 self.sender ~= Email_sender.sender_gm and self.sender ~= Email_sender.sender_sys then
		if self.create_time + THIRTY_MINUTE < l_time then 
			return true
		end
	end
	return false
end