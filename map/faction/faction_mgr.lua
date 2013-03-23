
local faction_update_loader = require("item.faction_update_loader")

Faction_mgr = oo.class(nil,"Faction_mgr")

function Faction_mgr:__init()
	self.faction_list = {}
	self.char2faction_l = {}

	--帮派之间关系
	self.faction_relate = {}					--标志位 1 为友好 2为敌对 3中立（未设置）

	--退出帮派时间
	self.leave_time = {}
	self.kick_time = {}
end

function Faction_mgr:get_faction_base_info_list()
	local t ={}
	for k,v in pairs (self.faction_list or {}) do
		local faction=self.faction_list[k]
		if faction ~= nil and faction:get_dissolve_flag() == 0 then
			local ret = faction:get_faction_list_info()	
			table.insert(t,ret)
		end
	end

	return t
end



function Faction_mgr:set_leave_time(leave_time,flag,kick_time)
	if flag == 0 then
		self.leave_time = {}
		self.kick_time = {}
	end
	for k,v in pairs(leave_time or {}) do
		local obj_id = v[1]
		self.leave_time[obj_id] = v[2]
	end

	for k,v in pairs(kick_time or {}) do
		local obj_id = v[1]
		self.kick_time[obj_id] = v[2]
	end
end

function Faction_mgr:get_leave_time(obj_id)
	return self.leave_time[obj_id] or 0, self.kick_time[obj_id] or 0
end

function Faction_mgr:get_faction_by_fid(faction_id)
	return self.faction_list[faction_id]
end

function Faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = self.char2faction_l[obj_id]
	if faction_id ~= nil then
		return self:get_faction_by_fid(faction_id)
	end
end

function Faction_mgr:add_member2faction(obj_id,faction_id)
	self.char2faction_l[obj_id] = faction_id
	self:syn_info_chat(faction_id,obj_id,1)
end

function Faction_mgr:del_member2faction(obj_id)
	self.char2faction_l[obj_id] = nil
	self:syn_info_chat(0,obj_id,2)
end

function Faction_mgr:add_faction(faction)
	local faction_id = faction:get_faction_id()
	if faction_id ~= nil then
		self.faction_list[faction_id] = faction
	end
end

function Faction_mgr:set_faction_list(faction_list)
	self.faction_list = faction_list
end

function Faction_mgr:del_faction(faction_id)
	self.faction_list[faction_id] = nil
end

--flag 1为add或创建帮派 2 delete
function Faction_mgr:syn_info_chat(faction_id,char_id,flag)
	local ret = {}
	ret[1] = faction_id or 0
	ret[2] = char_id or 0
	ret[3] = flag

	g_svsock_mgr:send_server_ex(WORLD_ID, 0, CMD_CHAT_FACTION_SYN_C, ret)
	
end


----------------------------------------------------------------------------------------------------------------------------
--玩家更新时 从common_server同步到玩家对应的map上
function Faction_mgr:serialize_from_common_server(pkt)
	local faction_id = pkt['2']
	local faction = self:get_faction_by_fid(faction_id)
	if not faction then
		faction = Faction(faction_id)
	end
	faction:update_faction(pkt)
	local player_list = faction:get_faction_player_list()
	for k,v in pairs(player_list or {}) do
		self:add_member2faction(v.obj_id,faction_id)
	end
	self:add_faction(faction)

	faction:init_set_book_practice_bonus()
	g_faction_impact_mgr:set_dissolve(faction:get_faction_id(), faction:get_dissolve_flag())
	return faction
end

--玩家更新，从comman_server同步到玩家不对应的map上
function Faction_mgr:serialize_from_common_server_ex(pkt)
	local faction_id = pkt.faction_id
	local faction = self:get_faction_by_fid(faction_id)
	if faction == nil then return end
	
	local player_list = faction:get_faction_player_list()
	for k,v in pairs(player_list or {}) do
		self:del_member2faction(v.obj_id)
	end

	faction:update_faction(pkt)

	local player_list = faction:get_faction_player_list()
	for k,v in pairs(player_list or {}) do
		self:add_member2faction(v.obj_id,faction_id)
	end
	self:add_faction(faction)

	return faction
end

--重新上线
function Faction_mgr:reset_online(obj_id)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		faction:on_line(obj_id)
	else
		self:online(obj_id)
	end
end

--主动邀请人
function Faction_mgr:add_player_auto(obj_id,pkt)
	local new_pkt = {}
	new_pkt.faction_id = pkt.faction_id
	new_pkt.faction_name = pkt.faction_name
	new_pkt.p_char_id = pkt.p_char_id
	g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_ADD_PLAYER_S, new_pkt)
end

--玩家更新列表
function Faction_mgr:serialize_player_list(pkt)
	local faction = self:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then 
		faction:update_faction_player_list(pkt)
	end
end

--玩家更新招募列表
function Faction_mgr:serialize_join_list(pkt)
	local faction = self:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then 
		faction:update_join_list(pkt)
	end
end

--玩家更新其他内容信息
function Faction_mgr:serialize_other_list(pkt)
	local faction = self:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then 
		faction:update_other_info(pkt)
	end
end

--同步
function Faction_mgr:syn_update(pkt)
	local faction = self:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then
		local cmd = pkt.cmd
		local ret = {}
		ret.list = pkt.list
		faction:syn_send_all(ret,cmd)
 		
		for k, v in pairs(pkt.list or {})do
			if cmd == 25642 then  --update
				faction:syn_info(1,v.flag,v)
			elseif cmd == 25643 then -- add
				faction:syn_info(2,v.flag,v)
			elseif cmd == 25644 then	--delete
				faction:syn_info(3,v.flag,v)
			end
		end
	end
end

-----------------------------------------------------------------------------------------------------------------------------

--玩家上线  ok
function Faction_mgr:online(obj_id)
	local node = {}
	local faction = self:get_faction_by_cid(obj_id)
	local new_pkt = {}
	new_pkt.flag = 0
	if faction ~= nil then	
		new_pkt.flag = 1       --只同步玩家上线信息
	end
	--local usec_1,sec_1 = crypto.timeofday()
	node.obj_id = obj_id
	node.flag = new_pkt.flag
	--node.time = sec_1+usec_1
	
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_GET_FACTION_REQ, new_pkt)
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_GET_FACTION_REP, self, self.load_process, self.load_time_out, node, 6)
end

function Faction_mgr:load_process(node,pkt)
	--local usec_2,sec_2 = crypto.timeofday()
	--local temp =  math.floor(((sec_2+usec_2)-node.time)*1000000)
	--print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@===============", temp)
	if pkt.result == 0 then
		if pkt.flag == 1 then
			local faction = self:get_faction_by_cid(pkt.obj_id)
			faction:on_line(pkt.obj_id)
			local obj = g_obj_mgr:get_obj(pkt.obj_id)
			if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
				local ret = faction:get_head_info(pkt.obj_id)
				obj:set_faction(ret)
			end
		else
			local faction = self:serialize_from_common_server(pkt)
			faction:on_line(pkt.obj_id)
			local obj = g_obj_mgr:get_obj(pkt.obj_id)
			if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
				local ret = faction:get_head_info(pkt.obj_id)
				obj:set_faction(ret)
			end
			faction:init_set_book_practice_bonus()
			g_faction_impact_mgr:set_dissolve(faction:get_faction_id(), faction:get_dissolve_flag())
		end
	else
		local new_pkt = {}
		new_pkt.faction_id =""
		g_cltsock_mgr:send_client(pkt.obj_id, CMD_M2B_FACTION_PLAYER_INFO_S, new_pkt)
	end
	
