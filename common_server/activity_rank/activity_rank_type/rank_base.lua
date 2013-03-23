--20120809
--zhengyg
--rank_base

local _rank_cfg = require("activity_rank.activity_rank_loader")

rank_base = oo.class(nil,"rank_base")

function rank_base:__init()
	self.id = nil
	self.turn_on = nil --是否开启
end

function rank_base:check_update() --只能在 check_update 修改开关状态 和时间判断 ， 其他地方禁止做这种检查
	local a_o = _rank_cfg.get_activity(self:get_type())
	if a_o == nil then 
		self.turn_on = nil
		return 
	end
	if ev.time > a_o.start_t and ev.time < a_o.end_t then
		self.turn_on = true
	else
		self.turn_on = nil
		return
	end
end

function rank_base:get_end_t()
	local a_o = _rank_cfg.get_activity(self:get_type())
	if a_o == nil then 
		return 0
	end
	return a_o.end_t or 0
end

function rank_base:get_rank_limit()
	return _rank_cfg._activity_rank_cfg[self:get_type()].limit or 20
end

function rank_base:get_type()
	return nil
end

function rank_base:do_timer()
end

function rank_base:syn_map_config(server_id)
	local pkt = {['id'] = self.id, ['type']=self:get_type(), ['turn_on']= self.turn_on}
	if server_id then
		g_server_mgr:send_to_server(server_id, 0, CMD_C2M_ACTIVITY_RANK_SETTING, pkt)
	else
		g_server_mgr:send_to_all_map(0,CMD_C2M_ACTIVITY_RANK_SETTING,Json.Encode(pkt),true)
	end
	--print("-*-*-",j_e(pkt))
end

function rank_base:syn_map_rank_data(server_id)	
	local pkt = self:serialize_to_net()
	pkt.type = self:get_type()
	
	if server_id then
		g_server_mgr:send_to_server(server_id, 0, CMD_C2M_ACTIVITY_RANK_DATA, pkt)
	else
		g_server_mgr:send_to_all_map(0,CMD_C2M_ACTIVITY_RANK_DATA,Json.Encode(pkt),true)
	end
end

function rank_base:update_rank_info(pkt)
end

--[[倒序数组插入元素位置定位 算法数据结构要求:desc_list = {['cnt']=0, ['list']={}, ['map']={}}
-- new_item = {char_id, field1, field2} 元素field1 field2 指用于排序的字段
-- desc_field 用于降序的值在 new_item 里面的索引 asc_field 用到升序的值在new_item里面索引 desc_field优先级大于asc_field

魅力榜应用时 desc_field指向累积魅力值 asc_field 指向达到当前魅力值的时间戳
]]
function rank_base:locate_index_dasc(desc_list, new_item, desc_field, asc_field)
	if desc_list.cnt == 0 then
		return 1
	elseif desc_list.cnt == 1 then
		if desc_list.list[1][desc_field] >= new_item[desc_field] then
			return 2
		else
			return 1
		end
	else
		local top = desc_list.cnt
		local botton = 1
		local index = nil

		while botton < top do
			index = math.floor((top + botton)/2)
			if desc_list.list[index][desc_field] > new_item[desc_field] then
				botton = index + 1
			elseif desc_list.list[index][desc_field] == new_item[desc_field] and asc_field and desc_list.list[index][asc_field] < new_item[asc_field] then
				botton = index + 1
			else 
				top = index - 1
			end
		end	

		if not desc_list.list[top] or desc_list.list[top][desc_field] > new_item[desc_field] then
			return top + 1
		elseif desc_list.list[top][desc_field] == new_item[desc_field] and asc_field and desc_list.list[top][asc_field] < new_item[asc_field] then
			return top + 1
		else
			return top
		end
	end
end

function rank_base:table_insert(sort_table, index, item)
	table.insert(sort_table.list, index, item)

	local len = sort_table.cnt + 1
	sort_table.cnt = len
	--同步修改map映射 char_id -> order_index
	for i = index, len do
		sort_table.map[ sort_table.list[i][1] ] = i
	end
end

function rank_base:table_remove(sort_table, index)
	sort_table.map[ sort_table.list[index][1] ] = nil
	table.remove(sort_table.list, index)

	local len = sort_table.cnt - 1
	sort_table.cnt = len
	--同步修改map映射 char_id -> order_index
	for i = index, len do
		sort_table.map[ sort_table.list[i][1] ] = i
	end
end
