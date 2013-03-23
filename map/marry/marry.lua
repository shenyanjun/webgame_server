--2011-10-26
--chenxidu
--婚姻列表同步到map

Marry = oo.class(nil, "Marry")
local integral_func=require("mall.integral_func")

local marry_info = require("config.loader.marry_dialogue_loader")

function Marry:__init()

	--总的婚姻条目表信息
	self.total 		   = {}
	self.total.list    = {}
	self.total.C2M     = {}
	self.total.list_ex = {}

end

--一下同步函数类型 syn_comm_list 0 更新修改 1 删除 2 第一次结婚广播 3 重办广播 4 系统邮件通知双方解除婚姻关系 5批准进入场景
-- 6 增加婚姻亲密度同步
-- 7 婚戒升级

--玩家上线 
function Marry:online(obj_id)
	--发送玩家的婚姻信息
	local player = g_obj_mgr:get_obj(obj_id) 
	if player == nil then return end
	local info = self:get_marry_info(obj_id) 
	if info ~= nil then
		for k,v in pairs(info.m_a or {}) do
			local time = v.time
			if time < ev.time then
				v.time = 0 
				self:syn_comm_list(info,0,nil)
			end
		end 
		player:on_dress_update(15)	
		player:on_update_attribute_no_change()
		g_cltsock_mgr:send_client(obj_id, CMD_M2B_MARRY_PLAYER_INFO_S, info)

		--多少天没上线提示
		if obj_id == info.char_id then
			if info.char_tm >0 and self:is_other_day(1,info.char_tm) == true then
				info.c_tt = 0
			end
			if info.mate_tm >0 and ev.time > info.mate_tm + 3*86400 and info.c_tt == 0 then
				local ret = {}
				ret.name = info.mate_name 
				ret.day  = (ev.time - info.mate_tm)/86400
				ret.day  = math.floor(ret.day) 
				g_cltsock_mgr:send_client(obj_id, CMD_MARRY_DATA_S, ret)
				info.c_tt = 1
				self:syn_comm_list(info,0,nil)
			end
			--如果大于30天强制解除婚姻关系
			if info.mate_tm > 0 and ev.time > info.mate_tm + 30*86400 then
				self:syn_comm_list(info,4,nil)	
			end
		else
			if info.mate_tm >0 and self:is_other_day(1,info.mate_tm) == true then
				info.m_tt = 0
			end
			if info.char_tm >0 and ev.time > info.char_tm + 3*86400 and info.m_tt == 0 then
				local ret = {}
				ret.name = info.char_name 
				ret.day  = (ev.time - info.char_tm)/86400
				ret.day  = math.floor(ret.day) 
				g_cltsock_mgr:send_client(obj_id, CMD_MARRY_DATA_S, ret)
				info.m_tt = 1
				self:syn_comm_list(info,0,nil)
			end
			--如果大于30天强制解除婚姻关系
			if  info.char_tm > 0 and ev.time > info.char_tm + 30*86400 then
				self:syn_comm_list(info,4,nil)	
			end
		end
	end
end

--上线第2天清零 time 上次离线时间
function Marry:get_day_time( time )	local l_time = time	local time_today ={}	time_today.year = os.date("%Y",l_time)	time_today.month = os.date("%m",l_time)	time_today.day = os.date("%d",l_time)	time_today.hour = 0	time_today.minute = 0	time_today.second = 0	local t_time = os.time(time_today)	return t_timeendfunction Marry:is_other_day(num,time)     --上线时判断	if num == nil then num = 1 end	if ev.time >= self:get_day_time(time) + num * 86400 then		return true	end	return falseend

--玩家申请结婚
function Marry:quest_create_marry(pkt)
	--查询两人是否已经结婚
	if self:is_marry(pkt.char_id,pkt.mate_id) == false then
		--首先询问另外一方
		local new_pkt = {}
		new_pkt.char_id = pkt.char_id
		new_pkt.mate_id = pkt.mate_id
		new_pkt.money   = pkt.money
		g_cltsock_mgr:send_client(pkt.mate_id, CMD_MARRY_QUEST_S, new_pkt)
	else
		return false
	end
end

--对方同意结婚(二者必须在同一线操作，所以不需要COMM服中转)
function Marry:answer_create_marry( pkt )
	local player_l = g_obj_mgr:get_obj(pkt.char_id)
	if player_l == nil then 
		g_cltsock_mgr:send_client(pkt.mate_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22499})
		return
	else
		--扣除队长的铜币(保证先付钱后给货)
		local pack_con = player_l:get_pack_con()
		if pack_con == nil then
			g_cltsock_mgr:send_client(pkt.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22503})	
			return
		end

		local money_list = {}
		money_list[MoneyType.GIFT_GOLD] = 990000
		local e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=(MONEY_SOURCE.MARRY)},1)
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(pkt.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=22503})
			return
		end		
	end

	local pkt_new = {}
	pkt_new.char_id = pkt.char_id
	pkt_new.mate_id = pkt.mate_id
	pkt_new.m_t     = 0             --结婚时间
	pkt_new.m_h     = 1
	pkt_new.m_k     = 0 
	pkt_new.m_q     = 0             --铜币结婚不送亲密度
	pkt_new.m_b     = 0
	pkt_new.char_tm = 0
	pkt_new.mate_tm = 0
	pkt_new.char_uq = 0
	pkt_new.mate_uq = 0

	pkt_new.money = pkt.money
	g_svsock_mgr:send_server_ex(COMMON_ID,pkt.char_id, CMD_M2P_MARRY_CREATE_REQ, pkt_new)
