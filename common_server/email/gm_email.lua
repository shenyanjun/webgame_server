--2010-01-07
--laojc
--gm邮件
require("email/email")
require("email/email_db")
local database_gift = "gift_set"

Gm_email = oo.class(nil, "Gm_email")

function Gm_email:init()
	self.gift_set_list ={}      --礼品设置

	self.player_l = g_player_mgr:get_all_char()

	self:load()
end

function Gm_email:create_email(recevier,title,content,email_type,item_list,email_id)
	local g_email = Email(-1,recevier,title,content,0,email_type,Email_sys_type.type_gm,item_list)
	if g_email ~= nil then
		if email_type == Email_type.type_annex and item_list ~= nil then
			local item ={}
			for k,v in pairs(item_list or {}) do
				item[1] ={}
				item[1]["item_id"] = v.item_id
				item[1]["item_obj"] = v
				item[1]["number"] = 1
			end
			g_email:set_item_list(item)
		elseif email_type == nil then
			g_email:set_email_type(Email_type.type_common)
		end
		if email_id ~= nil and email_id ~= 0 then
			g_email:set_email_id(email_id)
		end
		g_email_mgr:add_email(g_email)
	end
end


--礼品设置
function Gm_email:gm_gift_set(pkt)
	if pkt == nil or pkt.level == nil or pkt.occ == nil or pkt.time == nil or pkt.gift_id == nil or pkt.type == nil then return end

	local time_span = pkt.time
	local level = pkt.level
	local occ = pkt.occ
	local email_title = pkt.email_title
	local email_content = pkt.email_content or {}
	local item_list = pkt.item_list or {}
	local gift_id = pkt.gift_id
	local type = pkt.type

	self.gift_set_list[gift_id] = {}
	self.gift_set_list[gift_id].time = time_span
	self.gift_set_list[gift_id].level = level
	self.gift_set_list[gift_id].occ = occ
	self.gift_set_list[gift_id].email_title = email_title
	self.gift_set_list[gift_id].email_content = email_content
	self.gift_set_list[gift_id].item_list = item_list
	self.gift_set_list[gift_id].flag = 0
	self.gift_set_list[gift_id].type = type
	self.gift_set_list[gift_id].char_list = {}

end

function Gm_email:on_timer_gift(time_span)
	local dbh = f_get_db()
	for k,v in pairs(self.gift_set_list or {}) do
		local t_time = ev.time
		local time = v.time 

		local all_player = g_player_mgr.online_player_l
		if t_time > time then
			if v.type == 2 and v.flag == 0 then  --在线玩家邮件
				v.flag = 1
				local query = string.format("{gift_id:'%s'}", k)
				local data = string.format("{flag:1}")

				dbh:update(database_gift, query, data)

				for m,n in pairs(all_player or {})do
					if self.player_l[m]["level"]>=v.level[1] and self.player_l[m]["level"] <=v.level[2] then
						for b,c in pairs(v.occ or {}) do
							if self.player_l[m]["occ"] == c then
								if v.item_list ~= nil and table.size(v.item_list) ~= 0 then
									local item_list = {}
									item_list[1] = v.item_list
									self:create_email(m, v.email_title, v.email_content, Email_type.type_annex, item_list,nil)
								else
									self:create_email(m, v.email_title, v.email_content, Email_type.type_annex, nil,nil)
								end
							end
						end
					end
				end
			elseif v.type == 1 and v.flag == 0 then  --全服邮件
				v.flag = 2
				for m,n in pairs(all_player or {})do
					local player = g_player_mgr.all_player_l[m]
					local time_span = ev.time - v.time
					if v.type == 1 and time_span >= 0 and time_span < 60 * 60 * 24 * 14 then
						local p_level = player["level"]
						if p_level>=v.level[1] and p_level <=v.level[2] then
							local flg = 0
							--for mm,nn in pairs(v.char_list) do
								--if nn == m then
									--flg = 1
									--break
								--end
							--end
							if v.char_list[m] ~= nil then
								flg = 1
							end

							if flg == 0 then
								local occ = player["occ"]
								for b,c in pairs(v.occ or {}) do
									if occ == c then
										if v.item_list ~= nil and table.size(v.item_list) ~= 0 then
											local item_list = {}
											item_list[1] = v.item_list
											self:create_email(m, v.email_title, v.email_content, Email_type.type_annex, item_list,nil)
										else
											self:create_email(m, v.email_title, v.email_content, Email_type.type_annex, nil,nil)
										end
										self.gift_set_list[k].char_list[m] = 1
										break
									end
								end
							end
						end
					end
				end
			else
				
			end
		end
	end
