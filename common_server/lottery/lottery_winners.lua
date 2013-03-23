
----------------------------------玩家的选号

local g_u = iconv("gbk", "utf-8")

Lottery_winners = oo.class(nil, "Lottery_winners")

local delay_time = 60 * 5
local lvls = 4			--下注范围   0 ~ 5000
local winners_email = {}
function Lottery_winners:__init( data )
	if data then
		self.period 	= data.period
		self.valid_time = data.valid_time
		self.winners 	= data.winners
	else
		local submit_time = f_get_sunday() + 8 * 24 * 3600 + 1
		local day_table	  = os.date("*t" , submit_time)
		self.period 	= (day_table.year % 100) * 10000 + day_table.month * 100 + day_table.day
		self.valid_time = submit_time

		--self.winners[4].bonus 奖金   --self.winners[4].tostring(number)  tostring(中奖号码)  self.winners[4].number  中奖号码   
		--self.winners[4].number.tostring(char_id) = 中奖者tostring()  -self.winners[4].number.char_id = count  下注数
		self.winners 	= {}		
		for i = 1, lvls do
			self.winners[i] 	  = {}
			self.winners[i].bonus = 0
		end
	end
end

function Lottery_winners:notice_lottery()
--构造字符串并广播
	local pkt = {}
	winners_email = {}
	local all_flags = true
	for k , v in pairs(self.winners[3]) do
		if k ~= 'bonus' then
			all_flags = false					--有人中奖
			break
		end
	end

	if all_flags then

		return false
	end
	--pkt.stage = self.period

	for i = 1 , 27 do
		pkt[i] = {}
	end

	pkt[1].type 	= 0
	local draw_time = f_get_sunday() + 24 * 3600 + 1
	local draw_table  = os.date("*t" , draw_time)
	pkt[1].period = (draw_table.year % 100) * 10000 + draw_table.month * 100 + draw_table.day


	pkt[2].type		= 1	
	pkt[2].lvl	 	= 4

	local i = 1
	for k , v in pairs(self.winners[4]) do
		if k ~= 'bonus' then
			pkt[2+i].type		= 2
			pkt[2+i].lvl		= 4
			pkt[2+i].number_count		= i
			pkt[2+i].number	= k
			i = i + 1
		end
	end

	local flags = true
	local name = {}
	local winners_count = 0
	local lottery_count = 0

	for k,v in pairs(self.winners[4]) do
		if k ~= 'bonus' then
			for k1 , v1 in pairs(v) do
				flags = false					--有人中奖
				local char_id = tonumber(k1)
				winners_count = winners_count + 1
				lottery_count = lottery_count + v1

				local  t = 1
				local  tmp_name = g_player_mgr.all_player_l[char_id]["char_nm"]
				local tmp_flags = true
				for k , v in pairs(name) do
					if v == tmp_name then
						tmp_flags = false
						break
					end
					t = t + 1
					if t > 3 then
						tmp_flags = false
						break
					end
				end
				if tmp_flags then
					table.insert(name , tmp_name) 
				end
			end
		end
	end
	if flags then
		pkt[13].type = 4
		pkt[13].lvl  = 4
		pkt[13].bonus = all_bonus[4]
	else 
		pkt[13].type  = 3
		pkt[13].lvl  = 4
		pkt[13].player_count = winners_count
		pkt[13].bonus = math.ceil(self.winners[4].bonus / lottery_count)
		pkt[13].name  = name

		

		for k,v in pairs(self.winners[4]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do				--有人中奖
					local char_id = tonumber(k1)
					local s_pk = {}
					s_pk.char_id = char_id
					s_pk.bonus = pkt[13].bonus
					s_pk.lvl = 4
					table.insert(winners_email, s_pk)
				end
			end
		end

	end


	pkt[14].type	= 1	
	pkt[14].lvl	 	= 3

	i = 1
	for k , v in pairs(self.winners[3]) do
		if k ~= 'bonus' then
			pkt[14+i].type		= 2
			pkt[14+i].lvl		= 3
			pkt[14+i].number_count		= i
			pkt[14+i].number	= k
			i = i + 1
		end
	end

	flags = true
	name = {}
	winners_count = 0
	lottery_count = 0

	for k,v in pairs(self.winners[3]) do
		if k ~= 'bonus' then
			for k1 , v1 in pairs(v) do
				flags = false					--有人中奖
				local char_id = tonumber(k1)
				winners_count = winners_count + 1
				lottery_count = lottery_count + v1

				local  t = 1
				local  tmp_name = g_player_mgr.all_player_l[char_id]["char_nm"]
				local tmp_flags = true
				for k , v in pairs(name) do
					if v == tmp_name then
						tmp_flags = false
						break
					end
					t = t + 1
					if t > 3 then
						tmp_flags = false
						break
					end
				end
				if tmp_flags then
					table.insert(name , tmp_name) 
				end
			end
		end
	end
	if flags then
		pkt[20].type = 4
		pkt[20].lvl = 3
		pkt[20].bonus = all_bonus[3]
	else 
		pkt[20].type  = 3
		pkt[20].lvl = 3
		pkt[20].player_count = winners_count
		pkt[20].bonus = math.ceil(self.winners[3].bonus / lottery_count)
		pkt[20].name = name

		for k,v in pairs(self.winners[3]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do				--有人中奖
					local char_id = tonumber(k1)
					local s_pk = {}
					s_pk.char_id = char_id
					s_pk.bonus = pkt[20].bonus
					s_pk.lvl = 3
					table.insert(winners_email, s_pk)
				end
			end
		end

	end

	pkt[21].type	= 1	
	pkt[21].lvl	 	= 2

	i = 1
	for k , v in pairs(self.winners[2]) do
		if k ~= 'bonus' then
			pkt[21+i].type		= 2
			pkt[21+i].lvl		= 2
			pkt[21+i].number_count	= i
			pkt[21+i].number	= k
			i = i + 1
		end
	end

	flags = true
	name = {}
	winners_count = 0
	lottery_count = 0

	for k,v in pairs(self.winners[2]) do
		if k ~= 'bonus' then
			for k1 , v1 in pairs(v) do
				flags = false					--有人中奖
				local char_id = tonumber(k1)
				winners_count = winners_count + 1
				lottery_count = lottery_count + v1

				local  t = 1
				local  tmp_name = g_player_mgr.all_player_l[char_id]["char_nm"]
				local tmp_flags = true
				for k , v in pairs(name) do
					if v == tmp_name then
						tmp_flags = false
						break
					end
					t = t + 1
					if t > 3 then
						tmp_flags = false
						break
					end
				end
				if tmp_flags then
					table.insert(name , tmp_name) 
				end
			end
		end
	end
	if flags then
		pkt[24].type = 4
		pkt[24].lvl = 2
		pkt[24].bonus = all_bonus[2]
	else 
		pkt[24].type  = 3
		pkt[24].lvl = 2
		pkt[24].player_count = winners_count
		pkt[24].bonus = math.ceil(self.winners[2].bonus / lottery_count)
		pkt[24].name = name

		for k,v in pairs(self.winners[2]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do				--有人中奖
					local char_id = tonumber(k1)
					local s_pk = {}
					s_pk.char_id = char_id
					s_pk.bonus = pkt[24].bonus
					s_pk.lvl = 2
					table.insert(winners_email, s_pk)
				end
			end
		end

	end

	pkt[25].type	= 1	
	pkt[25].lvl	 	= 1

	i = 1
	for k , v in pairs(self.winners[1]) do
		if k ~= 'bonus' then
			pkt[25+i].type		= 2
			pkt[25+i].lvl		= 1
			pkt[25+i].number_count		= i
			pkt[25+i].number	= k
			i = i + 1
		end
	end

	flags = true
	name = {}
	winners_count = 0
	lottery_count = 0

	for k,v in pairs(self.winners[1]) do
		if k ~= 'bonus' then
			for k1 , v1 in pairs(v) do
				flags = false					--有人中奖
				local char_id = tonumber(k1)
				winners_count = winners_count + 1
				lottery_count = lottery_count + v1

				local  t = 1
				local  tmp_name = g_player_mgr.all_player_l[char_id]["char_nm"]
				local tmp_flags = true
				for k , v in pairs(name) do
					if v == tmp_name then
						tmp_flags = false
						break
					end
					t = t + 1
					if t > 3 then
						tmp_flags = false
						break
					end
				end
				if tmp_flags then
					table.insert(name , tmp_name) 
				end
			end
		end
	end
	if flags then
		pkt[27].type = 4
		pkt[27].lvl	 = 1
		pkt[27].bonus = all_bonus[1]
	else 
		pkt[27].type  = 3
		pkt[27].lvl	 = 1
		pkt[27].player_count = winners_count
		pkt[27].bonus = math.ceil(self.winners[1].bonus / lottery_count)
		pkt[27].name = name

		for k,v in pairs(self.winners[1]) do
			if k ~= 'bonus' then
				for k1 , v1 in pairs(v) do				--有人中奖
					local char_id = tonumber(k1)
					local s_pk = {}
					s_pk.char_id = char_id
					s_pk.bonus = pkt[27].bonus
					s_pk.lvl = 1
					table.insert(winners_email, s_pk)
				end
			end
		end

	end

	pkt = Json.Encode(pkt)
	for k , v in pairs(g_player_mgr.online_player_l) do
		g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_NOTICE_LOTTERY_S, pkt, true)
	end

	ev:timeout(delay_time,self:structure_all_email())

end

function Lottery_winners:structure_all_email()
	local f = function()
		for k , v in pairs(winners_email) do
			self:structure_email(v.char_id, v.bonus, v.lvl)
		end
	end
	return f
end

---------构造中奖玩家邮件
function Lottery_winners:structure_email(char_id,bonus,lvl)
	local submit_time = f_get_sunday() + 8 * 24 * 3600 + 1
	local day_table	  = os.date("*t" , submit_time)
	local draw_time = f_get_sunday() + 24 * 3600 + 1
	local draw_table  = os.date("*t" , draw_time)
	local period = (draw_table.year % 100) * 10000 + draw_table.month * 100 + draw_table.day

	local title  = f_get_string(544)--g_u("恭喜您彩票中奖了!")
	local lvl_type 
	if lvl == 1 then
		lvl_type = f_get_string(545)--g_u("一等奖")
	elseif lvl == 2 then
		lvl_type = f_get_string(546)--g_u("二等奖")
	elseif lvl == 3 then
		lvl_type = f_get_string(547)--g_u("三等奖")
	elseif lvl == 4 then
		lvl_type = f_get_string(548)-- g_u("幸运奖")
	end

	local content	= string.format(f_get_string(549),
										period, lvl_type, bonus, day_table.month, day_table.day)

	local g_email = Email(-1,char_id,title,content,0,Email_type.type_common,Email_sys_type.type_sys,{})
	if g_email ~= nil then
		g_email_mgr:add_email(g_email)
	end
end

-------------------------------------------------存盘
function Lottery_winners:spec_serialize_to_db()
	return self
end

function Lottery_winners:load(db_data)
	self.period		= db_data.period
	self.valid_time = db_data.valid_time
	self.winners 	= db_data.winners
end

-------------------------------------------------存盘
function Lottery_winners:spec_serialize_to_map()
	return self.winners
end