end

--成功结婚
function Marry:create_marry( pkt )
	if pkt.result == 0  then
		local player_l = g_obj_mgr:get_obj(pkt.char_id)
		if player_l then
			local l_j = player_l:get_ring()
			if l_j == 0 then
				player_l:set_ring_info(1)				
			end
			player_l:set_married()
			player_l:on_update_attribute()			
		end

		local player_r = g_obj_mgr:get_obj(pkt.mate_id)
		if player_r then
			local l_j = player_r:get_ring()
			if l_j == 0 then
				player_r:set_ring_info(1)		
			end
			player_r:set_married()
			player_r:on_update_attribute()		
		end

		--发送玩家的婚姻信息
		self:online(pkt.char_id)
		self:online(pkt.mate_id)

		--队长处弹出提示框,让队长在婚姻商城购买物品
		local pkt_new = {}
		pkt_new.money  = 0
		pkt_new.char_id = pkt.char_id
		pkt_new.mate_id = pkt.mate_id
		g_cltsock_mgr:send_client(pkt.char_id, CMD_M2B_MARRY_MONEY_S, pkt_new)
	else
		g_cltsock_mgr:send_client(pkt.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=pkt.result})	
	end
end

--接受公共服征婚和结婚数据
function Marry:serialize_from_common_server(pkt)
	if pkt.type == 1 then
		self.total.list_ex    = {}
		for k,v in pairs( pkt.all_list or {})do
			self.total.list_ex[v.char_id] = v
		end
	elseif pkt.type == 11 then
		self.total.list_ex[pkt.item.char_id] = pkt.item
	elseif pkt.type == 111 then
		self.total.list_ex[pkt.item.char_id] = nil
	elseif pkt.type == 2 then
		self.total.list = {}
		self.total.C2M  = {}
		for k,v in pairs( pkt.all_list or {})do
			self.total.list[v.uuid]   = v
			self.total.C2M[v.char_id] = v
			self.total.C2M[v.mate_id] = v
		end
	elseif pkt.type == 22 then
		self.total.list[pkt.item.uuid]   = pkt.item
		self.total.C2M[pkt.item.char_id] = pkt.item
		self.total.C2M[pkt.item.mate_id] = pkt.item
		self:check_push(pkt.item)
	elseif pkt.type == 222 then
		self.total.list[pkt.item.uuid]   = nil
		self.total.C2M[pkt.item.char_id] = nil
		self.total.C2M[pkt.item.mate_id] = nil
	end
end

--推送结婚信息
function Marry:check_push( info )
	if info.m_x > 0 and info.m_o + info.m_n >= ev.time then
		local ret = {}
		ret.list = self:get_marry_fb_list()
		if #ret.list > 0 then
			ret.result = 0
			ret = Json.Encode(ret)
			local online_players = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
			for k, v in pairs(online_players or {}) do
				g_cltsock_mgr:send_client(v:get_id(), CMD_GET_MARRY_FB_LIST_S, ret, true)
			end
		end
	end
end


--查询某人是否发布征婚
function Marry:is_send( char_id )
	if self.total.list_ex[char_id] then
		return true
	else
		return false
	end
end

--查询某人是否结婚
function Marry:is_marry( char_id,mate_id )
	if self.total.C2M[char_id] or self.total.C2M[mate_id] then
		return true
	else
		return false
	end
end

--获取列表发送给客户端
function Marry:get_marry_info(obj_id)
	return self.total.C2M[obj_id] 
end

--根据结婚id反回信息
function Marry:get_marry_info_ex( uuid )
	return self.total.list[uuid]
end

--外观接口
function Marry:get_marry( char_id )
	local list = {}
	local item = self.total.C2M[char_id]
	if item then
		if char_id == item.char_id then
			return item.mate_name
		else
			return item.char_name
		end
	end
	return list
end

--获取婚姻场景副本列表
function Marry:get_marry_fb_list()
	local list = {}
	for k,v in pairs (self.total.list or {}) do
		if v.char_id and v.m_o ~= 0 and v.m_o + v.m_n >= ev.time then
			local item = {}
			item.uuid  = v.uuid
			item.fb_id = v.m_i
			item.name1 = v.char_name
			item.name2 = v.mate_name
			item.time  = v.m_n
			item.open  = v.m_o
			item.is_all= v.m_y -- 0 或者 1
			item.line  = v.m_x
			item.num   = g_scene_mgr_ex:get_human_in_instance({v.m_i, v.uuid}) or -1
			table.insert(list,item)
		end
	end
	return list
