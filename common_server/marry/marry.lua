--2011-10-26
--chenxidu
--婚姻系统基类

local UPDATE_TIME = 3600 * 1   --过期刷新时间

Marry = oo.class(nil, "Marry")


function Marry:__init()

	--结婚
	self.total 		        = {}
	self.total.list         = {}
	self.total.C2M          = {}

	--征婚
	self.total.list_ex      = {} 

	self.update_time = ev.time + UPDATE_TIME

	--加载数据库
	self:load()
end

--加载数据
function Marry:load()
	local m_db   = f_get_db()
	local query1 = ""
	local query2 = ""
	local info   = {}

	local rs= Marry_db:LoadAllMarry()
	if rs then
		self.total.list    = {}
		for k,v in pairs(rs) do
			local marry = {}
			marry.uuid = v.uuid
			marry.char_id  = v.char_id		
			marry.mate_id  = v.mate_id
			marry.char_tm  = v.char_tm
			marry.mate_tm  = v.mate_tm
			marry.mate_uq  = v.mate_uq
			marry.char_uq  = v.char_uq
			marry.m_t      = v.m_t
			marry.m_h      = v.m_h 
			marry.m_k      = v.m_k
			marry.m_q      = v.m_q
			marry.m_b      = v.m_b

			--以下两个字段需要入库，开启后从数据库删除
			marry.m_i = v.m_i or 0
			marry.m_n = v.m_n or 0

			--以下只在内存不入库			 
			marry.c_tt = 0
			marry.m_tt = 0		
			marry.m_f = false  --是否开启副本
			--marry.m_i = 0      --结婚场景副本ID
			marry.m_x = 0      --副本是在哪条线开启
			marry.m_y = 0      --是否允许所有人都进入场景副本 0 批准 1 所有人可进
			--marry.m_n = 0      --结婚场景副本时长
			marry.m_o = 0      --结婚场景开始时间
			marry.m_w = {} 	--结婚场景物品列表(所选择购买的结婚物品)
			marry.m_l = {}		--允许进入场景列表
			marry.m_p = {}		--申请人列表
			marry.m_a = {}		--夫妻副本的id count 记录
			self.total.list[marry.uuid] = marry 
			self.total.C2M[marry.char_id] = marry
			self.total.C2M[marry.mate_id] = marry

			--设置婚姻字段			query1 = string.format("{id:%d}", v.char_id)			query2 = string.format("{id:%d}", v.mate_id)			info = {["married"] = 1}			info = Json.Encode(info)			m_db:update("characters", query1, info)
			m_db:update("characters", query2, info)

		end
	end

	local rs_ex= Marry_db:LoadAllMarryEx()
	if rs_ex then
		self.total.list_ex    = {}
		for k,v in pairs(rs_ex) do
			local marry = {}
			marry.char_id = v.char_id
			marry.tm = v.tm		
			marry.ts = v.ts
			marry.tz = v.tz
			local marry_item = Marry_item(marry)
			if marry_item then
				self.total.list_ex[marry.char_id] = marry_item 
			end
		end
	end
	return 
end

function Marry:get_click_param()
	return self, self.on_timer,3,nil
end

function Marry:on_timer()
	if ev.time > self.update_time then
		local list = self.total.list_ex
		if list ~= nil then 
			local del_list = {}
			local flags = false
			for k,v in pairs(list) do
				if v:is_expiredtime()then
					flags = true
					table.insert(del_list,v)
				end
			end
			if flags then
				self:delete_expired_marry(del_list)
			end
		end
		self.update_time = self.update_time + UPDATE_TIME
	end
end

--征婚信息过期
function Marry:delete_expired_marry(del_list)
	for k,v in pairs(del_list) do
		local item = {}
		item.char_id = v.char_id
		self:operate_send_db_ex(item,2)
		self:operate_send_list_ex(item,2)
	end
	return 
end

--获取列表发送给客户端
function Marry:get_marry_list()
	local arry = {}
	for k,v in pairs (self.total.list_ex or {}) do
			local item = {}
			item.char_id  = v.char_id
			item.name  = ""
			item.level =  0    
			item.occ   =  0 
			item.sex   =  0
			item.zhan  =  v.tz
			if v.char_id ~= 0 then
				item.occ   = g_player_mgr.all_player_l[v.char_id]["occ"]
				item.level = g_player_mgr.all_player_l[v.char_id]["level"]
				item.sex   = g_player_mgr.all_player_l[v.char_id]["gender"]
				item.name  = g_player_mgr.all_player_l[v.char_id]["char_nm"]
			end
			item.ts    =  v.ts 
			item.time  =  v.tm 
			table.insert(arry,item)
	end
	return arry
