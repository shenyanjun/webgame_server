--2012-8-9
--zhengyg
--rank_charm
local data_table = "activity_rank_sum"
--local data_table = "activity_rank_sum_test"


local _rank_cfg = require("activity_rank.activity_rank_loader")

rank_charm = oo.class(rank_base,"rank_charm")

function rank_charm:__init()
	rank_base.__init(self)
	
	self.today = 0 --f_get_today(ev.time)
	self.sort_today = {['cnt']=0, ['list']={}, ['map']={}} --今天排行
	self.sort_pre 	= {['cnt']=0, ['list']={}, ['map']={}} --昨天排行
	self.sort 		= {['cnt']=0, ['list']={}, ['map']={}} --总排行
	self.reward = {} --记录已经发放过的奖励 id,以免重复发放
	self.data_version = {ev.time, ev.time, ev.time}-- 今天榜，昨天榜，总榜数据版本
	--加载
	self:unserialize()
	
	--检查日期变更与数据相应更新
	self:check_update()
end

function rank_charm:check_update() --进行 日期变更 活动时间
	local turn_on = self.turn_on
	
	rank_base.check_update(self)--可能会修改 self.turn_on
	
	if not turn_on and not self.turn_on then return end --这样的好处是 活动完那时 再更新一次，方便发奖模块(do_reward_timer)依赖数据正确
	
	local a_o = _rank_cfg.get_activity(self:get_type())
	if a_o == nil then return end
	
	if a_o.id ~= self.id then --活动id不同了， 重置数据
		self.id = a_o.id
		self.today = f_get_today(ev.time)
		self.sort_today = {['cnt']=0, ['list']={}, ['map']={}} --今天排行
		self.sort 		= {['cnt']=0, ['list']={}, ['map']={}} --活动以来排行
		self.sort_pre 	= {['cnt']=0, ['list']={}, ['map']={}} --昨天排行
		self.reward = {} --记录已经发放过的奖励,以免重复发放
		--self.data_version = {ev.time, ev.time, ev.time}-- 今天榜，昨天榜，总榜数据版本
		self.data_version[1] = self.data_version[1] + 1
		self.data_version[2] = self.data_version[2] + 1
		self.data_version[2] = self.data_version[3] + 1
		self:syn_map_rank_data()
	end
	
	if not self.id then return end --无活动
	
	local today = f_get_today(ev.time)
	if f_get_today(self.today) ~= today then --更新昨天榜
		if f_get_today(self.today) == f_get_today(ev.time - 3600*24) then
			self.sort_pre = table.copy(self.sort_today) --昨天排行榜
		else
			self.sort_pre = {['cnt']=0, ['list']={}, ['map']={}} --公共服务停了一天以上没开 会跑到这里来
		end
		self.today = today
		self.sort_today = {['cnt']=0, ['list']={}, ['map']={}} --重置当天排行
		self.data_version[1] = self.data_version[1] + 1
		self.data_version[2] = self.data_version[2] + 1
		self:syn_map_rank_data()
	end
end

function rank_charm:do_timer() --定时执行
	rank_base.do_timer(self)
	self:check_update()	   --更新检测
	self:do_reward_timer() --发奖检查
	--print('rank_charm:do_timer()')
end

