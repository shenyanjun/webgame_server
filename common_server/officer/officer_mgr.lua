--2012-4-24
--chenxidu
--战场官职管理类
--local debug_print = print
local debug_print = function () end

OfficerMgr = oo.class(nil, "OfficerMgr")

local officer_loader = require("officer.officer_loader")

local _update_interval	= 3        
local _db_interval	  	= 60*8

local skill_list = {}
skill_list[1] = 2724
skill_list[2] = 2725
skill_list[3] = 2726
skill_list[4] = 2727
skill_list[5] = 2728

function OfficerMgr:__init()

	--已经获得官职人员列表
	self.have_officer_char_list = {}

	--建立char_id 和 官职id的反映射关系
	self.officer_char_key_list  = {}

	--已经获得官职人员列表(+char_name)
	self.have_officer_name_list = {}

	--参拜列表带名字(+char_name)
	self.visi_officer_name_list = {}

	--官职数据表(入库表)
	--self.bid_db_list = {}

end

--load
function OfficerMgr:load()
	self.bid_info = Officer_sort()

	self:load_officer_db()

	self.update_time    = ev.time + _update_interval                 --更新定时器
	self.db_time = ev.time + _db_interval            --入库定时器
	--self.is_update = false

	self.time = 0

	self.office_time_st = {}	--开始时间
	self.office_time_en = {}	--结束时间
	self:set_start_time()

	self:init_over()
	--self:test()
end

--加载已获得官职数据表
function OfficerMgr:load_officer_db()
	local error,row = Officer_db:LoadOfficer()
	if error == 0 and row then
		for id,item in pairs(row) do
			self.have_officer_char_list[item.off_id] = {}
			self.have_officer_char_list[item.off_id].list = {}

			if item.e_st >0 and ev.time >= item.e_st then			--官职过期，重新初始化
				self.have_officer_char_list[item.off_id].e_st  = 0
				if item.off_id == 1 then
					self.have_officer_char_list[item.off_id].visi  = {}
				end
				self.have_officer_name_list[item.off_id] = {}
			else
				--self.have_officer_char_list[item.off_id] = {}
				self.have_officer_char_list[item.off_id].list = item.list or {}
				self.have_officer_char_list[item.off_id].e_st = item.e_st 
				if item.off_id == 1 then
					self.have_officer_char_list[item.off_id].visi = {}
					for i = 1, 10 do
						self.have_officer_char_list[item.off_id].visi[i] = item.visi[i]
					end
					--self.have_officer_char_list[item.off_id].visi = item.visi or {}
				end

				self.have_officer_name_list[item.off_id] = {}
				if table.getn(item.list)>0 then
					for k,v in pairs(item.list or {}) do
						local items = {}
						items[1] = v
						items[2] = g_player_mgr.all_player_l[v]["occ"]
						items[3] = g_player_mgr.all_player_l[v]["level"]
						items[4] = g_player_mgr.all_player_l[v]["gender"]
						items[5] = g_player_mgr.all_player_l[v]["char_nm"]
						table.insert(self.have_officer_name_list[item.off_id],items)	
						self.officer_char_key_list[tostring(v)] = item.off_id
					end
				end

				if item.off_id == 1 then
					local tmp_cnt = 1
					for k,v in ipairs(item.visi or {}) do
						table.insert(self.visi_officer_name_list,g_player_mgr.all_player_l[v]["char_nm"])	
						tmp_cnt = tmp_cnt + 1
						if tmp_cnt > 10 then
							break
						end
					end
				end
			end
		end
	else
		for id = 1, MAX_OFFICER_COUNT do
			self.have_officer_char_list[id] = {}
			self.have_officer_char_list[id].list  = {}
			self.have_officer_char_list[id].e_st  = 0
			if id == 1 then
				self.have_officer_char_list[id].visi  = {}
			end
			self.have_officer_name_list[id] = {}
		end
	end