end

--组合成征婚包
function Marry:init_marry_pkt( char_id,pkt )
	local marry_item = {}
	marry_item.char_id = char_id
	--marry_item.tm = ev.time
	marry_item.ts = pkt.ts
	marry_item.tz = pkt.tz
	local item = Marry_item(marry_item)
	return item
end

--组合结婚婚包
function Marry:init_marry_ok_pkt(pkt )
	local marry_item = {}
	marry_item.uuid = crypto.uuid()
	marry_item.char_id   = pkt.char_id
	marry_item.mate_id   = pkt.mate_id
	marry_item.char_tm   = pkt.char_tm
	marry_item.mate_tm   = pkt.mate_tm
	marry_item.mate_uq  = pkt.mate_uq
	marry_item.char_uq  = pkt.char_uq
	marry_item.m_t = ev.time
	marry_item.m_h = pkt.m_h
	marry_item.m_k = pkt.m_k
	marry_item.m_q = pkt.m_q
	marry_item.m_b = pkt.m_b

	marry_item.m_i = pkt.m_i      --结婚场景副本ID
	marry_item.m_n = pkt.m_n      --结婚场景副本时长

	--以下只在内存不入库
	marry_item.c_tt = 0
	marry_item.m_tt = 0	
	marry_item.m_f = false  --是否开启副本
	--marry_item.m_i = 0      --结婚场景副本ID
	marry_item.m_x = 0      --副本是在哪条线开启
	marry_item.m_y = 1      --是否允许所有人都进入场景副本 0 批准 1 所有人可进
	--marry_item.m_n = 0      --结婚场景副本时长
	marry_item.m_o = 0      --结婚场景开始时间
	marry_item.m_w = {} 	--结婚场景物品列表(所选择购买的结婚物品)
	marry_item.m_l = {}		--允许进入场景列表
	marry_item.m_p = {}		--申请人列表
	marry_item.m_a = {}		--夫妻副本的id count 记录

	return marry_item
end

--查看是有已经有征婚信息 + 是否已经结婚
function Marry:insert_send_db( char_id,pkt )
	if self:is_send(char_id) == false then
		local marry_item = self:init_marry_pkt(char_id,pkt)
		self:operate_send_db_ex(marry_item,0)
		self:operate_send_list_ex(marry_item,0)
		return true
	end
	return false
end

--删除或者更新自己的征婚信息
function Marry:is_can_update( char_id,pkt)
	if self:is_send(char_id) == false then
		return false
	end
	local marry_item = self:init_marry_pkt(char_id,pkt)
	if pkt.type == 0 then
		self:operate_send_db_ex(marry_item,1)
		self:operate_send_list_ex(marry_item,1)
	elseif pkt.type == 1 then
		self:operate_send_db_ex(marry_item,2)
		self:operate_send_list_ex(marry_item,2)
	end
	return true	
end

--是否已经发布征婚
function Marry:is_send(char_id)
	if self.total.list_ex[char_id] then
		return true
	else
		return false
	end
end

--是否已经结婚
function Marry:is_marry(char_id,mate_id)
	if 	self.total.C2M[char_id] or self.total.C2M[mate_id] then 
		return true
	else	
		return false	
	end
end

