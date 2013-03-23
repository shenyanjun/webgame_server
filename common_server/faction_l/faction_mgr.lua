
local faction_update_loader = require("item.faction_update_loader")

local TWEL_TIME = 43200
local THIRTY_MIN = 1800

Faction_mgr = oo.class(nil, "Faction_mgr")

function Faction_mgr:__init()
	self.faction_list = {}
	self.faction_count = 0
	self.char2faction_l = {}

	--离开帮派时间
	self.leave_time ={}

	--被踢时间
	self.kick_time ={}

	--帮派之间关系
	self.faction_relate = {}					--标志位 1 为友好 2为敌对 3中立（未设置）

	--解散帮派后时间
	self.dissolve_time = {}

	--帮派领地
	self.territory = nil
end

--设置解散时间
function Faction_mgr:set_dissolve_time(char_id, time)
	self.leave_time[char_id] = time
end

function Faction_mgr:get_dissolve_time(char_id)
	return self.leave_time[char_id] or 0
end

function Faction_mgr:is_dissolve_time_ok(char_id)
	local time = self:get_dissolve_time(char_id)
	if time ~= 0 then
		if time + TWEL_TIME > ev.time then
			return false
		end
	end
	return true
end

function Faction_mgr:create_faction(obj_id,faction_name,faction_badge)
	local t_faction = Faction(obj_id,faction_name,faction_badge)
	if t_faction ~= nil then 
		if Faction_db:insert_faction(t_faction) then
			t_faction:add_member_ex(obj_id)
			self:add_member2faction(obj_id,t_faction:get_faction_id())
			self:add_faction(t_faction)
		else
			return nil
		end
	end
	return t_faction
end

function Faction_mgr:add_faction(faction)
	local faction_id = faction:get_faction_id()
	--local factioner_id = faction:get_factioner_id()
	if faction_id ~= nil then --or factioner_id ~= nil
		self.faction_list[faction_id] = faction
		--self.char2faction_l[factioner_id] = faction_id
		self:add_faction_count()
	end
end

function Faction_mgr:del_faction(faction_id)
	local faction = self.faction_list[faction_id]
	faction:set_over_flag(1)
	--Faction_db:update_faction(faction)
	--self.faction_list[faction_id] = nil
	self:del_relation_ex(faction_id)
end

function Faction_mgr:get_faction_by_fid(faction_id)
	local faction = self.faction_list[faction_id]
	if faction == nil then return end
	if faction:get_over_flag() == 1 then return end
	return self.faction_list[faction_id]
end

function Faction_mgr:get_faction_by_cid(obj_id)
	local faction_id = self.char2faction_l[obj_id]
	if faction_id ~=nil then
		return self:get_faction_by_fid(faction_id)
	end
end

function Faction_mgr:del_member(obj_id)
	self.char2faction_l[obj_id] = nil
	for k, v in pairs(self.faction_list) do
		if v.faction_player_list[obj_id] ~= nil and v:get_over_flag() == 0 then
			self.faction_list[k]:del_member_ex(obj_id)
		end
	end
end

function Faction_mgr:add_member2faction(obj_id,faction_id)
	self.char2faction_l[obj_id] = faction_id
end

function Faction_mgr:add_faction_count()
	self.faction_count = self.faction_count + 1
end

function Faction_mgr:set_faction(faction)
	local faction_id = faction:get_faction_id()
	if faction_id ~= nil then
		self.faction_list[faction_id] = faction
	end
end

function Faction_mgr:check_is_in_faction(obj_id)
	if self.char2faction_l[obj_id] ~= nil then
		return true
	end

	for k,v in pairs(self.faction_list) do
		if v:get_over_flag() == 0 and v.faction_player_list[obj_id] ~= nil then -- 
			return true
		end
	end

	return false
end

--自动退出时间
function Faction_mgr:get_leave_time(obj_id)
	return self.leave_time[obj_id] or 0
end

function Faction_mgr:set_leave_time(obj_id,time)
	if self.leave_time[obj_id] == nil then
		self.leave_time[obj_id] ={}
	end
	self.leave_time[obj_id] = time
end

--被踢时间
function Faction_mgr:get_kick_time(obj_id)
	return self.kick_time[obj_id] or 0
end