end

--检测官职是否过期
function OfficerMgr:check_officer_is_outtime()
	for id,item in pairs(self.have_officer_char_list) do
		if item.e_st > 0 and ev.time > item.e_st then
			table.remove(item.list, id)
		end
	end	
end

function OfficerMgr:get_start_time()
	for id = 1,MAX_OFFICER_COUNT do
		self.office_time_st[id], self.office_time_en[id] = officer_loader.get_start_time(id)
	end
end


function OfficerMgr:init_over()
	local time = ev.time 
	for id = 1, MAX_OFFICER_COUNT do
		local over = officer_loader.is_can_officer(id, time)		--当前
		local ov = self.bid_info:get_bid_db_list_over(id)
			if over ~=  ov then
			if over == 0 then
				--self:close_auction(id)
				self:return_all_honor(id)
				debug_print("Office init end by special:", ov, "->", over, id)
				if id == MAX_OFFICER_COUNT then
					self.bid_info:clear_total_info()
					self:notice(nil,5)
					self:set_start_time()
				end
				if ov == 2 then
					self.bid_info:renew_top_sort(id)
				end

			elseif over == 1 then
				if  id == 1 then
					self.bid_info:clear_all_info()
					self:notice(pkt,3)
				end
				self.bid_info:set_bid_db_list_over(id,1)
				debug_print("Office init star by normal :", ov, "->", over, id)
				local pkt = {}
				pkt.id = id
				if ov == 2 then
					self.bid_info:renew_top_sort(id)
				end
			elseif over == 2 then
				if self.bid_info:get_bid_db_list_over(id) == 0 then
					if  id == 1 then
						self.bid_info:clear_all_info()
					end
					self.bid_info:set_bid_db_list_over(id,2)
					debug_print("Office init start by special :", ov, "->", over, id)
					local pkt = {}
					pkt.id = id
					self:notice(pkt,3)
				end
			end
			self.bid_info:set_bid_db_list_over(id, over)
		end
	end
end

--从数据库中读取开始标识self.bid_info:get_bid_db_list_over(id)开始标识
function OfficerMgr:set_start_time()
	local st_tm_l, en_tm_l = officer_loader.set_start_time()
	for id = 1,MAX_OFFICER_COUNT do
		self.office_time_st[id], self.office_time_en[id] = st_tm_l[id], en_tm_l[id]
	end
end

--包装一次ontimer
function OfficerMgr:ontimer_function()
	local time = ev.time
	--if time > self.update_time + _update_interval then
	for id = 1,MAX_OFFICER_COUNT do
		local over = self.bid_info:get_bid_db_list_over(id)		--当前
		--print("bin_info_over:", over)
		if over == 0 then
			if time > self.office_time_st[id] then
				if  id == 1 then
					self.bid_info:clear_all_info()
					self:notice(pkt,3)
				end
				self.bid_info:set_bid_db_list_over(id,1)
				debug_print("Office star by normal :", over, "->", self.bid_info:get_bid_db_list_over(id), id)
				local pkt = {}
				pkt.id = id
			end
		elseif over == 1 then
			if time >= (self.office_time_en[id] - 15*60) then
				if id == 1 then 
					self:notice(pkt,6)
				end
				self.bid_info:renew_top_sort(id)
				self.bid_info:set_bid_db_list_over(id, 2)
				debug_print("Office change by normal :", over, "->", self.bid_info:get_bid_db_list_over(id), id)
			end
		elseif over == 2 then
			if time > self.office_time_en[id] then
				if id == 1 then 
					self.officer_char_key_list = {}
				end
				self:close_auction(id)
				self.bid_info:set_bid_db_list_over(id, 0)
				if id == MAX_OFFICER_COUNT then
					self.bid_info:clear_total_info()
					self:notice(nil,1)
					self:set_start_time()
					--@这里同步所有map
					self:send_all_officer_info()
				end
				debug_print("Office end by normal :", over, "->", self.bid_info:get_bid_db_list_over(id), id)
			end
		end
	end
	self.update_time = self.update_time + _update_interval
	--end

	self.bid_info:on_timer()
	--if time > self.db_time then
		--self:check_officer_is_outtime()
		--self.db_time = self.db_time + _db_interval
	--end