--插入结婚列表 type = 0  插入 1 更新 2 删除
function Marry:operate_send_list(item,type)
	if type == 0 then
		self.total.list[item.uuid] = item	
		self.total.C2M[item.char_id] = item
		self.total.C2M[item.mate_id] = item		
	end

	if type == 1 then
		self.total.list[item.uuid] = item
		self.total.C2M[item.char_id] = item
		self.total.C2M[item.mate_id] = item					
	end

	if type == 2 then
		self.total.list[item.uuid] = nil
		self.total.C2M[item.char_id] = nil
		self.total.C2M[item.mate_id] = nil				
	end

	--更新到map数据列表(单个更新到MAP)
	if type == 0 or type == 1 then
		local ret = {}
		ret.type = 22
		ret.item = {}
		ret.item = item
			 
		ret.item.c_occ =  0  --主方的职业  
		ret.item.c_lev =  0 
		ret.item.c_sex =  0

		ret.item.m_occ =  0  --一方方的职业  
		ret.item.m_lev =  0 
		ret.item.m_sex =  0

		ret.item.m_ll  = {}
		for k,v in pairs(ret.item.m_p or {}) do
			local it = {}
			it.char_id   = v
			local name = g_player_mgr:char_id2nm(v)
			it.char_name = name
			table.insert(ret.item.m_ll,it)
		end	

		if ret.item.mate_id ~= 0 then
			ret.item.m_occ = g_player_mgr.all_player_l[ret.item.mate_id]["occ"]
			ret.item.m_lev = g_player_mgr.all_player_l[ret.item.mate_id]["level"]
			ret.item.m_sex = g_player_mgr.all_player_l[ret.item.mate_id]["gender"]
			ret.item.mate_name = g_player_mgr.all_player_l[ret.item.mate_id]["char_nm"]
		end

		--防止改名道具
		if ret.item.char_id then
			ret.item.c_occ = g_player_mgr.all_player_l[ret.item.char_id]["occ"]
			ret.item.c_lev = g_player_mgr.all_player_l[ret.item.char_id]["level"]
			ret.item.c_sex = g_player_mgr.all_player_l[ret.item.char_id]["gender"]
			ret.item.char_name = g_player_mgr.all_player_l[ret.item.char_id]["char_nm"]
		end

		g_server_mgr:send_to_all_map(0,CMD_P2M_MARRY_UPDATE_S,ret)
	elseif type == 2 then
		local ret = {}
		ret.type = 222
		ret.item = {}
		ret.item = item
		g_server_mgr:send_to_all_map(0,CMD_P2M_MARRY_UPDATE_S,ret)
	end

end

function Marry:operate_send_list_ex(item,type)
	local item_new = Marry_item(item)
	if type == 0 then
		self.total.list_ex[item_new.char_id] = item_new
	end

	if type == 1 then
		self.total.list_ex[item_new.char_id] = item_new
	end

	if type == 2 then
		self.total.list_ex[item_new.char_id] = nil
	end
	
	--同步到MAP
	if type == 0 or type == 1 then
		local ret = {}
		ret.type = 11
		ret.item = {}
		ret.item = item_new
		ret.item.name  = ""
		ret.item.level =  0    
		ret.item.occ   =  0 
		ret.item.sex   =  0
		ret.item.zhan  =  0
		if ret.item.char_id ~= 0 then
			ret.item.occ   = g_player_mgr.all_player_l[item_new.char_id]["occ"]
			ret.item.level = g_player_mgr.all_player_l[item_new.char_id]["level"]
			ret.item.sex   = g_player_mgr.all_player_l[item_new.char_id]["gender"]
			ret.item.name  = g_player_mgr.all_player_l[item_new.char_id]["char_nm"]
		end
		g_server_mgr:send_to_all_map(0,CMD_P2M_MARRY_UPDATE_S,ret)
	else
		local ret = {}
		ret.type = 111
		ret.item = {}
		ret.item = item_new
		g_server_mgr:send_to_all_map(0,CMD_P2M_MARRY_UPDATE_S,ret)
	end

end

--插入已经征婚数据库列表 type = 0  插入 1 更新 2 删除 
function Marry:operate_send_db(item,type)
	if type == 0 then
		Marry_db:SaleMarry(item)

		--结婚后台日志
		local new_item = {}
		new_item.char_id = item.char_id
		new_item.char_name = g_player_mgr.all_player_l[item.char_id]["char_nm"]
		new_item.mate_id = item.mate_id
		new_item.mate_name = g_player_mgr.all_player_l[item.mate_id]["char_nm"]
		self:insert_mysql_log(new_item,1,ev.time)
		print("create marry log ",j_e(new_item),ev.time)
	end

	if type == 1 then
		if item.char_id and item.mate_id then
			Marry_db:UpdateMarry(item)
		end	
	end

	if type == 2 then
		Marry_db:DeleteMarry(item.char_id)
	end
end

function Marry:operate_send_db_ex(item,type)
	if type == 0 then
		Marry_db:SaleMarryEx(item)
	end

	if type == 1 then
		Marry_db:UpdateMarryEx(item)
	end

	if type == 2 then
		Marry_db:DeleteMarryEx(item.char_id)
	end