end

--申请进入婚姻场景副本
function Marry:insert_quest_fb_list(pkt,char_id)
	if pkt == nil then return end
	local item = self.total.list[pkt.uuid]
	if item == nil then return end

	if item.m_y == 1 then
		g_cltsock_mgr:send_client(char_id, CMD_QUEST_MARRY_FB_S,{["result"]=22489})
		return true
	else

		--对人数做个上限判断
		local n_p = 0
		for k ,v in pairs (item.m_p or {}) do
			if v then
				n_p = n_p + 1
			end
		end

		local l_p = 0
		for k ,v in pairs (item.m_l or {}) do
			if v then
				l_p = l_p + 1
			end	
		end

		local max_count = g_all_scene_config[item.m_i].human_max
		if max_count <= 0 then return end 
		if (n_p + l_p) >= max_count then
			g_cltsock_mgr:send_client(char_id, CMD_QUEST_MARRY_FB_S,{["result"]=22504})
			return 
		end 

		local in_ls = false
		for k,v in pairs(item.m_l or {})do
			if v == char_id then
				in_ls = true
				local ret = {}
				ret.type = 0
				ret.char_name = item.char_name
				ret.mate_name = item.mate_name
				ret.line      = item.m_x
				ret.id        = item.m_i
				ret.uuid      = item.uuid
				g_cltsock_mgr:send_client(char_id, CMD_QUEST_MARRY_FB_S,ret)
				return true
			end
		end
		for k,v in pairs(item.m_p or {})do
			if v == char_id then
				in_ls = true
				g_cltsock_mgr:send_client(char_id, CMD_QUEST_MARRY_FB_S,{["result"]=22487})
			end
		end
		if in_ls == false then
			table.insert(item.m_p,char_id)
			--及时同步到COMM
			self:syn_comm_list(item,0,nil)
			return true 
		end		
	end
end

--主人同意进入场景列表
function Marry:insert_fb_list(char_id, pkt )
	if pkt.uuid == nil or pkt.char_list == nil then return end

	local item = self.total.C2M[char_id]
	if item == nil then return end

	if pkt.is_all <= 0 then
		item.m_y = 0 
		item.char_list = pkt.char_list
		item.no_list   = pkt.no_list
	else
		item.m_y = 1 --允许所有人
	end

	--同步到COMM 将许可的人返回给COMM (com返回有要通知许可的人和拒绝的人)
	self:syn_comm_list(item,5,nil)

	return true 
end

function Marry:notice_again_marry_error(pkt)
	local char_id = pkt.char_id
	local player = g_obj_mgr:get_obj(char_id)
	if not player or pkt.id == 0 or pkt.id == nil then return end
	local pack_con = player:get_pack_con()
	local lock_con = player:get_protect_lock()
	if pack_con then
		if pack_con:check_money_lock(MoneyType.JADE) then		
			return
		end
	end
	local money_list = {}
	money_list[MoneyType.GOLD] =  math.floor((pkt.money or 0))
	pack_con:add_money_l(money_list, {['type'] = MONEY_SOURCE.MARRY})
end

function Marry:notice_all_player(pkt)
	--同意进入通知
	if pkt.list then
		local ret = {}
		ret.type = 0
		ret.char_name   = pkt.info.char_name
		ret.mate_name   = pkt.info.mate_name
		ret.line        = pkt.info.m_x
		ret.id          = pkt.info.m_i
		ret.uuid        = pkt.info.uuid
		local pkt_t = Json.Encode(ret or {})
		for k,v in pairs(pkt.list or {})do 
			local player = g_obj_mgr:get_obj(v)
			if player then
				g_cltsock_mgr:send_client(v, CMD_QUEST_MARRY_FB_S,pkt_t,true)	
			end
		end
	end

	--禁止进入通知
	if pkt.nlist then
		local ret = {}
		ret.type = 1
		ret.char_name   = pkt.info.char_name
		ret.mate_name   = pkt.info.mate_name
		ret.line        = pkt.info.m_x
		ret.id          = pkt.info.m_i
		ret.uuid        = pkt.info.uuid
		local pkt_t = Json.Encode(ret or {})
		for k,v in pairs(pkt.nlist or {})do 
			local player = g_obj_mgr:get_obj(v)
			if player then
				g_cltsock_mgr:send_client(v, CMD_QUEST_MARRY_FB_S,pkt_t,true)	
			end
		end
	end

	--找出主人发送最新的申请和批准列表(COMM返回后才能发送)
	if self.total.list[pkt.info.uuid] then
		local char_id = self.total.list[pkt.info.uuid].char_id
		local mate_id = self.total.list[pkt.info.uuid].mate_id

		if g_obj_mgr:get_obj(char_id) then
			local ret = {}
			ret.list,ret.uuid,ret.is_all = self:get_quest_list(char_id)
			ret.result = 0 
			g_cltsock_mgr:send_client(char_id, CMD_GET_QUEST_LIST_S,ret)
		end

		if g_obj_mgr:get_obj(mate_id) then
			local ret = {}
			ret.list,ret.uuid,ret.is_all = self:get_quest_list(mate_id)
			ret.result = 0 
			g_cltsock_mgr:send_client(mate_id, CMD_GET_QUEST_LIST_S,ret)
		end
	end
