--2012-4-24
--chenxidu
--战场官职表管理

Officer_sort = oo.class(nil, "Officer_sort")

local officer_loader = require("officer.officer_loader")


local update_time = 600			--10分钟入库一次

function Officer_sort:__init()
	--直接入库的self.bid_db_list[off_id].list[ [char_id1,money1], [char_id2,money2] ]
	self.bid_db_list = {}
	self.bid_db_map = {}
	self.bid_db_cnt = {}

	--总的反映射self.have_bid_key_list[char_id][off_id, money]
	self.have_bid_key_list = {}
	
	--1大部分时间；2最后15分钟
	--self.lvl = 1
	
	--所有玩家竞投数据，lvl=1时全部有序
	self.all_sort = {}
	--最高竞投玩家数据，lvl=2启用，全有序
	self.top_sort = {}

	--保存encode过的需发送的内容
	self.encode_info = {}

	for i = 1,MAX_OFFICER_COUNT do
		self.bid_db_map[i] = {}
		self.bid_db_cnt[i] = 0

		self.all_sort[i] = {}
		self.all_sort[i].list = {}
		self.all_sort[i].map = {}
		self.all_sort[i].cnt = 0

		self.top_sort[i] = {}
		self.top_sort[i].list = {}
		self.top_sort[i].map = {}
		self.top_sort[i].cnt = 0
		self.top_sort[i].limit = officer_loader.get_officer_show(i)	--该值为方便，不能热更

		self.encode_info[i] = {}
	end 

	self.update_time = ev.time + update_time

	self:load_bid_db()
end


--***************************************************数据库与计时器
--加载竞投数据表
function Officer_sort:load_bid_db()
	--local flags = officer_loader.is_in_bef_time(ev.time)
	----print("112 =", flags)
	--if not flags then
		--self.lvl = 1
	--end

	local error,row = Officer_db:LoadBid()
	if error == 0 and row then
		for id,item in pairs(row) do
			self.bid_db_list[item.off_id] = {}
			if item.t_st > 0 and item.over == 1 then
				self.bid_db_list[item.off_id].list = {}
				self.bid_db_list[item.off_id].t_st = item.t_st
				self.bid_db_list[item.off_id].over = 1
			else
				self.bid_db_list[item.off_id].list = item.list or {}
				self.bid_db_list[item.off_id].t_st = item.t_st or 0
				self.bid_db_list[item.off_id].over = item.over or 0

				for k,v in pairs(item.list or {}) do
					local char_id = v[1]
					self.have_bid_key_list[char_id] = {}
					self.have_bid_key_list[char_id][1]   = item.off_id
					self.have_bid_key_list[char_id][2] = v[2]

					self.bid_db_map[item.off_id][ v[1] ] = k
					self.bid_db_cnt[item.off_id] = self.bid_db_cnt[item.off_id] + 1
				end

				--处理all_sort
				self:handle_all_sort(item.off_id, item)
				--处理top_sort
				if self.bid_db_list[item.off_id].over == 2 then
					self:handle_top_sort(item.off_id)
				end
			end
		end
	else
		for id = 1,MAX_OFFICER_COUNT do
			self.bid_db_list[id] = {}
			self.bid_db_list[id].list  = {}
			self.bid_db_list[id].t_st  = 0
			self.bid_db_list[id].over  = 0
		end
	end

end

function Officer_sort:seralize_to_db()
	for id,item in pairs( self.bid_db_list or {}) do
		Officer_db:UpdateBidList(id,item)
	end
end

--计时
function Officer_sort:on_timer()
	if self.update_time < ev.time then
		self:seralize_to_db()
		self.update_time = ev.time + update_time
	end

	--if self.lvl == 1 and officer_loader.is_in_bef_time(ev.time) then
		--self:change_lvl()
	--end
end


