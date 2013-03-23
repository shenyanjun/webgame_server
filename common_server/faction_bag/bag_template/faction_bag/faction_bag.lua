--2012-05-21
--zhengyg
--class faction_bag

------------------------------------------
--[[
interface info:
	faction_bag:get_faction_id()
	faction_bag:get_lvl()
	else : please read bag_base.lua to find other interfaces 
]]
--lvl and grid_cnt config
local lvl_grid_cnt = {
[1] = 10,
[2] = 15,
[3] = 20,
[4] = 25,
[5] = 30,
}
--db array index , do not try to change this table
local db_key2index={
['lvl']=1,
['max_grid_cnt']=2,
['grid_info']=3
}

faction_bag = oo.class(bag_base,"faction_bag")

function faction_bag:__init(max_grid_cnt,faction_id)
	self.m_lvl = 1
	max_grid_cnt = lvl_grid_cnt[self.m_lvl]
	self.m_op_record = {}
	self.m_op_record.modify_time =0 --do not need save db
	self.m_record_con = fbag_record_container({},faction_id)
	bag_base.__init(self,max_grid_cnt,faction_id)
end
function faction_bag:get_record_modify_time()
	return self.m_op_record.modify_time
end
function faction_bag:set_record_modify_time()
	if self.m_op_record.modify_time == 0 then
		self.m_op_record.modify_time = os.time()
	end
end

function faction_bag:reset_record_modify_time()
	self.m_op_record.modify_time = 0
end

function faction_bag:set_earliest_save_time()
	g_faction_bag_mgr:add_modify_bag(self)
	bag_base.set_earliest_save_time(self)
end

function faction_bag:get_bag_type()
	return FACTION_BAG
end

function faction_bag:get_faction_id()
	return self:get_owner_id()
end

function faction_bag:serialized()
	local pack = {}
	pack.bag_info={}
	pack.faction_id = self:get_faction_id()
	pack.bag_info[db_key2index['lvl']] = self:get_lvl()
	pack.bag_info[db_key2index['max_grid_cnt']] = self:get_bag_size()
	pack.bag_info[db_key2index['grid_info']] = bag_base.serialized(self)
	return pack
end

function faction_bag:unserialized(pack)
	self.faction_id     = pack.faction_id
	self.m_lvl = pack.bag_info[db_key2index['lvl']] or 1
	local ret = bag_base.unserialized(self,pack.bag_info[db_key2index['grid_info']],pack.bag_info[db_key2index['max_grid_cnt']])
	return ret
end

function faction_bag:serialized_record()
	return self.m_record_con:serialized()
end

function faction_bag:unserialized_record(pack)
	self.m_record_con:unserialized(pack)
end

function faction_bag:get_lvl()
	return self.m_lvl
end

function faction_bag:update_lvl_grid_cnt(lvl,cnt)
	if lvl<=5 and lvl>0 then 
		self.m_lvl = lvl or self.m_lvl
	end
	if cnt>0 and cnt<= 30 then
		self:set_bag_size(cnt)
	end
end
function faction_bag:set_bag_size(max_size)
	bag_base.set_bag_size(self,max_size)
	return 0 
	
end

function faction_bag:set_item_price(uuid,price,char_id)
	local grid = self:get_grid_by_uuid(uuid)
	if grid then
		local notice = bag_notice()
		local pre_price = grid:get_price() or 0
		
		grid:set_price(price)
		notice:add_notice(grid)
		
		local log = faction_bag_sql_log(char_id ,self)
		log:do_price_log(notice,pre_price)
		
		self:set_earliest_save_time()--need save
		self:update_client2(self:get_faction_id(),self:notice_grid_change_to_net(notice))
		return 0
	end
	--self:send_client_bag(char_id)
	return 31162
end

function faction_bag:get_item_price(uuid)
	local grid = self:get_grid_by_uuid(uuid)
	if grid then
		return grid:get_price()
	end
	return nil
end

function faction_bag:add_item_bat(item_infos,char_id,price)
	local e_code , notice = bag_base.add_item_bat(self,item_infos)
	if e_code == 0 and char_id then
		local log = faction_bag_sql_log(char_id ,self)
		log:do_add_log(notice)
		self:update_client2(self:get_faction_id(),self:notice_grid_change_to_net(notice))
		--default price setting
		if price then
			for _,grid in pairs(notice:get_grids()) do
				self:set_item_price(grid:get_uuid(),price,char_id)
			end
		end
		return e_code 
	end
	return e_code , notice
end

function faction_bag:del_item_by_uuid(uuid,cnt,char_id)
	local e_code , notice = bag_base.del_item_by_uuid(self,uuid,cnt)
	if e_code == 0 and char_id then
		local log = faction_bag_sql_log(char_id ,self)
		log:do_sub_log(notice)
		self:update_client2(self:get_faction_id(), self:notice_grid_change_to_net(notice))
		return e_code
	end
	--self:send_client_bag(char_id)
	return e_code,notice