end

function Marry:notice_other(pkt)
	if pkt.result == 2 then
		--另一方不在线,通知主人
		g_cltsock_mgr:send_client(pkt.send, CMD_MARRY_DIVORCE_S, {["result"]=22493})
	else
		ret = {}
		ret.char_name   = pkt.char_name
		ret.char_id     = pkt.char_id
		ret.mate_name   = pkt.mate_name
		ret.mate_id     = pkt.mate_id
		ret.result = 0
		g_cltsock_mgr:send_client(pkt.recv, CMD_DIVORCE_QUEST_S,ret)
	end
end

function Marry:notice_add_qin(pkt)
	local player_1= g_obj_mgr:get_obj(pkt.char_id)
	if player_1 then
		player_1:on_update_attribute_no_change()
		self:online(pkt.char_id)
	end
	local player_r = g_obj_mgr:get_obj(pkt.mate_id)
	if player_r then
		player_r:on_update_attribute_no_change()
		self:online(pkt.mate_id)
	end
end

function Marry:notice_other_answer(pkt)
	if pkt.type == 0 then		if pkt.send == pkt.char_id then			g_cltsock_mgr:send_client(pkt.mate_id, CMD_MARRY_DIVORCE_S, {["result"]=22494})			--解除		elseif pkt.send == pkt.mate_id then 			g_cltsock_mgr:send_client(pkt.char_id, CMD_MARRY_DIVORCE_S, {["result"]=22494})		end		if pkt.send == pkt.mate_id then			g_cltsock_mgr:send_client(pkt.char_id, CMD_MARRY_DIVORCE_S, {["result"]=0})		else			g_cltsock_mgr:send_client(pkt.mate_id, CMD_MARRY_DIVORCE_S, {["result"]=0})		end	elseif pkt.type == 1 then		if pkt.send == pkt.mate_id then			g_cltsock_mgr:send_client(pkt.char_id, CMD_MARRY_DIVORCE_S, {["result"]=22492})		else			g_cltsock_mgr:send_client(pkt.mate_id, CMD_MARRY_DIVORCE_S, {["result"]=22492})		end	end
end

function Marry:notice_break_marry(pkt)
	local info = {}
	info.type = 1
	g_cltsock_mgr:send_client(pkt.char_id, CMD_M2B_MARRY_PLAYER_INFO_S, info)
	g_cltsock_mgr:send_client(pkt.mate_id, CMD_M2B_MARRY_PLAYER_INFO_S, info)

	--清楚本地内存数据(COMM返回后才能发送)
	local item = self.total.C2M[pkt.char_id] 
	if item then
		self.total.list[item.uuid] = nil
		self.total.C2M[pkt.char_id] = nil
		self.total.C2M[pkt.mate_id] = nil
	end

	local player1 = g_obj_mgr:get_obj(pkt.char_id) 
	if player1 then 
		player1:on_update_attribute()
		player1:on_dress_update(15)

		--成功离婚要提示双方 仙侣关系已经解除，清空仙侣亲密度，关闭婚礼场景、仙缘副本。
		local ret = {}
		ret.result = 0
		g_cltsock_mgr:send_client(pkt.char_id, CMD_MARRY_DIVORCE_S, ret)
	end

	local player2 = g_obj_mgr:get_obj(pkt.mate_id) 
	if player2 then 
		player2:on_update_attribute()
		player2:on_dress_update(15)

		--成功离婚要提示双方 仙侣关系已经解除，清空仙侣亲密度，关闭婚礼场景、仙缘副本。
		local ret = {}
		ret.result = 0
		g_cltsock_mgr:send_client(pkt.mate_id, CMD_MARRY_DIVORCE_S, ret)
	end

	--离婚时场景清理
	g_scene_mgr_ex:unregister_instance(pkt.uuid)
end

function Marry:notice_again_marry(pkt)
	if g_obj_mgr:get_obj(pkt.char_id) then
		g_cltsock_mgr:send_client(pkt.char_id, CMD_AGAIN_MARRY_S, {["result"]=0})	
	end
	if g_obj_mgr:get_obj(pkt.mate_id) then
		g_cltsock_mgr:send_client(pkt.mate_id, CMD_AGAIN_MARRY_S, {["result"]=0})	
	end	
end