--***********************内部工具
--二分查找定位索引
function Officer_sort:location_index(sort_table, count)
	if sort_table.cnt == 0 then
		return 1
	elseif sort_table.cnt == 1 then
		if sort_table.list[1][2] >= count then
			return 2
		else
			return 1
		end
	else
		local top = sort_table.cnt
		local botton = 1
		local index 

		while botton < top do
			index = math.floor((top + botton)/2)
			--print("141 =", index, j_e(sort_table.list))
			if sort_table.list[index][2] >= count then
				botton = index + 1
			else 
				top = index - 1
			end
		end	

		if not sort_table.list[top] or sort_table.list[top][2] >= count then
			return top + 1
		else
			return top
		end
	end
end

--加入数据结构,维护cnt和map
function Officer_sort:table_insert(sort_table, index, item)
	table.insert(sort_table.list, index, item)

	local len = sort_table.cnt + 1
	sort_table.cnt = len
	--维护map
	for i = index, len do
		sort_table.map[ sort_table.list[i][1] ] = i
	end
end

--移出数据结构
function Officer_sort:table_remove(sort_table, index)
	sort_table.map[ sort_table.list[index][1] ] = nil
	table.remove(sort_table.list, index)

	local len = sort_table.cnt - 1
	sort_table.cnt = len
	--维护map
	for i = index, len do
		sort_table.map[ sort_table.list[i][1] ] = i
	end
end

--***************************************
--构造好发给客户端的内容
function Officer_sort:calc_encode_info(id)
	local limit = self.top_sort[id].limit
	local tmp_t = {}

	self.encode_info[id] = {}
	if  self.bid_db_list[id].over == 1 then
		local list = self.all_sort[id].list
		for i = 1, limit do
			tmp_t[i] = list[i]
			if not tmp_t[i] then
				break 
			end
		end
	else
		local list = self.top_sort[id].list
		for i = 1, limit do
			tmp_t[i] = list[i]
			if not tmp_t[i] then
				break 
			end
		end
	end
	self.encode_info[id] = tmp_t
end
--加入所有排序表
function Officer_sort:handle_all_sort(id, item_l)
	for k, v in pairs(item_l.list or {}) do
		local info = table.copy(v)
		info[3] = g_player_mgr.all_player_l[v[1]]["char_nm"]
		self:add_all_sort_item(id, info)
	end

	self:calc_encode_info(id)
	--if id == 2 then
		--local pkt = {}
		--pkt.money = 2000
		--pkt.type = 1
		--pkt.id = 2
		--self:request_officer(4, pkt)
--
		--self:ret_request_officer(3)
		----print("188 =", j_e(self.all_sort[2]))
		----print("189 =", j_e(self.top_sort[2]))
	--end
end

--单个item加入所有排序表;item[char_id, count]
function Officer_sort:add_all_sort_item(id, item)
	if  self.bid_db_list[id].over == 1 then							--普通阶段，全部有序
		if not self.all_sort[id].map[ item[1] ] then		--新加入
			--定位加入到数组第几位 
			local index  = self:location_index(self.all_sort[id], item[2])
			self:table_insert(self.all_sort[id], index, item)
			--print("203 =", id, j_e(self.all_sort[id]))
		else												--追加
			local index = self.all_sort[id].map[ item[1] ]
			local old_count = self.all_sort[id].list[index][2]
			self:table_remove(self.all_sort[id], index)

			item[2] = item[2] + old_count
			index = self:location_index(self.all_sort[id], item[2])
			self:table_insert(self.all_sort[id], index, item)
		end
	else											--最后阶段，直接插入尾，并维护top_sort
		local tmp_item = table.copy(item)
		if not self.all_sort[id].map[ item[1] ] then		--新加入
			--定位加入到数组第几位 
			self:table_insert(self.all_sort[id], self.all_sort[id].cnt + 1, item)
		else												--追加
			local index = self.all_sort[id].map[ item[1] ]
			self.all_sort[id].list[index][2] = self.all_sort[id].list[index][2] + item[2]
		end

		--处理top_sort
		self:add_top_sort_item(id, tmp_item)
	end

	self:calc_encode_info(id)
