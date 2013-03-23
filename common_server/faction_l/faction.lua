--2011-01-14
--laojc
--帮派基类
--require("email/gm_email")

--帮派升级（演武厅，观星阁，建设点，科技点，帮贡）
FACTION = {
	action_level 		= 	1,    	--演武厅
	book_level   		= 	2,	  	--观星阁
	gold_level   		= 	3,		--金库
	construct_point 	= 	4,		--建设点
	technology_point 	= 	5,		--科技点
	contribution 		= 	6,		--帮贡
	faction_level       =   7,		--帮派等级
	faction_money       =   8,		--帮派资金
	money_tree_level    =   9,		--摇钱树
	warehouse_level     =  10,      -- 帮派仓库
}

--演武厅修炼升级
ACTION_PRACTICE = {
	strengh 			= 	1,		--根骨
	intelligence 		= 	2,		--悟性
	defense 			= 	3,		--防御
	attack 				= 	4,		--攻击
	s_attack            =   5,      -- 利器支配，物攻
	m_attack            =   6,      -- 法器支配，法功
	critical            =   7,      -- 致命一击，暴击
	critical_ef         =   8,      -- 爆破伤害，暴击效果
	point               =   9,      -- 专注，命中
	dodge               =  10,      -- 逍遥步，闪避
	critical_df         =  11,      -- 规律洞察，暴击抵抗
	d_critical_ef       =  12,      -- 坚韧，暴击效果抵抗
}

--观星阁修炼
BOOK_PRACTICE = {
	attack 				= 	1,		--攻击加成
	defense 			= 	2,		--防御加成
	expr 				= 	3,		--经验加成
	inspire				=   4,      --振奋加成
}

--摇钱树灌溉
MONEY_TREE = {
	irrigation			=   1,		--灌溉或摇钱

}

local KICK_TIME_LEN = 10*60 -- 帮派踢人冷却时间

--local MEMBER_MAX = 30    --成员上限
local JOIN_MAX = 30      --申请上限
local HOUR = 60*60

 -----不同等级 各职务的人数个数限定
--local post_count={
	--{1,1,1,2,0}, --level=1
	--{1,1,1,3,0}, --level=2
	--{1,1,2,4,0},
	--{1,1,3,5,0},
	--{2,2,4,6,0}
	--}


local faction_update_loader = require("item.faction_update_loader")
local faction_resource_exchange_loader = require("config.loader.faction_resource_exchange_loader")


Faction = oo.class(nil, "Faction")

function Faction:__init(obj_id,faction_name,faction_badge)
	self.level = 1
	self.faction_id = crypto.uuid()

	self.faction_badge=faction_badge  --徽章
	self.faction_name=faction_name    --帮派名
	self.territory_level=0            --领地等级
	self.money=88000
	self.rank=1                       --排名
	self.announcement=nil             --管理公告

	self.post_name =                  --职位名
	{
	    [1]=f_get_string(635),--gbk_utf8("帮主")
	    [2]=f_get_string(636),--gbk_utf8("副帮主")
	    [3]=f_get_string(637),--gbk_utf8("长老"),
	    [4]=f_get_string(638),--gbk_utf8("护法"),
	    [5]=f_get_string(639)--gbk_utf8("帮众")
	}

	self.post_num={            ---保存各种职务的人数
	[1]=1,    ---帮主个数
	[2]=0,    ---副帮主
	[3]=0,    ---法老
	[4]=0,    ---护法
	[5]=0
	}

	self.create_time = ev.time        --创建时间
	self.faction_player_list = {}	  --人员列表

	self.factioner_id = obj_id

	self.member_count = 1             --人员总数

	self.join_l = {}                  --申请加入列表

	--self:add_member_ex(obj_id)

	--演武厅
	self.action_level 		= 1 				--演武厅等级 
	self.action_practice 	= {0,0,0,0,0,0,0,0,0,0,0,0}   	--{根骨修炼等级，悟性等级，抗性等级，攻击等级, 5物攻，6法功，7暴击，8暴击效果，9命中，10闪避，11暴击抵抗，12暴击效果抵抗}
	self.action_end_time 	= 0					--演武厅升级结束时间
	
	--观星阁
	self.book_level 		= 1					--观星阁等级  
	self.book_practice 		= {1,1,1,1}			--{攻击加成等级，防御加成等级，经验加成等级，振奋加成等级}
	self.book_end_time		= 0					--观星阁升级结束时间

	--金库
	self.gold_level			= 1					--金库等级
	self.gold_end_time		= 0					--金库升级结束时间

	-- 帮派仓库
	self.warehouse_level    = 1
	self.warehouse_end_time = 0

	--建设度
	self.construct_point 	= 0

	--科技度
	self.technology_point	= 0

	self.faction_update_end_time = 0 			--帮派升级结束时间

	--权限
	self.permission_list    = {
								{1,1,1,0},        --成员管理
								{1,1,1,0},		  --帮派建设
								{0,0,0,0},		  --仓库权限
								{1,1,0,0},		  --外交权限
								{1,1,1,0},		  --技能研习
								{1,1,0,0},		  --副本开始
								{0,0,0,0},		  --资源转换	
							  }

	--摇钱树
	self.money_tree_level = 1					  --摇钱树等级
	self.irrigation = 0							  --灌溉值

	--历史消息
	self.history_info = {}

	--封闭状态
	self.dissolve_flag = 0 						--0为未封闭 1 为已封闭

	--解散状态
	self.over_flag = 0							--0为未解散 1为已解散

	--副本次数和时间
	self.fb_info = {}
	self.fb_info["switch_flag"] = 0             --开关
	self.fb_info["cur_scene_id"] = ""

	--约战开始关闭标志
	self.battle_info = {0,""}					--0是关闭 1是开启

	--用来定期分散插入数据库
	self.db_time = 0

	--帮派资源互换，帮派资金、建设点、科技点出售数量表
	self.resource_exchange_list = {0, 0, 0}
	self.resource_exchange_time = os.date("%x",os.time()) -- 保存日期，为了是实现每日重置列表数值

	--帮派副本等级
	self.fb_level = 0
	-- 玩家选中的帮派副本等级
	self.choose_fb_level = 0

	-- 保存帮派最后一次踢人时间
	self.last_kick_time = nil 
end


function Faction:set_choose_fb_level(level)
	if level == 1 then
		self.choose_fb_level = 1
		return 0
	elseif level <= self:get_fb_level() then
		self.choose_fb_level = level
		return 0
	end
	return 26077 -- 选中帮派副本等级超过现已打通帮派副本等级，不能进入
end

function Faction:get_choose_fb_level()
	return self.choose_fb_level
end

function Faction:set_fb_level(level)
	self.fb_level = level
end

function Faction:get_fb_level()
	return self.fb_level
end

function Faction:is_time_ok()
	local t_time = crypto.random(1,180) * 4
	if self.db_time + t_time <= ev.time then
		return true
	end
	return false
end

function Faction:get_db_time()
	return self.db_time
end

function Faction:set_db_time(time)
	self.db_time = time
end

-----------------------------------------------基本操作---------------------------------------------------------
--添加人员
function Faction:add_member(obj_s_id,obj_d_id)
	local obj_s = g_player_mgr.online_player_l[obj_s_id]
	if obj_s == nil then return end
	if self.faction_player_list[obj_s_id] == nil then return 26010 end  --你的权限不够

	if self.faction_player_list[obj_d_id] == nil and not self:is_member_full() then
		self.faction_player_list[obj_d_id] = self:create_member(obj_d_id)
		self:add_member_count(1)
		g_faction_mgr:add_member2faction(obj_d_id,self.faction_id)
		self:del_join_link(obj_d_id)

		--Faction_db:update_faction(self)
		return 0
	else
		return 26008
	end
end

--帮主创建帮派时的初始化人员列表
function Faction:add_member_ex(obj_id)
	self.faction_player_list[obj_id] = self:create_member(obj_id)
	self:set_post(obj_id,1)
end

--玩家被邀请后确定加入
function Faction:add_member_ex_f(obj_id)
	if self.faction_player_list[obj_id] == nil and not self:is_member_full() then
		self.faction_player_list[obj_id] = self:create_member(obj_id)
		self:add_member_count(1)
		g_faction_mgr:add_member2faction(obj_id,self.faction_id)
		self:del_join_link(obj_id)
		--Faction_db:update_faction(self)
		return 0
	end
	return nil 
end

function Faction:create_member(obj_id)
	local obj = g_player_mgr.all_player_l[obj_id]
	local t = {}
	if obj ~= nil then
		t["obj_id"] = obj_id
		t["contribution"] = 0                                        --贡献值
		t["post_index"] = 5										     --职位标志位
		t["status"] = "0"
		t["salary_flag"] = 0										 -- 表示领取工资那时刻的时间戳
		t["money_tree_flag"] = 1									 -- 摇钱获取经验等  标志位 1表示灌溉，0 代表摇钱
		if self.irrigation == 0 then
			t["money_tree_flag"] = 0
		end
		t["money_tree_time"] = 0									 -- 灌溉时间
		t["history_contribution"] = 0								 -- 历史贡献值
		t["money_tree_count"] = 0									 -- 摇的次数

		--下面玩家数据不必要插入数据库的
		t["name"] = g_player_mgr.all_player_l[obj_id]["char_nm"]
		t["post"] = g_player_mgr.all_player_l[obj_id]["occ"]         --角色
		t["faction_id"] = self.faction_id
		t["level"] = g_player_mgr.all_player_l[obj_id]["level"]
		t["gender"] = g_player_mgr.all_player_l[obj_id]["gender"]
		t["online_flag"] = 1                            --1 在线 0 非在线
		-- 新增字段，帮派成员vip情况
		t["vip_level"] = g_vip_play_inf:get_vip_type(obj_id)
		return t
	end