end

function faction_bag:get_and_del(uuid,cnt,char_id)
	local item , cnt_old  = self:get_item_by_uuid(uuid)
	if item then
		local e_code = self:del_item_by_uuid(uuid,cnt,char_id)
		if e_code == 0 then
			return 0 , item , cnt
		end
	end
	return 31162
end

function faction_bag:del_item_bat(item_infos,char_id)
	local e_code , notice = bag_base.del_item_bat(self,item_infos)
	if e_code == 0 and char_id then
		local log = faction_bag_sql_log(char_id,self)
		log:do_sub_log(notice)
		self:update_client2(self:get_faction_id(), self:notice_grid_change_to_net(notice))
		return e_code , notice
	end
	--self:send_client_bag(char_id)
	return e_code , notice
end

function faction_bag:destroy_item_by_uuid(uuid,char_id)
	local grid = self:get_grid_by_uuid(uuid)
	if grid == nil then
		--self:send_client_bag(char_id)
		return 43339 
	end
	local e_code , notice = bag_base.del_item_by_uuid(self,uuid,grid:get_item_cnt())
	if e_code == 0 then
		local log = faction_bag_sql_log(char_id,self)
		log:do_des_log(notice)
		self:update_client2(self:get_faction_id(), self:notice_grid_change_to_net(notice))
		return e_code 
	end
	--self:send_client_bag(char_id)
	return e_code,notice
end

function faction_bag:update_client(char_id , update_pkt)
	--[[local line = g_player_mgr:get_char_line(char_id)
	if line then
		g_server_mgr:send_to_server(line, char_id, CMD_C2M_UPDATE_ITEM_C, update_pkt)
	end
	--]]
	--update_pkt.faction_id = self:get_faction_id()
	g_server_mgr:send_to_all_map(char_id,CMD_C2M_UPDATE_ITEM_C,Json.Encode(update_pkt),true)
end

function faction_bag:update_client2(faction_id , update_pkt)
	--[[local line = g_player_mgr:get_char_line(char_id)
	if line then
		g_server_mgr:send_to_server(line, char_id, CMD_C2M_UPDATE_ITEM_C, update_pkt)
	end
	--]]
	update_pkt.faction_id = self:get_faction_id()
	g_server_mgr:send_to_all_map(0,CMD_C2M_UPDATE_ITEM_C,Json.Encode(update_pkt),true)
end

function faction_bag:clear_client_window(char_id)
	local line = g_player_mgr:get_char_line(char_id)
	if line then
		local pnt = 1
		local data = {}
		data.list = {}
		data.result = 0
		for _,grid in pairs(self.m_grid_list) do		
			data.list[pnt] = grid:serialized_to_net(self:get_bag_type(),2)
			data.list[pnt][5] = 0 -- num == 0 
			pnt = pnt + 1
		end
		g_server_mgr:send_to_server(line, char_id, CMD_C2M_UPDATE_ITEM_C, data)
	end
end

function faction_bag:send_client_bag(char_id)
	local line = g_player_mgr:get_char_line(char_id)
	if line then
		local s_pkt = self:serialized_to_net()
		g_server_mgr:send_to_server(line,char_id, CMD_C2M_BAG_RES_C, s_pkt)
	end
end

function faction_bag:add_op_record(time,char_name,item_name,item_cnt,type,cost)
	self.m_record_con:add(time,char_name,item_name,item_cnt,type,cost)
	self:set_record_modify_time()
	g_faction_bag_mgr:add_modify_record(self)
end

function faction_bag:get_op_record(page,page_size,op_type)
	return self.m_record_con:get(page,page_size,op_type)
end


reg_grid_builder(faction_bag.get_bag_type(),faction_bag_grid)

faction_bag_sql_log = oo.class(nil,"faction_bag_sql_log")

function faction_bag_sql_log:__init(char_id,bag)
	self.char_id = char_id
	self.char_name = g_player_mgr.all_player_l[char_id]["char_nm"]
	self.faction_id = bag:get_faction_id()
	self.bag=bag
end
function faction_bag_sql_log:get_char_id()
	return self.char_id
end
function faction_bag_sql_log:get_char_name()
	return self.char_name