end


--全部加入最高排序表
function Officer_sort:handle_top_sort(id)
	if not id then						--全部
		for i = 1,MAX_OFFICER_COUNT do
			local cnt = 0
			self.top_sort[i].list = {}
			self.top_sort[i].map = {}
			self.top_sort[i].cnt = 0
			for k, v in ipairs(self.all_sort[i].list) do
				self.top_sort[i].list[k] = table.copy(v)
				self.top_sort[i].cnt = self.top_sort[i].cnt + 1
				self.top_sort[i].map[ v[1] ] = k
				cnt = cnt + 1

				if cnt >= self.top_sort[i].limit then
					break
				end
			end
		end
	else								--按id
		local cnt = 0
		for k, v in ipairs(self.all_sort[id].list) do
			self.top_sort[id].list[k] = table.copy(v)
			self.top_sort[id].cnt = self.top_sort[id].cnt + 1
			self.top_sort[id].map[ v[1] ] = k
			cnt = cnt + 1

			if cnt >= self.top_sort[id].limit then
				break
			end
		end
	end
end

--单个item加入所有排序表;item[char_id, count]
function Officer_sort:add_top_sort_item(id, item)
	if not self.top_sort[id].map[ item[1] ] then		--新加入
		--过滤掉不符合最小进入值的
		if self.top_sort[id][ self.top_sort[id].limit ] and self.top_sort[id][ self.top_sort[id].limit ][2] >= item[2] then
			return
		end
		--定位加入到数组第几位 
		local index  = self:location_index(self.top_sort[id], item[2])
		self:table_insert(self.top_sort[id], index, item)

		if self.top_sort[id].cnt > self.top_sort[id].limit then		--达到上限														--达到上限
			self:table_remove(self.top_sort[id], self.top_sort[id].limit + 1)
		end
	else												--追加
		local index = self.top_sort[id].map[ item[1] ]
		local old_count = self.top_sort[id].list[index][2]
		self:table_remove(self.top_sort[id], index)

		item[2] = item[2] + old_count
		index = self:location_index(self.top_sort[id], item[2])
		self:table_insert(self.top_sort[id], index, item)
	end
end

--取消总表竞投,维护all_sort和top_sort
--单个char_id排除出所有排序表
function Officer_sort:sub_all_sort_item(id, char_id)
	local all_index = self.all_sort[id].map[char_id]
	self:table_remove(self.all_sort[id], all_index)

	local top_index = self.top_sort[id].map[char_id] 
	if top_index then
		self:table_remove(self.top_sort[id], top_index)
	end

	self:calc_encode_info(id)
end


--切换模式进入最后阶段,已不用
function Officer_sort:change_lvl()
	if self.lvl == 1 then
		self.lvl = 2

		for i = 1,MAX_OFFICER_COUNT do
			local cnt = 0
			self.top_sort[i].list = {}
			self.top_sort[i].map = {}
			self.top_sort[i].cnt = 0
			for k, v in ipairs(self.all_sort[i].list) do
				self.top_sort[i].list[k] = table.copy(v)
				self.top_sort[i].cnt = self.top_sort[i].cnt + 1
				self.top_sort[i].map[ v[1] ] = k
				cnt = cnt + 1

				if cnt >= self.top_sort[i].limit then
					break
				end
			end
		end

	else
		self.lvl = 1
	end
end




--*****************************对外接口
--char_id对应的money
function Officer_sort:get_char_money(char_id)
	local money = self.have_bid_key_list[char_id] and self.have_bid_key_list[char_id][2]
	local off_id = self.have_bid_key_list[char_id] and self.have_bid_key_list[char_id][1]
	return off_id or 0, money or 0
end

--off_id对应的列表长度
function Officer_sort:get_bid_db_list_length(off_id)
	return self.bid_db_cnt[off_id]