end

function Faction:set_salary_flag(obj_id,flag)
	if self.faction_player_list[obj_id] ~= nil then
		self.faction_player_list[obj_id]["salary_flag"] = flag
	end
end

function Faction:get_salary_flag(obj_id)
	return self.faction_player_list[obj_id].salary_flag
end

function Faction:reset_salary_flag()
	for k,v in pairs(self.faction_player_list or{}) do
		v.salary_flag = 0
	end
end

function Faction:is_fetch_salary_ok(obj_id)
	local time_l = self:get_salary_flag(obj_id)
	local str_time = os.date("%x",time_l)
	local str_now = os.date("%x",ev.time)
	if str_time ~= str_now then
		return 1
	end
	return 0
end

--批准加入
function Faction:approve_join(obj_s_id,obj_d_id)
	if self.join_l[obj_d_id]~=nil then
		return self:add_member(obj_s_id,obj_d_id)
	end
	return nil
		
end
--申请退出
function Faction:out_faction(obj_id)
	local obj = g_player_mgr.online_player_l[obj_id]
	if obj ~= nil then
		return self:del_member(obj_id)
	end
end

-- 踢人操作，时间上是否是否
function Faction:is_kick_time_permit()
	local last_kick_time = self:get_last_kick_time()
	if last_kick_time ~= nil then
		if last_kick_time+KICK_TIME_LEN < ev.time then
			return 0
		else
			return 26076, last_kick_time+KICK_TIME_LEN - ev.time
		end
	else
		return 0
	end
end

-- 获取最后一次踢人的时间
function Faction:get_last_kick_time()
	return self.last_kick_time
end

-- 设置最后一次踢人的时间
function Faction:set_last_kick_time(kick_time)
	self.last_kick_time = kick_time or ev.time
end



--踢人
function Faction:kick_member(obj_s_id,obj_d_id)
	if self.faction_player_list[obj_s_id] == nil or self.faction_player_list[obj_d_id] == nil then return end
	local s_index = self.faction_player_list[obj_s_id]["post_index"]
	local d_index = self.faction_player_list[obj_d_id]["post_index"]

	if s_index >= d_index then  return 26010, 0 end

	if self.level >= 3 then -- 帮派等级大于等于3级时，添加踢人时间保护
		local e_code, kick_time = self:is_kick_time_permit()
		if e_code ~= 0 then return e_code, kick_time end
	end
	return self:del_member(obj_d_id)
end

function Faction:del_member(obj_id)
	if self.faction_player_list[obj_id] ~= nil then
		local index = self.faction_player_list[obj_id]["post_index"]
		if index == 1 then 
			return 26015 
		else
			self:del_member_ex(obj_id)
			self:set_last_kick_time(ev.time) -- 设置最后一次踢人时间
			g_faction_mgr:del_member(obj_id)

			Faction_db:update_faction(self)
			return 0
		end	
	end
end

function Faction:del_member_ex(obj_id)
	if self.faction_player_list[obj_id] ~= nil then
		local index = self.faction_player_list[obj_id]["post_index"]
		self.post_num[index]=self.post_num[index]-1
		self.faction_player_list[obj_id]=nil
		self:add_member_count(-1)
	end
end

--卸任
function Faction:outgoing(obj_id, other_id)
	if self.faction_player_list[obj_id]~=nil then
		local index=self.faction_player_list[obj_id]["post_index"]
		if self.faction_player_list[other_id]~= nil then
			if index == 1 then
				--local char_id = self:demise()             --获取帮主接任人id
				if other_id ~= nil then
					local result = self:transfer(other_id)         --转交职务
					if result == 0 then
						return result,other_id
					end
				else
					return 26019
				end
			elseif index < 5 then
				self:set_post(obj_id,5)
				self.post_num[index]=self.post_num[index]-1
				--Faction_db:update_faction(self)
				return 0, nil		
			end
			return 0, nil
		else
			if index ~= 1 then
				self:set_post(obj_id,5)
				self.post_num[index]=self.post_num[index]-1
				--Faction_db:update_faction(self)
				return 0, nil	
			end	
		end
	end
end

--禅让(获取接掌门的玩家id)
function Faction:demise()
	local fubang={
		[1]=0,   --标志位
		[2]=0,   --等级
		[3]=0    --角色id
	}

	local zhanglao={
		[1]=0,
		[2]=0,
		[3]=0
	}

	local hufa ={
		[1]=0,
		[2]=0,
		[3]=0
	}

	local bangzhong ={
		[1]=0,
		[2]=0,
		[3]=0
	}
	for k,v in pairs(self.faction_player_list) do
		if v["post_index"] == 2 then
			if v["level"]>fubang[2] then
				fubang[2]=v["level"]
				fubang[3]=v["obj_id"]
				fubang[1]=1
			end
		elseif v["post_index"] == 3 then
			if v["level"]>zhanglao[2] then
				zhanglao[2]=v["level"]
				zhanglao[3]=v["obj_id"]
				zhanglao[1]=1
			end
		elseif v["post_index"] == 4 then
			if v["level"]>hufa[2] then
				hufa[2]=v["level"]
				hufa[3]=v["obj_id"]
				hufa[1]=1
			end
		else
			if v["post_index"]==5 then
				if v["level"]>bangzhong[2] then
					bangzhong[2]=v["level"]
					bangzhong[3]=v["obj_id"]
					bangzhong[1]=1
				end
			end
		end
	end

	if fubang[1] == 1 then
		return fubang[3]
	elseif zhanglao[1] == 1 then 
		return zhanglao[3]
	elseif hufa[1] ==1 then
		return hufa[3]
	elseif bangzhong[1] == 1 then
		return bangzhong[3]
	else 
		return nil
	end
end

function Faction:transfer(obj_id)             --转让帮主
	local char_id=self.factioner_id
	local index = self.faction_player_list[obj_id]["post_index"]
	self:set_post(char_id,5)
	self:set_post(obj_id,1)
	self:set_factioner_id(obj_id)
	if index < 5 then		
		self.post_num[index] = self.post_num[index]-1
	end
	--Faction_db:update_faction(self)
	return 0
end

--任命
function Faction:appointment(obj_s_id,obj_d_id,index)
	if self.faction_player_list[obj_d_id]~=nil and self.faction_player_list[obj_s_id]~=nil then
		local d_index = self.faction_player_list[obj_d_id]["post_index"]
		local s_index = self.faction_player_list[obj_s_id]["post_index"]
		if s_index < index and d_index > s_index and index ~= 5 then
			if self.post_num[index] < faction_update_loader.faction_list[self.level][7][index] then
				self:set_post(obj_d_id,index)

				if index < 5 then
					self.post_num[index]=self.post_num[index]+1
				end

				if d_index<5 then
					self.post_num[d_index]=self.post_num[d_index]-1
				end
				--Faction_db:update_faction(self)
				return 0
			else
				return 26016
			end
		elseif index == 5 and s_index < index and d_index > s_index then
			self:set_post(obj_d_id,index)
			if d_index < 5 then
				self.post_num[d_index]=self.post_num[d_index]-1
			end
			
			--Faction_db:update_faction(self)
			return 0
		end
	end
end



--申请加入
function Faction:add_join_link(obj_id)
	local char_id, count = self:get_join_count_char()
	if self:is_join_full(count) then return end

	if self.join_l[obj_id] == nil then
		self.join_l[obj_id] = {}
	end
	self.join_l[obj_id]["char_id"] = obj_id
	self.join_l[obj_id]["time"] = ev.time
	self.join_l[obj_id]["post"] = g_player_mgr.all_player_l[obj_id]["occ"]
	self.join_l[obj_id]["level"] = g_player_mgr.all_player_l[obj_id]["level"]
	self.join_l[obj_id]["name"] = g_player_mgr.all_player_l[obj_id]["char_nm"]
	--self.join_l[obj_id]["time_span"] = ev.time
end

function Faction:del_join_link(obj_id)
	self.join_l[obj_id] = nil 
end

function Faction:get_join_count_char()
	local time_l = ev.time
	local t_time = 0
	local char_id =nil 
	local count = 0
	for k,v in pairs(self.join_l or {})do
		local time_span = time_l - v["time"]
		if t_time < time_span then
			t_time = time_span
			char_id = k
		end
		count = count + 1
	end
	return char_id,count
end

function Faction:is_join_full(count)
	if count > JOIN_MAX then
		return true
	end
	return false
end

function Faction:is_join_char(obj_id)
	if self.join_l[obj_id] ~= nil then
		return true
	end
	return false
end



--玩家上下线
function Faction:out_line(obj_id)   --下线
	if self.faction_player_list[obj_id] ~= nil then
		local time_l = ev.time
		self.faction_player_list[obj_id]["status"] = os.date("%Y.%m.%d %H:%M:%S", time_l, time_l)
		self.faction_player_list[obj_id]["online_flag"] = 0
		--Faction_db:update_faction(self)
	end