function rank_charm:do_reward_timer() --发奖,服务器启动初始化时不做此操作
	local a_cfg = _rank_cfg._activity_rank_cfg[self:get_type()]
	
	if not self.id or a_cfg and a_cfg.id ~= self.id then return end

	if not self.turn_on and self:get_end_t() < (ev.time - 3600*24) then return end --活动过期后一天，依然保持奖励补发机制
		
	local timestamp_set = a_cfg and a_cfg.timestamp_set
	if timestamp_set == nil then return end
	
	for t_id, t_stamp in pairs(timestamp_set) do --遍历所有发奖时间戳
		if self.reward[tostring(t_stamp.t_id)] == nil then --该批奖励未发放
			if f_get_today(t_stamp.start_t) < self.today then
				self.reward[tostring(t_stamp.t_id)] = 1 --今天之前没有发的奖励，作废
			elseif ev.time > t_stamp.start_t and f_get_today(t_stamp.start_t) == self.today then --该批奖励时间到 并且当前时间在今天内
				self.reward[tostring(t_stamp.t_id)] = 1 --标志应该时间点 奖励成已经发放
				
				for order, gift in pairs(t_stamp.gift_set) do --各名次奖励
					local recevier = nil
					local title = nil
					local content = nil
					local box_title = ""
					local money_list = ""
					
					if t_stamp.reward_type == 1 then --日榜,第二天发前一天的奖品，所以从昨日榜去取数据
						recevier = self.sort_pre.list[order] and self.sort_pre.list[order][1]
						title = string.format(f_get_string(2945),order)
						content = string.format(f_get_string(2946),order)
						box_title = string.format(f_get_string(2949),order)
					elseif t_stamp.reward_type == 2 then--总榜
						recevier = self.sort.list[order] and self.sort.list[order][1]
						title = string.format(f_get_string(2947),order)
						content = string.format(f_get_string(2948),order)
						box_title = string.format(f_get_string(2950),order)
					end
					
					if recevier then
						local email = {}
						email.sender = -1
						email.recevier = recevier
						email.title = title
						email.content = content
						email.box_title = box_title
						email.money_list = {}
						
						email.item_list = {}
						if gift.item_id then
							local item = {}
							item.id = gift.item_id
							item.name = gift.name or ""
							item.count = gift.num
							table.insert(email.item_list, item)
						end
						g_email_mgr:send_email_interface(email)
						--print("CHARM_RANK_GIFT:",j_e(email))
					end
				end
			end
		end
	end
end

function rank_charm:get_type()
	return ACTIVITY_RANK_TYPE.RANK_CHARM
end

function rank_charm:update_rank_info(pkt)
	rank_base.update_rank_info(self,pkt)
	
	--print(j_e(pkt))
	
	local change_flag = nil
	
	if not self.turn_on then return end --活动未开启
	
	if 1 == self:update_rank_info_utility(self.sort,pkt.info) then --更新总榜
		self.data_version[3] = self.data_version[3] + 1
		change_flag = true
	end
	
	if pkt.info_today[4] == self.today then --更新日榜
		if 1== self:update_rank_info_utility(self.sort_today,pkt.info_today) then
			self.data_version[1] = self.data_version[1] + 1
			change_flag = true
		end
	end
	
	if change_flag then--有改动 需通知map,不频繁，应该不会有性能问题
		self:syn_map_rank_data()
	end
	
	--self:print() --测试
end

function rank_charm:update_rank_info_utility(sort_list,info)
	if info[2] <= 0 then --数值小于等于0 完全没资格
		return 
	end
	
	local min_cnt = 1		 --上榜最小值
	if sort_list.cnt >= self:get_rank_limit() then
		min_cnt = sort_list.list[self:get_rank_limit()][2]
	end
	
	if info[2] < min_cnt then --根本没入围
		return
	end
	
	local index =  sort_list.map[info[1]] --查一下是否已经在榜里面
	
	if index == nil then --之前不在榜上
		index = self:locate_index_dasc(sort_list, info, 2, 3)
		if index <= self:get_rank_limit() then	--在榜范围内
			self:table_insert(sort_list,index,info) --上榜
			if sort_list.list[self:get_rank_limit()+1] then --消除榜外的数据
				self:table_remove(sort_list,self:get_rank_limit()+1)
			end
			return 1
		end
	else
		local old_index = index
		local old_charm = sort_list.list[index][2]
		
		self:table_remove(sort_list, index) --先将之前的数据移除
		index = self:locate_index_dasc(sort_list, info, 2, 3)
		if index <= self:get_rank_limit() then --在榜范围内
			self:table_insert(sort_list,index,info) --上榜
			if sort_list.list[self:get_rank_limit()+1] then
				self:table_remove(sort_list,self:get_rank_limit()+1)
			end
		end
		
		local new_charm = sort_list.list[index][2]
		if old_index~=index or new_charm~=old_charm then
			return 1
		end
	end