end

--重启同步到各个MPA(同步已经结婚+征婚的数据)
function Marry:send_all_marry_info(server_id)
	local ret = {}
	ret.type = 2
	ret.all_list = {}
	ret.all_list = self.total.list
	for k,v in pairs(ret.all_list or {})do
		 
		v.c_occ =  0  --主方的职业  
		v.c_lev =  0 
		v.c_sex =  0

		v.m_occ =  0  --一方方的职业  
		v.m_lev =  0 
		v.m_sex =  0

		v.m_ll  = {}
		for kk,vv in pairs(v.m_p or {}) do
			local item = {}
			item.char_id   = vv
			local name = g_player_mgr:char_id2nm(vv)
			item.char_name = name
			table.insert(v.m_ll,item)
		end	

		if v.mate_id ~= 0 then
			v.m_occ = g_player_mgr.all_player_l[v.mate_id]["occ"]
			v.m_lev = g_player_mgr.all_player_l[v.mate_id]["level"]
			v.m_sex = g_player_mgr.all_player_l[v.mate_id]["gender"]
			v.mate_name = g_player_mgr.all_player_l[v.mate_id]["char_nm"]
		end

		--防止改名道具
		if v.char_id then
			v.c_occ = g_player_mgr.all_player_l[v.char_id]["occ"]
			v.c_lev = g_player_mgr.all_player_l[v.char_id]["level"]
			v.c_sex = g_player_mgr.all_player_l[v.char_id]["gender"]
			v.char_name = g_player_mgr.all_player_l[v.char_id]["char_nm"]
		end
	end
	g_server_mgr:send_to_server(server_id,0,CMD_P2M_MARRY_INFO_S,ret)

	--征婚信息
	local ret_ex = {}
	ret_ex.type = 1
	ret_ex.all_list = {}
	for k,v in pairs (ret_ex.all_list or {}) do
		local item = {}
		item = v
		item.name  = ""
		item.level =  0    
		item.occ   =  0 
		item.sex   =  0
		item.zhan  =  0
		if item.char_id ~= 0 then
			item.occ   = g_player_mgr.all_player_l[item.char_id]["occ"]
			item.level = g_player_mgr.all_player_l[item.char_id]["level"]
			item.sex   = g_player_mgr.all_player_l[item.char_id]["gender"]
			item.name  = g_player_mgr.all_player_l[item.char_id]["char_nm"]
		end
		table(ret_ex.all_list,item)
	end

	g_server_mgr:send_to_server(server_id,0,CMD_P2M_MARRY_INFO_S,ret_ex)
end

--成功结婚
function Marry:create_marry(pkt)
	pkt.char_name = g_player_mgr.all_player_l[pkt.char_id]["char_nm"]
	pkt.mate_name = g_player_mgr.all_player_l[pkt.mate_id]["char_nm"]

	--首先删除征婚列表里有的内容
	local item_c = self.total.list_ex[pkt.char_id]
	if item_c then
		self:operate_send_db_ex(item_c,2)
		self:operate_send_list_ex(item_c,2)
	end

	local item_m = self.total.list_ex[pkt.mate_id]
	if item_m then
		self:operate_send_db_ex(item_m,2)
		self:operate_send_list_ex(item_m,2)
	end

	--入库操作
	local marry_item = self:init_marry_ok_pkt(pkt)
	self:operate_send_db(marry_item,0)
	self:operate_send_list(marry_item,0)

	--世界广播
	local pkt_new = {}
	pkt_new.char_name = pkt.char_name
	pkt_new.mate_name = pkt.mate_name
	pkt_new.type = 0
	pkts = Json.Encode(pkt_new)
	for k , v in pairs(g_player_mgr.online_player_l) do
		g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_NOTICE_MARRY_S, pkts, true)
	end

	--向聊天服获取玩家好友的列表
	local id_list = {}
	id_list.l_id   = pkt.char_id
	id_list.l_name = pkt.char_name
	id_list.l_list = {}

	id_list.r_id   = pkt.mate_id
	id_list.r_name = pkt.mate_name
	id_list.r_list = {}
	g_svsock_mgr:send_server_ex(WORLD_ID,pkt.char_id,CMD_W2C_GET_FRIEND_LIST_C, id_list)

	return true
end