end

function Faction:on_line(obj_id)    --上线
	if self.faction_player_list[obj_id] ~= nil then
		self.faction_player_list[obj_id]["status"] = "0"
		self.faction_player_list[obj_id]["online_flag"] = 1
		--self:online_syn(obj_id)
		--Faction_db:update_faction(self)
	end
end

--上线时通知客户端信息
function Faction:online_syn(obj_id)
	--玩家头上显示帮派的信息
	local ret = self:get_head_info(obj_id)
	g_svsock_mgr:send_server_ex(WORLD_ID,obj_id, CMD_C2M_FACTION_UPDATE_REQ, ret)

	--帮派的一些信息
	local ret_l = self:get_online_info(obj_id)
	g_svsock_mgr:send_server_ex(WORLD_ID,obj_id,CMD_W2C_FACTION_PLAYER_INFO_S,ret_l)
end

--玩家升级
function Faction:update_level(obj_id,level)
	if self.faction_player_list[obj_id] ~= nil then
		self.faction_player_list[obj_id]["level"] = level
		return 0
	end
	return -1
end

-- 玩家VIP状态改变
function Faction:vip_state_change(obj_id, vip_level)
	if self.faction_player_list[obj_id] ~= nil then
		self.faction_player_list[obj_id]["vip_level"] = vip_level
		return 0
	end
	return -1
end

------------------------------------------基本属性--------------------------------------------------------
function Faction:get_fb_info()
	return self.fb_info
end

function Faction:set_fb_info(scene_id)
	local scene_id = tostring(scene_id)
	if self.fb_info == nil then
		self.fb_info = {}
		self.fb_info["switch_flag"] = 0
		self.fb_info[scene_id][1] = 0
		self.fb_info[scene_id][2] = ev.time 
	end
	if self.fb_info[scene_id] == nil then
		self.fb_info[scene_id] = {}
		self.fb_info[scene_id][1] = 0
		self.fb_info[scene_id][2] = ev.time 
	end
	local time_l = self.fb_info[scene_id][2]
	local n_time = ev.time
	local str_time = os.date("%x",time_l)
	local str_now = os.date("%x",n_time)
	if str_time ~= str_now then
		self.fb_info[scene_id][2] = n_time
		self.fb_info[scene_id][1] = 0
	end
	self.fb_info[scene_id][1] = self.fb_info[scene_id][1] + 1

	--历史消息
	--local ret = {}
	--ret[1] = 15
	--ret[2] = n_time
	--self:set_history_info(ret,1)
end

--开关副本
function Faction:switch_fb(flag,scene_id)
	self.fb_info["switch_flag"] = flag
	self.fb_info["cur_scene_id"] = tostring(scene_id)
	--历史消息
	local ret = {}
	ret[1] = 15
	ret[2] = ev.time
	ret[3] = flag
	ret[4] = self.fb_info["cur_scene_id"]
	self:set_history_info(ret,1)
end


function Faction:get_battle_info()
	return self.battle_info
end

function Faction:set_battle_info(flag,scene_id)
	if self.battle_info == nil then
		self.battle_info = {}
	end
	self.battle_info[1] = flag
	self.battle_info[2] = tostring(scene_id)
end

--是否解散
function Faction:set_over_flag(flag)
	self.over_flag = flag
end

function Faction:get_over_flag()
	return self.over_flag
end

--是否封闭状态
function Faction:get_dissolve_flag()
	return self.dissolve_flag
end

--灌溉值
function Faction:get_irrigation()
	return self.irrigation
end

function Faction:set_irrigation(irrigation)
	self.irrigation = irrigation
end

--获取成员是否已经摇钱了
function Faction:get_money_tree_count(obj_id)
	local time_l = self.faction_player_list[obj_id]["money_tree_time"]
	local n_time = ev.time
	local str_time = os.date("%x",time_l)
	local str_now = os.date("%x",n_time)
	if str_time ~= str_now and time_l ~= 0 then
		self.faction_player_list[obj_id]["money_tree_count"] = 0
	end
	return self.faction_player_list[obj_id]["money_tree_count"] or 0
end
function Faction:set_money_tree_count(obj_id)
	--self.faction_player_list[obj_id]["money_tree_time"] = ev.time
	self.faction_player_list[obj_id]["money_tree_count"] = self.faction_player_list[obj_id]["money_tree_count"] + 1
end

function Faction:get_money_tree_flag(obj_id)
	return self.faction_player_list[obj_id]["money_tree_flag"]
end

function Faction:set_money_tree_flag(obj_id,flag)
	if self:get_money_tree_count(obj_id) < 3 then
		self.faction_player_list[obj_id]["money_tree_flag"] = flag
	end
end

function Faction:set_all_money_tree_flag(flag)
	for k,v in pairs(self.faction_player_list or {}) do
		self:set_money_tree_flag(k,flag)
	end
end

function Faction:get_irrigation_time(obj_id)
	return self.faction_player_list[obj_id]["money_tree_time"]
end

function Faction:set_irrigation_time(obj_id,time)
	local time_l = self.faction_player_list[obj_id]["money_tree_time"]
	local n_time = ev.time
	local str_time = os.date("%x",time_l)
	local str_now = os.date("%x",n_time)
	if str_time ~= str_now and time_l ~= 0 then
		self.faction_player_list[obj_id]["money_tree_count"] = 0
	end
	self.faction_player_list[obj_id]["money_tree_time"] = time
end

function Faction:is_irrigation_time_ok(obj_id)
	local irrigation_time = self:get_irrigation_time(obj_id)
	if irrigation_time == 0 then return true end
	local time_span = ev.time - irrigation_time 
	if time_span >= HOUR then--TWO_HOUR
		return true
	end
	return false
end

function Faction:is_irrigation_full()
	local irrigation_list = faction_update_loader.irrigation_list[self.money_tree_level]
	local irrigation_max = irrigation_list[2]
	if self.irrigation >= irrigation_max then
		return true
	end
	return false
end

function Faction:get_permission_list(index)
	return self.permission_list[index]
end

function Faction:set_permission(permission_list)
	self.permission_list = permission_list
end


function Faction:is_update_ok(t_table)
	if self.money < t_table[2] then return 26025 end
	if self.construct_point < t_table[3] then return 26030 end
	if self.level < t_table[4] then return 26031 end

	self:set_money(self.money - t_table[2])
	self:set_construct_point(self.construct_point - t_table[3])

	return 0,t_table[2],t_table[3]
end


--演武厅
function Faction:get_action_level()
	return self.action_level
end

function Faction:set_action_level()
	local t_level = self.action_level
	local action_list_loader = faction_update_loader.action_list[t_level + 1]

	if not action_list_loader then return 26021 end
	if self.action_end_time >=ev.time then return 26037 end

	local result,del_money,del_construct = self:is_update_ok(action_list_loader)
	if result == 0 then
		self.action_end_time = ev.time + action_list_loader[6]
	end
	return result,del_money,del_construct
end

-- 帮派仓库
function Faction:get_warehouse_level()
	return self.warehouse_level
end

-- 帮派仓库当前最大格子数
function Faction:get_grid_cnt()
	local t_level = self.warehouse_level
	local warehouse_list_loader = faction_update_loader.warehouse_list[t_level]
	return tonumber(warehouse_list_loader[5]) or 0
end

function Faction:set_warehouse_level()
	local t_level = self.warehouse_level
	local warehouse_list_loader = faction_update_loader.warehouse_list[t_level + 1]
	if not warehouse_list_loader then return end
	if self.warehouse_end_time >= ev.time then return end
	local result, del_money, del_construct = self:is_update_ok(warehouse_list_loader)
	if result == 0 then
		self.warehouse_end_time = ev.time + warehouse_list_loader[6]
	end
	return result,del_money,del_construct
end


function Faction:update_all_level(flag)
	if flag == 1 then
		self.action_level = self.action_level + 1
		self.action_end_time = 0
	elseif flag == 2 then
		self.book_level = self.book_level + 1
		self.book_end_time = 0
	elseif flag == 3 then
		self.gold_level = self.gold_level + 1
		self.gold_end_time = 0
	elseif flag == 4 then
		self.level = self.level + 1
		self.faction_update_end_time = 0
	elseif flag == 5 then -- 帮派仓库
		self.warehouse_level = self.warehouse_level + 1
		self.warehouse_end_time = 0
	end
end

function Faction:is_action_practice_ok(t_table)
	if self.technology_point < t_table[2] then return 26032 end
	if self.money < t_table[3] then return 26025 end
	if self.action_level < t_table[4] then return 26033 end

	self:set_money(self.money - t_table[3])
	self:set_technology_point(self.technology_point - t_table[2])

	return 0,t_table[3],t_table[2]
end


--演武厅修炼
function Faction:get_action_practice()
	return self.action_practice
end