end

function Faction_mgr:load_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " online failed! time out"
	g_faction_log:write(str)

	
	--local usec_2,sec_2 = crypto.timeofday()
	--local temp =  math.floor(((sec_2+usec_2)-node.time)*1000000)
	--print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@", temp)
end


--玩家下线
--function Faction_mgr:outline(obj_id)
	--local new_pkt = {}
	--local node = {}
	--node.obj_id = obj_id
	--g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_PLAYER_OUTLINE_REQ, new_pkt)
	--g_sock_event_mgr:add_event(obj_id, CMD_M2P_PLAYER_OUTLINE_REP, self, self.outline_process, self.outline_time_out, node, 3)
--end
--
--function Faction_mgr:outline_process(node,pkt)
	--if pkt.result == 0 then
		----local faction = self:serialize_from_common_server(pkt)
		--faction:out_line(node.obj_id)
	--else
		--
	--end
--end
--
--function Faction_mgr:outline_time_out(node)
--end

--------------------------------------------------------------------------------------------------------------------------------
--创建帮派  ok
function Faction_mgr:create_faction(obj_id,pkt)
	local player = g_obj_mgr:get_obj(obj_id)
	if not player then return end
	local pack_con = player:get_pack_con()
	local s_pkt = {}

	if pack_con:check_item_lock_by_item_id(103050000121) or pack_con:check_item_lock_by_item_id(103050000120) then
		return
	end

	local item_id = nil 
	if pack_con:get_item_count(103050000121) > 0 then
		item_id = 103050000121
	end
	if pack_con:get_item_count(103050000120) > 0 then
		item_id = 103050000120
	end
	if item_id == nil then 
		s_pkt.result = 26005 
		g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_ERROR_S, s_pkt)
		return
	end

	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_CREATE_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	node.item_id = item_id
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_CREATE_REP, self, self.create_process, self.create_time_out, node, 6)
end

function Faction_mgr:create_process(node,pkt)
	if pkt.result == 0 then     --代表有对应的信息
		local faction = self:serialize_from_common_server(pkt)
		faction:on_line(node.obj_id)
		--self:syn_info_chat(faction:get_faction_id(),node.obj_id,1)

		--faction:init_set_book_practice_bonus()
		g_event_mgr:notify_event(EVENT_SET.EVENT_CREATE_FACTION, node.obj_id, nil)
	
		local player = g_obj_mgr:get_obj(node.obj_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		pack_con:del_item_by_item_id(node.item_id,1,{['type']=ITEM_SOURCE.FACTION})

		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_CREATE_S, {["result"]=0})

		--世界广播
		local faction_id = faction:get_faction_id()
		local char_nm = player:get_name()
		local faction_nm = faction:get_faction_name()

		local content = {}
		--恭贺xxx建立xxxx！九天之上，风云变色，又一修真势力强势崛起。申请加入”

		local link = f_construct_link(1,node.obj_id)
		f_construct_content(content,char_nm,53,link)

		f_construct_content(content,f_get_string(620),12,nil)

		f_construct_content(content,f_get_string(621),12,nil)
		f_construct_content(content,faction_nm,57,nil)

		f_construct_content(content,f_get_string(623),12,nil)

		local link = f_construct_link(2,faction_id)
		f_construct_content(content,f_get_string(624),51,link)

		f_cmd_world_bd(content,1,3)

		local str = ev.time .. " char_id:" ..node.obj_id .. " create_faction success! delete item" .. node.item_id 
		g_faction_log:write(str)
	else
		local ret = {}
		ret.result = pkt.result
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, ret)
	end
end

function Faction_mgr:create_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " create_faction failed! time out"
	g_faction_log:write(str)
end

--------------------------------------------通信信息----------------------------------------------------------
--帮派列表 ok
function Faction_mgr:get_faction_list(obj_id)
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_LIST_REQ, {})

	local node = {}
	node.obj_id = obj_id
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_LIST_REP, self, self.get_process, self.get_time_out, node, 6)
end

function Faction_mgr:get_process(node,pkt)
	local t_ret = {}
	local t ={}
	for k,v in pairs (self.faction_list or {}) do
		local faction=self.faction_list[k]
		if faction ~=nil and faction:get_dissolve_flag() == 0 then		
			local ret = faction:get_faction_list_info()	
			table.insert(t,ret)
		end
	end

	t_ret.faction_list = t
	t_ret.relate_list = pkt.relate_list
	g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_LIST_S, t_ret)

	local relate_list = pkt.relate_list
	local faction = self:get_faction_by_cid(node.obj_id)
	if faction then
		local faction_id = faction:get_faction_id()
		self.faction_relate[faction_id] = {}
		for k,v in ipairs(relate_list) do
			for m, n in pairs(v) do
				self.faction_relate[faction_id][n] = k
			end	
		end
	end
end

function Faction_mgr:get_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " get_faction_list failed! time out"
	g_faction_log:write(str)
end

--申请加入  ok
function Faction_mgr:join(obj_id,pkt)
	if pkt == nil then return end

	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_JOIN_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_JOIN_REP, self, self.join_process, self.join_time_out, node, 6)
end

function Faction_mgr:join_process(node,pkt)
	if pkt.result == 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_JOIN_S, pkt)
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:join_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " join failed! time out"
	g_faction_log:write(str)
end


--申请退出   
function Faction_mgr:out(obj_id,pkt)
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_OUT_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_OUT_REP, self, self.out_process, self.out_time_out, node, 6)
end

function Faction_mgr:out_process(node,pkt)
	if pkt.result == 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_OUT_S, pkt)
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:out_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " out failed! time out"
	g_faction_log:write(str)
end

--邀请人加入   ok
function Faction_mgr:add_player(obj_id,pkt)

	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_ADD_PLAYER_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_ADD_PLAYER_REP, self, self.add_player_process, self.add_player_time_out, node, 6)
end

function Faction_mgr:add_player_process(node,pkt)
	--g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ADD_PLAYER_S, pkt)

	if pkt.result == 0 then
		local char_id = pkt.char_id 
		local new_pkt = {}
		new_pkt.faction_id = pkt.faction_id
		new_pkt.faction_name = pkt.faction_name
		--g_cltsock_mgr:send_client(char_id, CMD_M2B_FACTION_ADD_PLAYER_S, new_pkt)
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ADD_PLAYER_S, new_pkt)
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:add_player_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " add_player failed! time out"
	g_faction_log:write(str)
end

--踢人  ok
function Faction_mgr:kick_player(obj_id,pkt)

	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_KICK_PLAYER_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_KICK_PLAYER_REP, self, self.kick_player_process, self.kick_player_time_out, node, 6)
end

function Faction_mgr:kick_player_process(node,pkt)
	--g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_KICK_PLAYER_S, pkt)

	if pkt.result == 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_KICK_PLAYER_S, pkt)
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:kick_player_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " kick_player failed! time out"
	g_faction_log:write(str)
end

--职务卸任
function Faction_mgr:post_outing(obj_id,pkt)
	if obj_id == pkt.other_id then return end
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_POST_OUTGOING_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_POST_OUTGOING_REP, self, self.post_outing_process, self.post_outing_time_out, node, 6)
end

function Faction_mgr:post_outing_process(node,pkt)
	--g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_POST_OUTGOING_S, pkt)

	if pkt.result == 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_POST_OUTGOING_S, pkt)
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:post_outing_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " post_outing failed! time out"
	g_faction_log:write(str)