--邮件通知好友
function Marry:email_notice( list,char_name ,mate_name,id_l,id_r)
	----邮件通知
	local spk = {}
	spk.title   = f_get_string(2550) 
	spk.content = string.format(f_get_string(2551),char_name,mate_name)
	for k,v in pairs( list or {}) do
		if v ~= id_l and v ~= id_r then
			local g_email = Email(-1,v,spk.title,spk.content,0,Email_type.type_annex,Email_sys_type.type_sys,nil)
			if g_email ~= nil then
				g_email_mgr:add_email(g_email)
			end
		end
	end
end

function Marry:get_friend_list(pkt)	
	self:email_notice(pkt.l_list,pkt.l_name,pkt.r_name,pkt.r_id,pkt.l_id)
	self:email_notice(pkt.r_list,pkt.r_name,pkt.l_name,pkt.r_id,pkt.l_id)
end

--接受map过来的同步信息 result = 0 修改 1 删除 2 第一次结婚广播 3 重办广播 4 系统邮件通知双方解除婚姻关系 5批准进入场景
function Marry:receive_map_list(id,char_id,pkt)
	local item = self.total.C2M[char_id]
	--更新婚姻列表和数据库
	if pkt.result == 0 then
		self:operate_send_db(pkt.item,1)
		self:operate_send_list(pkt.item,1)
	elseif pkt.result == 1 then
		self:operate_send_db(pkt.item,2)
		self:operate_send_list(pkt.item,2)

		local new_item = {}
		new_item.char_id = pkt.item.char_id
		new_item.char_name = g_player_mgr.all_player_l[pkt.item.char_id]["char_nm"]
		new_item.mate_id = pkt.item.mate_id
		new_item.mate_name = g_player_mgr.all_player_l[pkt.item.mate_id]["char_nm"]

		--离婚
		if g_player_mgr:is_online_char(pkt.item.char_id) then				local line = g_player_mgr:get_char_line(pkt.item.char_id)			local pkt_t = {}			pkt_t.char_id = pkt.item.char_id			g_server_mgr:send_to_server(line, pkt.item.char_id, CMD_P2M_SET_RING_DB, pkt_t) 		else
			self:set_break_marry(pkt.item.char_id)
		end

		if g_player_mgr:is_online_char(pkt.item.mate_id) then				local line = g_player_mgr:get_char_line(pkt.item.mate_id)			local pkt_t = {}			pkt_t.char_id = pkt.item.mate_id			g_server_mgr:send_to_server(line, pkt.item.mate_id, CMD_P2M_SET_RING_DB, pkt_t) 		else
			self:set_break_marry(pkt.item.mate_id)
		end

		--写后台日志
		self:insert_mysql_log(new_item,2,ev.time)

		--邮件通知
		local spk = {}
		spk.title   = f_get_string(2556) 
		spk.content = string.format(f_get_string(2557))
		local list = {}
		table.insert(list,pkt.item.char_id)
		table.insert(list,pkt.item.mate_id)
		for k,v in pairs( list or {}) do
			if v ~= id_l and v ~= id_r then
				local g_email = Email(-1,v,spk.title,spk.content,0,Email_type.type_annex,Email_sys_type.type_sys,nil)
				if g_email ~= nil then
					g_email_mgr:add_email(g_email)
				end
			end
		end

		--给对方通知
		local ret = {}
		ret.char_id = pkt.item.char_id
		ret.mate_id = pkt.item.mate_id
		ret.uuid    = pkt.item.uuid
		g_server_mgr:send_to_all_map(0,CMD_P2M_BREAK_MARRY_REP,ret)
	elseif pkt.result == 2 then
		--第一次举办婚礼
		local add = pkt.item.m_q_add
		pkt.item.m_q = pkt.item.m_q + add
		self:operate_send_db(pkt.item,1)
		self:operate_send_list(pkt.item,1)

		--local pkt_new = {}
		--pkt_new.char_name = pkt.item.char_name
		--pkt_new.mate_name = pkt.item.mate_name
		--pkt_new.type =2
		--pkts = Json.Encode(pkt_new)
		--for k , v in pairs(g_player_mgr.online_player_l) do
			--g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_NOTICE_MARRY_S, pkts, true)
		--end

		local ret = {}
		ret.char_id = pkt.item.char_id
		ret.mate_id = pkt.item.mate_id
		ret.list    = pkt.item.m_w
		g_server_mgr:send_to_all_map(0,CMD_P2M_FIRST_MARRY_REP,ret)
	elseif pkt.result == 3 then
		--重办婚礼
		if self:check_again_marry(pkt.char_id) == true then
			self:operate_send_db(pkt.item,1)
			self:operate_send_list(pkt.item,1)
			--世界广播
			local pkt_new = {}
			pkt_new.char_name = pkt.item.char_name
			pkt_new.mate_name = pkt.item.mate_name
			pkt_new.type = 1
			pkts = Json.Encode(pkt_new)
			for k , v in pairs(g_player_mgr.online_player_l) do
				g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_NOTICE_MARRY_S, pkts, true)
			end

			local ret = {}
			ret.char_id = pkt.item.char_id
			ret.mate_id = pkt.item.mate_id
			g_server_mgr:send_to_all_map(0,CMD_P2M_AGAIN_MARRY_REP,ret)
		else
			--要返回钱给没有成功重办婚礼的一方
			local ret = {}
			ret.char_id = pkt.char_id
			ret.money   = pkt.money
			g_server_mgr:send_to_all_map(0,CMD_P2M_AGAIN_CHECK_REP,ret)
		end
	elseif pkt.result == 4 then
		--系统解除婚姻(已经有邮件通知，不用及时通知个人)
		self:operate_send_db(pkt.item,2)
		self:operate_send_list(pkt.item,2)

		local new_item = {}
		new_item.char_id = pkt.item.char_id
		new_item.char_name = g_player_mgr.all_player_l[pkt.item.char_id]["char_nm"]
		new_item.mate_id = pkt.item.mate_id
		new_item.mate_name = g_player_mgr.all_player_l[pkt.item.mate_id]["char_nm"]

		--离婚
		if g_player_mgr:is_online_char(pkt.item.char_id) then				local line = g_player_mgr:get_char_line(pkt.item.char_id)			local pkt_t = {}			pkt_t.char_id = pkt.item.char_id			g_server_mgr:send_to_server(line, pkt.item.char_id, CMD_P2M_SET_RING_DB, pkt_t) 		else
			self:set_break_marry(pkt.item.char_id)
		end

		if g_player_mgr:is_online_char(pkt.item.mate_id) then				local line = g_player_mgr:get_char_line(pkt.item.mate_id)			local pkt_t = {}			pkt_t.char_id = pkt.item.mate_id			g_server_mgr:send_to_server(line, pkt.item.mate_id, CMD_P2M_SET_RING_DB, pkt_t) 		else
			self:set_break_marry(pkt.item.mate_id)
		end

		--写后台日志
		self:insert_mysql_log(new_item,2,ev.time)

		--邮件通知
		local spk = {}
		spk.title   = f_get_string(2554) 
		spk.content = string.format(f_get_string(2555))
		local list = {}
		table.insert(list,pkt.item.char_id)
		table.insert(list,pkt.item.mate_id)
		for k,v in pairs( list or {}) do
			if v ~= id_l and v ~= id_r then
				local g_email = Email(-1,v,spk.title,spk.content,0,Email_type.type_annex,Email_sys_type.type_sys,nil)
				if g_email ~= nil then
					g_email_mgr:add_email(g_email)
				end
			end
		end

		--同步到两个人
		local ret = {}
		ret.char_id = pkt.item.char_id
		ret.mate_id = pkt.item.mate_id
		ret.uuid    = pkt.item.uuid
		g_server_mgr:send_to_all_map(0,CMD_P2M_BREAK_MARRY_REP,ret)
	elseif pkt.result == 5 then
		--批准游客进入场景
		local list = {}
		for _, obj_id in ipairs(pkt.item.m_l or {}) do			list[obj_id] = true		end

		for _,v in pairs (pkt.item.char_list or {}) do
			if not list[v] then
				table.insert(pkt.item.m_l, v)	
			end
		end

		local char_map = {}		for _, obj_id in ipairs(pkt.item.char_list or {}) do			char_map[obj_id] = true		end				local no_map = {}		for _, obj_id in ipairs(pkt.item.no_list or {}) do			no_map[obj_id] = true		end		local new_mp = {}		if pkt.item.char_list and pkt.item.no_list then			for _,vvv in pairs(pkt.item.m_p or {}) do				if not char_map[vvv] and  not no_map[vvv] then					table.insert(new_mp, vvv)				end			end		end

		pkt.item.m_p = new_mp

		self:operate_send_list(pkt.item,1)
		
		local ret = {}
		ret.list  = {}
		ret.nlist = {}
		ret.info  = {}
		ret.info  = pkt.item

		for k,v in pairs(pkt.item.char_list or {}) do
			table.insert(ret.list,v)
		end

		for k,v in pairs(pkt.item.no_list or {}) do
			table.insert(ret.nlist,v)
		end
		if ret.list ~= nil then
			g_server_mgr:send_to_all_map(0,CMD_P2M_MARRY_QUEST_REP,ret)
		end

		if ret.nlist ~= nil then
			g_server_mgr:send_to_all_map(0,CMD_P2M_MARRY_QUEST_REP,ret)
		end
	elseif pkt.result == 6 then
		--增加亲密度
		local add = pkt.item.m_q_add
		item.m_q = item.m_q + add
		self:operate_send_db(item,1)
		self:operate_send_list(item,1)

		--日志
		local pkt = {}
		pkt.char_id = char_id
		if char_id == item.char_id then
			pkt.char_name = item.char_name
		else
			pkt.char_name = item.mate_name
		end
		self:insert_mysql_intimacy_log(pkt,1,1,add,item.m_q)

		--同步到两个人
		local ret = {}
		ret.char_id = item.char_id
		ret.mate_id = item.mate_id
		g_server_mgr:send_to_all_map(0,CMD_P2M_ADD_QINMIDU_REP,ret)
	elseif pkt.result == 7 then
		--升级婚戒
		self:operate_send_db(pkt.item,1)
		self:operate_send_list(pkt.item,1)

		--同步到当前玩家
		--local ret = {}
		--ret.char_id = add_id
		--g_server_mgr:send_to_all_map(0,CMD_P2M_UPDADA_RING_REP,ret)
	end