function Faction:set_action_practice(index)
	if self.action_practice[index] ~= nil then
		local loader = {}
		local t_level = self.action_practice[index] + 1

		--if t_level > self.action_level then return 26033 end

		if index == ACTION_PRACTICE.strengh then
			loader = faction_update_loader.strengh_list[t_level]
		elseif index == ACTION_PRACTICE.intelligence then
			loader = faction_update_loader.intelligence_list[t_level]
		elseif index == ACTION_PRACTICE.defense then
			loader = faction_update_loader.pro_defence_list[t_level]
		elseif index == ACTION_PRACTICE.attack then
			loader = faction_update_loader.pro_attack_list[t_level]
		elseif index == ACTION_PRACTICE.s_attack then -- 利器支配，物攻
			loader = faction_update_loader.s_attack_list[t_level]
		elseif index == ACTION_PRACTICE.m_attack then -- 法器支配，法功
			loader = faction_update_loader.m_attack_list[t_level]
		elseif index == ACTION_PRACTICE.critical then -- 致命一击，暴击
			loader = faction_update_loader.critical_list[t_level]
		elseif index == ACTION_PRACTICE.critical_ef then -- 爆破伤害，暴击效果
			loader = faction_update_loader.critical_ef_list[t_level]
		elseif index == ACTION_PRACTICE.point then -- 专注，命中
			loader = faction_update_loader.point_list[t_level]
		elseif index == ACTION_PRACTICE.dodge then -- 逍遥步，闪避
			loader = faction_update_loader.dodge_list[t_level]
		elseif index == ACTION_PRACTICE.critical_df then -- 规律洞察，暴击抵抗
			loader = faction_update_loader.critical_df_list[t_level]
		elseif index == ACTION_PRACTICE.d_critical_ef then -- 坚韧，暴击效果抵抗
			loader = faction_update_loader.d_critical_ef_list[t_level]
		end

		if not loader then return 26035 end

		local result,del_money,del_technology = self:is_action_practice_ok(loader)
		if result == 0 then
			self.action_practice[index] = self.action_practice[index] + 1
		end

		return result,del_money,del_technology
	end
end

--观星阁
function Faction:get_book_level()
	return self.book_level
end

function Faction:set_book_level()
	local t_level = self.book_level
	local book_list_loader = faction_update_loader.book_list[t_level + 1]

	if not book_list_loader then return 26022 end
	if self.book_end_time >= ev.time then return 26038 end

	local result,del_money, del_construct = self:is_update_ok(book_list_loader)
	if result == 0 then
		self.book_end_time = ev.time + book_list_loader[6]
	end
	return result,del_money, del_construct
end


function Faction:is_book_practice_ok(t_table)
	if self.technology_point < t_table[4] then return 26032 end
	if self.money < t_table[2] then return 26025 end
	if self.book_level < t_table[3] then return 26027 end

	self:set_money(self.money - t_table[2])
	self:set_technology_point(self.technology_point - t_table[4])

	return 0,t_table[2],t_table[4]
end
--观星阁修炼
function Faction:get_book_practice()
	return self.book_practice
end

function Faction:set_book_practice(index)
	if self.book_practice[index] ~= nil then
		local loader = {}
		local t_level = self.book_practice[index] + 1
	--	if t_level > self.book_level then return 26027 end
		if index == BOOK_PRACTICE.attack then
			loader = faction_update_loader.attack_list[t_level]
		elseif index == BOOK_PRACTICE.defense then
			loader = faction_update_loader.defense_list[t_level]
		elseif index == BOOK_PRACTICE.expr then
			loader = faction_update_loader.expr_list[t_level]
		elseif index == BOOK_PRACTICE.inspire then
			loader = faction_update_loader.inspire_list[t_level]
		end

		if not loader then return 26035 end

		local result,del_money,del_technology = self:is_book_practice_ok(loader)
		if result == 0 then
			self.book_practice[index] = self.book_practice[index] + 1
		end
		return result,del_money,del_technology
	end
end

--金库
function Faction:get_gold_level()
	return self.gold_level
end

function Faction:set_gold_level()
	local t_level = self.gold_level
	local gold_list_loader = faction_update_loader.gold_list[t_level + 1]

	if not gold_list_loader then return 26023 end
	if self.gold_end_time >= ev.time then return 26039 end

	local result,del_money,del_construct = self:is_update_ok(gold_list_loader)
	if result == 0 then
		self.gold_end_time = ev.time + gold_list_loader[6]
	end
	return result,del_money,del_construct
end


function Faction:is_gold_full()
	local t_level = self.gold_level
	local gold_list_loader = faction_update_loader.gold_list[t_level]
	if self.money < gold_list_loader[5] then
		return 0
	end
	return 1
end

--建设度
function Faction:get_construct_point()
	return self.construct_point
end

function Faction:set_construct_point(c_point)
	if c_point < 0 then return end
	self.construct_point = c_point
	if self.construct_point > faction_update_loader.action_list[self.action_level][5] then
		self.construct_point = faction_update_loader.action_list[self.action_level][5]
	end
	return 0
end

function Faction:is_construct_full()
	local t_level = self.action_level
	local action_list_loader = faction_update_loader.action_list[t_level]
	if self.construct_point < action_list_loader[5] then
		return 0
	end
	return 1
end

--科技度
function Faction:get_technology_point()
	return self.technology_point
end

function Faction:set_technology_point(t_point)
	if t_point < 0 then return end
	self.technology_point = t_point
	if self.technology_point > faction_update_loader.book_list[self.book_level][5] then
		self.technology_point = faction_update_loader.book_list[self.book_level][5]
	end
	return 0
end

function Faction:is_technology_full()
	local t_level = self.book_level
	local book_list_loader = faction_update_loader.book_list[t_level]
	if self.technology_point < book_list_loader[5] then
		return 0
	end
	return 1
end

--等级
function Faction:get_level()
	return self.level
end

function Faction:add_level()
	local faction_list_loader = faction_update_loader.faction_list[self.level + 1]

	if not faction_list_loader then return 26024 end

	if self.money < faction_list_loader[2] then return 26025 end
	if self.action_level < faction_list_loader[3] then return 26026 end
	if self.book_level < faction_list_loader[4] then return 26027 end
	if self.gold_level < faction_list_loader[5] then return 26028 end
	if self.faction_update_end_time >= ev.time then return 26040 end
	if self.construct_point < faction_list_loader[9] then return 26030 end

	self.faction_update_end_time = ev.time + faction_list_loader[6] 
	self:set_money(self.money - faction_list_loader[2])
	self:set_construct_point(self.construct_point - faction_list_loader[9])
	--self.level = self.level + 1
	return 0,faction_list_loader[2], faction_list_loader[9]
end

--帮主
function Faction:get_factioner_id()
	return self.factioner_id
end

function Faction:set_factioner_id(obj_id)
	self.factioner_id = obj_id
end

--徽章
function Faction:get_faction_badge()
	return self.faction_badge
end

function Faction:set_faction_badge(badge)
	self.faction_badge = badge
end

--排名
function Faction:get_rank()
	return self.rank or 1
end

function Faction:add_rank()
	self.rank = self.rank + 1
end

--领地等级
function Faction:get_territory_level()
	return self.territory_level
end

function Faction:set_territory_level(level)
	self.territory_level = level
end

--金钱
function Faction:get_money()
	return self.money
end

function Faction:set_money(money)
	if money < 0 then return end
	self.money = money
	if self.money > faction_update_loader.gold_list[self.gold_level][5] then
		self.money = faction_update_loader.gold_list[self.gold_level][5]
	end
end

function Faction:add_money(money)
	self.money = self.money + money
	if self.money > faction_update_loader.gold_list[self.gold_level][5] then
		self.money = faction_update_loader.gold_list[self.gold_level][5]
	end
end

function Faction:del_money(money)
	self.money = self.money - money
end

function Faction:is_money_full()
	local gold_list_loader = faction_update_loader.gold_list[self.gold_level]
	if self.money < gold_list_loader[5] then
		return 0
	end
	return 1
end


--职位名
function Faction:set_post_name(name,index)
	if self.post_name[index] ~= nil then
		self.post_name[index] = name
	end
end

function Faction:get_post_name(index)
	if self.post_name[index] ~= nil then
		return self.post_name[index]
	end
end

function Faction:get_post_name_ex()
	return self.post_name
end

--获取帮派id
function Faction:get_faction_id()
	return self.faction_id
end

function Faction:get_faction_name()
	return self.faction_name
end

function Faction:set_faction_name(name)
	self.faction_name = name
end

--设置公告
function Faction:set_announcement(announcement)
	self.announcement = announcement
end

--人员数
function Faction:get_member_count()
	return self.member_count or 1
end

function Faction:add_member_count(count)
	self.member_count = self.member_count + count
end

--玩家职位标志
function Faction:set_post(char_id,index)
	if self.faction_player_list[char_id] ~= nil then
		self.faction_player_list[char_id]["post_index"] = index
	end
end

function Faction:get_post(char_id)
	if self.faction_player_list[char_id] ~= nil then
		return self.faction_player_list[char_id]["post_index"]
	end
end

function Faction:get_player_list()
	return self.faction_player_list
end

function Faction:get_contribution(char_id)
	if self.faction_player_list[char_id] ~= nil then
		return self.faction_player_list[char_id]["contribution"]
	end
end

--function Faction:set_contribution(char_id,contribution)
function Faction:set_contribution(char_id,contribution, unrecord) -- cailizhong修改，添加不加入历史帮贡的标记
	if contribution < 0 then return 2323 end
	if self.faction_player_list[char_id] ~= nil then
		local now_contribution = self.faction_player_list[char_id]["contribution"]
		self.faction_player_list[char_id]["contribution"] = contribution
		if unrecord == true then
		elseif contribution - now_contribution > 0 then
			self.faction_player_list[char_id]["history_contribution"] = self.faction_player_list[char_id]["history_contribution"] + (contribution - now_contribution)
		end
	end
	return 0