function Marry:notice_first_marry(pkt)	
	if g_obj_mgr:get_obj(pkt.char_id) then	
		g_cltsock_mgr:send_client(pkt.char_id, CMD_M2B_MARRY_CREATE_S, {["result"]=0})
		self:give_item_list(pkt.list,pkt.char_id,1)
		self:online(pkt.char_id)
	end

	if g_obj_mgr:get_obj(pkt.mate_id) then
		g_cltsock_mgr:send_client(pkt.mate_id, CMD_M2B_MARRY_CREATE_S, {["result"]=0})
		self:online(pkt.mate_id)
	end	
end

--单人返回调用的接口
function Marry:syn_comm_list_break( char_id )
	local info = self:get_marry_info(char_id) 	
	if info then
		self:syn_comm_list( info,1,char_id )
	end
end

--map同步信息到公共服 type = 0 修改 1 删除 2 第一次结婚广播 3 重办广播 4 30天没上线系统接触，要发邮件给双方 5 批准人
function Marry:syn_comm_list( marry_item,type,char_id )
	local ret = {}
	ret.item = {}
	ret.result = type
	ret.char_id = char_id
	ret.item = marry_item
	ret.item.m_ll = nil --这里要注意，这个table是不能入库的
	if marry_item.char_id and marry_item.mate_id then 
		if type == 6 then
			g_svsock_mgr:send_server_ex(COMMON_ID,char_id, CMD_M2P_MARRY_INFO, ret)
		else
			g_svsock_mgr:send_server_ex(COMMON_ID,marry_item.char_id, CMD_M2P_MARRY_INFO, ret)
		end
	end 	
end

--获取申请人列表
function Marry:get_quest_list(char_id)
	local item = self.total.C2M[char_id]
	if item == nil then return end

	local list = {}
	local uuid = 0 
	local is_all = 0

	uuid   = item.uuid
	is_all = item.m_y
	for k,v in pairs(item.m_ll or {}) do
		local it = {}
		it.char_id   = v.char_id
		it.char_name = v.char_name
		local faction  = g_faction_mgr:get_faction_by_cid(v.char_id)
		if faction then
			it.faction = faction:get_faction_name()
		else
			it.faction = nil	
		end
		table.insert(list,it)
	end

	return list,uuid,is_all
end

--给与婚礼物品 type 0 是测试背包是否够格子 1 是真正给与物品
function Marry:give_item_list(item_list,char_id,type)
	if item_list == nil then return end
	local player = g_obj_mgr:get_obj(char_id)
	if player == nil then return end
	local pack_con = player:get_pack_con()
	if pack_con == nil then return end

	--奖励物品
	local item_id_list = {}
	for k,v in pairs(item_list or {})do
		local e_code,item = Item_factory.create(v.id)		if e_code ~= 0 then			print("Error:Bag_container:db_load:", v.id)			return e_code		end
		if item:is_fashion() then
			item_id_list[k] = {}
			item_id_list[k].type = 2			item:set_last_time(7)
			item_id_list[k].item = item
			item_id_list[k].number  = v.count
			table.insert(item_list,v.item_id)
		else
			item_id_list[k] = {}
			item_id_list[k].type = 1
			item_id_list[k].item_id = v.id
			item_id_list[k].number  = v.count
			table.insert(item_list,v.item_id)
		end
	end

	if type == 0 then
		local error = pack_con:check_add_item_l_inter_face(item_id_list)
		if error ~= 0 then 
			return 22500
		end
	else
		if pack_con:add_item_l(item_id_list,{['type']=ITEM_SOURCE.FUNCTION_GIFT}) ~= 0 then  
			return 27003
		end
	end
	return 0
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

--重办婚礼
function Marry:set_again_marry( char_id,pkt )
	local item = self.total.C2M[char_id]
	if item == nil then return end

	local item_new = item
	item_new.m_o = 0 
	item_new.m_f = false 
	item_new.m_i = pkt.id
	item_new.m_y = 1 
	item_new.m_n = pkt.time
	item_new.m_w = pkt.list
	item_new.m_l = {}
	item_new.m_p = {}

	--同步到公共服
	self:syn_comm_list(item_new,0,char_id)
	return
end

--返还福利
function Marry:set_add_bonus(char_id,money)
	integral_func.add_bonus(char_id, money,{['type']=MONEY_SOURCE.NPC_BUY})	
end

