--2011-05-24
--cqs
--委托任务基类

local authorize_loader = require("config.loader.authorize_loader")

Authorize_mission = oo.class(nil, "Authorize_mission")

function Authorize_mission:__init(authorize_id, db_data)
	self.authorize_id	= authorize_id	
	
	--insert进来的数组队列;委托链表[[委托人ID字符串],[委托数量],[到期时间]]
	self.authorize_list	= (db_data and db_data.authorize_list) or {}	
	--insert进来的数组队列；接受而未完成链表[tostring(char_id):到期时间]
	self.draw_list		= (db_data and db_data.draw_list) or {}	
	--KV值表，k为tostring(char_id) v数量；完成链表		
	self.complete_list	= (db_data and db_data.complete_list) or {}	
		
end

------------------------------------------与map命令交互------------
--打开进行委托界面
function Authorize_mission:get_player_today_authorize(id)
	local char_id = tostring(id)
	local counts = 0
	for i = 1, table.getn(self.authorize_list) do
		if self.authorize_list[i][1] == char_id then
			counts = counts + self.authorize_list[i][2]
		end
	end

	for i = 1, table.getn(self.draw_list) do
		if self.draw_list[i][char_id] then
			counts = counts + 1
		end
	end

	return counts
end
--打开我的委托界面
function Authorize_mission:get_player_authorize(id)
	local char_id = tostring(id)
	local pkt = {}
	pkt.entrust = 0
	for i = 1, table.getn(self.authorize_list) do
		if self.authorize_list[i][1] == char_id then
			pkt.entrust = pkt.entrust + self.authorize_list[i][2]
		end
	end
	for i = 1, table.getn(self.draw_list) do
		if self.draw_list[i][char_id] then
			pkt.entrust = pkt.entrust + 1
		end
	end

	pkt.total = self.complete_list[char_id] or 0
	return pkt
end
--获得可接数量
function Authorize_mission:get_authorize_count()
	local count = 0
	for i = 1, table.getn(self.authorize_list) do
			count = count + self.authorize_list[i][2]
	end

	return count
end



-------------------------------------------------------------------------------
--增加委托
function Authorize_mission:authorize(pk)
	if not pk or not pk.char_id or not pk.count then
		return false
	end
	local s_pk = {}
	s_pk[1] = tostring(pk.char_id)
	s_pk[2] = pk.count
	s_pk[3] = ev.time + authorize_loader.get_authorize_complete_time(self.authorize_id)

	table.insert(self.authorize_list, s_pk)
	--if pk.type == 1 then
		--local char_id = tostring(pk.char_id)
		--if self.complete_list[char_id] then
			--self.complete_list[char_id] = self.complete_list[char_id] + pk.count
		--else
			--self.complete_list[char_id] = pk.count
		--end 
	--end
	--全服广播
	local pkt = {}
	pkt.name  = g_player_mgr.all_player_l[pk.char_id]["char_nm"]
	pkt.count = pk.count
	pkt.authorize_id = self.authorize_id
	pkt = Json.Encode(pkt)
	for k , v in pairs(g_player_mgr.online_player_l) do
		g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_NOTICE_AUTHORIZE_W, pkt, true)
	end
	return 0	
end

--完成一次
function Authorize_mission:complete_authorize()
	local authorizer = self.draw_list[1]
	if not authorizer then
		return 0
	end
	local char_id
	for k, v in pairs(authorizer) do
		char_id = k
		break
	end
	table.remove(self.draw_list,1)

	--if self.complete_list[char_id] then
		--self.complete_list[char_id] = self.complete_list[char_id] + 1
	--else
		--self.complete_list[char_id] = 1
	--end 
	return 0
end

--领取一次委托
function Authorize_mission:get_authorize()
	local authorizer_info = self.authorize_list[1]
	local authorizer = {}
	local flags = false
	local char_id
	if authorizer_info then	
		char_id = authorizer_info[1]
		authorizer[authorizer_info[1]] = ev.time + authorize_loader.get_authorize_complete_time(self.authorize_id)
	end
	if char_id then
		self.authorize_list[1][2] = self.authorize_list[1][2] - 1
		if self.authorize_list[1][2] <= 0 then
			flags = true
		end
		if flags then
			table.remove(self.authorize_list,1)
		end
		--table.insert(self.draw_list,authorizer)

		return 0 , char_id
	end
	return 20522 ,false
end

--领取奖励
function Authorize_mission:get_reward(char_id)
	if not char_id then
		return 0
	end
	local id = tostring(char_id)
	local count = self.complete_list[id] or 0
	self.complete_list[id] = nil

	return count	
end

--清到完成列表
function Authorize_mission:audit()
	local a_tmp = 0
	local d_tmp = 0
	for i = 1, table.getn(self.authorize_list) do
		if self.authorize_list[i][3] < ev.time then
			a_tmp = i
			local char_id =  self.authorize_list[i][1]
			--if self.complete_list[char_id] then
				--self.complete_list[char_id] = self.complete_list[char_id] + self.authorize_list[i][2]
			--else
				--self.complete_list[char_id] = self.authorize_list[i][2]
			--end 
		else 
			break
		end
	end
	for i = a_tmp, 1, -1 do
		table.remove(self.authorize_list, i)
	end


	for i = 1, table.getn(self.draw_list) do
		local flags = false
		for k, v in pairs(self.draw_list[i]) do
			if v < ev.time then
				--if self.complete_list[k] then
					--self.complete_list[k] = self.complete_list[k] + 1
				--else
					--self.complete_list[k] = 1
				--end
				d_tmp = i
			else
				flags = true
			end
			break
		end
		if flags then
			break
		end
	end
	for i = d_tmp, 1, -1 do
		table.remove(self.draw_list, i)
	end

	return 	
end

--序列化到数据库
function Authorize_mission:serialize_to_db()
	local pk = {}
	pk.authorize_list = self.authorize_list
	pk.complete_list  = self.complete_list
	pk.draw_list  	  = self.draw_list

	return pk	
end