end
--创建时间
function Faction:get_create_time()
	return self.create_time
end

--是否人满
function Faction:is_member_full()
	if self:get_member_count() >= faction_update_loader.faction_list[self.level][8] then
		return true
	end
	return false
end


------------------------------------------网络通信信息----------------------------------------------------
--帮派列表信息
function Faction:get_faction_list_info()
	local ret ={}
	ret[1] = self.faction_name
	ret[2] = self.level
	ret[3] = g_player_mgr.all_player_l[self.factioner_id]["char_nm"]
	ret[4] = self.member_count
	ret[5] = self.money
	ret[6] = self.territory_level
	ret[7] = self.faction_id
	return ret or {}
end

--帮派信息
function Faction:get_faction_info()
	local ret={}
	ret[1]=self.faction_name
	ret[2]=self.level
	ret[3]=self.faction_player_list[self.factioner_id]["name"]--self.money
	ret[4]=self.member_count
	ret[5]=self.construct_point
	ret[6]=self.technology_point
	ret[7]=self.money
	ret[8]=0
	ret[9]=""
	ret[10]=self.action_level
	ret[11]=self.book_level
	ret[12]=self.gold_level
	ret[13]=self.announcement or ""
	ret[14]=self.action_practice
	ret[15]=self.faction_id
	ret[16] = self.warehouse_level -- 帮派仓库

	return ret
end

--帮派全部内容
function Faction:get_all_info()
	local ret = {}
	ret['1'] = self.level
	ret['2'] = self.faction_id
	ret['3'] = self.faction_badge
	ret['4'] = self.faction_name
	ret['5'] = self.territory_level
	ret['6'] = self.money
	ret['7'] = self.rank
	ret['8'] = self.announcement or ""
	ret['9'] = self.post_name
	ret['10'] = self.create_time
	ret['11'] = self.post_num
	ret['12'] = self.action_level
	ret['13'] = self.book_level
	ret['14'] = self.gold_level
	ret['15'] = self.action_practice
	ret['16'] = self.book_practice
	ret['17'] = self.technology_point
	ret['18'] = self.construct_point
	ret['19'] = self:seralize_to_net(self.faction_player_list)
	ret['20'] = self.factioner_id
	ret['21'] = self.member_count
	ret['22'] = self.action_end_time
	ret['23'] = self.book_end_time
	ret['24'] = self.faction_update_end_time
	ret['25'] = self:seralize_to_net(self.join_l)
	ret['26'] = self.permission_list
	ret['27'] = self.money_tree_level
	ret['28'] = self.irrigation
	ret['29'] = self.gold_end_time
	ret['30'] = self.dissolve_flag
	ret['31'] = self.fb_info
	ret['32'] = self.battle_info
	ret['33'] = self.warehouse_level -- 帮派仓库
	ret['34'] = self.warehouse_end_time
	ret['35'] = self.fb_level
	ret['36'] = self.choose_fb_level -- 玩家选中的帮派副本等级

	return ret
end

--同步招聘信息
function Faction:get_join_list_to_net()
	local ret = {}
	ret.join_l = self:seralize_to_net(self.join_l)
	ret.faction_id = self.faction_id
	return ret
end

--同步玩家列表
function Faction:get_player_list_to_net()
	local ret = {}
	ret.faction_player_list = self:seralize_to_net(self.faction_player_list)
	ret.member_count = self.member_count
	ret.faction_id = self.faction_id
	return ret
end

--同步其他信息
function Faction:get_other_list_to_net()
	local ret = {}
	ret.level = self.level
	ret.faction_id = self.faction_id
	ret.faction_badge = self.faction_badge
	ret.faction_name = self.faction_name
	ret.territory_level = self.territory_level
	ret.money = self.money
	ret.rank = self.rank
	ret.announcement = self.announcement
	ret.post_name = self.post_name
	ret.create_time = self.create_time
	ret.post_num = self.post_num
	ret.action_level = self.action_level
	ret.book_level = self.book_level
	ret.gold_level = self.gold_level
	ret.action_practice = self.action_practice
	ret.book_practice = self.book_practice
	ret.technology_point = self.technology_point
	ret.construct_point = self.construct_point
	ret.factioner_id = self.factioner_id
	ret.member_count = self.member_count
	ret.action_end_time = self.action_end_time
	ret.book_end_time = self.book_end_time
	ret.faction_update_end_time = self.faction_update_end_time
	ret.warehouse_level = self.warehouse_level -- 帮派仓库
	ret.warehouse_end_time = self.warehouse_end_time

	return ret
end

function Faction:seralize_to_net(t_table)
	local c = 0
	local ret = {}
	for k,v in pairs(t_table) do
		c = c + 1
		ret[c] = {k,v}
	end
	return ret
end

--招募列表信息
function Faction:get_recruit_info()
	local ret={}
	for k,v in pairs(self.join_l or {}) do
		local list = self:get_single_join_list(k)
		table.insert(ret,list)
	end
	return ret
end

function Faction:get_single_join_list(obj_id)
	local obj=self.join_l[obj_id]
	local t_ret = {}
	if obj then
		t_ret[1] = obj["char_id"]
		t_ret[2] = obj["name"]
		t_ret[3] = obj["level"]
		t_ret[4] = obj["post"]
		t_ret[5] = obj["time"]
	end
	return t_ret
end

--公告信息
function Faction:get_announcement()
	return self.announcement or ""
end

--成员列表
function Faction:get_player_info()
	local ret = {}
	for k,v in pairs(self.faction_player_list or {}) do
		local list = self:get_single_info_ex(k)
		table.insert(ret,list)
	end
	return ret
end

--单个成员数组信息
function Faction:get_single_info_ex(obj_id)
	local ret = self.faction_player_list[obj_id]
	if ret ~= nil then
		local list = {}--self:get_single_info(k)
		list[1] = obj_id
		list[2] = ret.name
		list[3] = ret.level
		list[4] = self.post_name[ret["post_index"]]
		list[5] = ret.contribution
		list[6] = ret.status
		list[7] = ret.post
		list[8] = ret.gender
		list[9] = ret.post_index
		if ret.status == "0" then
			list[10] = 1
		else
			list[10] = 0
		end
		list[11] = ret.history_contribution
		list[12] = ret.salary_flag
		list[13] = ret.money_tree_flag
		list[14] = ret.money_tree_time
		list[15] = ret.money_tree_count
		-- 新增字段，帮派成员vip情况
		list[16] = ret.vip_level
		--list[16] = g_vip_play_inf:get_vip_type(obj_id)
		return list
	end
end

--单个成员的信息
function Faction:get_single_info(obj_id)
	local ret = self.faction_player_list[obj_id]
	if ret ~= nil then
		ret["post_name"] = self.post_name[ret["post_index"]]
	end
	return ret
end

--玩家头上显示的帮派信息
function Faction:get_head_info(obj_id)
	local player_info = self:get_single_info(obj_id)
	local ret ={}
	if player_info ~= nil then
		ret.faction_id = self.faction_id
		ret.faction_nm = self.faction_name
		ret.post_nm = player_info.post_name
		ret.post_id = player_info.post_index
	end
	return ret
end

--玩家一上线通信信息
function Faction:get_online_info(obj_id)
	local player_info = self:get_single_info(obj_id)
	local ret ={}
	if player_info ~= nil then
		ret.faction_id = self.faction_id
		ret.faction_name = self.faction_name
		ret.post_index = player_info.post_index
		ret.post_name = player_info.post_name
		ret.badge = self.faction_badge
		ret.flag = 2
	end
	return ret
	
end

--获取玩家写入数据库的信息
function Faction:get_player_list_info()
	local ret = {}
	local c = 1
	for k,v in pairs(self.faction_player_list or {}) do
		ret[c] = {}
		ret[c].obj_id = v.obj_id
		ret[c].contribution = v.contribution
		ret[c].post_index = v.post_index
		ret[c].status = v.status
		ret[c].salary_flag = v.salary_flag
		ret[c].money_tree_flag = v.money_tree_flag
		ret[c].money_tree_time = v.money_tree_time
		ret[c].history_contribution = v.history_contribution
		ret[c].money_tree_count = v.money_tree_count
		c = c + 1
	end

	return ret
end

