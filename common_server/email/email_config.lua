--email发送人

local content_list = {}
content_list[1] = f_get_string(501)
content_list[2] = f_get_string(502)
content_list[3] = f_get_string(503)
content_list[4] = f_get_string(504)
content_list[5] = f_get_string(505)
content_list[6] = f_get_string(506)
content_list[7] = f_get_string(507)
content_list[8] = f_get_string(508)

Email_sender=
{
	sender_sys = 0,
	sender_gm = -1
}

Email_title =
{
	title_sys = content_list[1],
	title_sys_back = content_list[2],
	title_content = content_list[3]
}

Email_type =
{
	type_common = 0,     --文本邮件
	type_annex = 1,      --货到付款
	type_gold = 2        --寄送金钱或物品
}

Email_status = 
{
	status_new = 0,      --新邮件
	status_noread = 1,   --未读邮件
	status_read =2       --已读邮件
}

Email_sys_type = 
{
	type_normal = 0,     --普通邮件
	type_sys = 1,        --系统邮件（map等向email发的邮件）
	type_gm = 2          --gm后台邮件
}

Email_send_status =
{
	send_success =  content_list[4],
	send_failed =  content_list[5]
}

Email_faction =
{
	faction_c_n = content_list[6],
	faction_c_f = content_list[7],
	faction_c_k = content_list[8]
}