end

function OfficerMgr:get_click_param()
	return self, self.on_timer,3,nil
end

--竞拍是否开始结算(在这里定时入库)
function OfficerMgr:on_timer()
	self:ontimer_function()
end

--[[--
function OfficerMgr:is_close_officer(id)
	local is_close 
	is_close,self.time = officer_loader.is_close_officer(id,ev.time)
	return is_close
end
--]]--
--竞拍官职
function OfficerMgr:request_officer(char_id,pkt)
	self.bid_info:request_officer(char_id,pkt)
end

--取消竞投
function OfficerMgr:ret_request_officer(char_id)
	self.bid_info:ret_request_officer(char_id)
end

--结束竞拍,发官职奖励(清数据库)
function OfficerMgr:close_auction(id)
	local all_count = officer_loader.get_officer_count(id) if all_count == 0 then return end
	self.have_officer_char_list[id] = {}
	if id == 1 then
		self.have_officer_char_list[1].visi = {}
	end
	self.have_officer_char_list[id].list = {}
	self.have_officer_char_list[id].e_st = ev.time + officer_loader.get_officer_time(id)
	self.have_officer_name_list[id] = {}

	local top_list,all_list = self.bid_info:get_top_bid_list(id)
	for k,v in pairs(top_list or {}) do
		table.insert(self.have_officer_char_list[id].list,v[1])

		local items = {}
		items[1] = v[1]
		items[2] = g_player_mgr.all_player_l[v[1]]["occ"]
		items[3] = g_player_mgr.all_player_l[v[1]]["level"]
		items[4] = g_player_mgr.all_player_l[v[1]]["gender"]
		items[5] = g_player_mgr.all_player_l[v[1]]["char_nm"]
		table.insert(self.have_officer_name_list[id],items)	
		self.officer_char_key_list[tostring(v[1])] = id

		--@修改为通知map管理器，map管理器通知本线玩家
		--if g_player_mgr:is_online_char(v[1]) then
			--local pkt_t = {}			--pkt_t.id = id			--pkt_t.result = 0			--local line = g_player_mgr:get_char_line(v[1])			--g_server_mgr:send_to_server(line, v[1], CMD_SEND_OFFICER_RESULT_C, pkt_t)
		--end

		--邮件通知
		local spk = {}
		spk.title   = f_get_string(2716) 
		spk.content = string.format(f_get_string(2717),officer_loader.get_officer_name(id))
		local g_email = Email(-1,v[1],spk.title,spk.content,0,Email_type.type_annex,Email_sys_type.type_sys,nil)
		if g_email ~= nil then
			g_email_mgr:add_email(g_email)
		end

		local ret = {}
		ret.char_id = v[1]
		ret.char_name = g_player_mgr.all_player_l[v[1]]["char_nm"]
		ret.level = g_player_mgr.all_player_l[v[1]]["level"]
		ret.honour = v[2]
		ret.left_honour = 0
		ret.type = id
		ret.io = 1
		ret.succeed = 1
		self:set_tou_log(ret)
	end
	for k,v in pairs(all_list or {}) do
		if g_player_mgr:is_online_char(v[1]) then
			local pkt_t = {}			local line = g_player_mgr:get_char_line(v[1])			pkt_t.result = 0			pkt_t.money = v[2]			g_server_mgr:send_to_server(line, v[1], CMD_SEND_OFFICER_HONOUR_C, pkt_t)

			local spk = {}
			spk.title   = f_get_string(2716) 
			spk.content = string.format(f_get_string(2718))
			local g_email = Email(-1,v[1],spk.title,spk.content,0,Email_type.type_annex,Email_sys_type.type_sys,nil)
			if g_email ~= nil then
				g_email_mgr:add_email(g_email)
			end
		else
			--不在线没有竞投成功的(荣誉值插入邮件)
			self:send_email(v[1], v[2])
		end
	end

	--直接清掉数据库
	--self.bid_info:clear_all_info()
	self:seralize_officer_db_one(id,self.have_officer_char_list[id])
	--@4个id，每个都把所有列表重发一次；id=1时，列表的234都是错误信息
	--self:send_all_officer_info()