end

--获取招募信息
function Faction_mgr:recruit(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local ret = faction:get_recruit_info()
		g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_RECRUIT_S, ret)
	end
end

--获取任免职务信息
function Faction_mgr:post_info(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local new_pkt ={}
		new_pkt.post_info ={}
		for i =1 ,5 do
			new_pkt.post_info[i]={}
			new_pkt.post_info[i].post_name= faction.post_name[i]
			new_pkt.post_info[i].level=i
			new_pkt.post_info[i].count = faction.post_num[i]
		end
		g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_POST_INFO_S, new_pkt)
	end
end

--获取职务名
function Faction_mgr:get_post_name_ex(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local new_pkt = {}
		new_pkt.bangzhu = faction:get_post_name(1)
		new_pkt.fubangzhu = faction:get_post_name(2)
		new_pkt.zhanglao = faction:get_post_name(3)
		new_pkt.hufa = faction:get_post_name(4)
		new_pkt.bangzhong = faction:get_post_name(5)
		g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_POST_NAME_S, new_pkt)
	end 
end

--获取帮派成员列表
function Faction_mgr:get_faction_member(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local ret = faction:get_player_info()
		g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_MEMBER_S, ret)
	end
end

--批准加入帮派 ok
function Faction_mgr:approve(obj_id,pkt)
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_APPROVE_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_APPROVE_REP, self, self.approve_process, self.approve_time_out, node, 6)
end

function Faction_mgr:approve_process(node,pkt)
	if pkt.result == 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_APPROVE_S, pkt)
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:approve_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " approve failed! time out"
	g_faction_log:write(str)
end

--拒绝加入帮派 ok
function Faction_mgr:refuse(obj_id,pkt)
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_REFUSE_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_REFUSE_REP, self, self.refuse_process, self.refuse_time_out, node, 6)
end

function Faction_mgr:refuse_process(node,pkt)
	if pkt.result == 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_REFUSE_S, pkt)

		local faction = self:get_faction_by_cid(node.obj_id)
		for k,v in pairs(pkt.char_id_list or {}) do
			local content = {}
			--[系统] xxx帮拒绝了你的请求！
			f_construct_content(content,f_get_string(621),11,nil)
			f_construct_content(content,faction:get_faction_name(),57,nil)

			f_construct_content(content,f_get_string(627),11,nil)

			f_cmd_world_bd(content,4,1,v)
		end

	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:refuse_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " refuse failed! time out"
	g_faction_log:write(str)
end

--保存管理公告 ok
function Faction_mgr:save_announcement(obj_id,pkt)
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_ANNOUNCEMENT_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_ANNOUNCEMENT_REP, self, self.save_announcement_process, self.save_announcement_time_out, node, 6)
end

function Faction_mgr:save_announcement_process(node,pkt)
	--if pkt.result ~= 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ANNOUNCEMENT_S, pkt)
	--else
		--g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	--end
end

function Faction_mgr:save_announcement_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " save_announcement failed! time out"
	g_faction_log:write(str)
end

--任命
function Faction_mgr:appointment(obj_id,pkt)
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_APPOINTMENT_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_APPOINTMENT_REP, self, self.appointment_process, self.appointment_time_out, node, 6)
end

function Faction_mgr:appointment_process(node,pkt)
	if pkt.result == 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_APPOINTMENT_S, pkt)
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:appointment_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " appointment failed! time out"
	g_faction_log:write(str)
end

--玩家确定加入 ok
function Faction_mgr:join_conf(obj_id,pkt)
	g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_JOIN_CONF_REQ, pkt)

	local node = {}
	node.obj_id = obj_id
	
	g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_JOIN_CONF_REP, self, self.join_conf_process, self.join_conf_time_out, node, 6)
end

function Faction_mgr:join_conf_process(node,pkt)
	if pkt.result == 0 then
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_JOIN_CONF_S, pkt)
		self:online(node.obj_id)
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_ERROR_S, pkt)
	end
end

function Faction_mgr:join_conf_time_out(node)
	local str = ev.time .. " char_id:" ..node.obj_id .. " join_conf failed! time out"
	g_faction_log:write(str)
end

--招募广告
function Faction_mgr:broadcast(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local faction_name = faction:get_faction_name()
		local content = {}
		--[招募] xxxxxxxxxxxxxxxx,申请加入
		f_construct_content(content,f_get_string(621),12,nil)
		f_construct_content(content,faction_name,57,nil)
		f_construct_content(content,f_get_string(622),12,nil)
		f_construct_content(content,pkt.broadcast_content,19,nil)

		local link = f_construct_link(2,faction:get_faction_id())
		f_construct_content(content,f_get_string(624),51,link)
		
		local player = g_obj_mgr:get_obj(obj_id)
		if not player then return end
		local pack_con = player:get_pack_con()

		if pkt.flag == 1 then
			local money = pack_con:get_money()
			local s_pkt = {}
			s_pkt.result = 0
			local count  = tonumber(money.gold) + tonumber(money.gift_gold)
			if count < 100 then
				s_pkt.result = 26070
				g_svsock_mgr:send_server_ex(WORLD_ID, obj_id, CMD_M2B_FACTION_BROADCAST_S, s_pkt)
				return
			end
			
			pack_con:dec_gold_gift_and_gold(100, {['type']=MONEY_SOURCE.FACTION_RECRUIT})
			f_cmd_world_bd(content,1,4)

		elseif pkt.flag == 2 then
			local count = pack_con:get_all_item_count(131000000111)
			if count < 1 then
				local s_pkt = {}
				s_pkt.result = 26020
				g_svsock_mgr:send_server_ex(WORLD_ID, obj_id, CMD_M2B_FACTION_BROADCAST_S, s_pkt)
				return
			end

			pack_con:del_item_by_item_id_bind_first(131000000111, 1, {['type']=ITEM_SOURCE.FACTION_RECRUIT})
			f_cmd_world_bd(content,6,7)
		end

	end
end

--帮派升级（演武厅，观星阁，金库，建设点，科技点，帮贡,帮派等级，帮派资金）统一接口
function Faction_mgr:update_faction_level(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local result = 0
		if pkt.flag == 1 then--FACTION.action_level
			result = faction:condition_action()
		elseif pkt.flag == 2 then--FACTION.book_level
			result = faction:condition_book()
		elseif pkt.flag == 3 then--FACTION.gold_level
			result = faction:condition_gold()
		elseif pkt.flag == 7 then--FACTION.faction_level
			result = faction:condition_faction()
	--[[	elseif pkt.flag == 10 then -- FACTION.warehouse_level -- 帮派仓库
			result = faction:condition_warehouse()--]]
		end
		if result == 0 then
			g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_UPDATE_INFO_REQ, pkt)

			local node = {}
			node.obj_id = obj_id
			node.flag = pkt.flag
			node.param = pkt.param
			node.type = pkt.type  --这个代表帮贡，科技点，建设度来源（10，代表帮派任务,11为使用道具）
			node.io = pkt.io
			g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_UPDATE_INFO_REP, self, self.update_faction_level_process, self.update_faction_level_time_out, node, 6)
		else
			local ret = {}
			ret.result = result
			ret.flag = pkt.flag
			g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_UPDATE_S, ret)
		end
	end
end

