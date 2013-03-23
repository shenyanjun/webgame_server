
 ------邮件发送包
 Sv_commands[1][CMD_MAIL_CHAR_SEND_C] = 
   function (conn, char_id, pkt)
       g_email_mgr:send_email(char_id, pkt)
   end  
  --确认物品包
  --Sv_commands[CMD_M2C_QUERY_ITEM_REP] = 
   --function (conn, char_id, pkt)
       --emailMgr:HandleQueryItem(conn, char_id, pkt)
   --end 
   
 ------邮件获取列表包
 
 --所有
 Sv_commands[1][CMD_MAIL_GET_MAIL_C] = 
   function (conn, char_id, pkt)
       g_email_mgr:get_email_list(char_id)
   end
    
 --读取邮件包
Sv_commands[1][CMD_MAIL_CHAR_READ_EMAIL_C] = 
   function (conn, char_id, pkt)
       g_email_mgr:open_email(char_id, pkt)
   end
--读取附件属性包

 --删除邮件列表包
Sv_commands[1][CMD_MAIL_DELETE__C] = 
	function(conn,char_id,pkt)
		g_email_mgr:del_email_l(char_id,pkt)
	end

--新邮件提示
Sv_commands[1][CMD_MAIL_CHAR_PROMPT_NEWMAIL_C] = 
	function(conn,char_id,pkt)
		g_email_mgr:prompt_newmail(conn,char_id,pkt)
	end
	
--检查是否达到40封
Sv_commands[1][CMD_MAIL_CHECK_FULL_C] = 
	function(conn,char_id,pkt)
		g_email_mgr:check_email_count(conn,char_id,pkt)
	end

--取附件
Sv_commands[1][CMD_MAIL_GET_ATTACKMENT_C] = 
	function(conn,char_id,pkt)
		g_email_mgr:fetch_email(char_id,pkt.email_id)
	end

--批量取附件
Sv_commands[1][CMD_MAIL_GET_ATTACKMENT_L_C] = 
	function(conn,char_id,pkt)
		g_email_mgr:fetch_email_list(char_id, pkt)
	end


-------------------gm-------------------------
--后台发送邮件
Sv_commands[1][CMD_M2W_MAIL_ACK] = 
function(conn, char_id, pkt)
	local char_l = pkt.char_lst
	local title = pkt.email_title
	local content = pkt.email_content
	for k,v in pairs(char_l) do
		Gm_email:create_email(v, title, content, Email_type.type_common, nil, nil)
	end
end

--后台发送奖励(from gm)
Sv_commands[1][CMD_M2W_ADD_GOODS_ACK] = 
function(conn, char_id, pkt)
	print("#########Sv_commands[CMD_M2W_ADD_GOODS_ACK]")
	local char_l = pkt.char_lst
	local title = pkt.email_title
	local content = pkt.email_content
	local item_list = {}
	item_list[1] = pkt.item
	for k,v in pairs(char_l) do
		Gm_email:create_email(v.char_id, title, content, Email_type.type_annex, item_list, v.email_id)
	end
end

--活动开关
Sv_commands[1][CMD_M2W_ACTIVITY_SWICTH_ACK] = 
function(conn, char_id, pkt)
	print(" Error ~~ Sv_commands[CMD_M2W_ACTIVITY_SWICTH_ACK]")

	if pkt.type == 1 then
		g_collection_activity_mgr:check_swicth(pkt.swicth)
	end
end

--后台活动设置
Sv_commands[1][CMD_M2W_ACTIVITY_SETTING_ACK] = 
function(conn, char_id, pkt)
	print(" Error ~~ Sv_commands[CMD_M2W_ACTIVITY_SETTING_ACK]， type = ", pkt.type)
	g_activity_mgr:accept_notice(pkt.type)
end

--------------仇人email通知----------
Sv_commands[1][CMD_M2C_ENEMY_EMAIL_S] = 
function(conn, char_id, pkt)
	if pkt == nil or pkt.enemy_nm ==nil or pkt.obj_id == nil then return end
	
	Map_email:enemy_email(char_id,pkt)
	
end

-------------全服礼品设置-----------
Sv_commands[1][CMD_G2W_GIFT_SET_C] = 
function(conn, char_id, pkt)
	--print("%%%%%%%%%%%%%%%>>>>>>>>>>>>>>>>>",j_e(pkt))
	if pkt == nil  then return end
	
	Gm_email:gm_gift_set(pkt)
	
end

Sv_commands[1][CMD_G2W_GIFT_STOP_C] = 
function(conn, char_id, pkt)
	--print("%%%%%%%%%%%%%%%>>>>>>>>>>>>>>>>>",j_e(pkt))
	if pkt == nil  then return end
	
	Gm_email:gm_gift_stop(pkt)
	
end

Sv_commands[1][CMD_C2W_GET_AVERAGE_LEVEL_W] = 
function(conn, char_id, pkt)
	--print("%%%%%%%%%%%%%%%>>>>>>>>>>>>>>>>>",j_e(pkt))
	if pkt == nil  then return end
	--print("135 =", j_e(pkt))
	g_world_lvl_mgr:change_average_lvl(pkt.lvl)
	
end


--------------------map 发邮件到common--------------------------
--钱和物品塞到礼包发出
--pkt.sender发送者，系统为-1
--item_list发送物品列表  item_list[i]:[count],[id],[name],[item_db]
Sv_commands[0][CMD_M2P_SEND_EMAIL_S] =
function(conn,char_id, pkt)
	if not pkt or not pkt.recevier or not pkt.sender then
		return
	end

	local sender = pkt.sender
	local recevier = pkt.recevier
	local title = pkt.title or ""
	local content = pkt.content or ""
	local item_list = pkt.item_list
	local money_list = pkt.money_list
end


--单独发一个物品或没有物品
--item_db物品的特殊属性
Sv_commands[0][CMD_M2P_SEND_EMAIL_NO_BOX_S] =
function(conn,char_id, pkt)
	--print("149 =", j_e(pkt))
	if not pkt or not pkt.recevier or not pkt.sender then
		return
	end
	local sender 	= pkt.sender
	local recevier 	= pkt.recevier
	local title 	= pkt.title or ""
	local content 	= pkt.content or ""
	local item_id	= pkt.item_id
	local item_db 	= pkt.item_db
		e_code,item = Item_factory.clone(item_id, item_db)
	else
		e_code,item = Item_factory.create(item_id)
	end
	if e_code ~= 0 then
		--print("173")
		return
	end
end