end

function OfficerMgr:send_email(char_id, honor)
	local pkt = {}
	pkt.sender     = -1
	pkt.recevier   = char_id
	pkt.title      = f_get_string(2716)
	pkt.content    = f_get_string(2718)
	pkt.box_title  = f_get_string(2720)
	pkt.money_list = {}
	pkt.gift_box   = {}
	pkt.item_list  = {}
	pkt.money_list[MoneyType.HONOR] = honor
	g_email_mgr:send_email_interface(pkt)
end

--竞拍不正常结束全部荣誉值返还
function OfficerMgr:return_all_honor(id)
	local top_list,all_list = self.bid_info:get_top_bid_list(id)
	for k,v in pairs(top_list or {}) do
		self:send_email(v[1], v[2])
	end
	for k,v in pairs(all_list or {}) do
		self:send_email(v[1], v[2])
	end
end

--使用官职效果(禁言+秒杀+加成)
function OfficerMgr:execute_officer(owenr,pkt)
	local char = tostring(owenr)
	pkt.char_id = g_player_mgr:char_nm2id(pkt.char_name)
	if not g_player_mgr:is_online_char(pkt.char_id) then
		local line = g_player_mgr:get_char_line(owenr)
		pkt.result = 22829
		g_server_mgr:send_to_server(line,owenr,CMD_OFFICER_BANNED_REQUEST_C,pkt)	
		return
	end

	if self.officer_char_key_list[char] > (self.officer_char_key_list[tostring(pkt.char_id)] or 100) then
		local line = g_player_mgr:get_char_line(owenr)
		pkt.result = 22805
		g_server_mgr:send_to_server(line,owenr,CMD_OFFICER_BANNED_REQUEST_C,pkt)	
		return
	end

	pkt.result= 0
	pkt.owenr = owenr
	pkt.name  = g_player_mgr.all_player_l[owenr]["char_nm"]
	pkt.level = g_player_mgr.all_player_l[owenr]["level"]
	pkt.pid    = self.officer_char_key_list[char]
	g_server_mgr:send_to_server(g_player_mgr:get_char_line(pkt.char_id),pkt.char_id,CMD_USE_OFFICER_SKILL_RETURN_M,pkt)	
end

function OfficerMgr:see_my_money(char_id)
	local line = g_player_mgr:get_char_line(char_id)
	local pkt = {}	pkt.result  = 0	pkt.char_id = char_id	pkt.id,pkt.money = self.bid_info:get_char_money(char_id)
	pkt.total = pkt.money
	g_server_mgr:send_to_server(line,char_id, CMD_SEND_OWNER_OFFICER, pkt)
end

--获取竞投列表
function OfficerMgr:send_bid_list(char_id,pkt)
	self.bid_info:send_bid_list(char_id, pkt)
end

--同步已经获取官职人员列表(启动公共服，活动结束同步)
function OfficerMgr:send_all_officer_info(server_id)
	local ret = {}
	ret.list = self.have_officer_char_list
	if server_id then
		g_server_mgr:send_to_server(server_id,0,CMD_SEND_OFFICER_REQUEST_LIST_C,ret)
	else
		g_server_mgr:send_to_all_map(0,CMD_SEND_OFFICER_REQUEST_LIST_C,ret)
	end