end

--离婚询问
function Marry:break_marry_quest(pkt)
	if pkt.char_id == nil then return end
	if g_player_mgr.online_player_l[pkt.recv] ~= nil then
		pkt.result = 1 
		g_server_mgr:send_to_all_map(0,CMD_P2M_BREAK_MARRY_EX_REP,pkt)	
	else
		pkt.result = 2
		g_server_mgr:send_to_all_map(0,CMD_P2M_BREAK_MARRY_EX_REP,pkt)	
	end
end

function Marry:break_marry_answer(pkt)
	g_server_mgr:send_to_all_map(0,CMD_P2M_BREAK_MARRY_EN_REP,pkt)		
end

--检测是否可以重办婚姻
function Marry:check_again_marry( char_id )
	local item = self.total.C2M[char_id]
	if item == nil then return false end

	if (item.m_o ~= 0 and item.m_o + item.m_n <= ev.time) or (item.m_o == 0 and item.m_n ==0) then
		return true 
	end

	return false 
end

--婚姻接口
function Marry:set_break_marry(char_id)
	local m_db = f_get_db()	local query = string.format("{id:%d}",char_id)	local info = {["married"] = 0}	info = Json.Encode(info)	m_db:update("characters", query, info)
end

--获取对方婚姻接口
function Marry:get_marry_char_id(char_id)
	local item = self.total.C2M[char_id]
	if item == nil then return nil end

	if char_id == item.char_id then
		return item.mate_id
	elseif char_id == item.mate_id then
		return item.char_id
	end
	return nil
end

--结婚离婚流水
function Marry:insert_mysql_log(pkt,type,time)	
	if pkt then
		local str = string.format(
			"insert into log_marry set char_id = %d,char_name = '%s',partner_id = %d,partner_name = '%s',type = %d,time = %d",
				pkt.char_id,
				pkt.char_name,
				pkt.mate_id,
				pkt.mate_name,
				type,
				time)
		g_web_sql:write(str) 
		end
end

function Marry:insert_mysql_intimacy_log(pkt,type,io,count,current)	
	if pkt then
		local str = string.format(
			"insert into log_intimacy set char_id = %d,char_name = '%s',type =%d,io = %d,intimacy = %d,current_intimacy = %d,time =%d",
				pkt.char_id,
				pkt.char_name,
				type,
				io,
				count,
				current,
				ev.time)
				g_web_sql:write(str) 
	end
end