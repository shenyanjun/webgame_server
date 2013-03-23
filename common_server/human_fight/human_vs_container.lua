
local slave_sys_loader = require("config.loader.slave_sys_loader")
local BASE_COUNT = 20
local MAX_ADD_COUNT = 5
local SLAVE_MEMBER_COUNT = 5  --最多5个奴隶
local DEFEATED_MEMBER_COUNT = 20 --手下败将人数 20
local SLAVE_ENEMY_COUNT = 10  --夺仆之敌人数
local OLD_OWNER_MEMBER_COUNT = 10  --我的旧主人数
local LIBERATION_COUNT = 20 --解放奴隶人数
local OPERA_COUNT = 10  --调戏奴隶次数
local BE_OPERA_COUNT = 3 --被调戏次数

Human_vs_container = oo.class(nil,"Human_container")

function Human_vs_container:__init(char_id)
	self.char_id = char_id

	--可以挑战次数
	self.count = BASE_COUNT

	--挑战剩余时间
	self.time_span = 0

	--分数
	self.point = 0

	--挑战胜率 第一位为胜 第二位为负
	self.vs_list = {0,0}

	self.human_obj = nil

	--挑战时间
	self.challenge_time = 0

	--录像
	self.vedio_con = nil

	--计数
	self.dis_count = 0

	--每天增加的次数上限
	self.max_add_count = MAX_ADD_COUNT

	--判断时间以防连续刷
	self.time_d = 0

	--奴隶操作次数
	self.s_count = OPERA_COUNT

	--奴隶列表 id, 呢称
	self.slave_list = {}    -- {{char_id,name}}

	--奴隶主
	self.slave_owner = nil

	--手下败将 {char_id,char_id}  --要排序，日，不然用键值对了
	self.defeated_member = {}

	--旧主 {char_id,char_id}
	self.old_owner = {}

	--夺仆之敌 {char_id,char_id}
	self.slave_enemy = {}

	--被调戏次数
	self.be_s_count = BE_OPERA_COUNT

	--调戏时间限制
	self.s_time = 0

end

function Human_vs_container:get_left_s_time()
	local time_span = self.s_time - ev.time
	return time_span > 0 and time_span or 0
end

function Human_vs_container:set_s_time(time)
	self.s_time = time
end

function Human_vs_container:get_be_s_count()
	return self.be_s_count
end

function Human_vs_container:del_be_s_count(count)
	self.be_s_count = self.be_s_count - count
end

function Human_vs_container:set_be_s_count(count)
	if count == nil then
		count = BE_OPERA_COUNT
	end
	self.be_s_count = count
end

function Human_vs_container:get_reward(char_id_d, flag)
	local lv_s = g_player_mgr.all_player_l[self.char_id].level
	local lv_d = g_player_mgr.all_player_l[char_id_d].level

	local param_1 = 1 
	local param_2 = 1
	local dis = lv_s - lv_d
	if dis > 5 then
		param_1 = 0
	elseif dis < -5 then
		param_1 = 2
	end

	if dis >= 5 then
		param_2 = 0
	elseif dis <= -5 then
		param_2 = 2
	end

	local exp = lv_d * 1000 * param_1
	local money = lv_d * 30 * param_2

	local loader = slave_sys_loader.slave_reward[flag]
	local type = loader[1]
	if loader == 1 then
		return exp
	else
		return money
	end
end

function Human_vs_container:is_on_table(table_info, char_id)
	for k,v in pairs(table_info) do
		if v == char_id then
			return true
		end
	end

	return false
end

function Human_vs_container:is_on_table_ex(table_info, char_id)
	for k,v in pairs(table_info) do
		if v[1] == char_id then
			return true
		end
	end

	return false
end

function Human_vs_container:set_s_count(count)
	if count == nil then
		count = OPERA_COUNT
	end
	self.s_count = count
end

function Human_vs_container:set_slave_info(s_info)
	self.slave_list = self:serialize_info(s_info[1] or {})
	self.defeated_member = self:serialize_info(s_info[2] or {})
	self.old_owner = self:serialize_info(s_info[3] or {})
	self.slave_enemy = self:serialize_info(s_info[4] or {})
end

function Human_vs_container:get_s_count()
	return self.s_count
end

function Human_vs_container:del_s_count(count)
	self.s_count = self.s_count - count
