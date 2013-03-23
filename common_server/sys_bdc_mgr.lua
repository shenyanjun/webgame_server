--2010-12-15
--laojc
--服务器端向客户端发送的广播消息 统一归类

----------------属性类型----------------------------
--人名： type = 1   char_id =   
--帮派申请加入： type=2,  faction_id =
--摆摊广告：type = 3, npc_id = 
--加为好友：type = 4, char_nm = 
--宠物: type = 5,  uuid = 
--道具：type = 6,  uuid = 
--宠物精魂：type = 7, uuid =
--宠物蛋：type = 8, uuid = 
--开宝箱: type = 9, chest_id = 
--后台：type =10, url = 

----------------广播方式------------------------------
--只在世界广播 -- 1
--只在横屏广播 -- 2
--世界+横屏广播 -- 3
--帮派 -- 4
--队伍 -- 5


--bdc_type:广播方式   content:json对象，格式为 [{s:"XXX",c:"ffffff",l:{char_id:333,type:1}},{}....]
function f_send_bdc(bdc_type,msg_type,content,char_id)
	local pkt ={}
	pkt.bdc_type = bdc_type
	pkt.msg_type = msg_type
	pkt.content = content

	pkt = Json.Encode(pkt or {})
	if char_id == nil then
		local list = g_player_mgr:get_online_player()
		for k,v in pairs(list) do
			g_svsock_mgr:send_server_ex(WORLD_ID,k,CMD_C2B_SYS_BDC_S,pkt, true)
		end
	else
		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_C2B_SYS_BDC_S, pkt, true)
	end
	
end

--color = nil 时为 默认颜色  str_content: 为整条字符串  param{color:"",char_id:33}
function f_default_bdc(bdc_type,msg_type,str_content,param)
	local pkt ={}
	pkt.bdc_type = bdc_type
	pkt.msg_type = msg_type
	
	local content ={}
	content[1]={}
	content[1].s = str_content

	if param.color == nil then
		content[1].c = DEFAUT_COLOR
	else
		content[1].c = param.color
	end
	pkt.content = content

	pkt = Json.Encode(pkt or {})
	if param.char_id == nil then
		local list = g_player_mgr:get_online_player()
		for k,v in pairs(list) do
			g_svsock_mgr:send_server_ex(WORLD_ID,k,CMD_C2B_SYS_BDC_S, pkt, true)
		end
	else
		g_svsock_mgr:send_server_ex(WORLD_ID, param.char_id, CMD_C2B_SYS_BDC_S, pkt, true)
	end

end

--function f_construct_content(table_content,str,color,link)
	--local content = {}
	--content.s = str
	--content.c = color
	--content.l = link
--
	--table.insert(table_content,content)
--
	----local t = {...}
	----for k,v in pairs(t) do
		----print(v)
	----end
--end
--
--function f_construct_link(p_type, property)
	--local link = {}
	--link.type = p_type
	--if p_type == 1 then		
		--link.char_id = property
	--elseif p_type == 2 then
		--link.faction_id = property
	--elseif p_type == 3 then
		--link.npc_id = property
	--elseif p_type == 4 then
		--link.char_nm = property
	--elseif p_type == 5 then
		--link.uuid = property
	--elseif p_type == 6 then
		--link.uuid = property
	--elseif p_type == 7 then
		--link.uuid = property
	--elseif p_type == 8 then
		--link.uuid = property
	--elseif p_type == 9 then
		--link.uuid = property
	--elseif p_type == 10 then
		--link.url = property
	--end
	--return link
--end
--