end

--获取off_id对应的over
function Officer_sort:get_bid_db_list_over(off_id)
	return self.bid_db_list[off_id].over
end
--设置off_id对应的over
function Officer_sort:set_bid_db_list_over(off_id, over)
	if over == 2 then
		self:handle_top_sort(off_id)
	end

	self.bid_db_list[off_id].over = over
end

--获取off_id对应的t_st
function Officer_sort:get_bid_db_list_t_st(off_id)
	return self.bid_db_list[off_id].t_st
end
--设置off_id对应的t_st
function Officer_sort:set_bid_db_list_t_st(off_id, t_st)
	self.bid_db_list[off_id].t_st = t_st
end

--还原top_sort
function Officer_sort:renew_top_sort(id)
	local cnt = 0
	self.top_sort[id].list = {}
	self.top_sort[id].map = {}
	self.top_sort[id].cnt = 0
end

--获取top列表
function Officer_sort:get_top_bid_list(off_id)
	local tmp_t = {}
	local tmp_last = {}
	if self.bid_db_list[off_id].over == 2 then
		local limit = officer_loader.get_officer_count(off_id)
		local char_id_l = {}
		for i = 1, limit do
			local tt = self.top_sort[off_id].list[i]
			if not tt then
				break
			else
				char_id_l[tt[1]] = true

				local tmp = table.copy(tt)
				table.insert(tmp_t, tmp)
			end
		end

		local tmp_list = self.all_sort[off_id].list
		for i = 1, self.all_sort[off_id].cnt do
			if not char_id_l[ tmp_list[i][1] ] then
				table.insert(tmp_last, tmp_list[i])
			end
		end
	end

	return tmp_t, tmp_last
end

--获取所有列表
function Officer_sort:get_all_bid_list(off_id)
	return self.bid_db_list[off_id]
end

function Officer_sort:get_all_bid_count()
	local cnt = 0
	for k, v in pairs (self.bid_db_cnt) do
		 cnt = cnt + v
	end

	return cnt
end

--获取竞投列表
function Officer_sort:send_bid_list(char_id,pkt)
	if self.bid_db_list[pkt.id].over ~= 0 then		local line = g_player_mgr:get_char_line(char_id)		local ret = {}		ret.result = 0		ret.id   = pkt.id		ret.list = self.encode_info[pkt.id]		ret.cnt = self:get_all_bid_count()		--ret.time = time		--print("414 =", j_e(ret))		g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_GET_OFFICER_LIST_C, ret)
	end
end

--清空所有列表
function Officer_sort:clear_all_info()
	self.bid_db_list = {}
	self.bid_db_map = {}
	self.bid_db_cnt = {}

	self.have_bid_key_list = {}
	
	--self.lvl = 1
	
	self.all_sort = {}
	self.top_sort = {}

	self.encode_info = {}

	for i = 1,MAX_OFFICER_COUNT do
		self.all_sort[i] = {}
		self.all_sort[i].list = {}
		self.all_sort[i].map = {}
		self.all_sort[i].cnt = 0

		self.top_sort[i] = {}
		self.top_sort[i].list = {}
		self.top_sort[i].map = {}
		self.top_sort[i].cnt = 0
		self.top_sort[i].limit = officer_loader.get_officer_show(i)	--该值为方便，不能热更

		self.bid_db_list[i] = {}
		self.bid_db_list[i].list  = {}
		self.bid_db_list[i].t_st  = 0
		self.bid_db_list[i].over  = 0

		self.encode_info[i] = {}

		self.bid_db_map[i] = {}
		self.bid_db_cnt[i] = 0
	end 

end

