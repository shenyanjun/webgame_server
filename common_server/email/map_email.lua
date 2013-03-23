--2010-01-07
--laojc
--map 通知email 发邮件

Map_email = oo.class(nil, "Map_email")
 
function Map_email:init()
end


function Map_email:create_email(sender,recevier,title,content,gold,email_type,sys_type,item_list)
	--local m_email =  Email(sender,recevier,title,content,gold,email_type,sys_type,item_list)
	g_email_mgr:create_email(sender,recevier,title,content,gold,email_type,sys_type,item_list)
end


function Map_email:enemy_email(char_id,pkt)
	local sender = Email_sender.sender_sys
	local enemy_nm = pkt.enemy_nm
	local enemy_id = pkt.obj_id
	local faction_name = pkt.faction_nm
	
	local content = ""
	if faction_name == nil then
		content = string.format(Email_faction.faction_c_n, enemy_nm)
	else
		content = string.format(Email_faction.faction_c_f, faction_name, enemy_nm)
	end

	local title = Email_title.title_sys
	local sys_type = Email_sys_type.type_sys
	local type = Email_type.type_common

	self:create_email(sender,char_id,title,content,0,type,sys_type,{})

	---------------帮派广播--------------
	local mine_nm = g_player_mgr.all_player_l[char_id]["char_nm"]
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	if faction ~= nil then
		local faction_id = faction:get_faction_id()
		if faction_id ~= nil then
			--local faction_list = faction:get_faction_list(faction_id)
			for k,v in pairs(faction:get_player_list() or {}) do --self.faction_player_list[obj_id]["online_flag"] = 0
				if v.online_flag == 1 then
					self:faction_kill(nil,mine_nm,char_id,faction_name,enemy_nm,enemy_id,k)
				end
			end
		end
	end

	--local mine_nm = pkt.mine_nm
	--local char_faction_name = nil
	--local post_name = nil
	--local char_faction =nil
	--local flag =false 
	--local t_faction = g_faction_mgr:get_faction_by_cid(char_id)
	--if t_faction ~=nil then
		--char_faction_name = t_faction:get_faction_name()
--
		--local post_index = t_faction:get_post(char_id)
		--post_name = t_faction:get_post_name(post_index) 
--
		----判断是否是帮主被杀死
		--if char_id ==  t_faction:get_factioner_id() then
			--flag = true
		--end
	--else
		--return
	--end
--
	--if char_faction_name == nil or post_name == nil then return end
	--local new_pkt ={}
	--new_pkt.say = say
	--for k,v in pairs(t_faction.faction_player_list) do
		--if v["status"] == "0" then
			--f_faction_kill(post_name,mine_nm,char_id,faction_name,enemy_nm,enemy_id,k)
		--end
	--end
--
	----------世界广播，如果是帮主被杀死 -----------------
	--if flag == true then
		--f_factioner_kill(char_faction_name,mine_nm,enemy_nm)
	--end
end

--（5）人员被杀死
function Map_email:faction_kill(post_nm,killed_nm,killed_id,faction_nm,killer_nm,killer_id,char_id)
	--"[%s][%s]被『%s』帮的[%s]杀死了,我们一定要报仇！"
	--"[%s][%s]被[%s]杀死了,我们一定要报仇！"
	--"[%s][%s]被『%s』帮的[%s]杀死了,我们一定要报仇！"
	--"[%s][%s]被[%s]杀死了,我们一定要报仇！"
	local content = {}

	--f_construct_content(content,post_nm,19,nil)

	local link = f_construct_link(1,killed_id)
	f_construct_content(content,killed_nm,53,nil)
	f_construct_content(content,f_get_string(628),19,nil)

	if faction_nm ~= nil then
		f_construct_content(content,f_get_string(621),19,nil)
		f_construct_content(content,faction_nm,57,nil)
		f_construct_content(content,f_get_string(629),19,nil)

	end

	local link = f_construct_link(1,killer_id)
	f_construct_content(content,killer_nm,53,nil)

	f_construct_content(content,f_get_string(630),19,nil)

	f_send_bdc(4,5,content,char_id)
end

Map_email:init()