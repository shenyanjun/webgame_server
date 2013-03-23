--2012-7-14
--zhengyg
--成就树活动 数据汇总管理 ， 负责统计本服各成就条参与人数,及最先到达各层的名单
activity_achi_tree_mgr = oo.class(nil,"activity_achi_tree_mgr")
local _max_row = 9
function activity_achi_tree_mgr:__init()
	--玩家成就信息
	self.char_achi = {}
	--本服汇总数据,定时刷进数据库
	self.local_firster = {}
	self.local_row_num  = {}
	self.local_num  = 0
	--全服汇总数据 , 定时读取
	self.china_firster = {}
	self.china_row_num = {}
	self.china_num	   = {}
	
	self.is_loading = nil
	self.local_need_save = nil
end

function activity_achi_tree_mgr:db_load()
	self.is_loading = 1
	local dbh = f_get_db()
	local rows, e_code = dbh:select('achi_tree_rank_local',nil,nil,"{char_id:1}")
	assert(e_code == 0,'achi_tree_rank_local:db_load() error1')
	if rows then
		for _,pack in pairs(rows) do
			local char_id = pack.char_id
			if char_id then
				self:update_one_info(pack)
			end
		end
	end
	--[[
	rows, e_code = dbh:select_one("achi_tree_rank_sum", nil, "{type:1}", nil)
	assert(e_code == 0,'achi_tree_rank_local:db_load() error2')
	if rows then
		for row_id = 1,_max_row do
			if rows.local_firster and rows.local_firster[row_id] then
				self.local_firster[row_id] = rows.local_firster[row_id]
			end
		end
	end
	--]]
	self.is_loading = nil
	
	self:do_timer()
end

function activity_achi_tree_mgr:update_one_info(pkt)
	local old_info = self.char_achi[pkt.char_id]
	if  old_info == nil then
		self.local_num = (self.local_num or 0) + 1
		self:update_local_row_num(nil,pkt)
		self:update_local_firster(pkt)
		
	else
		self:update_local_row_num(old_info,pkt)
		self:update_local_firster(pkt)
	end
	self.char_achi[pkt.char_id] = pkt
	
	if self.is_loading == nil and self.local_need_save then --加载阶段 禁止存盘
		self:save_local_info()	   --运行阶段,有本地达人出现，即时存盘
	end
end

function activity_achi_tree_mgr:update_local_row_num(old_info , pkt)
	if old_info then
		local last_end = nil
		local cur_end = nil
		for row_id = 1,_max_row do
			if old_info.row[row_id]==nil or row_id == _max_row then last_end = row_id break end
		end
		for row_id = 1,_max_row do
			if pkt.row[row_id]==nil or row_id == _max_row then cur_end = row_id break end
		end
		last_end = last_end or 0
		cur_end = cur_end or 0
		for row_id = last_end+1,cur_end do
			self.local_row_num[row_id] = (self.local_row_num[row_id] or 0) + 1
		end
	else
		for row_id = 1,_max_row do
			self.local_row_num[row_id] = (self.local_row_num[row_id] or 0) + 1
			if pkt.row[row_id] == nil then break end
		end
	end
end

function activity_achi_tree_mgr:update_local_firster(pkt) --确定全服达人,服务器启动加载阶段消耗一点性能
	--print("activity_achi_tree_mgr:update_local_firster")
	
	for row_id = 1,_max_row do			
		if pkt.row[row_id] == nil then break end
		if self.local_firster[row_id] == nil then
			self.local_firster[row_id] = pkt
			if self.is_loading == nil then --加载阶段不做更新
				self.local_need_save = 1
			end
		elseif self.is_loading and self.local_firster[row_id].row and self.local_firster[row_id].row[row_id] then --加载阶段 对比
			if pkt.row[row_id] < self.local_firster[row_id].row[row_id] then
				self.local_firster[row_id] = pkt
			end
		end
	end
end

function activity_achi_tree_mgr:on_timer()
	self:do_timer()
end

function activity_achi_tree_mgr:save_local_info(right_now)
	if self.local_need_save == nil and right_now == nil then return end
	local dbh = f_get_db()
	--保存本服汇总数据
	local rec = {}
	rec.type = 1
	rec.local_num = self.local_num or 0
	rec.local_row_num = self.local_row_num or {}
	rec.local_firster = self.local_firster or {}
	rec.set_time = ev.time
	if 0 == dbh:update("achi_tree_rank_sum","{type:1}" , Json.Encode(rec), true) then
		self.local_need_save = nil
	end
end

function activity_achi_tree_mgr:do_timer(shut_down)
	--print("-----activity_achi_tree_mgr:do_timer")
	self:save_local_info(true)
	
	if shut_down then return end
	
	local dbh = f_get_db()
	--读取大陆汇总数据
	local rows, e_code = dbh:select_one("achi_tree_rank_sum", nil, "{type:2}", nil)
	if rows then
		self.china_firster = rows.china_firster or {}
		self.china_row_num = rows.china_row_num or {}
		self.china_num	   = rows.china_num or 0
		self:notice_map()
	end
end

function activity_achi_tree_mgr:notice_map()
	local pkt = {}
	pkt.china_firster = {}
	local cnt = 1;
	for row_id = _max_row - 2,_max_row do -- 最后三层达人
		local info = self.china_firster[row_id]
		if info then
			pkt.china_firster[cnt] = {info.char_id,info.lvl,info.nm,info.sex,info.occ,info.cnt,info.pf,info.sid}
			cnt = cnt + 1
		end
	end
	pkt.china_row_num = self.china_row_num
	pkt.china_num = self.china_num or 0 
	g_server_mgr:send_to_all_map(0,CMD_M2C_ACHI_SUM_INFO,Json.Encode(pkt),true)
end

function activity_achi_tree_mgr:get_click_param()
	return self,self.on_timer,21*60,nil --到时发版本要再调一下时间,调长一点
end

function activity_achi_tree_mgr:test()
	print("-----activity_achi_tree_mgr:test()")
	print(self.local_num)
	print(j_e(self.local_row_num))
	print(j_e(self.local_firster))
end