--离婚
function Marry:break_marry( char_id,pkt )
	if pkt.type == 0 then
		--先判断钱够不够
		local need_gold = 880000
		local char_id = char_id
		local player = g_obj_mgr:get_obj(char_id)
		if not player then return end
		local pack_con = player:get_pack_con()
		local lock_con = player:get_protect_lock()
		if pack_con then
			if pack_con:check_money_lock(MoneyType.GOLD) then		
				return
			end
		end
		local money = pack_con:get_money()
		if money then
			if money.gold < need_gold then 
				g_cltsock_mgr:send_client(char_id, CMD_MARRY_DIVORCE_S, {["result"]=22505})
				return
			end
		end	
		local info = self:get_marry_info(char_id)
		if info == nil then return end
		pack_con:dec_money(MoneyType.GOLD, need_gold, {['type']=MONEY_SOURCE.MARRY})
		--integral_func.add_bonus(char_id, need_gold,{['type']=MONEY_SOURCE.MARRY})	

		--同步到公共服
		self:syn_comm_list(info,1,nil)	
	else
		--协议离婚，要发到公共服
		local info = self:get_marry_info(char_id)
		if info == nil then return end
		if char_id == info.char_id then
			local ret = {}
			ret.send = info.char_id
			ret.recv = info.mate_id
			ret.char_id   = info.char_id
			ret.char_name = info.char_name
			ret.mate_id   = info.mate_id
			ret.mate_name = info.mate_name
			g_svsock_mgr:send_server_ex(COMMON_ID,pkt.char_id, CMD_P2M_BREAK_MARRY_EX_REQ, ret)
		elseif char_id == info.mate_id then
			local ret = {}
			ret.send = info.mate_id
			ret.recv = info.char_id
			ret.char_id   = info.char_id
			ret.char_name = info.char_name
			ret.mate_id   = info.mate_id
			ret.mate_name = info.mate_name
			g_svsock_mgr:send_server_ex(COMMON_ID,pkt.char_id, CMD_P2M_BREAK_MARRY_EX_REQ, ret)		
		end 
	end
end


--以下涉及到副本的接口因为是在MAP内存，只是在单个MAP，不要求精准的同步信息
--------------------------------------外部副本接口------------------------------------------

--设置副本开启接口
function Marry:set_fb_open( uuid,time,line )
	local item = self.total.list[uuid]
	if item == nil then return false end
	item.m_o = time
	item.m_f = true
	item.m_x = line
	--同步到comm
	self:syn_comm_list(item,0,nil)

	return true
end

--设置副本加时接口
function Marry:set_fb_addtime( uuid,addtime )
	local item = self.total.list[uuid]
	if item == nil then return false end
	
	item.m_n = item.m_n + addtime
	--同步到comm
	self:syn_comm_list(item,0,nil)
	return true
end

--设置副本关闭
function Marry:set_fb_close( uuid )
	local item = self.total.list[uuid]
	if item == nil then return false end

	item.m_f = false
	item.m_i = 0
	item.m_n = 0
	item.m_x = 0
	item.m_l = {}
	item.m_p = {}
	--同步到comm
	self:syn_comm_list(item,0,nil)
	return true
end

--获取副本是否已经开启信息
function Marry:get_fb_isopen( uuid )
	local item = self.total.list[uuid]
	if item then
		return item.m_x
	else
		return 0
	end
end

--查询是否可以进入副本
function Marry:get_fb_can_in( uuid,char_id )
	local item = self.total.list[uuid]
	if item == nil then return false end

	if item.m_y == 1 then
		return true
	elseif item.m_y == 2 then
		return false
	elseif item.m_y == 0 then
		for k,v in pairs (item.m_l or {}) do
			if v == char_id then
				return true
			end	
		end
	end

	return false
end

--踢人时，从已经申请列表中删除(学习这种处理方式，防止空洞的出现)
function Marry:set_kill_id_list( uuid,kill_id_list )
	local item = self.total.list[uuid]
	if item == nil then return false end

	local kill_list = {}	for _, obj_id in ipairs(kill_id_list or {}) do		kill_list[obj_id] = true	end

	local new_ml = {}	for _,obj_id in pairs(item.m_l or {}) do		if not kill_list[obj_id] then			table.insert(new_ml, obj_id)		end	end
	
	item.m_l = new_ml

	--同步到公共服
	self:syn_comm_list(item,0,nil)
	return
end

--获取婚戒接口
function Marry:get_marry_ring( char_id )
	local item = self.total.C2M[char_id]
	if item == nil then return 0,"",0 end

	if char_id == item.char_id then
		local iii = item.m_q - item.char_uq 
		if iii <= 0 then
			return 0 ,item.mate_name,item.m_t
		else
			return iii ,item.mate_name,item.m_t
		end
	else
		local iii = item.m_q - item.mate_uq
		if iii <= 0 then
			return 0,item.char_name,item.m_t
		else
			return iii ,item.char_name,item.m_t
		end
	end

	return 0,"",0
end

--检查是否可以升级
function Marry:check_ring_up(char_id)
	local item = self.total.C2M[char_id]
	if item == nil then return false end

	local player = g_obj_mgr:get_obj(char_id)
	if player == nil then return end
	local my_level = player:get_ring()
	if my_level == 0 or my_level ==10 then return false end

	local wate = 0
	if char_id == item.char_id then
		wate = item.char_uq
	else
		wate = item.mate_uq
	end

	local my_q = self:get_have_res(my_level) 
	local ne_q = self:get_need_res(my_level) - self:get_have_res(my_level) 

	if item.m_q - wate >= ne_q then	
		return true
	else
		return false
	end
end