end
function faction_bag_sql_log:do_add_log(notice)
	for _,grid in pairs(notice:get_grids()) do
		local faction_id = self.faction_id
		local faction_name = g_faction_mgr:get_faction_by_fid(faction_id):get_faction_name()
		local char_id 	= self:get_char_id()
		local char_name = self:get_char_name()
		local item_id = grid:get_item():get_item_id()
		local item_name = grid:get_item():get_name()
		local old_num	= notice:get_old_num(grid) or 0
		local left_num	= grid:get_item_cnt()
		local op_time	= os.time()
		local item_price = grid:get_price() or 0 
		local io = 1
		local type = 1
		local change_num = math.abs(left_num - old_num)
		local sql_str = string.format("insert log_faction_bag (faction_id,faction_name,char_id,char_name,type,io,item_id,item_name,item_num,item_left_num,remark,time) values ('%s','%s','%s','%s',%d,%d,%d,'%s',%d,%d,'%s',%d)",
							faction_id,
							faction_name,
							char_id,
							char_name,
							type,
							io,
							item_id,
							item_name,
							change_num,
							left_num,
							'',
							os.time()
							)
		g_web_sql:write(sql_str)		
		self.bag:add_op_record(op_time,char_name,item_id,change_num,type,0)
	end
end

function faction_bag_sql_log:do_sub_log(notice)
	for _,grid in pairs(notice:get_grids()) do
		local faction_id = self.faction_id
		local faction_name = g_faction_mgr:get_faction_by_fid(faction_id):get_faction_name()
		local char_id 	= self:get_char_id()
		local char_name = self:get_char_name()
		local item_id = grid:get_item():get_item_id()
		local item_name = grid:get_item():get_name()
		local old_num	= notice:get_old_num(grid) or 0
		local left_num	= grid:get_item_cnt()
		local op_time	= os.time()
		local item_price = grid:get_price() or 0 
		local io = 0
		local type = 2
		local change_num = math.abs(left_num - old_num)
		local sql_str = string.format("insert log_faction_bag (faction_id,faction_name,char_id,char_name,type,io,item_id,item_name,item_num,item_left_num,remark,time) values ('%s','%s','%s','%s',%d,%d,%d,'%s',%d,%d,'%s',%d)",
							faction_id,
							faction_name,
							char_id,
							char_name,
							type,
							io,
							item_id,
							item_name,
							math.abs(left_num - old_num),
							left_num,
							'',
							os.time()
							)
		g_web_sql:write(sql_str)		
		self.bag:add_op_record(op_time,char_name,item_id,change_num,type,item_price * change_num)
	end
end

function faction_bag_sql_log:do_des_log(notice)
	for _,grid in pairs(notice:get_grids()) do
		local faction_id = self.faction_id
		local faction_name = g_faction_mgr:get_faction_by_fid(faction_id):get_faction_name()
		local char_id 	= self:get_char_id()
		local char_name = self:get_char_name()
		local item_id = grid:get_item():get_item_id()
		local item_name = grid:get_item():get_name()
		local old_num	= notice:get_old_num(grid) or 0
		local left_num	= grid:get_item_cnt()
		local op_time	= os.time()
		local item_price = grid:get_price() or 0 
		local io = 0
		local type = 3
		local change_num = math.abs(left_num - old_num)
		local sql_str = string.format("insert log_faction_bag (faction_id,faction_name,char_id,char_name,type,io,item_id,item_name,item_num,item_left_num,remark,time) values ('%s','%s','%s','%s',%d,%d,%d,'%s',%d,%d,'%s',%d)",
							faction_id,
							faction_name,
							char_id,
							char_name,
							type,
							io,
							item_id,
							item_name,
							math.abs(left_num - old_num),
							left_num,
							'',
							os.time()
							)
	g_web_sql:write(sql_str)		
	self.bag:add_op_record(op_time,char_name,item_id,change_num,type,0)
	end
end

function faction_bag_sql_log:do_price_log(notice,pre_price)
	for _,grid in pairs(notice:get_grids()) do
		local faction_id = self.faction_id
		local faction_name = g_faction_mgr:get_faction_by_fid(faction_id):get_faction_name()
		local char_id 	= self:get_char_id()
		local char_name = self:get_char_name()
		local item_id = grid:get_item():get_item_id()
		local item_name = grid:get_item():get_name()
		local old_num	= notice:get_old_num(grid) or 0
		local left_num	= grid:get_item_cnt()
		local op_time	= os.time()
		local item_price = grid:get_price() or 0 
		local io = 2
		local type = 4
		local change_num = math.abs(left_num - old_num)
		local sql_str = string.format("insert log_faction_bag (faction_id,faction_name,char_id,char_name,type,io,item_id,item_name,item_num,item_left_num,remark,time) values ('%s','%s','%s','%s',%d,%d,%d,'%s',%d,%d,'%s',%d)",
							faction_id,
							faction_name,
							char_id,
							char_name,
							type,
							io,
							item_id,
							item_name,
							math.abs(left_num - old_num),
							left_num,
							(pre_price or 0)..'->'..item_price,
							os.time()
							)
		g_web_sql:write(sql_str)		
	end
end