--清空所有列表,t_st
function Officer_sort:clear_total_info()
	self.bid_db_map = {}
	self.bid_db_cnt = {}

	self.have_bid_key_list = {}
	
	--self.lvl = 1
	
	self.all_sort = {}
	self.top_sort = {}

	self.encode_info = {}

	for i = 1,MAX_OFFICER_COUNT do
		self.all_sort[i] = {}
		self.all_sort[i].list = {}
		self.all_sort[i].map = {}
		self.all_sort[i].cnt = 0

		self.top_sort[i] = {}
		self.top_sort[i].list = {}
		self.top_sort[i].map = {}
		self.top_sort[i].cnt = 0
		self.top_sort[i].limit = officer_loader.get_officer_show(i)	--该值为方便，不能热更

		--self.bid_db_list[i] = {}
		self.bid_db_list[i].list  = {}
		--self.bid_db_list[i].t_st  = 0
		--self.bid_db_list[i].over  = 0

		self.encode_info[i] = {}

		self.bid_db_map[i] = {}
		self.bid_db_cnt[i] = 0
	end 

end

----维护竞投列表（最低边界插入）
--function Officer_sort:sort_list(char_id,pkt)
	--local char = tostring(char_id)
	--local temp_list = self.bid_db_list[pkt.id].list
	--local count = officer_loader.get_officer_show(pkt.id)
	--if table.getn(temp_list) <= count then
		--if pkt.type == 1 then
			--local item = {}
			--item.char_id = char_id	
			--item.money = pkt.money	
			--table.insert(temp_list,item)
		--elseif pkt.type == 2 then 
			--for k,v in pairs(self.bid_db_list[pkt.id].list or {}) do
				--if v.char_id == char_id then
					--v.money = v.money + pkt.money
					--break
				--end	
			--end
		--end
		--self.have_bid_list[pkt.id][char] = pkt.money + (self.have_bid_list[pkt.id][char] or 0)
		--table.sort(temp_list, function(e1,e2) return e1.money > e2.money end)
		--self:sort_bid_len_list(pkt.id)
	--else
		----优化插入
		--local money = 0
		--if pkt.type == 1 then
			--money = pkt.money
		--elseif pkt.type == 2 then
			--for k,v in pairs(self.bid_db_list[pkt.id].list or {}) do
				--if v.char_id == char_id then
					--money = v.money + pkt.money
					--break
				--end	
			--end			
		--end	
		--if money >= temp_list[count].money then
			--for i=1,count do 
				--if  pkt.money >= temp_list[i+1].money and pkt.money < temp_list[i].money then
					--if pkt.type == 1 then
						--local item = {}
						--item.char_id = char_id
						--item.money   = pkt.money
						--table.insert(temp_list,i+1,item)	
					--elseif pkt.type == 2 then
						--for k,v in pairs(self.bid_db_list[pkt.id].list or {}) do
							--if v.char_id == char_id then
								--v.money = v.money + pkt.money
								--break
							--end	
						--end
						----追加不用插入新数据元，直接排序
						--self.have_bid_list[pkt.id][char] = pkt.money + (self.have_bid_list[pkt.id][char] or 0)
						--table.sort(temp_list, function(e1,e2) return e1.money > e2.money end)
						--self:sort_bid_len_list(pkt.id)
					--end
					--break				
				--end
			--end
		--else
			----直接插后面
			--if pkt.type == 1 then
				--local item = {}
				--item.char_id = char_id
				--item.money   = pkt.money
				--table.insert(temp_list,item)
				--self.have_bid_list[pkt.id][char] = pkt.money
			--else
				--for k,v in pairs(self.bid_db_list[pkt.id].list or {}) do
					--if v.char_id == char_id then
						--v.money = v.money + pkt.money
						--self.have_bid_list[pkt.id][char] = self.have_bid_list[pkt.id][char] + pkt.money
						--break
					--end	
				--end
			--end
		--end
	--end
	--return 0
--end