--帮派升级（演武厅，观星阁，金库，建设点，科技点，帮贡，帮派等级,帮派资金）统一接口
function Faction:update_faction_level(char_id,flag,param, unrecord)
	if flag == FACTION.action_level then
		local result,del_money,del_construct = self:set_action_level()
		--历史信息
		if result == 0 then
			local ret = self:construct_update_info(char_id,del_money,del_construct,1)
			self:set_history_info(ret,1)
		end
		return result
	elseif flag == FACTION.book_level then
		local result,del_money,del_construct = self:set_book_level()
		--历史信息
		if result == 0 then
			local ret = self:construct_update_info(char_id,del_money,del_construct,2)
			self:set_history_info(ret,1)
		end	
		return result
	elseif flag == FACTION.gold_level then
		local result,del_money,del_construct = self:set_gold_level()
		--历史信息
		if result == 0 then
			local ret = self:construct_update_info(char_id,del_money,del_construct,3)
			self:set_history_info(ret,1)
		end
		return result
	elseif flag == FACTION.warehouse_level then
		local result,del_money,del_construct = self:set_warehouse_level()
		--历史信息
		if result == 0 then
			local ret = self:construct_update_info(char_id,del_money,del_construct,10)
			self:set_history_info(ret,1)
		end	
		return result
	elseif flag == FACTION.construct_point then
		return self:set_construct_point(self.construct_point + param)--.construct_point
	elseif flag == FACTION.technology_point then
		return self:set_technology_point(self.technology_point + param)--.technology_point
	elseif flag == FACTION.contribution then -- 个人帮贡
		local contribution = self:get_contribution(char_id)
		local t_contribution = contribution + param--.contribution
		return self:set_contribution(char_id,t_contribution, unrecord)
	elseif flag == FACTION.faction_level then
		local result,del_money,del_construct = self:add_level()
		--历史信息
		if result == 0 then
			local ret = self:construct_update_info(char_id,del_money,del_construct,7)
			self:set_history_info(ret,1)
		end
		return result
	elseif flag == FACTION.faction_money then
		local money = self.money + param
		if money >= 0 then
			self:set_money(money)
			return 0
		end
		return 26041     --错误码
	end
end

--演武厅修炼
function Faction:update_action_practice(char_id,flag)
	local result,del_money,del_technology = self:set_action_practice(flag)	
	
	--历史信息
	if result == 0 then
		local ret = self:skill_update_info(char_id,del_money, del_technology, flag)
		self:set_history_info(ret,1)
	end
	return result
end

--观星阁修炼
function Faction:update_book_practice(char_id,flag)
	local result,del_money,del_technology = self:set_book_practice(flag)
	--历史信息
	if result == 0 then
		local ret = self:buf_update_info(char_id,del_money, del_technology, flag)
		self:set_history_info(ret,1)
	end
	return result
end


--帮派建筑升级信息
function Faction:get_update_info()
	local time_l = ev.time
	local ret = {}

	ret[1] = {}
	ret[1][1] = self.action_level--self.level
	ret[1][2] = self.action_end_time - time_l
	if self.action_end_time - time_l <= 0 then 
		ret[1][2] = 0
	end
	ret[2] = {}
	ret[2][1] = self.book_level
	ret[2][2] = self.book_end_time - time_l
	if self.book_end_time - time_l <= 0 then
		ret[2][2] = 0
	end
	ret[3] = {}
	ret[3][1] = self.gold_level
	ret[3][2] = self.gold_end_time - time_l 
	if self.gold_end_time - time_l <= 0 then
		ret[3][2] = 0
	end
	ret[4] = 0
	ret[5] = 0
	ret[6] = 0
	ret[7] = {}
	ret[7][1] = self.level
	ret[7][2] = self.faction_update_end_time - time_l
	if self.faction_update_end_time - time_l <= 0 then
		ret[7][2] = 0
	end

	-- 帮派仓库
	ret[8] = 0
	ret[9] = 0
	ret[10] = {}
	ret[10][1] = self.warehouse_level
	ret[10][2] = self.warehouse_end_time - time_l
	if self.warehouse_end_time - time_l <= 0 then
		ret[10][2] = 0
	end

	return ret
end

--根据char_id权限限制  index :1成员管理，2帮派建设，3仓库权限，4外交权限，5技能研习, 6为副本开启,7为资源转换  dissolve_flag:nil为要判断封闭状态 其他为不考虑封闭状态
function Faction:is_permission_ok(index,char_id,dissolve_flag)
	local result = 0
	local char_index = self:get_post(char_id)
	if char_index == 1 then
		return result
	end
	if self.permission_list[index][char_index-1] == 0 or self.permission_list[index][char_index-1] == nil then
		result = 26036
	end
	if dissolve_flag == nil then
		if self.dissolve_flag == 1 then
			result = 26047
		end
	end
	return result
end

--初始化buf
function Faction:init_set_book_practice_bonus()
	for k, v in pairs(self.book_practice or {}) do
		local result1 = 0
		local result2 = 0
		if v ~= 0 then
			if k == 1 then
				result1 = faction_update_loader.attack_list[v][5]
				result2 = faction_update_loader.attack_list[v][6]
			elseif k == 2 then
				result1 = faction_update_loader.defense_list[v][5]
				result2 = faction_update_loader.defense_list[v][6]
				--return faction_update_loader.defense_list[level][5],faction_update_loader.defense_list[level][6]
			elseif k == 3 then
				result1 = faction_update_loader.expr_list[v][5]
				result2 = faction_update_loader.expr_list[v][6]
				--return faction_update_loader.expr_list[level][5],faction_update_loader.expr_list[level][6]
			elseif k == 4 then
				result1 = faction_update_loader.inspire_list[v][5]
				result2 = faction_update_loader.inspire_list[v][6]
			end

			--g_faction_impact_mgr:add_attribute_impact(self.faction_id, k + 5000, v, result2 or 0, result1 or 0)
		end
	end
end

--测试接口
function Faction:add_exp(char_id)
	self:set_construct_point(self.construct_point + 2000000000)
	self:set_technology_point(self.technology_point + 200000000)
	self:set_money(self.money + 2000000000)
	self.dissolve_flag = 0
	self:set_contribution(char_id,1000)
	local new_pkt = {}
	new_pkt.faction_id = self.faction_id
	new_pkt.cmd =25642
	new_pkt.list ={}
	new_pkt.list[1]= self:syn_info(char_id,1,7)
	new_pkt.list[2]= self:syn_info(char_id,1,2)
	new_pkt.list[3]= self:syn_info(char_id,1,11)
	g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
end


----------------------------------------------同步操作----------------------------------------------------------------
--同步消息   
--[[
obj_id:要更新的玩家id     flag : 1 update, 2 add, 3 delete 
(1)flag = 1时，flag_type = 1 为公告，2为成员列表 3帮派关系
   flag = 2时，flag_type = 1 为成员列表，2为招募列表
   flag = 3时，flag_type = 1 为成员列表，2为招募列表 

   other_faction_id : 别的帮派id

]]
function Faction:syn_info(obj_id,flag,flag_type,other_faction_id)
	local pkt={}
	pkt.flag =  flag_type
	if flag == 1 then   --update
		if flag_type ==1 then
			pkt.announcement=self.announcement
		elseif flag_type ==2 then
			pkt.faction_member=self:get_single_info_ex(obj_id)
		elseif flag_type==3 then	--帮派敌对友好关系
			pkt.relate_list= {}
			pkt.relate_list[1] = g_faction_mgr:get_faction_by_fid(other_faction_id):get_faction_list_info()
			if g_faction_mgr.faction_relate[self.faction_id] == nil then
				pkt.relate_list[2] = 3   ---3为中立
			else
				pkt.relate_list[2] = g_faction_mgr.faction_relate[self.faction_id][other_faction_id] or 3
			end
		elseif flag_type==4 then   --buf更新
			pkt.book_practice = self.book_practice
			pkt.technology_point= self.technology_point
			pkt.faction_money = self.money
		elseif flag_type==5 then   --修炼更新
			pkt.action_practice = self.action_practice
			pkt.technology_point= self.technology_point
			pkt.faction_money = self.money
		elseif flag_type==6 then   --建筑升级和建设度
			pkt.faction_update = self:get_update_info()
			pkt.construct_point = self.construct_point
			pkt.faction_money = self.money
		elseif flag_type==7 then	--科技点，建设度，帮派资金
			pkt.construct_point= self.construct_point
			pkt.technology_point= self.technology_point
			pkt.faction_money = self.money
		elseif flag_type==8 then	--权限
			pkt.permission_list= self.permission_list
		elseif flag_type==9 then	--摇钱树
			pkt.money_tree_level= self.money_tree_level
			pkt.irrigation = self.irrigation
		elseif flag_type == 10 then
			pkt.history_info = self.history_info[table.getn(self.history_info)]
		elseif flag_type == 11 then
			pkt.dissolve_flag = self.dissolve_flag 
		elseif flag_type == 12 then
			pkt.fb_info = {}
			pkt.fb_info[1] = self.fb_info["switch_flag"]
			pkt.fb_info[2] = self.fb_info["cur_scene_id"]
		elseif flag_type == 13 then
			pkt.territory = self:is_territory()
		elseif flag_type == 14 then
			pkt.faction_name = self.faction_name
		elseif flag_type == 15 then
			pkt.battle_info = self.battle_info
		elseif flag_type == 16 then
			pkt.fb_level = self.fb_level
			pkt.choose_fb_level = self.choose_fb_level -- 玩家选中的帮派副本等级
		end
	elseif flag ==2 then  --add 
		if flag_type==1 then
			pkt.faction_member=self:get_single_info_ex(obj_id)
		elseif flag_type == 2 then
			pkt.join_info=self:get_single_join_list(obj_id)
		elseif flag_type == 3 then
			--pkt.faction_list=self
		end
	elseif flag == 3 then  --delete
		if flag_type==1 then
			pkt.player_id=obj_id
		elseif flag_type ==2 then
			pkt.recruit_player_id=obj_id
		end
	end

	return pkt
end

function Faction:syn_send_all(pkt,cmd)--,flag_o
	if pkt == nil then return end
	pkt = Json.Encode(pkt or {})
	for k,v in pairs(self.faction_player_list or {}) do
		if v["status"]=="0" then
			g_svsock_mgr:send_server_ex(WORLD_ID,k, cmd, pkt, true)
		end
	end