function Faction_mgr:set_kick_time(obj_id,time)
	self.kick_time[obj_id] = time
end

--创建帮派的基本条件
function Faction_mgr:get_result(obj_id, faction_name)
	local obj = g_player_mgr.online_player_l[obj_id]
	if obj == nil then return 26001 end

	if self:check_is_in_faction(obj_id) then return 26002 end

	local obj_all = g_player_mgr.all_player_l[obj_id]
	if obj_all == nil then return 26001 end
	if tonumber(obj_all["level"]) < 15 then return 26003 end

	----你退出上次帮派的时间不超过12小时
	if self:get_leave_time(obj_id) + TWEL_TIME > ev.time and self:get_leave_time(obj_id) ~= 0 then return 26004 end
	
	----你被踢的时间还未够半小时
	if self:get_kick_time(obj_id) ~= 0 and self:get_kick_time(obj_id) + TWEL_TIME > ev.time then return 26007 end

	--解散时间
	if not self:is_dissolve_time_ok(obj_id) then return 26052 end

	for k,v in pairs(self.faction_list or {}) do
		if faction_name== v.faction_name then
			return 26018
		end
	end

	return 0
	
end

--申请(邀请)加入条件判断
function Faction_mgr:get_join_result(obj_id)
	local obj = g_player_mgr.online_player_l[obj_id]
	if obj == nil then return 26001 end

	if self:check_is_in_faction(obj_id) then return 26002 end

	local obj_all = g_player_mgr.all_player_l[obj_id]
	if obj_all == nil then return 26001 end
	if tonumber(obj_all["level"]) < 15 then return 26003 end

	----你退出上次帮派的时间不超过12小时
	if self:get_leave_time(obj_id) + TWEL_TIME > ev.time and self:get_leave_time(obj_id) ~= 0 then return 26004 end
	
	----你被踢的时间还未够半小时
	if self:get_kick_time(obj_id) ~= 0 and self:get_kick_time(obj_id) + TWEL_TIME > ev.time then return 26007 end

	--解散时间
	if not self:is_dissolve_time_ok(obj_id) then return 26052 end

	return 0
end


--------------------------------------------通信信息----------------------------------------------------------
--帮派列表和帮派敌对友好关系
function Faction_mgr:get_faction_list(obj_id)
	--local t_ret = {}
	--local t ={}
	--for k,v in pairs (self.faction_list or {}) do
		--local faction=self.faction_list[k]
		--if faction ~=nil and faction:get_dissolve_flag() == 0 and faction:get_over_flag() == 0 then		
			--local ret = faction:get_faction_list_info()	
			--table.insert(t,ret)
		--end
	--end

	--t_ret.faction_list = t
	t_ret = {}
	t_ret.relate_list = {}
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		t_ret.relate_list = self:get_relate_info(faction:get_faction_id())
	end
	return t_ret
end

function Faction_mgr:seralize_to_net(t_table)
	local c = 0
	local ret = {}
	for k,v in pairs(t_table or {}) do
		c = c + 1
		ret[c] = {k,v}
	end
	return ret
end

function Faction_mgr:get_leave_time_ex(flag,leave_table,kick_table)
	local pkt = {}
	pkt.flag =  flag 
	pkt.leave_time = self:seralize_to_net(leave_table)
	pkt.kick_time = self:seralize_to_net(kick_table)
	return pkt