end

function Human_vs_container:get_slave_owner()
	return self.slave_owner
end

function Human_vs_container:set_slave_owner(slave_owner)
	self.slave_owner = slave_owner
end

function Human_vs_container:get_slave_member_count()
	return table.size(self.slave_list)
end

function Human_vs_container:is_slave_list_full()
	if table.size(self.slave_list) >= SLAVE_MEMBER_COUNT then
		return true
	end

	return false
end

function Human_vs_container:add_slave(char_id)
	self:del_slave(char_id)
	table.insert(self.slave_list, 1, {char_id,""})
	if table.size(self.slave_list) > SLAVE_MEMBER_COUNT then
		table.remove(self.slave_list, SLAVE_MEMBER_COUNT + 1)
	end
end

function Human_vs_container:del_slave(char_id)
	for index, v in pairs(self.slave_list) do
		if v[1] == char_id then
			self.slave_list[index] = nil
		end
	end
end

function Human_vs_container:get_slave_list()
	return self.slave_list
end

function Human_vs_container:set_slave_name(char_id, name)
	for k, v in pairs(self.slave_list) do
		if v[1] == char_id then
			v[2] = name
			return
		end
	end
end

function Human_vs_container:del_defeated_member(char_id)
	for index, v in pairs(self.defeated_member) do
		if v == char_id then
			self.defeated_member[index] = nil
		end
	end
end

function Human_vs_container:add_defeated_member(char_id)
	self:del_defeated_member(char_id)
	table.insert(self.defeated_member, 1, char_id)
	if table.size(self.defeated_member) > DEFEATED_MEMBER_COUNT then
		table.remove(self.defeated_member, DEFEATED_MEMBER_COUNT + 1)
	end
end

function Human_vs_container:get_defeated_member()
	return self.defeated_member
end

function Human_vs_container:del_old_owner(char_id)
	for index, v in pairs(self.old_owner) do
		if v == char_id then
			self.old_owner[index] = nil
		end
	end
end

function Human_vs_container:add_old_owner(char_id)
	self:del_old_owner(char_id)
	table.insert(self.old_owner, 1, char_id)
	if table.size(self.old_owner) > OLD_OWNER_MEMBER_COUNT then
		table.remove(self.old_owner,OLD_OWNER_MEMBER_COUNT + 1)
	end

end

function Human_vs_container:get_old_owner()
	local info = self.old_owner
	local slave_owner = self:get_slave_owner()
	if slave_owner then
		self:del_old_owner(slave_owner)
		table.insert(info, 1, slave_owner)
	end

	return info
end

function Human_vs_container:del_slave_enemy(char_id)
	for index, v in pairs(self.slave_enemy) do
		if v == char_id then
			self.slave_enemy[index] = nil
		end
	end
end

function Human_vs_container:add_slave_enemy(char_id)
	self:del_slave_enemy(char_id)
	table.insert(self.slave_enemy, 1, char_id)
	if table.size(self.slave_enemy) > SLAVE_ENEMY_COUNT then
		table.remove(self.slave_enemy,SLAVE_ENEMY_COUNT + 1)
	end
end

function Human_vs_container:get_slave_enemy()
	return self.slave_enemy
end

function Human_vs_container:get_slave_info()
	local slave_info = {}
	local flag = 0
	local human_vs_mgr = g_human_vs_mgr
	for index, v in pairs(self.slave_list) do
		local container = human_vs_mgr:get_container(v[1])
		if container then
			local list = {}
			list[1] = v[1]  --char_id
			list[2] = g_player_mgr.all_player_l[v[1]].char_nm  --奴隶名称
			list[3] = v[2] or ""  --呢称
			list[4] = container:get_fight() --战斗力
			list[5] = container:get_slave_member_count() --奴隶人数
			list[6] = container:get_slave_owner() and 1 or 0
			list[7] = g_player_mgr.all_player_l[v[1]].occ
			list[8] = g_player_mgr.all_player_l[v[1]].gender
			list[9] = g_player_mgr.all_player_l[v[1]].level
			list[10] = container:get_be_s_count()
			table.insert(slave_info, list)
		else
			flag = 1
			self.slave_list[index] = nil
		end
	end

	local slave_owner = self:get_slave_owner()
	local name =""
	if slave_owner then
		name = g_player_mgr.all_player_l[slave_owner].char_nm
	end
	local self_info = {slave_owner or 0,
	self:get_slave_member_count(),
	self:get_s_count(),
	name,
	self:get_left_s_time()
	}

	if flag == 1 then
		self:update_player()
	end

	return slave_info, self_info