end

function Gm_email:get_click_param_gift()
	return self,self.on_timer_gift,30,nil
end

function Gm_email:gm_gift_stop(pkt)
	if pkt == nil or pkt.gift_id == nil then return end
	if self.gift_set_list[pkt.gift_id] ~=nil then
		self.gift_set_list[pkt.gift_id] = nil 
	end
end

function Gm_email:gm_gift_on_timer()
	local dbh = f_get_db()
	for k,v in pairs(self.gift_set_list) do
		local condition = string.format("{gift_id:'%s'}", k)
		local ret = {}
		ret.gift_id = k
		ret.time = v.time
		ret.level = v.level
		ret.occ = v.occ
		ret.email_title = v.email_title
		ret.email_content = v.email_content
		ret.item_list = v.item_list
		ret.flag = v.flag
		ret.type = v.type
		ret.char_list = {}
		for mm,nn in pairs(v.char_list or {}) do
			table.insert(ret.char_list, mm)
		end

		dbh:update(database_gift,condition,Json.Encode(ret),true)
	end
end

function Gm_email:gm_gift_param_ex()
	return self,self.gm_gift_on_timer,60*60*24,nil  --60*60*24
end


function Gm_email:online_send_email(char_id)
	local t_time = ev.time
	local player = g_player_mgr.all_player_l[char_id]
	for k,v in pairs(self.gift_set_list or {}) do
		local time_span = ev.time - v.time
		if v.type == 1 then
			if v.flag == 0 or v.flag == 2 then
				if time_span >= 0 and time_span < 60 * 60 * 24 * 14 then
					local p_level = player["level"]
					if p_level>=v.level[1] and p_level <=v.level[2] then
						local flg = 0
						--for mm,nn in pairs(v.char_list) do
							--if nn == char_id then
								--flg = 1
								--break
							--end
						--end
						if v.char_list[char_id] ~= nil then
							flg = 1
						end

						if flg == 0 then
							local occ = player["occ"]
							for b,c in pairs(v.occ or {}) do
								if occ == c then
									if v.item_list ~= nil and table.size(v.item_list) ~= 0 then
										local item_list = {}
										item_list[1] = v.item_list
										self:create_email(char_id, v.email_title, v.email_content, Email_type.type_annex, item_list,nil)
									else
										self:create_email(char_id, v.email_title, v.email_content, Email_type.type_annex, nil,nil)
									end
									self.gift_set_list[k].char_list[char_id] = 1
									break
								end
							end
						end
					else
						self.gift_set_list[k].char_list[char_id] = 1
					end
				elseif time_span > 60 * 60 * 24 * 14 then
					v.flag = 1
					local query = string.format("{gift_id:'%s'}", k)
					local data = string.format("{flag:1}")
					local dbh = f_get_db()
					dbh:update(database_gift, query, data)
				end
			end
		end
	end
end


--------------------数据库加载----------------------
function Gm_email:load()
	local rs= selectallgift()
	if rs == nil then return end

	for k,v in pairs (rs) do
		local gift_id = v.gift_id

		self.gift_set_list[gift_id]={}
		self.gift_set_list[gift_id].time = v.time
		self.gift_set_list[gift_id].level = v.level
		self.gift_set_list[gift_id].occ = v.occ
		self.gift_set_list[gift_id].email_title = v.email_title
		self.gift_set_list[gift_id].email_content = v.email_content
		self.gift_set_list[gift_id].item_list = v.item_list
		self.gift_set_list[gift_id].flag = v.flag
		self.gift_set_list[gift_id].type = v.type or 1
		self.gift_set_list[gift_id].char_list = {}
		for m,n in pairs(v.char_list or {}) do
			self.gift_set_list[gift_id].char_list[n] = 1
		end
	end
end


Gm_email:init()