function Faction_mgr:update_faction_level_process(node,pkt)
	local faction = self:get_faction_by_cid(node.obj_id)
	if faction ~= nil then
		if pkt.flag == 1 or pkt.flag == 2 or pkt.flag == 3 or pkt.flag == 7 or pkt.flag== 10 then -- 添加帮派仓库flag=10
			g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_UPDATE_S, pkt)
		elseif pkt.flag == 6 then
			local args = {}
			args.count = node.param
			g_event_mgr:notify_event(EVENT_SET.EVENT_FACTION_CON_ADD,node.obj_id,args)
		end
	end
end

function Faction_mgr:update_faction_level_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " update_faction_level failed! time out"
	g_faction_log:write(str)
end

--技能升级修炼
function Faction_mgr:update_action_practice(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local result = faction:condition_action_practice(pkt.flag) 
		result = 0
		if result == 0 then
			g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_SKILL_UPDATE_REQ, pkt)

			local node = {}
			node.obj_id = obj_id
			node.flag = pkt.flag
			
			g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_SKILL_UPDATE_REP, self, self.update_action_practice_process, self.update_action_practice_time_out, node, 6)
		else
			local ret = {}
			ret.result = result
			g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_SKILL_S, ret)
		end
	end
end

function Faction_mgr:update_action_practice_process(node,pkt)
	--print(j_e(pkt))

	g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_SKILL_S, pkt)

	----流水
	--if pkt.result == 0 then
		--local faction = self:get_faction_by_cid(node.obj_id)
		--if faction ~= nil then
			--local fund,build,science = 0
			--local action_practice = faction:get_action_practice()
			--local lvl = action_practice[node.flag]
			--local loader = nil
			--if node.flag == 1 then
				--loader = faction_update_loader.strengh_list[lvl]
			--elseif node.flag == 2 then
				--loader = faction_update_loader.intelligence_list[lvl]
			--elseif node.flag == 3 then
				--loader = faction_update_loader.pro_defence_list[lvl]
			--elseif node.flag == 4 then
				--loader = faction_update_loader.pro_attack_list[lvl]
			--end
			--if loader ~= nil then
				--fund = loader[3]
				--build = 0
				--science = loader[2]
				--local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d,io=%d,contribution='%s'",
						--faction:get_faction_id(), faction:get_faction_name(), node.obj_id, 4,fund,build,science,ev.time,0,Json.Encode({}))
				--f_multi_web_sql(str)
			--end
		--end
	--end

end

function Faction_mgr:update_action_practice_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " update_action_practice failed! time out"
	g_faction_log:write(str)
end

--buf升级
function Faction_mgr:update_buf_practice(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local result = faction:condition_book_practice(pkt.flag)
		if result == 0 then
			g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_BUF_UPDATE_REQ, pkt)

			local node = {}
			node.obj_id = obj_id
			node.flag = pkt.flag
			node.faction_id = faction:get_faction_id()
			
			g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_BUF_UPDATE_REP, self, self.update_buf_practice_process, self.update_buf_practice_time_out, node, 6)
		else
			local ret = {}
			ret.result = result
			ret.flag = pkt.flag
			g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_BUF_S, ret)
		end
	end
end

function Faction_mgr:update_buf_practice_process(node,pkt)
	g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_BUF_S, pkt)

		----流水
	--if pkt.result == 0 then
		--local faction = self:get_faction_by_cid(node.obj_id)
		--if faction ~= nil then
			--local fund,build,science = 0
			--local book_practice = faction:get_book_practice()
			--local lvl = book_practice[node.flag]
			--local loader = nil
			--if node.flag == 1 then
				--loader = faction_update_loader.attack_list[lvl]
			--elseif node.flag == 2 then
				--loader = faction_update_loader.defense_list[lvl]
			--elseif node.flag == 3 then
				--loader = faction_update_loader.expr_list[lvl]
			--end
			--if loader ~= nil then
				--fund = loader[2]
				--build = 0
				--science = loader[4]
				--local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d,io=%d,contribution='%s'",
						--faction:get_faction_id(), faction:get_faction_name(), node.obj_id, 5,fund,build,science, ev.time,0,Json.Encode({}))
				--f_multi_web_sql(str)
			--end
		--end
	--end
end

function Faction_mgr:update_buf_practice_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " update_buf_practice failed! time out"
	g_faction_log:write(str)
end


--帮派关系修改
function Faction_mgr:update_relate(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_RELATE_UPDATE_REQ, pkt)

		local node = {}
		node.obj_id = obj_id
		node.flag = pkt.flag
		
		g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_RELATE_UPDATE_REP, self, self.update_relate_process, self.update_relate_time_out, node, 6)
	end
end

function Faction_mgr:update_relate_process(node,pkt)
	g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_RELATE_UPDATE_S, pkt)
end

function Faction_mgr:update_relate_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " update_relate failed! time out"
	g_faction_log:write(str)
end

--设置权限
function Faction_mgr:permission(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_PERMISSION_REQ, pkt)

		local node = {}
		node.obj_id = obj_id
		
		g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_PERMISSION_REP, self, self.permission_process, self.permission_time_out, node, 6)
	end
end

function Faction_mgr:permission_process(node,pkt)
	g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_PERMISSION_S, pkt)
end

function Faction_mgr:permission_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " permission failed! time out"
	g_faction_log:write(str)
end

--获取工资单
function Faction_mgr:get_salary(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then

		if faction:is_fetch_salary_ok(obj_id) == 0 then 
			return g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_SALARY_S ,{["result"] = 26043})
		end
		local level = g_obj_mgr:get_obj(obj_id):get_level()
		local post_index = faction:get_post(obj_id)
		--基础俸禄
		local base_salary = math.floor(level * level * 0.8)
		--职位加成
		local post_salary = (5 - post_index) * 80 * 8
		--帮派加成
		local faction_salary = (level + (6 - post_index)*80) * (faction:get_level() - 1) * 8

		--总共
		local salary = base_salary + post_salary + faction_salary

		local ret = {}
		ret.result = 0
		ret.salary = {}
		ret.salary[1] = base_salary
		ret.salary[2] = faction_salary
		ret.salary[3] = post_salary
		ret.salary[4] = salary

		g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_SALARY_S , ret)
		
	end
end

--领取工资
function Faction_mgr:fetch_salary(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local level = g_obj_mgr:get_obj(obj_id):get_level()
		local post_index = faction:get_post(obj_id)
		--基础俸禄
		local base_salary = math.floor(level * level * 0.8)
		--职位加成
		local post_salary = (5 - post_index) * 80 * 8
		--帮派加成
		local faction_salary = (level + (6 - post_index)*80) * (faction:get_level() - 1) * 8

		--总共
		local salary = base_salary + post_salary + faction_salary
		
		if salary < 0 then return end

		local contribution = faction:get_contribution(obj_id)
		if contribution < 2 then
			return g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_OBTAINSALARY_S ,{["result"] = 26071})
		end

		if salary > faction:get_money() then
			g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_OBTAINSALARY_S ,{["result"] = 26025})
		else 
			local ret = {}
			ret.salary = salary
			g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_OBTAINSALARY_REQ, ret)

			local node = {}
			node.obj_id = obj_id
			
			g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_OBTAINSALARY_REP, self, self.fetch_salary_process, self.fetch_salary_time_out, node, 6)
		end
	end
end