--升级婚戒接口
function Marry:update_ring( char_id )
	local item = self.total.C2M[char_id]
	if item == nil then return false end

	local wate = 0
	if char_id == item.char_id then
		wate = item.char_uq
	else
		wate = item.mate_uq
	end

	local player = g_obj_mgr:get_obj(char_id)
	if player == nil then return end
	local my_level = player:get_ring()
	if my_level == 0 then return end

	local my_q = self:get_have_res(my_level) 
	local ne_q = self:get_need_res(my_level) - self:get_have_res(my_level) 
	if item.m_q - wate >= ne_q then		
		
		--扣钱操作
		local pack_con = player:get_pack_con()
		local my_level = player:get_ring()
		local money    = self:get_ring_price(my_level)

		local money_list = {}
		money_list[MoneyType.GIFT_GOLD] = money
		local e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=(MONEY_SOURCE.MARRY_RING)},1)
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(char_id, CMD_UPDATE_RING_S, {["result"]=22503})
			return
		end

		if char_id == item.char_id then
			item.char_uq = item.char_uq + ne_q
		else
			item.mate_uq = item.mate_uq + ne_q
		end

		local pkt = {}
		pkt.char_id = char_id
		pkt.level   = my_level + 1
		self:notice_level_ring(pkt)

		--同步
		self:syn_comm_list(item,7,nil)

		--日志
		local pkt = {}
		pkt.char_id = char_id
		if char_id == item.char_id then
			pkt.char_name = item.char_name
		else
			pkt.char_name = item.mate_name
		end

		self:insert_mysql_intimacy_log(pkt,3,0,ne_q,item.m_q-ne_q-wate)

		return true
	end
	return false
end

function Marry:notice_level_ring(pkt)
	local player = g_obj_mgr:get_obj(pkt.char_id)
	if player == nil then return end
	--人物属性更新
	--local my_level = player:get_ring()
	--if my_level == 0 then return end

	player:set_ring_info(pkt.level)
	player:on_update_attribute()
	self:online(pkt.char_id)
	g_cltsock_mgr:send_client(pkt.char_id, CMD_UPDATE_RING_S, {["result"]=0})
end

--获取副本次数接口
function Marry:get_fb_count( uuid,fb_id )
	local item = self.total.list[uuid]
	if item == nil then return false end

	local is_in = false
	local count = 0 
	local time  = 0 
	for k,v in pairs(item.m_a or {}) do
		if tonumber(v.fb_id) == tonumber(fb_id) then
			is_in = true
			count = v.count
			time  = v.time
		end
	end

	if is_in == false then
		local it = {}
		it.fb_id = fb_id	
		it.count = 0	
		it.time  = 0
		table.insert(item.m_a,it)
		self:syn_comm_list(item,0,nil)
		return true	
	else
		if ev.time < time then
			if count < self:get_fb_maxcount(fb_id) then
				return true
			end				
		else
			--第二天了
			for k,v in pairs(item.m_a or {}) do
				if tonumber(v.fb_id) == tonumber(fb_id) then
					v.count = 0
					v.time = f_get_tomorrow()
					self:syn_comm_list(item,0,nil)
					return true
				end
			end
		end
	end
	return false
end

--增加副本次数
function Marry:add_fb_count( uuid,fb_id,count )
	local item = self.total.list[uuid]
	if item == nil then return false end

	for k,v in pairs(item.m_a) do
		if v.fb_id == fb_id then
			if self:get_fb_maxcount(fb_id) > v.count then
				v.count = v.count + 1	
				v.time  = f_get_tomorrow()
				self:syn_comm_list(item,0,nil)
			end
		end
	end
end

--增加婚姻亲密度
function Marry:use_item_add_res( char_id,count )
	local item = self.total.C2M[char_id]
	if item == nil then return 22501 end

	item.m_q_add = count
	self:syn_comm_list(item,6,char_id)
	return 0
end

--增加婚姻亲密度
function Marry:use_flw_add_res( char_id,obj_id,count )
	local item = self.total.C2M[obj_id]
	if item == nil then return 22502 end

	if obj_id == item.char_id then
		if char_id ~= item.mate_id then
			return 22502 	
		end
	else
		if char_id ~= item.char_id then
			return 22502 
		end
	end

	item.m_q_add = count
	self:syn_comm_list(item,6,obj_id)
	return 0
end

--减少亲密度接口
function Marry:dec_flw_add_res( char_id,obj_id,count )
	local item = self.total.C2M[obj_id]
	if item == nil then return 22501 end

	item.m_q = item.m_q - count
	self:syn_comm_list(item,0,nil)
	
	local player_1= g_obj_mgr:get_obj(item.char_id)
	if player_1 then
		self:online(item.char_id)
		player_1:on_update_attribute_no_change()
	end
	local player_r = g_obj_mgr:get_obj(item.mate_id)
	if player_r then
		self:online(item.mate_id)
		player_r:on_update_attribute_no_change()
	end

	return 0
end

--婚戒升级需要亲密度
function Marry:get_need_res(level)
	return marry_info.get_need_res(level)
end

--婚戒时给与最低亲密度
function Marry:get_have_res(level)
	return marry_info.get_have_res(level)