end

--使用技能返回 
function OfficerMgr:use_skill_return(char_id,pkt)
	if pkt.result == 0 then
		self:notice(pkt,2)
	end
	local line = g_player_mgr:get_char_line(char_id)	g_server_mgr:send_to_server(line, char_id, CMD_USE_OFFICER_SKILL_RETURN_C,pkt)
end

--世界广播 type=1 竞拍成功官职 =2 使用特权 =3竞投开始 4=天帝上线 5=竞拍不成功服务器维修
function OfficerMgr:notice(pkt,type)
	--print("___",j_e(self.have_officer_char_list))
	if type == 1 then
		for i = 2,1,-1 do
			for k,v in pairs(self.have_officer_char_list[i].list or {})do
				local pkt_new = {}
				pkt_new.char_name = g_player_mgr.all_player_l[v]["char_nm"]			
				if i == 2 then
					pkt_new.index = 2
				else
					pkt_new.index = 1
				end
				pkt_new.type = 1
				local pkts = Json.Encode(pkt_new)
				--print("===",j_e(pkt_new))
				for k , v in pairs(g_player_mgr.online_player_l) do
					g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_W2C_OPEN_OFFICER_NOTICE_C, pkts, true)
				end				
			end
		end
	elseif type == 2 then
		local new_pkt = {}
		local player_mgr = g_player_mgr

		local officer_id = self.officer_char_key_list[tostring(pkt.owenr)]
		local officer1 = ""
		officer1 = officer1 .. f_get_string(2731)
		local officer_name = officer_loader.get_officer_name(officer_id)
		officer1 = officer1 ..officer_name
		officer1 = officer1 .. f_get_string(2732)
		new_pkt[1]   = officer1

		local officer2 = ""
		officer2 = officer2 .. f_get_string(2735)
		local use_name 	= player_mgr.all_player_l[pkt.owenr]["char_nm"]
		officer2 = officer2 .. use_name
		officer2 = officer2 .. f_get_string(2736)
		new_pkt[2] = officer2
		
		local str = 2734
		if officer_id == 1 then
			str = 2733
		end
		local content = f_get_string(str)
		new_pkt[3] = content

		local officer3 = ""
		officer3 = officer3 .. f_get_string(2735)
		local des_name 	= player_mgr.all_player_l[pkt.char_id]["char_nm"]
		officer3 = officer3 .. des_name
		officer3 = officer3 .. f_get_string(2736)
		new_pkt[4] = officer3


		local string_id = skill_list[pkt.id]
		--print("string_id", string_id, pkt.id)
		local right = f_get_string(string_id)
		new_pkt[5] = right

		local pkt_s = {}
		pkt_s.use_skill = new_pkt
		pkt_s.type = 2
		pkt_s = Json.Encode(pkt_s)
		--print("new_pkt====", pkt_s)
		for k , v in pairs(g_player_mgr.online_player_l) do
			g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_W2C_OPEN_OFFICER_NOTICE_C, pkt_s, true)
		end
	elseif type == 3 then
		--竞投开始
		local new_pkt = {}
		new_pkt.type = 3
		--new_pkt.id   = pkt.id
		local pkts = Json.Encode(new_pkt)
		for k , v in pairs(g_player_mgr.online_player_l) do
			g_svsock_mgr:send_server_ex(WORLD_ID,k,CMD_W2C_OPEN_OFFICER_NOTICE_C, pkts,true)
		end
	elseif type == 4 then
		--天帝上线
		local new_pkt = {}
		new_pkt.char_id = pkt.char_id
		new_pkt.type = 4
		new_pkt.des_name = g_player_mgr.all_player_l[pkt.char_id]["char_nm"]
		local pkts = Json.Encode(new_pkt)
		for k , v in pairs(g_player_mgr.online_player_l) do
			g_svsock_mgr:send_server_ex(WORLD_ID,k,CMD_W2C_OPEN_OFFICER_NOTICE_C, pkts,true)
		end
	elseif type == 5 then	
		local pkt = {}
		pkt.type = 5
		local pkts = Json.Encode(pkt)
		for k , v in pairs(g_player_mgr.online_player_l) do
			g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_W2C_OPEN_OFFICER_NOTICE_C, pkts, true)
		end	
	elseif type == 6 then	
		local pkt = {}
		pkt.type = 6
		local pkts = Json.Encode(pkt)
		local svscok_mgr = g_svsock_mgr
		for k , v in pairs(g_player_mgr.online_player_l) do
			svscok_mgr:send_server_ex(WORLD_ID, k, CMD_W2C_OPEN_OFFICER_NOTICE_C, pkts, true)
		end	
	end				