end

--帮派日常维护
function Faction:money_maintenance()
	-- 维护金额=（（帮派等级*10+演武厅等级*3+观星阁等级*3+小金库等级*4+(仓库等级-1)*4）+18）*150+当前帮派资金*0.0004
	if self.money ~= 0 then
		local money_l = math.ceil(( self.level * 10 + self.action_level * 3 + self.book_level * 3 + self.gold_level * 4 + (self.warehouse_level - 1) * 4 + 18 ) * 150 + self.money * 0.0004)
		local p_money = money_l
		if self.money >= money_l then
			self.money = self.money - money_l
		else
			p_money = self.money
			self.money = 0
		end
		local new_pkt = {}
		new_pkt.faction_id = self:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1]= self:syn_info(nil,1,7)
		--主动废弃
		if self.money == 0 then
			self.dissolve_flag = 1
			local ret = {}
			ret[1] = 13
			ret[2] = ev.time
			ret[3] = 1
			self:set_history_info(ret,1)
			new_pkt.list[3] = self:syn_info(nil,1,10)
		else
			if self.dissolve_flag == 1 then
				self.dissolve_flag = 0
				local ret = {}
				ret[1] = 13
				ret[2] = ev.time
				ret[3] = 0
				self:set_history_info(ret,1)
				new_pkt.list[3] = self:syn_info(nil,1,10)
			end
		end
		new_pkt.list[2] = self:syn_info(nil,1,11)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

		--流水和历史消息
		if p_money >0 then
			local ret = {}
			ret[1] = 6
			ret[2] = ev.time
			ret[3] = p_money
			self:set_history_info(ret)

			local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d, io = %d,contribution='%s'",
							self:get_faction_id(), self:get_faction_name(), 0, 6,p_money,0,0,ev.time,0,Json.Encode({}))
			g_web_sql:write(str)
		end
	else
		--if self.dissolve_flag == 0 then
			self.dissolve_flag = 1
			
			--历史消息
			local ret = {}
			ret[1] = 13
			ret[2] = ev.time
			ret[3] = 1
			self:set_history_info(ret,1)

			local new_pkt = {}
			new_pkt.faction_id = self:get_faction_id()
			new_pkt.cmd =25642
			new_pkt.list ={}
			new_pkt.list[1]= self:syn_info(nil,1,11)
			new_pkt.list[2]= self:syn_info(nil,1,10)
			new_pkt.list[3]= self:syn_info(nil,1,7)
			g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)

		--end
	end
end 

--历史消息 flag 是否通知客户端标志
function Faction:set_history_info(history,flag)
	table.insert(self.history_info,history)
	if table.size(self.history_info) >= 50 then
		table.remove(self.history_info,1)
	end

	if flag == nil then
		local new_pkt = {}
		new_pkt.faction_id = self:get_faction_id()
		new_pkt.cmd =25642
		new_pkt.list ={}
		new_pkt.list[1]= self:syn_info(nil,1,10)
		g_server_mgr:send_to_all_map(0,CMD_P2M_FACTION_SYN_UPDATE_S,Json.Encode(new_pkt), true)
	end

end

--function Faction:set_history_info_ex(history)
	--table.insert(self.history_info,history)
--end
--
--function Faction:del_history_info_ex()
	--if table.size(self.history_info) >= 50 then
		--table.remove(self.history_info,1)
	--end
--end

function Faction:get_history_info()
	return self.history_info or {}
end

--升级历史信息
function Faction:construct_update_info(char_id,del_money,del_construct,flag)
	local ret ={}
	ret[1] = 1
	ret[2] = ev.time
	ret[3] = char_id
	ret[4] = self.faction_player_list[char_id]["name"]
	ret[5] = del_money
	ret[6] = del_construct
	ret[7] = flag
	return ret
end

--技能升级历史信息组包
function Faction:skill_update_info(char_id,del_money,del_technology,flag)
	local ret ={}
	ret[1] = 4
	ret[2] = ev.time
	ret[3] = char_id
	ret[4] = self.faction_player_list[char_id]["name"]
	ret[5] = self.action_practice[flag]
	ret[6] = del_money
	ret[7] = del_technology
	ret[8] = flag
	return ret
end

--buf升级历史信息组包
function Faction:buf_update_info(char_id,del_money,del_technology,flag)
	local ret = {}
	ret[1] = 5
	ret[2] = ev.time
	ret[3] = self.book_practice[flag]
	ret[4] = del_money
	ret[5] = del_technology
	ret[6] = flag
	ret[7] = char_id
	ret[8] = self.faction_player_list[char_id]["name"]
	return ret
end

--道具加速升级
function Faction:update_speed_time(flag,all_time)
	local t_flag = 0
	if flag == FACTION.action_level then
		if self.action_end_time == 0 then return 1212121 end
		if self.action_end_time > all_time + ev.time then
			self.action_end_time = self.action_end_time - all_time
		else
			self.action_end_time = 0
			self.action_level = self.action_level + 1
			t_flag = 1
		end
	elseif flag == FACTION.book_level then
		if self.book_end_time == 0 then return 1212121 end
		if self.book_end_time > all_time + ev.time then
			self.book_end_time = self.book_end_time - all_time
		else
			self.book_end_time = 0
			self.book_level = self.book_level + 1
			t_flag = 1
			--帮派庭院 屏蔽 121114 chendong
			--g_faction_courtyard_mgr:update_censer_info(self.faction_id) -- 更新帮派烧香信息
		end
	elseif flag == FACTION.gold_level then
		if self.gold_end_time == 0 then return 1212121 end
		if self.gold_end_time > all_time + ev.time then
			self.gold_end_time = self.gold_end_time - all_time
		else
			self.gold_end_time = 0
			self.gold_level = self.gold_level + 1
			t_flag = 1
			--帮派庭院 屏蔽 121114 chendong
			--g_faction_courtyard_mgr:update_faction_money_tree(self.faction_id) -- 帮派金库升级，通过更新摇钱树(铜券树)等级
		end
	elseif flag == FACTION.faction_level then
		if self.faction_update_end_time == 0 then return 1212121 end
		if self.faction_update_end_time > all_time + ev.time then
			self.faction_update_end_time = self.faction_update_end_time - all_time
		else
			self.faction_update_end_time = 0
			self.level = self.level + 1
			t_flag = 1
		end
	elseif flag == FACTION.warehouse_level then -- 帮派仓库
		if self.warehouse_end_time == 0 then return 1212121 end
		if self.warehouse_end_time > all_time + ev.time then
			self.warehouse_end_time = self.warehouse_end_time - all_time
		else
			self.warehouse_end_time = 0
			self.warehouse_level = self.warehouse_level + 1
			t_flag = 1
		end
	end

	if t_flag == 1 then 
		local ret = {}
		ret[1] = 11
		ret[2] = ev.time
		if flag == 1 then
			ret[3] = self:get_action_level()
		elseif flag == 2 then
			ret[3] = self:get_book_level()
		elseif flag == 3 then
			ret[3] = self:get_gold_level()
		elseif flag == 7 then
			ret[3] = self:get_level()
		elseif flag == 10 then -- 帮派仓库
			ret[3] = self:get_warehouse_level()
		end
		ret[4] = flag
		self:set_history_info(ret,1)
	end
	return 0,t_flag
end

--帮派合并时添加成员
function Faction:faction_merge(other_player, other_faction_id)
	local ret = {}
	for k, v in pairs(other_player or {}) do
		self.faction_player_list[k] = self:create_member(k)
		self.faction_player_list[k].contribution = v.contribution
		self.faction_player_list[k].history_contribution = v.contribution
		self.faction_player_list[k].status = v.status
		self.faction_player_list[k].online_flag = v.online_flag
		self:add_member_count(1)
		g_faction_mgr:add_member2faction(k, self.faction_id)

		table.insert(ret,k)
	end
	g_faction_mgr:del_faction(other_faction_id)
	return 0, ret, other_faction_id
end

--判断帮派是否站有领地
function Faction:is_territory()

	if self.faction_id == Application_filter:get_faction_id() then
		return 1
	end
	return 0
end


--帮派升级流水
function Faction:log_faction(node,char_id)
	local fund,build,science = 0,0,0
	local type = 3
	local loader = nil
	local flag = 0
	local io = 0
	local contribution = {}
	if node.flag == 1 then
		local lvl = self:get_action_level()
		loader = faction_update_loader.action_list[lvl+1]
		fund = loader[2]
		build = loader[3]
		science = 0
		flag = 1
	elseif node.flag == 2 then
		local lvl = self:get_book_level()
		loader = faction_update_loader.book_list[lvl+1]
		fund = loader[2]
		build = loader[3]
		science = 0
		flag = 1
	elseif node.flag == 3 then
		local lvl = self:get_gold_level()
		loader = faction_update_loader.gold_list[lvl+1]
		fund = loader[2]
		build = loader[3]
		science = 0
		flag = 1
	elseif node.flag == 7 then
		local lvl = self:get_level()
		loader = faction_update_loader.faction_list[lvl+1]
		fund = loader[2]
		build = loader[9]
		science = 0
		type = 2
		flag = 1
	elseif node.flag == 10 then -- 帮派仓库
		local lvl = self:get_warehouse_level()
		loader = faction_update_loader.warehouse_list[lvl+1]
		fund = loader[2]
		build = loader[3]
		science = 0
		flag = 1
	elseif node.flag == 4 or node.flag == 5 or node.flag == 8 or node.flag == 6 then
		type = node.type
		if node.flag == 4 then
			build = math.abs(node.param or 0)
			science = 0
			fund = 0
		elseif node.flag == 5 then
			science = math.abs(node.param or 0)
			fund = 0
			build = 0
		elseif node.flag == 8 then
			fund = math.abs(node.param or 0)
			build = 0
			science = 0
		elseif node.flag == 6 then
			fund = 0
			build = 0
			science = 0
			local contr = {}
			contr[1] = char_id
			contr[2] = math.abs(node.param or 0)
			table.insert(contribution,contr)
		end
		flag = 1

		if node.io == nil then
			io = 1
		else
			io = node.io
		end
	end
	if flag == 1 then
		local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d,io=%d,contribution='%s'",
				self:get_faction_id(), self:get_faction_name(), char_id, type or 12, fund, build, science,ev.time,io,Json.Encode(contribution))
		g_web_sql:write(str)
	end