------------------------------------------------------------------------------------
--1,摆摊
--[[
function f_stall_ad(char_id,char_nm,line,say,npc_id)
	local content ={}
	--[交易] [xxx]:(一线) xxxx ,打开摊位
	f_construct_content(content,gbk_utf8("("),13,nil)
	f_construct_content(content,line,13,nil)
	f_construct_content(content,gbk_utf8(")"),13,nil)
	f_construct_content(content,gbk_utf8("["),13,nil)
	local link = f_construct_link(1,char_id)
	f_construct_content(content,char_nm,53,link)
	f_construct_content(content,gbk_utf8("]:"),13,nil)
	

	
	f_construct_content(content,say,13,nil)

	link = f_construct_link(3,npc_id)
	f_construct_content(content,gbk_utf8("打开摊位"),51,link)

	f_send_bdc(1,2,content)
end
]]
--2,邮件
function f_email_ad(content,char_id)
	local COLOR = 20
	local param ={}
	param.color = COLOR
	param.char_id= char_id
	f_default_bdc(1,1,content,param)
end

--[[3,好友
	--加好友
function f_friend_add(char_id,char_nm,friend_id,friend_nm)
	local content = {}
	--[系统] 您已成功添加xxx为好友！
	f_construct_content(content,gbk_utf8("您已成功添加"),11,nil)

	local link = f_construct_link(1,friend_id)
	f_construct_content(content,friend_nm,53,link)

	f_construct_content(content,gbk_utf8("为好友!"),11,nil)

	f_send_bdc(1,1,content,char_id)

	local content = {}

	local link = f_construct_link(1,char_id)
	f_construct_content(content,char_nm,53,link)

	f_construct_content(content,gbk_utf8("已成功添加您为好友,"),11,nil)

	local link = f_construct_link(4,char_nm)
	f_construct_content(content,gbk_utf8("加对方为好友"),51,link)

	f_send_bdc(1,1,content,friend_id)
end
	--删除好友
function f_friend_del(char_id,friend_id,friend_nm,flag)
	local content = {}
	--[系统] 成功删除好友XXX
	if flag == 1 then
		f_construct_content(content,gbk_utf8("成功删除好友"),11,nil)

		local link = f_construct_link(1,friend_id)
		f_construct_content(content,friend_nm,53,link)
	else
		f_construct_content(content,gbk_utf8("删除好友"),11,nil)

		local link = f_construct_link(1,friend_id)
		f_construct_content(content,friend_nm,53,link)

		f_construct_content(content,gbk_utf8("失败！"),11,nil)
	end

	f_send_bdc(1,1,content,char_id)
end

	--加入黑名单
function f_friend_black_add(char_id,blc_id,blc_nm,flag)
	local content = {}
	--[系统] 成功将xxx加入黑名单！
	if flag == 1 then
		f_construct_content(content,gbk_utf8("成功将"),11,nil)

		local link = f_construct_link(1,blc_id)
		f_construct_content(content,blc_nm,53,link)

		f_construct_content(content,gbk_utf8("加入黑名单！"),11,nil)
	else
		f_construct_content(content,gbk_utf8("将"),11,nil)
		local link = f_construct_link(1,blc_id)
		f_construct_content(content,blc_nm,53,link)

		f_construct_content(content,gbk_utf8("加入黑名单失败！"),11,nil)
	end

	f_send_bdc(1,1,content,char_id)
end

	--删除黑名单
function f_friend_black_del(char_id,blc_id,blc_nm,flag)
	local content = {}
	--[系统] 成功将xxx移出黑名单！
	if flag == 1 then

		f_construct_content(content,gbk_utf8("成功将"),11,nil)

		local link = f_construct_link(1,blc_id)
		f_construct_content(content,blc_nm,53,link)

		f_construct_content(content,gbk_utf8("移出黑名单！"),11,nil)
	else
		f_construct_content(content,gbk_utf8("将"),11,nil)

		local link = f_construct_link(1,blc_id)
		f_construct_content(content,blc_nm,53,link)

		f_construct_content(content,gbk_utf8("移出黑名单失败！"),11,nil)
	end

	f_send_bdc(1,1,content,char_id)
end
   

--4,帮派
--（1）创建帮派
function f_create_faction(char_id,char_nm,faction_nm,faction_id)
	local content = {}
	--恭贺xxx建立xxxx！九天之上，风云变色，又一修真势力强势崛起。申请加入”

	local link = f_construct_link(1,char_id)
	f_construct_content(content,char_nm,53,link)

	f_construct_content(content,gbk_utf8("建立"),12,nil)

	f_construct_content(content,gbk_utf8("『"),12,nil)
	f_construct_content(content,faction_nm,57,nil)

	f_construct_content(content,gbk_utf8("』帮!九天之上，风云变色，又一修真势力强势崛起。"),12,nil)

	local link = f_construct_link(2,faction_id)
	f_construct_content(content,gbk_utf8("申请加入"),51,link)

	f_send_bdc(1,3,content,nil)

end

--(2)帮派招募
function f_faction_zm(info,faction_id,faction_name)
	local content = {}
	--[招募] xxxxxxxxxxxxxxxx,申请加入
	f_construct_content(content,gbk_utf8("『"),12,nil)
	f_construct_content(content,faction_name,57,nil)
	f_construct_content(content,gbk_utf8("』"),12,nil)
	f_construct_content(content,info,19,nil)

	local link = f_construct_link(2,faction_id)
	f_construct_content(content,gbk_utf8("申请加入"),51,link)

	f_send_bdc(1,4,content,nil)

end

--(3)批准加入

function f_construct_all(char_nm_list)
	local content = {}
	f_construct_content(content,gbk_utf8("欢迎"),12,nil)
	local num = table.getn(char_nm_list or {})
	for k,v in pairs(char_nm_list) do
		f_construct_content(content,v,53,nil)
		if k ~= num then
			f_construct_content(content,gbk_utf8(","),12,nil)
		end
	end
	f_construct_content(content,gbk_utf8("加入帮派，我们帮派的实力又增加了一分！ "),12,nil)

	return content
end
function f_faction_pizhun(content,char_id)
	f_send_bdc(4,5,content,char_id)
end

--(4)拒绝加入
function f_faction_refuse(faction_nm,char_id)
	local content = {}
	--[系统] xxx帮拒绝了你的请求！
	f_construct_content(content,gbk_utf8("『"),11,nil)
	f_construct_content(content,faction_nm,57,nil)

	f_construct_content(content,gbk_utf8("』帮拒绝了你的请求！"),11,nil)

	f_send_bdc(4,1,content,char_id)
end

--（5）人员被杀死
function f_faction_kill(post_nm,killed_nm,killed_id,faction_nm,killer_nm,killer_id,char_id)
	--"[%s][%s]被『%s』帮的[%s]杀死了,我们一定要报仇！"
	--"[%s][%s]被[%s]杀死了,我们一定要报仇！"
	local content = {}

	--f_construct_content(content,post_nm,19,nil)

	local link = f_construct_link(1,killed_id)
	f_construct_content(content,killed_nm,53,nil)
	f_construct_content(content,gbk_utf8("被"),19,nil)

	if faction_nm ~= nil then
		f_construct_content(content,gbk_utf8("『"),19,nil)
		f_construct_content(content,faction_nm,57,nil)
		f_construct_content(content,gbk_utf8("』帮的"),19,nil)

	end

	local link = f_construct_link(1,killer_id)
	f_construct_content(content,killer_nm,53,nil)

	f_construct_content(content,gbk_utf8("杀死了，我们一定要报仇！"),19,nil)

	f_send_bdc(4,5,content,char_id)
end

--(6)帮主被杀广播
function f_factioner_kill(char_faction_name,mine_nm,enemy_nm)
	--『%s帮』[帮主][%s]被[%s]击毙!
	local content = {}

	f_construct_content(content,gbk_utf8("『"),12,nil)

	f_construct_content(content,char_faction_name,57,nil)
	f_construct_content(content,gbk_utf8("帮』[帮主]["),12,nil)
	f_construct_content(content,mine_nm,53,nil)
	f_construct_content(content,gbk_utf8("]被["),12,nil)
	f_construct_content(content,enemy_nm,53,nil)
	f_construct_content(content,gbk_utf8("]击毙！"),12,nil)

	f_send_bdc(3,1,content,nil)
end
]]