--竞拍官职
function Officer_sort:request_add(char_id,pkt)
	local add_item = {}
	add_item[1] = char_id
	add_item[2] = pkt.money
	if not g_player_mgr.all_player_l[char_id] then
		return
	end
	add_item[3] = g_player_mgr.all_player_l[char_id]["char_nm"]

	self:add_all_sort_item(pkt.id, add_item)

	if pkt.type == 1 then			--投
		local tmp_info = {}
		tmp_info[1] = char_id
		tmp_info[2] = pkt.money

		self.bid_db_cnt[pkt.id] = self.bid_db_cnt[pkt.id] + 1
		table.insert(self.bid_db_list[pkt.id].list, self.bid_db_cnt[pkt.id], tmp_info)
		self.bid_db_map[pkt.id][char_id] = self.bid_db_cnt[pkt.id]

		self.have_bid_key_list[char_id] = {}
		self.have_bid_key_list[char_id][1] = pkt.id
		self.have_bid_key_list[char_id][2] = pkt.money

	elseif pkt.type == 2 then		--追加
		self.bid_db_list[pkt.id].list[ self.bid_db_map[pkt.id][char_id] ][2] = 
				self.bid_db_list[pkt.id].list[ self.bid_db_map[pkt.id][char_id] ][2] + pkt.money
		self.have_bid_key_list[char_id][2] = self.have_bid_key_list[char_id][2] + pkt.money
	end
end

function Officer_sort:request_officer(char_id, pkt)
	local result = 0
	if self.bid_db_list[pkt.id].over == 0 then result = 22812 end
	
	--local char = tostring(char_id)
	if pkt.type == 1 then
		if self.have_bid_key_list[char_id] then result = 22817 end
	elseif pkt.type == 2 then
		if not self.have_bid_key_list[char_id] or self.have_bid_key_list[char_id][1] ~= pkt.id then result = 22826 end
	else
		return
	end

	if result == 0 then 
		self:request_add(char_id, pkt) 
	end

	local line = g_player_mgr:get_char_line(char_id)	local pkt_t = {}	pkt_t.result = result	pkt_t.char_id = char_id	pkt_t.id      = pkt.id	pkt_t.money   = pkt.money	pkt_t.total   = (self.have_bid_key_list[char_id] and self.have_bid_key_list[char_id][2]) or 0	g_server_mgr:send_to_server(line,char_id, CMD_BUCTION_OFFICER_REQUEST_C, pkt_t)
	g_server_mgr:send_to_server(line,char_id, CMD_SEND_OWNER_OFFICER, pkt_t)
	
	if result == 0 then
		self:send_bid_list(char_id, pkt_t)		
	end
end

--取消竞投
function Officer_sort:request_sub(char_id, id)
	self:sub_all_sort_item(id, char_id)

	self.bid_db_cnt[id] = self.bid_db_cnt[id] - 1
	local money = self.have_bid_key_list[char_id][2]

	table.remove(self.bid_db_list[id].list, self.bid_db_map[id][char_id])
	for i = self.bid_db_map[id][char_id], self.bid_db_cnt[id] do
		self.bid_db_map[id][ self.bid_db_list[id].list[i][1] ] = i
	end

	self.have_bid_key_list[char_id] = nil
	self.bid_db_map[id][char_id] = nil

	return money
end

function Officer_sort:ret_request_officer(char_id)
	local result = 0
	local off_id = self.have_bid_key_list[char_id] and self.have_bid_key_list[char_id][1]
	if not off_id then result = 22819 end

	if self.bid_db_list[off_id].over ~= 1 then result = 22828 end

	local money = 0

	if result == 0 then
		money = self:request_sub(char_id, off_id)
	end

	local line = g_player_mgr:get_char_line(char_id)	local pkt_t = {}	pkt_t.result = result	pkt_t.char_id = char_id	pkt_t.id      = off_id	pkt_t.money   = money	g_server_mgr:send_to_server(line, char_id, CMD_CANCEL_OFFICER_REQUEST_C, pkt_t)

	if result == 0 then
		self:send_bid_list(char_id, pkt_t)
	end
	
end


