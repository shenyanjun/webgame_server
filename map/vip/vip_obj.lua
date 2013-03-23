--author:   zhanglongqi
--date:     2011.03.30
--file:     Vip_obj.lua

--[[
char_id     --玩家,主键and索引
card_type --vip卡类型
end_time  --结束时间
]]


--[[
卡类型：
1   周卡
2   月卡
3   季卡
4   半年卡
]]

local vip_config=require("vip.vip_loader")
local one_hour = 1*60*60

local database="vip_card"
Vip_obj=oo.class(nil,"Vip_obj")


--功能：初始化
--参数：char_id
--返回：空
function Vip_obj:__init(char_id)
    self.char_id=char_id
	self.end_time = nil
	self.card_type = 0
	self.open_bonus = "0"	--注意是字符串
	self.transfer = 0		--传送次数
	self.transfer_day = ""
	self.to_save = nil		--判断下线是否需要保存
end


--功能：获取卡类型
--参数：空
--返回：卡类
function Vip_obj:get_card_type()
	if self.end_time == nil or self.card_type==0 then return 0 end
	if ev.time >= self.end_time then
		local player = g_obj_mgr:get_obj(self.char_id)
		player:on_dress_update(12)
		return 0
	end
    return self.card_type
end


--功能：卡时效
--参数：卡类
--返回：时长
function Vip_obj:get_alive_time(card_type)
	if card_type<0 then
	     return 0 
	end
	return (vip_config.VipTable[card_type]["valid_time"] or 0)*one_hour
end

--传送剩余次数
function Vip_obj:get_transfer_surplus()
	local today = os.date("%Y%m%d", ev.time)
	--print("today", today, type(today))
	if today ~= self.transfer_day then
		self.transfer_day = today
		self.transfer = vip_config.VipTable[self.card_type]["transfer"] or 0
	end
	return self.transfer, self:get_vip_info()
end

function Vip_obj:sub_transfer(t)
	self.transfer = self.transfer - t
	self.to_save = true
end

--功能：使用卡
--参数：卡类
--返回：
function Vip_obj:use_card(card_type)
    if card_type < 0 then
	    return
	end
	self.card_type = card_type
	local alive_time = self:get_alive_time(card_type)
	self.end_time = ev.time+alive_time
	self.transfer = vip_config.VipTable[card_type]["transfer"] or 0
	self:insert_char()
end

--功能：不同卡，覆盖
--参数：卡类
--返回：
function Vip_obj:cover_card(card_type)
    if card_type < 0 then
	    return 
	end

	self.card_type = card_type
	local alive_time = self:get_alive_time(card_type)
	self.end_time = ev.time+alive_time
	self.transfer = vip_config.VipTable[card_type]["transfer"] or 0
	self:update_char_cover()
end 

--功能：同卡，叠加
--参数：卡类
--返回：
function Vip_obj:add_card(card_type)
    if card_type ~= self.card_type then
	   return
	end
	self.card_type = card_type
	local alive_time = self:get_alive_time(card_type)

	if ev.time > self.end_time then
	    self.end_time = ev.time+alive_time
		self.transfer = vip_config.VipTable[card_type]["transfer"] or 0
	else
	    self.end_time = self.end_time+alive_time
		self.transfer = (vip_config.VipTable[card_type]["transfer"] or 0) + self.transfer
	end
	self:update_char()
end 

--功能：更新
--参数：空
--返回：空
function Vip_obj:update_char()
	local dbh=f_get_db()
	local data={}
	data.char_id=self.char_id
	data.card_type=self.card_type
	data.end_time=self.end_time
	data.open_bonus = self.open_bonus
	data.transfer = self.transfer
	data.transfer_day = self.transfer_day
	local query=string.format("{char_id:%d}",self.char_id)
	local err=dbh:update(database,query,Json.Encode(data))
end 

function Vip_obj:update_char_cover()
	self.open_bonus = tostring(tonumber(os.date("%Y%m%d",ev.time))-1)
	local dbh=f_get_db()
	local data={}
	data.char_id=self.char_id
	data.card_type=self.card_type
	data.end_time=self.end_time
	data.open_bonus = self.open_bonus
	data.transfer = self.transfer
	data.transfer_day = self.transfer_day

	local query=string.format("{char_id:%d}",self.char_id)
	local err=dbh:update(database,query,Json.Encode(data))
end

--功能：插入
--参数：空
--返回：空
function Vip_obj:insert_char()
	local dbh=f_get_db()
	local data={}
	data.char_id=self.char_id
	data.card_type=self.card_type
	data.end_time=self.end_time 
	data.transfer = self.transfer
	data.transfer_day = self.transfer_day

	local err=dbh:insert(database,Json.Encode(data))
	return err 
	
end 


function Vip_obj:delete_char()
   local dbh=f_get_db()
   local data={}
	local str = string.format("{char_id:%d}",self.char_id)	
   local err=dbh:delete(database,str)
   return err 
  