function Faction_mgr:fetch_salary_process(node,pkt)
	g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_OBTAINSALARY_S ,{["result"] = pkt.result})
	if pkt.result == 0 then
		local player = g_obj_mgr:get_obj(pkt.obj_id)
		local pack_con = player:get_pack_con()
		pack_con:add_money(MoneyType.GIFT_GOLD, pkt.salary, {['type']=MONEY_SOURCE.FACTION_SALARY})
		local str = ev.time .. " char_id:" ..pkt.obj_id .. " fetch_salary :" .. pkt.salary
		g_faction_log:write(str)

		local faction = self:get_faction_by_cid(pkt.obj_id)

		local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d,io=%d,contribution='%s'",
					faction:get_faction_id(), faction:get_faction_name(), pkt.obj_id, 1,pkt.salary, 0,0, ev.time,0,Json.Encode({}))
		f_multi_web_sql(str)
	end
end

function Faction_mgr:fetch_salary_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " fetch_salary failed! time out"
	g_faction_log:write(str)
end

--摇钱树灌溉或摇一下
function Faction_mgr:irrigation(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_MONEY_TREE_REQ, {})

		local node = {}
		node.obj_id = obj_id
		
		g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_MONEY_TREE_REP, self, self.irrigation_process, self.irrigation_time_out_process, node, 6)
	end
end

function Faction_mgr:irrigation_process(node,pkt)
	g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_MONEY_TREE_S ,pkt)
	local faction = self:get_faction_by_cid(node.obj_id)
	if faction ~= nil then
		local player = g_obj_mgr:get_obj(node.obj_id)
		if not player then return end
		if pkt.result == 0 and pkt.flag == 1 then
			local expr = player:get_level() * 300
			player:add_exp(expr)
			local str = ev.time .. " char_id:" ..node.obj_id .. " add_exp :" .. expr
			g_faction_log:write(str)
		elseif pkt.result == 0 and pkt.flag == 0 then
			local pack_con = player:get_pack_con()
			if not pack_con then return end
			local jade_gift = faction:get_irrigation_jade_gift()
			pack_con:add_money(MoneyType.GIFT_JADE, jade_gift, {['type']=MONEY_SOURCE.FACTION_IRRIGATION})
			local str = ev.time .. " char_id:" ..node.obj_id .. " jade_gift:" .. jade_gift
			g_faction_log:write(str)
		end
	end
end

function Faction_mgr:irrigation_time_out_process(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " irrigation failed! time out"
	g_faction_log:write(str)
end


--使用道具减少升级时间
function Faction_mgr:update_speed_time(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		if pkt.build_id == 1 then
			if faction:get_action_end_time() == 0 then
				return 26046
			end 
		elseif pkt.build_id == 2 then
			if faction:get_book_end_time() == 0 then
				return 26046
			end 
		elseif pkt.build_id == 3 then
			if faction:get_gold_end_time() == 0 then
				return 26046
			end 
		elseif pkt.build_id == 7 then
			if faction:get_faction_update_end_time() == 0 then
				return 26046
			end 
		elseif pkt.build_id == 10 then -- 帮派仓库
			if faction:get_warehouse_end_time() == 0 then
				return 26046
			end
		end
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_SPEED_TIME_REQ, pkt)

		local node = {}
		node.obj_id = obj_id
		node.item_id_list = pkt.item_id_list
		node.build_id = pkt.build_id
		node.all_time = pkt.all_time
		
		g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_SPEED_TIME_REP, self, self.update_speed_process, self.update_speed_time_out_process, node, 6)
		return 0
	end
end

function Faction_mgr:update_speed_process(node,pkt)
end

function Faction_mgr:update_speed_time_out_process(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " update_speed_time! time out"
	g_faction_log:write(str)
end

--获取历史信息
function Faction_mgr:get_history_info(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_HISTORY_INFO_REQ, {})

		local node = {}
		node.obj_id = obj_id
		--注册一个三秒超时事件，等common服返回
		g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_HISTORY_INFO_REP, self, self.history_process, self.history_time_out_process, node, 6)
	end
end

function Faction_mgr:history_process(node,pkt)
	g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_HISTORY_INFO_S ,pkt)
end

function Faction_mgr:history_time_out_process(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " get_history_info failed! time out"
	g_faction_log:write(str)
end 

--使用帮派道具
function Faction_mgr:use_faction_subtime_item(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	local s_pkt = {}
	s_pkt.result = 0
	if not faction then
		s_pkt.result = 200101
		g_cltsock_mgr:send_client(obj_id, CMD_B2M_FACTION_SUB_TIME_S ,s_pkt)
		return
	end
	local item_list = pkt.item_list
	local player = g_obj_mgr:get_obj(obj_id)

	if player and item_list then
		local pack_con = player:get_pack_con()
		local e_code, sys_pack = pack_con:get_bag(SYSTEM_BAG)
		local time = 0
		local node = {}
		node.item_id_list = {}
		local num = 1
		local tmp_list = {}
		for k , v in pairs(item_list) do
			if v ~= 0 then
				if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG,v) then
					return
				end
				local slot = sys_pack:get_item_by_slot(v)
				local item = slot and slot.item
				if not item then
					s_pkt.result = 43001
					g_cltsock_mgr:send_client(obj_id, CMD_B2M_FACTION_SUB_TIME_S ,s_pkt)
					return
				end
				if item:get_m_class() ~= 1 or item:get_s_class() ~= 35 then
					s_pkt.result = 43064
					g_cltsock_mgr:send_client(obj_id, CMD_B2M_FACTION_SUB_TIME_S ,s_pkt)
					return
				end
				time = time + item.proto.value.subtime
				node.item_id_list[num] = slot.item_id
				tmp_list[num] = {SYSTEM_BAG,v,1}
				num = num +1
			end
		end

		node.obj_id = obj_id
		node.build_id = pkt.building_id
		node.all_time = time * 3600
		s_pkt.result = self:update_speed_time(obj_id,node)
		s_pkt.all_time = time
		s_pkt.build_id = pkt.building_id

		g_cltsock_mgr:send_client(obj_id, CMD_B2M_FACTION_SUB_TIME_S ,s_pkt)

		pack_con:del_item_by_bags_slots(tmp_list,{['type']=ITEM_SOURCE.FACTION_SUBTIME},1)

		return 0
	end
end

--解散帮派
function Faction_mgr:faction_dissolve(obj_id,pkt)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		if faction:get_level() >=3 and faction:get_dissolve_flag() == 0 then
			return g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_DISSOLVE_S, {["result"]= 26075})
		end
		local factioner_id = faction:get_factioner_id()
		if factioner_id ~= obj_id then return end
		local member_count = faction:get_member_count()
		if member_count > 1 then return end
		
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_DISSOLVE_REQ, {})
		local node = {}
		node.obj_id = obj_id
		g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_DISSOLVE_REP, self, self.dissolve_process, self.dissolve_time_out, node, 6)
	end
end

function Faction_mgr:dissolve_process(node,pkt)
	if pkt.result == 0 then
		self:del_member2faction(node.obj_id)

		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_DISSOLVE_S, pkt)

		local obj = g_obj_mgr:get_obj(node.obj_id)
		if obj ~= nil and obj:get_type() == OBJ_TYPE_HUMAN then
			obj:set_faction({})
		end
	else
		g_cltsock_mgr:send_client(node.obj_id, CMD_M2B_FACTION_DISSOLVE_S, pkt)
	end
end

function Faction_mgr:dissolve_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " faction_dissolve failed! time out"
	g_faction_log:write(str)
end


--获取副本次数
function Faction_mgr:get_fb(obj_id,scene_id)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local count = faction:get_fb_count(scene_id)
		return count
	end
end