end

--获取副本上限次数
function Marry:get_fb_maxcount(fb_id)
	return marry_info.get_fb_count(fb_id)
end

--升级婚戒接口
function Marry:get_ring_peice(level)
	return marry_info.get_update_ring(level)
end

--计算物品价钱接口
function Marry:compute_item_price( item_list )
	local all_price = 0
	for k,v in pairs( item_list or {}) do
		local price = marry_info.get_item_birce(tonumber(v.id)) or 0
		all_price = all_price + price * v.count
	end
	return all_price
end

function Marry:compute_item_price_ex( id )
	local all_price = 0
	all_price = all_price + marry_info.get_item_birce(tonumber(id))or 0
	return all_price
end

--升级戒指需要价钱接口
function Marry:get_ring_price( level )
	return marry_info.get_update_ring(level)
end

--购买物品后更新入库 type 2 第一次婚礼3 重办婚礼
function Marry:syns_marry_info(char_id,id,time,list,m_b,type,money, m_q_add)
	local item = self.total.C2M[char_id]
	if item == nil then return false end

	if type == 2 then
		item.m_i = id
		item.m_o = 0
		item.m_f = false
		item.m_n = time
		item.m_q_add = m_q_add
		item.m_w = list
		item.m_b = 1

		--日志
		local pkt_1 = {}
		pkt_1.char_id = item.char_id
		pkt_1.char_name = item.char_name

		local pkt_2 = {}
		pkt_2.char_id = item.mate_id
		pkt_2.char_name = item.mate_name

		self:insert_mysql_intimacy_log(pkt_1,4,1,m_q_add,item.m_q+m_q_add)
		self:insert_mysql_intimacy_log(pkt_2,4,1,m_q_add,item.m_q+m_q_add)

		self:syn_comm_list(item,type,nil)

		--婚礼消费写MYSQL
		ret = {}
		ret.char_id = item.char_id
		ret.mate_id = item.mate_id
		ret.m_i     = item.m_i
		ret.m_n     = item.m_n
		ret.list    = item.m_w
		self:insert_mysql_log_ex(ret,type,money,ev.time)
	else 
		--重办婚礼，两个人都可以办，要防止两个人在不同的线同时开始重办婚礼
		local new_item = item
		new_item.m_i = id
		new_item.m_o = 0
		new_item.m_f = false
		new_item.m_n = time
		new_item.m_w = list
		new_item.m_q_add = m_q_add
		new_item.m_b = 1
		new_item.m_y = 1
		new_item.m_l = {}
		new_item.m_p = {}
		new_item.money = money

		--日志
		local pkt_1 = {}
		pkt_1.char_id = item.char_id
		pkt_1.char_name = item.char_name

		local pkt_2 = {}
		pkt_2.char_id = item.mate_id
		pkt_2.char_name = item.mate_name

		self:insert_mysql_intimacy_log(pkt_1,4,1,m_q_add,item.m_q+m_q_add)
		self:insert_mysql_intimacy_log(pkt_2,4,1,m_q_add,item.m_q+m_q_add)

		self:syn_comm_list(new_item,type,char_id)

		--婚礼消费写MYSQL
		ret = {}
		ret.char_id = new_item.char_id
		ret.mate_id = new_item.mate_id
		ret.m_i     = new_item.m_i
		ret.m_n     = new_item.m_n
		ret.list    = new_item.m_w

		self:insert_mysql_log_ex(ret,type,money,ev.time)
	end
	return true	
end

--副本进入场景申请
function Marry:fb_quest_insert( uuid,char_id )
	local pkt = {}
	pkt.uuid    = uuid
	pkt.char_id = char_id
	self:insert_quest_fb_list(pkt,char_id)
end

--场景花销流水
function Marry:insert_mysql_log_ex(pkt,type,money,time)	
	if pkt then
		local str = string.format(
			"insert into log_marry_scene set scene_id =%d,char_id = %d,partner_id = %d,use_time =%d,type = %d,money = %d,money_type = %d,time =%d,item = '%s'",
				pkt.m_i,
				pkt.char_id,
				pkt.mate_id,
				pkt.m_n,
				type,
				money,
				3,
				time,
				Json.Encode(pkt.list))
				g_web_sql:write(str) 
	end
end

--亲密度流水 
-- type 			 1 仙缘令 2 鲜花 3 升级婚戒 4首次结婚送500
-- io				 0 减少 1 为增加 
-- intimacy          当前操作值
-- current_intimacy  剩余亲密度

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

--角色离线(更新离线时间)
function Marry:update_out_time( char_id )
	local item = self.total.C2M[char_id]
	if item == nil then return false end

	if char_id == item.char_id then
		item.char_tm = ev.time
		self:syn_comm_list(item,0,nil)
		return
	elseif char_id == item.mate_id then
		item.mate_tm = ev.time
		self:syn_comm_list(item,0,nil)
		return
	end
end

--获取结婚对象的char_id
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