end 


--功能：数据装载
--参数：空
--返回：err
function Vip_obj:db_load()
   local dbh=f_get_db() 
   local query=string.format("{char_id:%d}",self.char_id) 
   local fields="{_id:0}"
   local row,err=dbh:select_one(database,fields,query) 
   if row~=nil and err==0 then
		self.char_id = row.char_id 
		self.card_type = row.card_type 
		self.end_time = row.end_time
		self.open_bonus = row.open_bonus
		self.transfer = row.transfer or 0
		self.transfer_day = row.transfer_day
   end 
   return 0
end 

function Vip_obj:logout_save()
	if self.to_save then
		self:update_char()
	end
end

--功能：客户端
--参数：
--返回：
function Vip_obj:get_vip_info()
	if self.end_time and ev.time >= self.end_time and 0 ~= self.card_type then
		self:send_email()
		self.card_type = 0
		self:update_char()
		local pkt = {}
		pkt.endtime = self.end_time
		pkt.cardtype = 0
		g_svsock_mgr:send_server_ex(COMMON_ID,self.char_id,CMD_M2C_SYS_VIP_INFO,pkt)
	end

	if self.end_time == nil or self.card_type==0 then return 0 end
	if ev.time >= self.end_time then
		return 0
	end
	return self.card_type
end 

--功能:使用事件
--参数:
--返回:
function Vip_obj:use_item(card_type)
	 if card_type<0 then
	     return 20400
	 end
	if card_type == 5 then
		if 1 <= self.card_type then
			return 0
	 	end
	end
	local op_type = 0
	local player=g_obj_mgr:get_obj(self.char_id)
	if self.end_time==nil then
		 self:use_card(card_type)
		 op_type = 1
	elseif self.card_type~=card_type then
		self:cover_card(card_type)
		op_type = 2
	elseif self.card_type==card_type then
		self:add_card(card_type)
		op_type = 3
	end

	local args = {}
	args.level = card_type
	self:event_use_trigger(args)
	
	player:on_dress_update(12) 
	local remain_time = self:get_remain_time()
	self:notify_client(remain_time)	 
	self:write_log(op_type,remain_time)
	if card_type == 2 then
		local sys_l = {}
		sys_l[1] = player:get_name()
		sys_l[2] = f_get_string(657)
		local str_json = f_get_sysbd_format(10014, sys_l)
		f_cmd_sysbd(str_json)
	end
	if card_type == 3 then
		local sys_l = {}
		sys_l[1] = player:get_name()
		sys_l[2] = f_get_string(658)
		local str_json = f_get_sysbd_format(10015, sys_l)
		f_cmd_sysbd(str_json)
	end
	local pkt = {}
	pkt.endtime = self.end_time
	pkt.cardtype = card_type
	g_svsock_mgr:send_server_ex(COMMON_ID,self.char_id,CMD_M2C_SYS_VIP_INFO,pkt)
	return 0
end


function Vip_obj:get_remain_time()
	if self.end_time == nil or self.card_type==0 then return 0 end
	local ret = self.end_time-ev.time
	if ret <= 0  then
		ret = 0
		local player = g_obj_mgr:get_obj(self.char_id)
		player:on_dress_update(12)
	end
	return ret
end


function Vip_obj:notify_client(remain_time)
	local retpkt = {} 
	retpkt.time = remain_time
	retpkt.flag = self:is_get_bonus()
	g_cltsock_mgr:send_client(self.char_id,CMD_MAP_VIP_GET_VALID_TIME_S,retpkt)
end


function Vip_obj:write_log(op_type,remain)
	local str = "insert into log_vip(char_id,char_name,\
	type,vip_type,validity,time) \
	values(%d,'%s',%d,%d,%d,%d)"
	local player = g_obj_mgr:get_obj(self.char_id)
	local str_log = string.format(str,self.char_id, player:get_name(),
	op_type,self.card_type,remain,ev.time)
	g_mall_log:write(str_log)
	g_web_sql:write(str_log)
end


function Vip_obj:open_bonus_ex()
	self.open_bonus = os.date("%Y%m%d",ev.time)
	self:update_char()
end


function Vip_obj:is_get_bonus()
	if self.open_bonus == os.date("%Y%m%d",ev.time) then
		return 0
	end
	return 1
end

function Vip_obj:send_email()
	if not self.char_id then return end
	local pkt = {}
	pkt.sender = 0
	pkt.recevier = self.char_id
	pkt.title = f_get_string(515) or ""
	pkt.content = f_get_string(514) or ""
	g_svsock_mgr:send_server_ex(COMMON_ID,0,CMD_M2P_SEND_EMAIL_NO_BOX_S,pkt)
end

function Vip_obj:event_use_trigger(args)
	g_event_mgr:notify_event(EVENT_SET.EVENT_BECOME_VIP, self.char_id, args)
end