end

function Human_vs_container:get_table_info(char_id)
	
	local container = g_human_vs_mgr:get_container(char_id)

	local list = {}
	list[1] = char_id
	list[2] = g_player_mgr.all_player_l[char_id].char_nm  --奴隶名称
	list[3] = container:get_fight() --战斗力
	list[4] = container:get_slave_member_count() --奴隶人数
	list[5] = container:get_slave_owner() and 1 or 0
	list[6] = g_player_mgr.all_player_l[char_id].occ
	list[7] = g_player_mgr.all_player_l[char_id].gender
	list[8] = g_player_mgr.all_player_l[char_id].level
	local slave_owner = container:get_slave_owner()
	list[9] = slave_owner and g_player_mgr.all_player_l[slave_owner].char_nm or ""
	local faction = g_faction_mgr:get_faction_by_cid(char_id)
	list[10] = faction and faction:get_faction_name() or ""

	return list
end

--获取手下败将，夺仆之敌，旧主面板信息
function Human_vs_container:get_message_info(table_info)
	local ret = {}
	local flag = 0
	local human_vs_mgr = g_human_vs_mgr
	for index, char_id in pairs(table_info) do
		local container = human_vs_mgr:get_container(char_id)
		if container then
			local list = self:get_table_info(char_id)
			table.insert(ret, list)
		else
			table_info[index] = nil
			flag = 1
		end
	end

	if flag == 1 then
		self:update_player()
	end

	return ret
end

--获取解放奴隶列表
function Human_vs_container:get_liberation_info()
	local faction = g_faction_mgr:get_faction_by_cid(self.char_id)
	local ret = {}
	if faction then
		local human_vs_mgr = g_human_vs_mgr
		local count = 0
		for char_id, _ in pairs(faction:get_player_list()) do
			if count < LIBERATION_COUNT then
				local container = human_vs_mgr:get_container(char_id)
				if container and char_id ~= self.char_id then
					local slave_owner = container:get_slave_owner()
					if slave_owner then
						local container_owner = human_vs_mgr:get_container(slave_owner)
						if container_owner and slave_owner ~= self.char_id then
							local list = self:get_table_info(char_id)
							table.insert(ret, list)
							count = count + 1
						elseif not container_owner then
							container:set_slave_owner()
							container:update_player()
						end
					end
				end
			else
				break
			end
		end
	end

	return ret
end

function Human_vs_container:del_max_add_count()
	self.max_add_count = self.max_add_count - 1
end

function Human_vs_container:is_full_add_count()
	if self.max_add_count <= 0 then
		return true
	end

	return false
end

function Human_vs_container:get_fight()
	return self.human_obj:get_fight()
end

function Human_vs_container:reset()
	self.point = 0
	self.vs_list = {0,0}
end

function Human_vs_container:get_day_time()
	local l_time = self.challenge_time
	local time_today ={}
	time_today.year = os.date("%Y",l_time)
	time_today.month = os.date("%m",l_time)
	time_today.day = os.date("%d",l_time)
	time_today.hour = 0
	time_today.minute = 0
	time_today.second = 0
	local t_time = os.time(time_today)
	return t_time
end

function Human_vs_container:is_other_day(num)     --上线时判断
	if num == nil then num = 1 end
	if ev.time >= self:get_day_time() + num * 86400 then
		self.count = BASE_COUNT
		self.challenge_time = ev.time
		self.s_count = OPERA_COUNT
		self.be_s_count = BE_OPERA_COUNT
		self:reset_slave()
		return true
	end
	return false
end

function Human_vs_container:reset_slave()
	for k, v in pairs(self.slave_list) do
		local container = g_human_vs_mgr:get_container(v[1])
		if container then 
			container:set_be_s_count()
		end
	end
end

function Human_vs_container:get_point()
	return self.point
end

function Human_vs_container:set_point(point)
	self.point = point
end

function Human_vs_container:get_char_id()
	return self.char_id
end