--设置副本次数
function Faction_mgr:set_fb(obj_id,scene_id)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local pkt = {}
		pkt.scene_id = scene_id
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_FB_SET_REQ, pkt)
		local node = {}
		node.obj_id = obj_id
		g_sock_event_mgr:add_event(obj_id, CMD_P2M_FACTION_FB_SET_REP, self, self.set_fb_process, self.set_fb_time_out, node, 6)
	end
end

function Faction_mgr:set_fb_process(node,pkt)
	
end

function Faction_mgr:set_fb_time_out(node,pkt)
	local str = ev.time .. " char_id:" ..node.obj_id .. " set_fb failed! time out"
	g_faction_log:write(str)
end

--统一加帮贡，建设度，科技点和帮派资金
function Faction_mgr:add_content(faction_id,pkt)
	local faction = self:get_faction_by_fid(faction_id)
	if faction ~= nil then
		pkt.faction_id = faction_id
		g_svsock_mgr:send_server_ex(COMMON_ID,0, CMD_M2P_FACTION_ADD_CONTENT_REQ, pkt)
	end
end

--帮派商人购买
function Faction_mgr:can_buy_item(obj_id,item_info,item_count)
	local player = g_obj_mgr:get_obj(obj_id)
	if not player then return end

	local pack_con = player:get_pack_con()
	if pack_con:check_money_lock(9) then
		return 
	end

	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local gold_level = item_info[3]
		local contribution = item_info[2] * item_count

		local f_gold_level = faction:get_gold_level()
		local f_contribution = faction:get_contribution(obj_id)

		--金库等级
		if f_gold_level < gold_level then return 26028 end
		--帮贡
		if f_contribution < contribution then return 26049 end
		--封闭状态
		if faction:get_dissolve_flag() == 1 then return 26047 end

		return 0
	end
end

--设置开关
function Faction_mgr:switch_fb(pkt)
	local faction = self:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then
		g_svsock_mgr:send_server_ex(COMMON_ID,0, CMD_M2P_FACTION_SWITCH_REQ, pkt)
	end
end


--使用道具取消退出帮派限定时间
function Faction_mgr:del_leave_time(obj_id)
	local leave_time, kick_time = self:get_leave_time(obj_id)

	if leave_time ~= 0 and leave_time + 12*60*60 > ev.time then
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_SET_LEAVE_TIME_REQ, {})
		return 0
	elseif kick_time ~= 0 and kick_time + 12*60*60 > ev.time then
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_SET_LEAVE_TIME_REQ, {})
		return 0
	else
		return 26053
	end
end

--查看别的帮派信息
function Faction_mgr:get_faction_info(obj_id,pkt)
	local faction = self:get_faction_by_fid(pkt.faction_id)
	if faction ~= nil then 
		local ret = faction:get_faction_info()
		g_cltsock_mgr:send_client(obj_id, CMD_M2B_FACTION_INFO2_S, ret)
	else
		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_INFO2_REQ, pkt)
	end
end

--帮主弹劾令
function Faction_mgr:impeach(obj_id)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		local player_list = faction:get_faction_player_list()
		local factioner_id = faction:get_factioner_id()
		if factioner_id == obj_id then return 26055 end
		local status = player_list[factioner_id].status
		if status == "0" then
			return 26056
		else
			local ret = {}
			ret.year = string.sub(status,1,4)
			ret.month = string.sub(status,6,7)
			ret.day = string.sub(status,9,10)

			ret.hour = string.sub(status,12,13)
			ret.min = string.sub(status,15,16)
			ret.second = string.sub(status,18,19)

			local time_old = os.time(ret)
			if time_old + 24 * 3600 * 3 < ev.time then
				g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_M2P_FACTION_IMPEACH_REQ, {})
			else
				return 26057
			end
			return 0
		end
	end
end

--帮派合并
function Faction_mgr:can_be_faction_merge(obj_id_s, obj_id_d)
	local my_faction = self:get_faction_by_cid(obj_id_s)
	if not my_faction then return 26064 end

	local other_faction = self:get_faction_by_cid(obj_id_d)
	if not other_faction then return 26065 end

	if my_faction:get_factioner_id() ~= obj_id_s or other_faction:get_factioner_id() ~= obj_id_d then return 26066 end
	if my_faction:get_faction_id() == other_faction:get_faction_id() then return 26061 end

	local my_faction_level = my_faction:get_level()
	local my_member_count = my_faction:get_member_count()
	local other_member_count = other_faction:get_member_count()
	local member_count = faction_update_loader.faction_list[my_faction_level][8]

	if member_count - my_member_count < other_member_count then return 26067 end

	if my_faction:get_dissolve_flag() == 1 then return 26068 end

	if App_filter:get_faction_id() == other_faction:get_faction_id() then return 26069 end

	return 0

end

--obj_id_s 为合并者 obj_id_d：为被合并者
function Faction_mgr:faction_merge(obj_id_s, obj_id_d)
	local pkt = {}
	pkt[1] = obj_id_s
	pkt[2] = obj_id_d
	g_svsock_mgr:send_server_ex(COMMON_ID,0, CMD_M2P_FACTION_MERGE_C, pkt)
end

--帮派改名
function Faction_mgr:change_name(char_id,f_name)
	local faction = self:get_faction_by_cid(char_id)
	if not faction then return 26072 end

	local factioner_id = faction:get_factioner_id()
	if factioner_id ~= char_id then return 26073 end

	for k,v in pairs(self.faction_list) do
		if v:get_faction_name() == name then
			return 26704
		end
	end

	if f_filter_world(f_name) then return 30013 end

	return 0
end

function Faction_mgr:del_relation(my_id,other_id)
	if self.faction_relate[my_id] ~= nil then
		self.faction_relate[my_id][other_id] = nil
	end
end

function Faction_mgr:add_relation(my_id,other_id,flag)
	if self.faction_relate[my_id] == nil then
		self.faction_relate[my_id] = {}
	end

	self.faction_relate[my_id][other_id] = flag
end

function Faction_mgr:get_faction_relate(faction_id)
	local ret = {}
	ret[1] = {}	--友好
	ret[2] = {}	--敌对
	ret[3] = {}	--所有
	for k,v in pairs(self.faction_relate[faction_id] or {}) do
		if v == 1 then
			table.insert(ret[1],k)
		elseif v == 2 then
			table.insert(ret[2],k)
		end
	end

	for m,n in pairs(self.faction_list or {}) do
		table.insert(ret[3],m)
	end

	return ret
end


function Faction_mgr:random_friend_manor(faction_id)
	local manor_l = g_faction_manor_mgr:get_faction_manor_l()
	local relate_l = self.faction_relate[faction_id] or {}
	local random_l = {}
	for k, v in pairs(self.faction_list or {}) do
		if manor_l[k] ~= nil and k ~= faction_id and (relate_l[k] == nil or relate_l[k] == 1) then
			table.insert(random_l, k)
		end
	end
	local len = #random_l
	if len > 0 then
		return random_l[crypto.random(1, len+1)]
	end
	return nil
end

function Faction_mgr:random_hostility_manor(faction_id)
	local manor_l = g_faction_manor_mgr:get_faction_manor_l()
	local relate_l = self.faction_relate[faction_id] or {}
	local random_l = {}
	for k, v in pairs(self.faction_list or {}) do
		if manor_l[k] ~= nil and k ~= faction_id and (relate_l[k] == nil or relate_l[k] == 2) then
			table.insert(random_l, k)
		end
	end
	local len = #random_l
	if len > 0 then
		return random_l[crypto.random(1, len+1)]
	end
	return nil
end