end

function rank_charm:serialize()
	local dbh = f_get_db()
	--保存本服汇总数据
	local rec = {}
	rec.type = self:get_type()
	rec.id = self.id
	rec.today = self.today
	
	rec.sort = {}
	for i = 1,self:get_rank_limit() do
		if self.sort.list[i] == nil then break end
		rec.sort[i] = self.sort.list[i]
	end
	
	rec.sort_today = {}
	for i = 1,self:get_rank_limit() do
		if self.sort_today.list[i] == nil then break end
		rec.sort_today[i] = self.sort_today.list[i]
	end
	
	rec.sort_pre = {}
	for i = 1,self:get_rank_limit() do
		if self.sort_pre.list[i] == nil then break end
		rec.sort_pre[i] = self.sort_pre.list[i]
	end
	
	rec.sort_today = {}
	for i = 1,self:get_rank_limit() do
		if self.sort_today.list[i] == nil then break end
		rec.sort_today[i] = self.sort_today.list[i]
	end
	
	rec.reward = self.reward
	rec.data_version = self.data_version
	--print(j_e(rec))
	if 0 == dbh:update(data_table,"{type:1}", Json.Encode(rec), true) then
		--db update suc
	end
end

function rank_charm:unserialize()
	local today = f_get_today(ev.time)
	local yesterday = f_get_today(ev.time - 3600*24)

	local dbh = f_get_db()
	local condition = string.format("{type:%d}",self:get_type())
	local rows, e_code = dbh:select_one(data_table, nil, condition)

	assert(e_code == 0,'rank_charm:unserialize() error1')

	if rows then
		self.id = rows.id
		self.reward = rows.reward or {}
		self.today = rows.today
		
		--加载今日榜
		for index,info in pairs(rows.sort_today or {}) do
			self:update_rank_info_utility(self.sort_today, info)
		end		
		--加载昨日榜
		for index, info in pairs(rows.sort_pre or {}) do
			self:update_rank_info_utility(self.sort_pre, info)
		end
		--加载总榜
		for index, info in pairs(rows.sort or {}) do
			self:update_rank_info_utility(self.sort, info)
		end
		
		self.data_version = rows.data_version or {ev.time, ev.time, ev.time}
	end
	--self:print()
end

function rank_charm:serialize_to_net()
	local to_net = {}
	
	to_net.sort = {}
	for i = 1, self:get_rank_limit() do
		local it = self.sort.list[i]
		if it == nil then break end
		
		local char = g_player_mgr.all_player_l[it[1]]
		to_net.sort[i] = {it[1], it[2], char.char_nm or "", char.occ or 0, char.gender or 0}
	end
	
	to_net.sort_today = {}
	for i = 1, self:get_rank_limit() do
		local it = self.sort_today.list[i]
		if it == nil then break end
		
		local char = g_player_mgr.all_player_l[it[1]]
		to_net.sort_today[i] = {it[1], it[2], char.char_nm or "", char.occ or 0, char.gender or 0}
	end
	
	to_net.sort_pre = {}
	for i = 1, self:get_rank_limit() do
		local it = self.sort_pre.list[i]
		if it == nil then break end
		
		local char = g_player_mgr.all_player_l[it[1]]
		to_net.sort_pre[i] = {it[1], it[2], char.char_nm or "", char.occ or 0, char.gender or 0}
	end

	to_net.data_version = self.data_version
	
	return to_net
end

function rank_charm:print()
	for i = 1, 50 do
		if self.sort.list[i] == nil then break end
		print('sort_'..i, j_e(self.sort.list[i]))
	end
	for i = 1, 50 do
		if self.sort_today.list[i] == nil then break end
		print('sort_today_'..i, j_e(self.sort_today.list[i]))
	end
	for i = 1, 50 do
		if self.sort_pre.list[i] == nil then break end
		print('sort_pre_'..i, j_e(self.sort_pre.list[i]))
	end
end

register_activity_rank_builder(rank_charm.get_type(),rank_charm)