function Human_vs_container:get_count()
	return self.count
end

function Human_vs_container:set_count(count)
	self.count = count
end

function Human_vs_container:is_count_full()
	if self.count <= 0 then
		return true
	end

	return false
end

function Human_vs_container:can_be_fight()
	if self:is_count_full() then 
		return 22651
	elseif self:get_left_time() > 0 then
		return 22652
	end

	return 0
end

function Human_vs_container:is_fresh_all_time()
	if math.abs(ev.time - self.time_d) < 1 then
		return true
	else
		self.time_d = ev.time
	end

	return false
end

function Human_vs_container:get_left_time()
	local time_l = self.time_span - ev.time
	if time_l < 0 then
		return 0
	end

	return time_l
end

function Human_vs_container:add_dis_count()
	self.dis_count = self.dis_count + 1
end

function Human_vs_container:set_time_span(time_span)
	local count = self:get_count()
	if count%5 == 0 and count ~= 0 then
		self.time_span = time_span
	else
		self.time_span = 0
	end
end

function Human_vs_container:get_vs_list()
	return self.vs_list
end

function Human_vs_container:set_vs_list(vs_list)
	self.vs_list = vs_list
end

--设置胜负盘数 flag:1 为胜 2为负
function Human_vs_container:set_winning(flag)
	self.vs_list[flag] = self.vs_list[flag] + 1
end

function Human_vs_container:set_challenge_time(time)
	self.challenge_time = time
end

function Human_vs_container:get_percent()
	local win = self.vs_list[1]
	local lost = self.vs_list[2]
	local sum = win + lost
	if sum <= 0 then
		return 0
	end

	return win/sum
end

function Human_vs_container:get_human_obj()
	return self.human_obj
end

function Human_vs_container:get_vedio_con()
	return self.vedio_con
end

--更新人物属性
function Human_vs_container:update_list(pkt)
	if self.human_obj == nil then
		self.human_obj = Human_obj(self.char_id)
	end
		
	self.human_obj:update_list(pkt)
end

--加载human_obj
function Human_vs_container:load_human_obj()
	if self.human_obj == nil then
		self.human_obj = Human_obj(self.char_id)
		self.human_obj:load()
	else
		self.human_obj:reset_hp_mp()
	end
end

--加载录像
function Human_vs_container:load_vedio_con()
	if self.vedio_con == nil then
		self.vedio_con = Human_vedio_container(self.char_id)
		self.vedio_con:load()
	end
end

function Human_vs_container:load()
	self:load_human_obj()
	self:load_vedio_con()
end


function Human_vs_container:get_net_info()
	local ret = {}
	--基础信息
	ret.base_info = {}
	ret.base_info[1] = self:get_fight()
	ret.base_info[2] = g_human_vs_mgr:get_rank_by_id(self.char_id)  --排行
	ret.base_info[3] = self:get_point()
	ret.base_info[4] = self:get_vs_list()
	ret.base_info[5] = self:get_left_time()
	ret.base_info[6] = self:get_count()

	--挑战列表
	ret.chellange_info = g_human_vs_mgr:get_char_info(self.char_id)

	--上周第一名
	ret.win_info = g_human_vs_mgr:get_last_winner()

	return ret
end

function Human_vs_container:serialize_info(table_info)
	local ret = {}
	for k,v in pairs(table_info) do
		table.insert(ret,v)
	end
	return ret
end


function Human_vs_container:update_player()
	local ret = {}
	ret.char_id = self.char_id
	ret.count = self.count
	ret.challenge_time = self.challenge_time
	ret.time_span = self.time_span
	ret.point = self.point
	ret.vs_list = self.vs_list

	--奴隶操作次数
	ret.s_count = self.s_count
	ret.slave_owner = self.slave_owner

	--奴隶列表 id, 呢称
	ret.slave_info = {}
	ret.slave_info[1] = self.slave_list or {}
	ret.slave_info[2] = self.defeated_member or {}
	ret.slave_info[3] = self.old_owner or {}
	ret.slave_info[4] = self.slave_enemy or {}

	ret.be_s_count = self.be_s_count
	ret.s_time = self.s_time

	local db = f_get_db()
	local condition = string.format("{char_id:%d}", self.char_id)
	db:update("human_fight", condition, Json.Encode(ret), true)
end