end


--技能升级修炼流水
--流水
function Faction:log_skill(node,char_id)
	local fund,build,science = 0,0,0
	local action_practice = self:get_action_practice()
	local lvl = action_practice[node.flag]
	local loader = nil
	if node.flag == 1 then
		loader = faction_update_loader.strengh_list[lvl]
	elseif node.flag == 2 then
		loader = faction_update_loader.intelligence_list[lvl]
	elseif node.flag == 3 then
		loader = faction_update_loader.pro_defence_list[lvl]
	elseif node.flag == 4 then
		loader = faction_update_loader.pro_attack_list[lvl]
	elseif node.flag == 5 then -- 利器支配，物攻
		loader = faction_update_loader.s_attack_list[lvl]
	elseif node.flag == 6 then -- 法器支配，法功
		loader = faction_update_loader.m_attack_list[lvl]
	elseif node.flag == 7 then -- 致命一击，暴击
		loader = faction_update_loader.critical_list[lvl]
	elseif node.flag == 8 then -- 爆破伤害，暴击效果
		loader = faction_update_loader.critical_ef_list[lvl]
	elseif node.flag == 9 then -- 专注，命中
		loader = faction_update_loader.point_list[lvl]
	elseif node.flag == 10 then -- 逍遥步，闪避
		loader = faction_update_loader.dodge_list[lvl]
	elseif node.flag == 11 then -- 规律洞察，暴击抵抗
		loader = faction_update_loader.critical_df_list[lvl]
	elseif node.flag == 12 then -- 坚韧，暴击效果抵抗
		loader = faction_update_loader.d_critical_ef_list[lvl]
	end
	if loader ~= nil then
		fund = loader[3]
		build = 0
		science = loader[2]
		local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d,io=%d,contribution='%s'",
				self:get_faction_id(), self:get_faction_name(), char_id, 4,fund,build,science,ev.time,0,Json.Encode({}))
		g_web_sql:write(str)
	end
end

--buf流水
function Faction:log_buf(node,char_id)
	local fund,build,science = 0,0,0
	local book_practice = self:get_book_practice()
	local lvl = book_practice[node.flag]
	local loader = nil
	if node.flag == 1 then
		loader = faction_update_loader.attack_list[lvl]
	elseif node.flag == 2 then
		loader = faction_update_loader.defense_list[lvl]
	elseif node.flag == 3 then
		loader = faction_update_loader.expr_list[lvl]
	end
	if loader ~= nil then
		fund = loader[2]
		build = 0
		science = loader[4]
		local str = string.format("insert faction_refresh set faction_id ='%s'  ,faction_name = '%s', char_id=%d, type=%d, fund=%d, build = %d, science=%d, create_time=%d,io=%d,contribution='%s'",
				self:get_faction_id(), self:get_faction_name(), char_id, 5,fund,build,science, ev.time,0,Json.Encode({}))
		g_web_sql:write(str)
	end
end
----email
--function Faction:send_email(char_id)
	-----发邮件到帮主和副帮主
	--local content=string.format("[%s]已主动退出帮派，每位成员都是大家庭中的一份子，请帮主及时联系挽留",utf8_gbk(g_player_mgr.all_player_l[char_id]["char_nm"]))
	--local title=gbk_utf8("通知")
	--local content=gbk_utf8(content)
--
	--local list = self.faction_player_list
	--for k,v in pairs(list or {}) do
		--if	v["post_index"]==1 or v["post_index"]==2 then
			--Gm_email:create_email(k,title,content,Email_type.type_common,nil,nil)
		--end
	--end
--end


--------------------------------cailizhong-----------------------------------
-- 获取帮派资金与当前等级最大帮派资金之差
function Faction:get_empty_money()
	local gold_list_loader = faction_update_loader.gold_list[self.gold_level]
	return gold_list_loader[5] - self:get_money()
end

-- 获取科技点与当前等级最大科技点之差
function Faction:get_empty_technology()
	local book_list_loader = faction_update_loader.book_list[self.book_level]
	return book_list_loader[5] - self:get_technology_point()
end

-- 获取建设点与当前等级最大建设点之差
function Faction:get_empty_construct()
	local action_list_loader = faction_update_loader.action_list[self.action_level]
	return action_list_loader[5] - self:get_construct_point()
end

-- 帮派资源互换
function Faction:resource_exchange(sell_type, sell_cnt, buy_type, buy_cnt)
	local tmp_list = self:get_resource_exchange_list()
	if tmp_list[sell_type]==nil or tmp_list[buy_type]==nil then return 31211 end
	local num1 = 0
	if sell_type == 1 then -- 帮派资金
		num1 = self:get_money()
	elseif sell_type == 2 then -- 建设度
		num1 = self:get_construct_point()
	elseif sell_type == 3 then -- 科技点
		num1 = self:get_technology_point()
	end
	if num1 < sell_cnt then return 31213 end-- 出售数量不足

	local num2 = 0
	if buy_type == 1 then -- 帮派资金
		num2 = self:get_empty_money()
	elseif buy_type == 2 then -- 建设度
		num2 = self:get_empty_construct()
	elseif buy_type == 3 then -- 科技点
		num2 = self:get_empty_technology()
	end
	if num2 < buy_cnt then return 31215 end

	-- 判断比率是否跟配置文件一致,暂时未添加
	local scale = faction_resource_exchange_loader.get_exchange_scale(sell_type, buy_type)
	--if math.floor(sell_cnt * scale[2] / scale[1]) ~= buy_cnt then return 31217 end
	-- 策划需求变动，更改公式
	--if math.ceil(buy_cnt * scale[1] / scale[2]) ~= sell_cnt then return 31217 end
	if sell_cnt * scale[2] ~= buy_cnt * scale[1] then return 31217 end
	-- 判断是否超出限制
	--local limit_num = faction_resource_exchange_loader.get_exchange_limit(self.gold_level, sell_type)
	--if tmp_list[sell_type] + sell_cnt > limit_num then return 31214 end-- 超出限制
	-- 策划要求改为限制买入类型
	local limit_num = faction_resource_exchange_loader.get_exchange_limit(self.gold_level, buy_type)
	if tmp_list[buy_type] + buy_cnt > limit_num then return 31214 end-- 超出限制

	if sell_type == 1 then -- 帮派资金
		self:del_money(sell_cnt)
	elseif sell_type == 2 then -- 建设度
		self:set_construct_point(num1 - sell_cnt)
	elseif sell_type == 3 then -- 科技点
		self:set_technology_point(num1 - sell_cnt)
	end

	--self:add_resource_exchange_list(sell_type, sell_cnt)
	-- 策划要求改为限制买入类型
	self:add_resource_exchange_list(buy_type, buy_cnt)

	if buy_type == 1 then -- 帮派资金
		self:add_money(buy_cnt)
	elseif buy_type == 2 then -- 建设度
		self:set_construct_point(self.construct_point + buy_cnt)
	elseif buy_type == 3 then -- 科技点
		self:set_technology_point(self.technology_point + buy_cnt)
	end
	return 0
end

-- 设置转换剩余列表
function Faction:add_resource_exchange_list(k, cnt)
	self.resource_exchange_list[k] = self.resource_exchange_list[k] + cnt
end

-- 获取转换剩余列表
function Faction:get_reamin_num_list()
	local ret = {}
	local tmp = self:get_resource_exchange_list()
	ret[1] = faction_resource_exchange_loader.get_exchange_limit(self.gold_level, 1) - tmp[1]
	ret[2] = faction_resource_exchange_loader.get_exchange_limit(self.gold_level, 2) - tmp[2]
	ret[3] = faction_resource_exchange_loader.get_exchange_limit(self.gold_level, 3) - tmp[3]
	return ret
end

-- 返回帮派资源互换限定列表
function Faction:get_resource_exchange_list()
	if self.resource_exchange_time ~= os.date("%x",os.time()) then -- 重置
		self.resource_exchange_list = {0, 0, 0} -- 帮派资金、建设点、科技点
		self.resource_exchange_time = os.date("%x",os.time())
	end
	return self.resource_exchange_list
end

-- 获取某一资源当日已经兑换的数量
function Faction:get_resource_have_exchange(resource_type)
	return self.resource_exchange_list[resource_type] or 0
end 
--------------------------------------------------