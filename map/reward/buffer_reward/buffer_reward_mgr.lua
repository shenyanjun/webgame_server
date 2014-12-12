--2010-11-17
--laojc
--buffer奖励设置
require("reward.buffer_reward.buffer_reward_obj")
local reward_db = require("reward.buffer_reward.buffer_reward_db")


buffer_reward_mgr = oo.class(nil,"buffer_reward_mgr")

function buffer_reward_mgr:__init()
	self.reward_list={}

	--额外的buff
	self.reward_ex_list = {}
end

--向客户端发送
function buffer_reward_mgr:buffer_reward_start(reward)
	local obj_l = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)

	local t_time = os.time()
	local time_today ={}
	time_today.year = os.date("%Y",t_time)
	time_today.month = os.date("%m",t_time)
	time_today.day = os.date("%d",t_time)
	time_today.hour = 0
	time_today.minute = 0
	time_today.second = 0

	local today = os.time(time_today)

	local end_time =today + reward["end_time"]
	local time_l = end_time - t_time

	local pkt ={}
	pkt.impact_id =reward.type
	local time = reward.time
	pkt.param ={}
	pkt.param[1] = time * 100
	pkt.time = time_l
	for k,v in pairs (obj_l) do
		g_cltsock_mgr:send_client(k, CMD_M2C_BUFFER_REWARD_S, pkt)
	end

	if reward.type == 6 or reward.type == 7 or reward.type == 8 then
		f_cmd_linebd(f_create_sysbd_format(reward.bdc_content or "", 16))
	end
end

function buffer_reward_mgr:buffer_reward_stop(reward)
	local obj_l = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
	local pkt ={}
	pkt.type =reward.type
	for k,v in pairs (obj_l) do
		g_cltsock_mgr:send_client(k, CMD_M2C_BUFFER_REWARD_STOP_S, pkt)
	end
end

--多种buffer外部传进 pkt包含 （type:类型， p_time:倍数, time:有效时间 level:等级）
function buffer_reward_mgr:buffer_reward_start_ex(pkt)
	if pkt.type < 9 then return end
	local obj_l = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
	local new_pkt ={}
	new_pkt.impact_id =pkt.type
	new_pkt.param ={}
	new_pkt.param[1] = pkt.p_time * 100
	new_pkt.param[2] = pkt.level 
	new_pkt.time = pkt.time

	self.reward_ex_list[pkt.type - 8] = new_pkt

	new_pkt = Json.Encode(new_pkt)
	for k,v in pairs (obj_l) do
		g_cltsock_mgr:send_client(k, CMD_M2C_BUFFER_REWARD_S, new_pkt, true)
	end
end

function buffer_reward_mgr:buffer_reward_stop_ex(type)
	if type < 9 then return end
	local obj_l = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
	local pkt ={}
	pkt.type = type
	pkt = Json.Encode(pkt)
	self.reward_ex_list[type - 8] = nil
	for k,v in pairs (obj_l) do
		g_cltsock_mgr:send_client(k, CMD_M2C_BUFFER_REWARD_STOP_S, pkt, true)
	end
end

--玩家一上线，通知
function buffer_reward_mgr:online_char_buffer(char_id)
	for k,v in pairs(self.reward_list) do
		if v.flag == 1 then
			local t_time = os.time()
			local time_today ={}
			time_today.year = os.date("%Y",t_time)
			time_today.month = os.date("%m",t_time)
			time_today.day = os.date("%d",t_time)
			time_today.hour = 0
			time_today.minute = 0
			time_today.second = 0

			local today = os.time(time_today)

			local end_time =today + v["end_time"]
			local time_l = end_time - t_time
			local time = v.time

			local pkt ={}
			pkt.impact_id = k     --类型
			pkt.param = {}       
			pkt.param[1] = time * 100  --倍数
			pkt.time = time_l     --时间
			g_cltsock_mgr:send_client(char_id, CMD_M2C_BUFFER_REWARD_S, pkt)
		end
	end

	for m,n in pairs(self.reward_ex_list) do
		g_cltsock_mgr:send_client(char_id, CMD_M2C_BUFFER_REWARD_S, n)
	end
end

--创建reward
function buffer_reward_mgr:create_reward(pkt)
	local type = pkt.type
	local start_date = pkt.start_date
	local end_date = pkt.end_date
	local start_time = pkt.start_time
	local end_time = pkt.end_time
	local time = pkt.time
	local bdc_content = pkt.bdc_content or ""

	local reward = buffer_reward_obj(type,start_date,end_date,start_time,end_time,time, bdc_content)
	return reward
end
--添加buffer奖励
function buffer_reward_mgr:add_reward(reward)
	local type = reward.type
	self.reward_list[type] = reward
end

--停止buffer奖励
function buffer_reward_mgr:del_reward(reward)
	local type = reward.type
	if self.reward_list[type] ~=nil then
		self.reward_list[type] = nil 
		self:buffer_reward_stop(reward)
	end
end

--查找reward
function buffer_reward_mgr:find_reward(type)
	return self.reward_list[type]
end