-- cailizhong添加
-- 往帮派仓库放入物品
function Faction_mgr:put_item_into_warehouse(obj_id, pkt)
	if obj_id==nil or pkt==nil or pkt.uuid==nil or pkt.count==nil then -- 参数错误
		return g_cltsock_mgr:send_client(obj_id, CMD_PUT_ITEM_INTO_WAREHOUSE_S, {["result"] = 31177})
	end
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then -- 人物不属于帮派
		--封闭状态
		if faction:get_dissolve_flag() == 1 then return 26047 end

		local player = g_obj_mgr:get_obj(obj_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if not pack_con then return end
		local t_item = pack_con:get_item_by_uuid(pkt.uuid, SYSTEM_BAG)
		-- 添加检查
		if not t_item then
			return g_cltsock_mgr:send_client(obj_id, CMD_PUT_ITEM_INTO_WAREHOUSE_S, {["result"] = 31162})
		end
		if t_item.item:get_bind() ~= 1 then -- 绑定物品不能放入帮派仓库
			return g_cltsock_mgr:send_client(obj_id, CMD_PUT_ITEM_INTO_WAREHOUSE_S, {["result"] = 31184})
		end
		pkt.item_id = t_item.item_id
		
		pkt.item_db = t_item.item:serialize_to_db()

		local e_code = pack_con:del_item_by_uuid(SYSTEM_BAG, pkt.uuid, pkt.count, {['type']=ITEM_SOURCE.FACTION_WAREHOUSE}) -- 扣除物品
		if e_code ~= 0 then --从背包扣物品失败
			return g_cltsock_mgr:send_client(obj_id, CMD_PUT_ITEM_INTO_WAREHOUSE_S, {["result"] = 31183})
		end
		g_svsock_mgr:send_server_ex(COMMON_ID, obj_id, CMD_PUT_ITEM_INTO_WAREHOUSE_M, pkt) -- 往common发送往仓库放入物品的消息
		local node = {}
		node.obj_id = obj_id
		g_sock_event_mgr:add_event(obj_id, CMD_PUT_ITEM_INTO_WAREHOUSE_C, self, self.put_item_success, self.put_item_time_out, node, 6)
	end
end

-- 放入物品成功
function Faction_mgr:put_item_success(node, pkt)
	if pkt.result ~= 0 then	
		return self:put_item_time_out(node, pkt)
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_PUT_ITEM_INTO_WAREHOUSE_S, pkt)
end

-- 放入物品超时
function Faction_mgr:put_item_time_out(node,pkt)
	local ret = {}
	if pkt~=nil and pkt.result~=nil then
		ret.result = pkt.result
	else
		ret.result = 31176
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_PUT_ITEM_INTO_WAREHOUSE_S, ret)
end

-- 设置物品价格
function Faction_mgr:set_item_price_warehouse(obj_id, pkt)
	if obj_id==nil or pkt==nil or pkt.uuid==nil or pkt.price==nil or pkt.price<0 then -- 参数错误
		return g_cltsock_mgr:send_client(obj_id, CMD_SET_ITEM_PRICE_WAREHOUSE_S, {["result"] = 31177})
	end
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		--封闭状态
		if faction:get_dissolve_flag() == 1 then return 26047 end

		local e_code = faction:is_warehouse_permission_ok(obj_id) -- 是否拥有权限
		if e_code ~= 0 then
			return g_cltsock_mgr:send_client(obj_id, CMD_SET_ITEM_PRICE_WAREHOUSE_S, {["result"] = 31178})
		end
		g_svsock_mgr:send_server_ex(COMMON_ID, obj_id, CMD_SET_ITEM_PRICE_WAREHOUSE_M, pkt) -- 往common发送设置物品价格的消息
		local node = {}
		node.obj_id = obj_id
		g_sock_event_mgr:add_event(obj_id, CMD_SET_ITEM_PRICE_WAREHOUSE_C, self, self.set_item_price_success, self.set_item_price_time_out, node, 6)
	end
end

-- 设置物品价格成功
function Faction_mgr:set_item_price_success(node, pkt)
	if pkt.result ~= 0 then	
		return self:set_item_price_time_out(node, pkt)
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_SET_ITEM_PRICE_WAREHOUSE_S, pkt)
end

-- 设置物品价格超时
function Faction_mgr:set_item_price_time_out(node, pkt)
	local ret = {}
	if pkt~=nil and pkt.result~=nil then
		ret.result = pkt.result
	else
		ret.result = 31179
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_SET_ITEM_PRICE_WAREHOUSE_S, ret)
end

-- 摧毁仓库物品
function Faction_mgr:destory_item_warehouse(obj_id, pkt)
	-- 是否需要再传递一个销毁个数
	if obj_id==nil or pkt==nil or pkt.uuid==nil then -- 参数错误
		return g_cltsock_mgr:send_client(obj_id, CMD_DESTORY_ITEM_WAREHOUSE_S, {["result"] = 31177})
	end
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		--封闭状态
		if faction:get_dissolve_flag() == 1 then return 26047 end

		local e_code = faction:is_warehouse_permission_ok(obj_id) -- 是否拥有权限
		if e_code ~= 0 then
			return g_cltsock_mgr:send_client(obj_id, CMD_DESTORY_ITEM_WAREHOUSE_S, {["result"] = 31180})
		end
		g_svsock_mgr:send_server_ex(COMMON_ID, obj_id, CMD_DESTORY_ITEM_WAREHOUSE_M, pkt) -- 往common发送往摧毁仓库物品的消息
		local node = {}
		node.obj_id = obj_id
		g_sock_event_mgr:add_event(obj_id, CMD_DESTORY_ITEM_WAREHOUSE_C, self, self.destory_item_success, self.destory_item_time_out, node, 6)
	end
end

-- 摧毁物品成功
function Faction_mgr:destory_item_success(node, pkt)
	if pkt.result ~= 0 then	
		return self:destory_item_time_out(node, pkt)
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_DESTORY_ITEM_WAREHOUSE_S, pkt)
end

-- 摧毁物品超时
function Faction_mgr:destory_item_time_out(node, pkt)
	local ret = {}
	if pkt~=nil and pkt.result~=nil then
		ret.result = pkt.result
	else
		ret.result = 31181
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_DESTORY_ITEM_WAREHOUSE_S, ret)
end