end
--------------------------------------------通信操作----------------------------------------------------------
--玩家上线
function Faction_mgr:online(conn,obj_id,flag)
	local faction =self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		faction:on_line(obj_id)

		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25642
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(obj_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
		if flag == 0 then
			local ret = faction:get_all_info()
			ret.result = 0
			ret.flag = flag
			ret.obj_id = obj_id
			g_server_mgr:send_to_server(conn.id,obj_id, CMD_P2M_GET_FACTION_REP, ret)

		else
			local ret = {}
			ret.result = 0
			ret.flag = flag
			ret.obj_id = obj_id
			g_server_mgr:send_to_server(conn.id,obj_id, CMD_P2M_GET_FACTION_REP, ret)
		end

		--显示头上信息
		--local ret = faction:get_head_info(obj_id)
		--g_server_mgr:send_to_server(conn.id,obj_id,CMD_P2M_PLAYER_HEAD_INFO_S,ret)
	else
		local pkt = {}
		pkt.obj_id = obj_id
		g_server_mgr:send_to_server(conn.id,obj_id, CMD_P2M_GET_FACTION_REP, pkt)
	end

	--上线同步退出帮派等时间信息
	local t_ret = self:get_leave_time_ex(0,self.leave_time,self.kick_time)
	g_server_mgr:send_to_server(conn.id,obj_id, CMD_P2M_FACTION_LEAVE_TIME_S, t_ret)
end

--玩家下线
function Faction_mgr:outline(conn,obj_id)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then 
		faction:out_line(obj_id)

		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25642
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(obj_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

	end
end

--升级
function Faction_mgr:update_level(conn,obj_id,level)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then 
		faction:update_level(obj_id,level)

		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25642
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(obj_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

	end
end


-- 玩家VIP状态改变
function Faction_mgr:vip_state_change(obj_id, vip_level)
	local faction = self:get_faction_by_cid(obj_id)
	if faction ~= nil then
		faction:vip_state_change(obj_id, vip_level)
		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25642
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(obj_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
	end
end

----服务器重启
--function Faction_mgr:reset_online_l(pkt)
	--if pkt==nil or pkt.player_list==nil then return end
	--for k,v in pairs(pkt.player_list) do
		--self:online(v.obj_id,1)
	--end
--end


---------------------------------------------------帮派建筑升级滴答----------------------------------------------------
function Faction_mgr:on_timer()
	for k, v in pairs(self.faction_list or {}) do
		local flag = 0
		if v.action_end_time ~= 0 and v.action_end_time <= ev.time then
			flag = 1
			v:update_all_level(1)
		end
		if v.book_end_time ~= 0 and v.book_end_time <= ev.time then
			flag = 2 
			v:update_all_level(2)
		end 
		if v.gold_end_time ~=0 and v.gold_end_time <= ev.time then
			flag = 3
			v:update_all_level(3)
		end
		if v.faction_update_end_time ~= 0 and v.faction_update_end_time <= ev.time then
			flag = 7
			v:update_all_level(4)
		end
		if v.warehouse_end_time ~= 0 and v.warehouse_end_time <= ev.time then -- 帮派仓库
			flag = 10
			v:update_all_level(5)
		end

		if flag ~= 0 then
			local ret = {}
			ret[1] = 11
			ret[2] = ev.time
			if flag == 1 then
				ret[3] = v:get_action_level()
			elseif flag == 2 then
				ret[3] = v:get_book_level()
				--帮派庭院 屏蔽 121114 chendon
				--g_faction_courtyard_mgr:update_censer_info(v:get_faction_id()) -- 观星阁升级，更新帮派烧香等级
			elseif flag == 3 then -- 帮派金库
				ret[3] = v:get_gold_level()
				--帮派庭院 屏蔽 121114 chendon
				--g_faction_courtyard_mgr:update_faction_money_tree(v:get_faction_id()) -- 帮派金库升级，通过更新摇钱树(铜券树)等级
			elseif flag == 7 then
				ret[3] = v:get_level()
			elseif flag == 10 then -- 帮派仓库
				ret[3] = v:get_warehouse_level()
			end
			ret[4] = flag
			v:set_history_info(ret,1)

			local new_pkt = {}
			new_pkt.faction_id = v:get_faction_id()
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1]= v:syn_info(nil,1,6)
			new_pkt.list[2]= v:syn_info(nil,1,10)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
		end
	end

end

function Faction_mgr:get_click_param()
	return self, self.on_timer,2,nil
end

----------------------------------------------------基本操作----------------------------------------------------------
--开始创建帮派 ok
function Faction_mgr:begin_create(conn, pkt,obj_id)
	self:set_leave_time(obj_id,0)
	local t_faction = self:create_faction(obj_id,pkt.faction_name,pkt.faction_badge)
	if t_faction ~= nil then
		--通知其他线
		local info = {}
		table.insert(info, t_faction:get_all_info())
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_INFO_S,Json.Encode(info),true)

		local ret = t_faction:get_all_info()
		ret.result = 0
		g_server_mgr:send_to_server(conn.id,obj_id, CMD_P2M_FACTION_CREATE_REP, ret)

		--显示头上信息
		local ret = t_faction:get_head_info(obj_id)
		g_server_mgr:send_to_server(conn.id,obj_id,CMD_P2M_PLAYER_HEAD_INFO_S,ret)

		-- 帮派神兽
		g_faction_dogz_mgr:on_line(nil, obj_id) -- 获取帮派神兽信息
		--摇钱树 屏蔽摇钱树online信息 121114 chendong
		--[[
		-- 帮派摇钱树（铜券树）
		--g_faction_courtyard_mgr:on_line(conn, obj_id, 1) -- 获取铜券树信息
		--烧香 屏蔽烧香online信息 121114 chendong
		-- 帮派烧香
		--g_faction_courtyard_mgr:on_line(conn, obj_id, 2)
		--]]
	end
end

---------------------------------------------------数据库读写------------------------------------------
function Faction_mgr:load_faction()
	local rows = Faction_db:select_all_faction()
	if rows == nil then return end
	for k,v in pairs(rows or {}) do
		if v.over_flag == 0 or v.over_flag == nil then
			local factioner_id = v.factioner_id
			local faction_name = v.faction_name
			local faction_badge = v.faction_badge
			if factioner_id ~= nil then
				local t_faction = Faction(factioner_id,faction_name,faction_badge)
				if t_faction ~= nil then
					t_faction.faction_id = v.faction_id
					t_faction.level = tonumber(v.level)
					t_faction.faction_name = v.faction_name
					t_faction.faction_badge	= tonumber(v.faction_badge)
					t_faction.territory_level = tonumber(v.territory_level)
					t_faction.money	= tonumber(v.money)
					t_faction.announcement = v.announcement
					t_faction.create_time = tonumber(v.create_time)	
					t_faction.rank = tonumber(v.rank)
					--t_faction.member_count = tonumber(v.member_count)
					t_faction.action_level = tonumber(v.action_level)
					t_faction.book_level = tonumber(v.book_level)
					t_faction.gold_level = tonumber(v.gold_level)
					-- 修改写法，因为增加了8个帮派技能
					--t_faction.action_practice = v.action_practice
					t_faction.action_practice = {}
					t_faction.action_practice[1] = v.action_practice[1] or 0
					t_faction.action_practice[2] = v.action_practice[2] or 0
					t_faction.action_practice[3] = v.action_practice[3] or 0
					t_faction.action_practice[4] = v.action_practice[4] or 0
					t_faction.action_practice[5] = v.action_practice[5] or 0
					t_faction.action_practice[6] = v.action_practice[6] or 0
					t_faction.action_practice[7] = v.action_practice[7] or 0
					t_faction.action_practice[8] = v.action_practice[8] or 0
					t_faction.action_practice[9] = v.action_practice[9] or 0
					t_faction.action_practice[10] = v.action_practice[10] or 0
					t_faction.action_practice[11] = v.action_practice[11] or 0
					t_faction.action_practice[12] = v.action_practice[12] or 0

					t_faction.book_practice = {}
					t_faction.book_practice[1] = v.book_practice[1]
					t_faction.book_practice[2] = v.book_practice[2]
					t_faction.book_practice[3] = v.book_practice[3]
					t_faction.book_practice[4] = v.book_practice[4] or 1

					t_faction.book_end_time = v.book_end_time or 0
					t_faction.gold_end_time = v.gold_end_time or 0
					t_faction.action_end_time = v.action_end_time or 0
					t_faction.faction_update_end_time = v.faction_update_end_time
					t_faction.construct_point = v.construct_point
					t_faction.technology_point = v.technology_point
					t_faction.money_tree_level = v.money_tree_level or 1
					t_faction.irrigation = v.irrigation or 0
					--t_faction.permission_list = v.permission_list
					--修改了写法，因为后来加多了一个帮派资源互换，而之前存在数据库的都没有该字段
					t_faction.permission_list = {}
					t_faction.permission_list[1] = v.permission_list[1] or {1,1,1,0}        --成员管理
					t_faction.permission_list[2] = v.permission_list[2] or {1,1,1,0}	    --帮派建设
					t_faction.permission_list[3] = v.permission_list[3] or {0,0,0,0}		--仓库权限
					t_faction.permission_list[4] = v.permission_list[4] or {1,1,0,0}		--外交权限
					t_faction.permission_list[5] = v.permission_list[5] or {1,1,1,0}		--技能研习
					t_faction.permission_list[6] = v.permission_list[6] or {1,1,0,0}		--副本开始
					t_faction.permission_list[7] = v.permission_list[7] or {0,0,0,0}	    --资源转换
					
					t_faction.warehouse_level = tonumber(v.warehouse_level) or 1 -- 帮派仓库
					t_faction.warehouse_end_time = v.warehouse_end_time or 0
					t_faction.resource_exchange_list = v.resource_exchange_list -- 资源互换列表
					t_faction.resource_exchange_time = v.resource_exchange_time -- 互换列表记录日期
					t_faction.fb_level = v.fb_level or 0
					t_faction.choose_fb_level = v.choose_fb_level or 0
					t_faction.last_kick_time = v.last_kick_time -- 保存帮派最后一次踢人时间

					t_faction.over_flag = v.over_flag or 0
					t_faction.dissolve_flag = v.dissolve_flag or 0
					if v.fb_info ~=nil and v.fb_info["switch_flag"] ~= nil then
						t_faction.fb_info = v.fb_info
					end

					local post_name	= v.post_name or {
					[1]=f_get_string(635),
					[2]=f_get_string(636),
					[3]=f_get_string(637),
					[4]=f_get_string(638),
					[5]=f_get_string(639)
					}
					t_faction.post_name[1] = post_name[1]
					t_faction.post_name[2] = post_name[2]
					t_faction.post_name[3] = post_name[3]
					t_faction.post_name[4] = post_name[4]
					t_faction.post_name[5] = post_name[5]

					local member = v.member	
					t_faction.member_count = 0
					for k,m in pairs(member or {}) do
						if self.char2faction_l[m.obj_id] ~= nil then
							f_faction_log("faction load: " .. tostring(m.obj_id ) .. " faction_id_1:" .. self.char2faction_l[m.obj_id] .. " faction_id_2:" .. t_faction.faction_id)
						end
						local player = g_player_mgr.all_player_l[m.obj_id]
						local ret = {}
						ret.obj_id = tonumber(m.obj_id)
						ret.contribution = tonumber(m.contribution)
						ret.post_index = tonumber(m.post_index)
						ret.status = m.status
						ret.salary_flag = m.salary_flag
						ret.money_tree_flag = m.money_tree_flag or 1
						ret.money_tree_time = m.money_tree_time or 0
						ret.money_tree_count = m.money_tree_count or 0
						ret.history_contribution = m.history_contribution or m.contribution
						
						ret.name = player["char_nm"]
						ret.post = player["occ"]
						ret.post_name = t_faction.post_name[ret.post_index]
						ret.faction_id = v.faction_id
						ret.level = player["level"]
						ret.gender = player["gender"]
						ret.online_flag = 0
						-- 新增字段，帮派成员vip情况
						ret.vip_level = g_vip_play_inf:get_vip_type(ret.obj_id)

						if ret.post_index < 5 and ret.post_index ~= 1 then		
							t_faction.post_num[ret.post_index] = t_faction.post_num[ret.post_index] + 1
						end
						t_faction.member_count = t_faction.member_count + 1
						t_faction.faction_player_list[ret.obj_id] = table.copy(ret)
						self:add_member2faction(ret.obj_id,t_faction.faction_id)
						--else
							--f_faction_log("faction load: " .. tostring(m.obj_id ) .. " faction_id_1:" .. self.char2faction_l[m.obj_id] .. " faction_id_2:" .. t_faction.faction_id)
						--end
					end
					self:add_faction(t_faction)
				end
			end
		end
	end
end

-------------------------------------------帮派关系------------------------------------------
function Faction_mgr:load_relation()
	local rows = Faction_db:select_faction_relate()
	if rows == nil then return end

	for k, v in pairs(rows or {}) do
		local my_faction_id	= v.my_faction_id
		local other_faction_id = v.other_faction_id
		local flag = v.flag

		if self.faction_relate[my_faction_id] == nil then
			self.faction_relate[my_faction_id] = {}
		end

		if self.faction_relate[my_faction_id][other_faction_id] == nil then
			self.faction_relate[my_faction_id][other_faction_id] = {}
		end

		self.faction_relate[my_faction_id][other_faction_id] = flag
	end
end

function Faction_mgr:add_relation(my_id,other_id,flag)
	if my_id == other_id then return 26044 end
	local faction_other = self:get_faction_by_fid(other_id)
	if faction_other:get_dissolve_flag() == 1 then return 26048 end
	local one_count = 0
	local second_count = 0
	for k, v in pairs(self.faction_relate[my_id] or {}) do
		if v == 1 then
			one_count = one_count + 1
		else
			second_count = second_count + 1
		end
	end
	if self.faction_relate[my_id] == nil then
		self.faction_relate[my_id] = {}
	end
	
	if flag == 1 and one_count >= 4 then return 26042 end   --限制4个
	if flag == 2 and second_count >=4 then return 26042 end

	local t_flag = self.faction_relate[my_id][other_id]
	if t_flag ~= flag then
		self.faction_relate[my_id][other_id] = flag
		
		local dbh = f_get_db()
		local condition = string.format("{my_faction_id:'%s',other_faction_id:'%s'}", my_id,other_id)
		local record = {}
		record.flag = flag
		record.my_faction_id = my_id
		record.other_faction_id = other_id
		local err_code = dbh:update("faction_relation", condition, Json.Encode(record),true)
		if err_code ~= 0 then
			f_faction_log("faction_relation update failed!")
		end
	end
	return 0
end

function Faction_mgr:del_relation(my_id,other_id)
	if self.faction_relate[my_id] ~= nil then
		local dbh = f_get_db()
		local condition = string.format("{my_faction_id:'%s',other_faction_id:'%s'}", my_id,other_id)
		local err_code = dbh:delete("faction_relation", condition)
		if err_code ~= 0 then
			f_faction_log("faction_relation delete failed!")
		end
		self.faction_relate[my_id][other_id] = nil
	end
end

function Faction_mgr:del_relation_ex(other_faction_id)
	--local ret = {}
	for k,v in pairs(self.faction_relate or {}) do
		if v == other_faction_id then
			--table.insert(ret,k)
			self.faction_relate[k][other_faction_id] = nil
		end
	end
	self.faction_relate[other_faction_id] = nil

	local dbh = f_get_db()
	local condition = string.format("{$or:[{other_faction_id:'%s'}, {my_faction_id:'%s'}]}",other_faction_id,other_faction_id)
	local err_code = dbh:delete("faction_relation", condition)
	if err_code ~= 0 then
		f_faction_log("faction_relation delete failed!")
	end

	--local condition = string.format("{my_faction_id:'%s'}",other_faction_id)
	--local err_code = dbh:delete("faction_relation", condition)
	--if err_code ~= 0 then
		--print("Error :",other_faction_id)
		--f_faction_log("faction_relation delete failed!")
	--end

	--return ret
end

function Faction_mgr:get_relate_info(my_id)
	local relate_list = {}
	relate_list[1] = {}		--友好
	relate_list[2] = {}		--敌对
	for k,v in pairs(self.faction_relate[my_id] or {}) do
		local faction_other = self:get_faction_by_fid(k)
		if faction_other ~= nil then
			if faction_other:get_dissolve_flag() == 0 then
				table.insert(relate_list[v], k)
			else
				self:del_relation(my_id,k)
			end
		end
	end
	return relate_list
end

--重启服务器通知
function Faction_mgr:restart_server(obj_id)
	local faction = self:get_faction_by_cid(obj_id)
	if faction then
		faction:on_line(obj_id)

		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25642
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(obj_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
	end
end

-------------------------------------------------定时写入数据------------------------------------------
function Faction_mgr:data_on_timer()
	self:seralize_faction()
end

function Faction_mgr:get_click_seralize_param(tm)
	return self,self.data_on_timer,tm,nil
end

function Faction_mgr:seralize_faction()
	--local usec_1,sec_1 = crypto.timeofday()
	for k, v in pairs(self.faction_list or {}) do 
		Faction_db:update_faction_ex(v)
	end
--
	--local usec_2,sec_2 = crypto.timeofday()
	--local temp =  math.floor(((sec_2+usec_2)-(sec_1+usec_1))*1000000)
	--print("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@Faction_mgr:seralize_faction", temp)
end

function Faction_mgr:seralize_faction_ex()
	for k, v in pairs(self.faction_list or {}) do
		for m, n in pairs(v.faction_player_list or {}) do
			if n["status"] == "0" then
				v.faction_player_list[m]["status"] = os.date("%Y.%m.%d %H:%M:%S", ev.time, ev.time)
			end
		end 
		Faction_db:update_faction(v)
	end
end


----------------------------------------------日常维护（扣除资金）--------------------------------------
function Faction_mgr:money_on_timer()
	self:money_delete()
end

function Faction_mgr:get_click_money_param(tm)
	return self,self.money_on_timer,tm,nil
end

function Faction_mgr:money_delete()
	for k, v in pairs(self.faction_list or {}) do
		v:money_maintenance()
	end
end


-------------------------------------------重启同步 ------------------------------------------
function Faction_mgr:syn_all_faction(server_id)
	local ret = {}
	for k, v in pairs(self.faction_list or {}) do
		if v:get_over_flag() == 0 then
			table.insert(ret, v:get_all_info())
		end
	end
	g_server_mgr:send_to_server(server_id,0,CMD_P2M_FACTION_INFO_S,ret)
end


--是否可以合并
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

	if Application_filter:get_faction_id() == other_faction:get_faction_id() then return 26069 end

	return 0
end

function Faction_mgr:faction_merge(obj_id_s, obj_id_d)
	local my_faction = self:get_faction_by_cid(obj_id_s)
	local other_faction = self:get_faction_by_cid(obj_id_d)

	local my_player_list = my_faction:get_player_list()
	local other_player_list = other_faction:get_player_list()

	return my_faction:faction_merge(other_player_list, other_faction:get_faction_id())
end

function Faction_mgr:change_name(char_id,name)
	local faction = self:get_faction_by_cid(char_id)
	if not faction then return end

	if faction:get_factioner_id() ~= char_id then return end
	
	for k,v in pairs(self.faction_list or {}) do
		if faction_name== v.faction_name then
			return
		end
	end

	faction:set_faction_name(name)

	local new_pkt = {}
	new_pkt.faction_id = faction:get_faction_id()
	new_pkt.cmd =25642
	new_pkt.list ={}
	new_pkt.list[1] = faction:syn_info(nil,1,14)
	g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
end

function Faction_mgr:change_player_name(char_id, name)
	local faction = self:get_faction_by_cid(char_id)
	if faction then
		faction.faction_player_list[char_id].name = name

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1] = faction:syn_info(char_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
	end
end

function Faction_mgr:change_player_occ(char_id, occ)
	local faction = self:get_faction_by_cid(char_id)
	if faction then
		faction.faction_player_list[char_id].post = occ

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1] = faction:syn_info(char_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
	end
end

function Faction_mgr:change_player_gender(char_id, gender)
	local faction = self:get_faction_by_cid(char_id)
	if faction then
		faction.faction_player_list[char_id].gender = gender

		local new_pkt = {}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1] = faction:syn_info(char_id,1,2)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
	end
end

function Faction_mgr:set_battle_info(faction_id,flag,scene_id)
	local faction = self:get_faction_by_fid(faction_id)
	if faction then
		faction:set_battle_info(flag, scene_id)
		--同步信息
		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25642
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(nil,1,15)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
	end
end

--设置金钱，科技点，建设度 flag 1:金钱，2科技点 3建设度
function Faction_mgr:set_ctm_info(faction_id,count,flag)
	local faction = self:get_faction_by_fid(faction_id)
	if faction then
		if flag == 1 then
			local money = faction:get_money()
			faction:set_money(math.max(0, money + count))
		elseif flag == 2 then
			local technology_point = faction:get_technology_point()
			faction:set_technology_point(math.max(0, technology_point + count))
		elseif flag == 3 then
			local construct_point = faction:get_construct_point()
			faction:set_construct_point(math.max(0, construct_point + count))
		end

		local new_pkt ={}
		new_pkt.faction_id = faction:get_faction_id()
		new_pkt.cmd = 25642
		new_pkt.list={}
		new_pkt.list[1]= faction:syn_info(nil,1,7)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
	end
end