--type:1 打怪经验BUFF 2,聚灵阵经验BUFF 3,温泉经验BUFF 4,战场经验BUFF 5,押镖任务BUFF 6,7,8跨服战buff 9,额外打怪，
--10,额外聚灵阵经验BUFF 11,额外温泉经验BUFF 12,额外战场经验BUFF 13,额外押镖任务BUFF 14,15,16,17（分别是一代二代三代变异宠物加成）
function buffer_reward_mgr:buff_reward(type)
	local reward_ex = self.reward_ex_list[type]
	if type == 1 then  --打怪的时候有 打怪buf和跨服buf累加
		local reward_1 = self.reward_list[type]
		local reward_2 = self.reward_list[6]  --
		local reward_3 = self.reward_list[7]
		local reward_4 = self.reward_list[8]

		local time_t = 0
		if reward_1 ~= nil then
			if reward_1.flag==1 then
				time_t = time_t + tonumber(reward_1["time"])
			end
		end

		if reward_2 ~= nil then
			if reward_2.flag==1 then
				time_t = time_t + tonumber(reward_2["time"])
			end
		end

		if reward_3 ~= nil then
			if reward_3.flag==1 then
				time_t = time_t + tonumber(reward_3["time"])
			end
		end

		if reward_4 ~= nil then
			if reward_4.flag==1 then
				time_t = time_t + tonumber(reward_4["time"])
			end
		end

		if reward_ex ~= nil then
			return time_t + reward_ex.param[1] / 100
		else
			return time_t
		end
	else
		local t_time = 0
		local reward = self.reward_list[type]
		if reward ~= nil then
			if reward.flag==1 then
				t_time = t_time + tonumber(reward["time"]) 
			end 
		end

		if reward_ex ~= nil then
			return t_time + reward_ex.param[1] / 100
		else
			return t_time
		end
	end
	return 0
end

--pkt {type:6,7,8（第一名，第二名，第三四名） time:经验倍数, start_date:开始时间的日期 即凌晨时间点 （秒）,start_time：开始时间 （秒），end_date：结束时间日期 即凌晨时间点（秒），end_time：结束时间点（秒）, bdc_content:广播内容}
function buffer_reward_mgr:world_war_buffer(pkt)
	if pkt.type ~= 6 and pkt.type ~= 7 and pkt.type ~= 8 then return end
	local reward = self:create_reward(pkt)
	if reward ~=nil then
		self:add_reward(reward)
	end

	local db = f_get_db()
	local t = {}
	t.type = pkt.type
	t.start_date = pkt.start_date
	t.end_date = pkt.end_date
	t.start_time = pkt.start_time
	t.end_time = pkt.end_time
	t.time = pkt.time
	t.bdc_content = pkt.bdc_content
	local query = string.format("{type:%d}",pkt.type)

	db:update("buffer", query, Json.Encode(t),true)
	
end

--时间比较
function buffer_reward_mgr:is_on_time(reward)
	local t_time = os.time()
	local time_today ={}
	time_today.year = os.date("%Y",t_time)
	time_today.month = os.date("%m",t_time)
	time_today.day = os.date("%d",t_time)
	time_today.hour = 0
	time_today.minute = 0
	time_today.second = 0

	--buffer设定时间
	local start_date = reward["start_date"]
	local end_date = reward["end_date"]
	local start_time = reward["start_time"]
	local end_time = reward["end_time"]

	--当天时间
	local today = os.time(time_today)
	local today_min = today + start_time
	local today_max = today + end_time

	--比较

	--print("bbbbbbbbbbbbbbbbbbbbbbbbb",t_time,today,start_date,end_date,t_time,today_min,today_max)
	if t_time < end_date + end_time then
		if today >= start_date then
			if today <= end_date then
				if t_time > today_min then
					if t_time < today_max then
						return 1
					else
						return 2
					end
				else
					return 2
				end
			else
				return 3
			end
		else
			return 4
		end
	else
		return 5
	end
end

function buffer_reward_mgr:on_timer(time_span)
	for k , v in pairs(self.reward_list)do
	--print("-----------self.reward_list------------------",self.reward_list[k])
		local reward = self.reward_list[k]
		local flag = reward["flag"]
		local result = self:is_on_time(reward)
		if result == 1 then
			if flag == 0 then
				self.reward_list[k]["flag"]=1
				self:buffer_reward_start(reward)
			end
		elseif result ==2 then 
			if flag == 1 then
				self.reward_list[k]["flag"]=0
				self:buffer_reward_stop(reward)
				--print("111111111111111111111111111")
			end
		elseif result == 3 then	
			if reward ~=nil then
				self:del_reward(reward)
			end
		elseif result == 5 then
			if reward ~=nil then
				self:del_reward(reward)
			end
		end
	end
end

function buffer_reward_mgr:get_click_param(time_span)
	return self, self.on_timer, time_span, nil
end




----------------------load----------------------------
function buffer_reward_mgr:load()
	local rs = reward_db.select_all_reward()
	if rs == nil then return end

	for k,v in pairs(rs) do
		local type = v.type
		if type == nil then return end

		self.reward_list[type]={}
		self.reward_list[type]["type"] = v.type
		self.reward_list[type]["start_time"] = v.start_time
		self.reward_list[type]["start_date"] = v.start_date
		self.reward_list[type]["end_time"] = v.end_time
		self.reward_list[type]["end_date"] = v.end_date
		self.reward_list[type]["time"] = tonumber(v.time)
		self.reward_list[type]["flag"] = 0
		self.reward_list[type]["bdc_content"] = v.bdc_content or ""
	end
end