-- 从仓库取出物品
function Faction_mgr:get_item_from_warehouse(obj_id, pkt)
	if obj_id==nil or pkt==nil or pkt.uuid==nil or pkt.count==nil or pkt.count<=0 then -- 参数错误
		return g_cltsock_mgr:send_client(obj_id, CMD_GET_ITEM_FROM_WAREHOUSE_S, {["result"] = 31177})
	end
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		--封闭状态
		if faction:get_dissolve_flag() == 1 then return 26047 end
		-- 检查人物背包是否还有一个格子
		local player = g_obj_mgr:get_obj(obj_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		if pack_con:get_bag_free_slot_cnt() < 1 then
			local ret = {}
			ret.result = 43004
			return g_cltsock_mgr:send_client(obj_id, CMD_GET_ITEM_FROM_WAREHOUSE_S, ret)
		end

		g_svsock_mgr:send_server_ex(COMMON_ID,obj_id, CMD_GET_ITEM_FROM_WAREHOUSE_M, pkt) -- 向common请求物品
		local node = {}
		node.obj_id = obj_id
		g_sock_event_mgr:add_event(obj_id, CMD_GET_ITEM_FROM_WAREHOUSE_C, self, self.get_item_success, self.get_item_time_out, node, 6)
	end
end

-- 取出物品成功
function Faction_mgr:get_item_success(node, pkt)
	if pkt.result ~= 0 then	
		return self:get_item_time_out(node, pkt)
	end

	local e_code,item = Item_factory.clone(pkt.item_id, pkt.item_db)

	if e_code~= 0 then
		return g_cltsock_mgr:send_client(node.obj_id, CMD_GET_ITEM_FROM_WAREHOUSE_S, {["result"] = e_code})	
	end

	local item_list = {}
	if item:is_fashion() then -- 是时装
		item_list[1] = {}
		item_list[1].type = 2
		item_list[1].item = item
		item_list[1].number = tonumber(pkt.count)
	else
		item_list[1] = {}
		item_list[1].type = 1
		item_list[1].item_id = tonumber(pkt.item_id)
		item_list[1].number = tonumber(pkt.count)
	end
	local player = g_obj_mgr:get_obj(node.obj_id)
	if not player then return end
	local pack_con = player:get_pack_con()
	if not pack_con then return end
	local e_code = pack_con:check_add_item_l_inter_face(item_list) -- 检查能否添加物品
	if e_code ~= 0 then -- 背包满了
		local t_pkt = {}
		t_pkt.sender = -1
		t_pkt.recevier = node.obj_id
		t_pkt.title = f_get_string(2751)
		t_pkt.content = f_get_string(2753)
		t_pkt.item_id = pkt.item_id
		t_pkt.item_db = pkt.item_db
		t_pkt.number = tonumber(pkt.count)
		g_svsock_mgr:send_server_ex(COMMON_ID, node.obj_id, CMD_M2P_SEND_EMAIL_NO_BOX_S, t_pkt)
		return g_cltsock_mgr:send_client(node.obj_id, CMD_GET_ITEM_FROM_WAREHOUSE_S, {["result"] = 0})
	end

	if pkt.count == 1 then -- 单个物品或可能是带属性物品
		e_code = pack_con:add_by_item(item,{['type'] = ITEM_SOURCE.FACTION_WAREHOUSE})
	else
		e_code = pack_con:add_item_l(item_list, {['type'] = ITEM_SOURCE.FACTION_WAREHOUSE}, SYSTEM_BAG)
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_GET_ITEM_FROM_WAREHOUSE_S, {["result"] = e_code})
end

-- 取出物品超时
function Faction_mgr:get_item_time_out(node, pkt)
	local ret = {}
	if pkt~=nil and pkt.result~=nil then
		ret.result = pkt.result
	else
		ret.result = 31182
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_GET_ITEM_FROM_WAREHOUSE_S, ret)
end


-- 打开帮派资源互换面板
function Faction_mgr:open_resource_exchange(obj_id, pkt)
	if obj_id==nil then return g_cltsock_mgr:send_client(obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, {["result"] = 31211}) end
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		-- 封闭状态
		if faction:get_dissolve_flag() == 1 then return g_cltsock_mgr:send_client(obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, {["result"] = 26047}) end
		local node = {}
		node.obj_id = obj_id
		node.type = pkt.type
		g_svsock_mgr:send_server_ex(COMMON_ID, obj_id, CMD_FACTION_RESOURCE_EXCHANGE_M, pkt)
		g_sock_event_mgr:add_event(obj_id, CMD_FACTION_RESOURCE_EXCHANGE_C, self, self.open_resource_exchange_success, self.open_resource_exchange_time_out, node, 6)
	end
end

-- 帮派资源面板请求信息成功
function Faction_mgr:open_resource_exchange_success(node, pkt)
	if pkt.result ~= 0 then
		return self:open_resource_exchange_time_out(node, pkt)
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, pkt)
end

-- 帮派资源面板请求信息超时
function Faction_mgr:open_resource_exchange_time_out(node, pkt)
	local ret = {}
	if pkt~=nil and pkt.result~=nil then
		ret.result = pkt.result
	else
		ret.result = 31216
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, ret)
end

-- 帮派资源互换
function Faction_mgr:resource_exchange(obj_id, pkt)
	if obj_id==nil or pkt==nil or pkt.sell_type==nil or pkt.buy_type==nil or pkt.sell_cnt==nil or pkt.buy_cnt==nil then
		return g_cltsock_mgr:send_client(obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, {["result"] = 31211})
	end
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		-- 封闭状态
		if faction:get_dissolve_flag() == 1 then return g_cltsock_mgr:send_client(obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, {["result"] = 26047}) end
	--[[	if obj_id ~= faction:get_factioner_id() then -- 不是帮主不允许操作
			return g_cltsock_mgr:send_client(obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, {["result"] = 26036})
		end--]]
		local node = {}
		node.obj_id = obj_id
		-- 帮派资源互换后台流水用到char_name
		local player = g_obj_mgr:get_obj(obj_id)
		pkt.char_name = player:get_name()
		g_svsock_mgr:send_server_ex(COMMON_ID, obj_id, CMD_FACTION_RESOURCE_EXCHANGE_M, pkt)
		g_sock_event_mgr:add_event(obj_id, CMD_FACTION_RESOURCE_EXCHANGE_C, self, self.open_resource_exchange_success, self.open_resource_exchange_time_out, node, 6)
	end
end

-- 帮派资源互换成功
function Faction_mgr:resource_exchange_success(node, pkt)
	if pkt.result ~= 0 then
		return self:resource_exchange_time_out(node, pkt)
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, pkt)
end

-- 帮派资源互换超时
function Faction_mgr:resource_exchange_time_out(node, pkt)
	local ret = {}
	if pkt~=nil and pkt.result~=nil then
		ret.result = pkt.result
	else
		ret.result = 31212
	end
	g_cltsock_mgr:send_client(node.obj_id, CMD_FACTION_RESOURCE_EXCHANGE_S, ret)
end


-- 玩家选中帮派副本等级设置
function Faction_mgr:set_choose_fb_level(char_id, choose_fb_level)
	local faction = self:get_faction_by_cid(char_id)
	if faction then
		local faction_id = faction:get_faction_id()
		if faction_id then
			if 0 == faction:is_fb_permission_ok(char_id) then
				local ret = {}
				ret.choose_fb_level = choose_fb_level
				ret.faction_id = faction_id
				g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2P_FACTION_CHOOSE_FB_LEVEL_C, ret)
			else
				g_cltsock_mgr:send_client(char_id, CMD_CHOOSE_FACTION_FB_LEVEL_S, {["result"] = 0})
			end
		end
	end
end

function Faction_mgr:get_choose_fb_level(faction_id)
	local faction = self:get_faction_by_fid(faction_id)
	if faction then
		return faction:get_choose_fb_level() or 0
	end
end

--副本等级设置
function Faction_mgr:set_fb_level(faction_id, level)
	local faction = self:get_faction_by_fid(faction_id)
	if faction then
		local ret = {}
		ret.level = level
		ret.faction_id = faction_id

		g_svsock_mgr:send_server_ex(COMMON_ID, 0, CMD_M2P_FACTION_FB_LEVEL_C, ret)
	end
end

function Faction_mgr:get_fb_level(faction_id)
	local faction = self:get_faction_by_fid(faction_id)
	if faction then
		return faction:get_fb_level() or 0
	end
end

--获取帮派振奋buff等级
function Faction_mgr:get_inspire_buff(faction_id)
	local faction = self:get_faction_by_fid(faction_id)
	if faction then
		local book_practice = faction:get_book_practice()
		return book_practice[4] or 1
	end
end