end

function OfficerMgr:officer_top_online(char_id)
	local pkt = {}
	pkt.char_id = char_id
	self:notice(pkt,4)	
end

function OfficerMgr:see_officer_list(char_id)
	local line = g_player_mgr:get_char_line(char_id)
	local ret = {}
	ret.list = {}
	ret.list[1] = self.have_officer_name_list[1]
	ret.list[2] = self.have_officer_name_list[2]
	ret.list[3] = self.have_officer_name_list[3]
	ret.list[4] = self.have_officer_name_list[4]
	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_SEE_OFFICER_LISR_C, ret)
end

function OfficerMgr:visi_officer_list(char_id)
	local line = g_player_mgr:get_char_line(char_id)
	local ret = {}
	ret.list = self.visi_officer_name_list
	--print("544 =", j_e(ret))
	g_svsock_mgr:send_server_ex(WORLD_ID, char_id, CMD_SEE_ANNOUN_LISR_C, ret)
	--print("1111",j_e(ret))
end

function OfficerMgr:visi_officer(char_id)
	local ilen = table.getn(self.visi_officer_name_list)
	if ilen < 10 then
		table.insert(self.visi_officer_name_list,g_player_mgr.all_player_l[char_id]["char_nm"])
		table.insert(self.have_officer_char_list[1].visi, char_id)
	else
		table.remove(self.visi_officer_name_list, 1)
		table.insert(self.visi_officer_name_list, g_player_mgr.all_player_l[char_id]["char_nm"])
		
		table.remove(self.have_officer_char_list[1].visi, 1)
		table.insert(self.have_officer_char_list[1].visi, char_id)
	end
	--table.insert(self.have_officer_char_list[1].visi,char_id)
	self:visi_officer_list(char_id)
end

function OfficerMgr:seralize_bid_db()
	self.bid_info:seralize_to_db()
end

function OfficerMgr:seralize_officer_db()
	for id,item in pairs( self.have_officer_char_list or {}) do
		Officer_db:UpdateOfficerList(id,item)
	end
end

function OfficerMgr:seralize_officer_db_one(id,item)
	Officer_db:UpdateOfficerList(id,item)
end

--竞投操作流水
function OfficerMgr:set_tou_log(pkt)	
	if pkt then
		local str = string.format(
			"insert into log_bidding_position set char_id = %d,char_name = '%s',level = %d,honour =%d,left_honour = %d,type = %d,io = %d,succeed = %d,time = %d",
				pkt.char_id,pkt.char_name,pkt.level,pkt.honour,pkt.left_honour,pkt.type,pkt.io,pkt.succeed,ev.time)
				g_web_sql:write(str) 
	end
end

--测试竞投性能
local test_count = 4000
function OfficerMgr:test()
	local time = os.clock()
	print("696 start~!")
	for i = 1, test_count do
		local pkt ={}
		pkt.type = 1
		pkt.id = crypto.random(1, 5)
		--print("459 =", pkt.id)
		pkt.money = crypto.random(1, 10000)
		self:request_officer(i, pkt)
	end
	print("705 =", os.clock() - time)
end


