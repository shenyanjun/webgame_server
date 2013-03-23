
----------------------------------玩家的选号
require("lottery.lottery_number")

Lottery_numbers = oo.class(nil, "Lottery_numbers")

local limits = 5000			--下注范围   0 ~ 5000
local lvls	 = 4			--获奖等级

function Lottery_numbers:__init(data)
	if data then
		self:load(data)
	else
		local submit_time = f_get_sunday() + 8 * 24 * 3600 + 1
		local day_table	  = os.date("*t" , submit_time)
		self.period 	= (day_table.year % 100) * 10000 + day_table.month * 100 + day_table.day
		self.valid_time = submit_time

		self.numbers 	= {}
		--for i = 0, limits do
			--self.numbers[tostring(i)] = Lottery_number()	--下表为字符串，方便入库
		--end
	end
end

function Lottery_numbers:get_total_count()
	local total_count = 0

	for k,v in pairs(self.numbers) do
		total_count = total_count + 1
	end
	return total_count
end

function Lottery_numbers:choice_number(char_id,number)
	if number >= 0 and number <= limits then
		local s_number = tostring(number)
		if self.numbers[s_number] then
			self.numbers[s_number]:choice_number(char_id)
		else
			self.numbers[s_number] = Lottery_number()
			self.numbers[s_number]:choice_number(char_id)
		end
	end
end


-------------------------------------------------抽奖，返回符合winners格式的中奖列表
function Lottery_numbers:draw_lottery()
----------winners[4].tostring(number)  tostring(中奖号码)  winners[4].number  中奖号码   
		--winners[4].number.tostring(char_id) = 中奖者tostring()  winners[4].number.char_id = count  下注数
	local winners = {} 
	for i = 1 , lvls do
		winners[i] = {}
	end

	local all_number = {}
	all_number.count = 0
	all_number.list  = {}
	for i = 0, limits do
		all_number.count = all_number.count + 1
		all_number.list[tostring(i)] = 1
	end

	--people[i]  ,i人买的号码list,放tostring(0~5000)
	local people = {}
	people[0] = {}
	people[0].count = 0
	people[0].list = {}
	for k,v in pairs(self.numbers) do
		local player_count = v:get_player_count()
		if not people[player_count] then
			people[player_count] = {}
			people[player_count].count = 0
			people[player_count].list  = {}
		end
		table.insert(people[player_count].list , k)
		people[player_count].count = people[player_count].count + 1

		all_number.list[k] = nil
		all_number.count = all_number.count - 1
	end
	for k , v in pairs(all_number.list) do
		people[0].count = people[0].count + 1
		table.insert(people[0].list , k)
	end
	--print("people =",j_e(people))
-----------------------------------抽取鼓励奖
 	---------------将鼓励奖25个候选号码放入数组random_table4中
	local random_table4 = {}
	local random4 = {1,1,3,5,15,0}

	for i = 5 , 1, -1 do
		if not people[i] then
			random4[5 + 1 - i + 1] = random4[5 + 1 - i + 1] + random4[5 + 1 - i]
		elseif people[i].count <= random4[5 + 1 - i] then
			random4[5 + 1 - i + 1] = random4[5 + 1 - i + 1] + random4[5 + 1 - i] - people[i].count
			for j = 1, people[i].count do
				local pk = {}					--random_table4中保存来自几人表
				pk.number 	= people[i].list[j]
				pk.location	= i
				pk.sort 	= j
				table.insert(random_table4,pk)
			end
		else
			f_get_number_to_table(i,people[i].count, people[i].list, random_table4, random4[5 + 1 - i])
		end
	end
	if random4[6] > 0 then
		for i = 6, 1000 do
			if not people[i] then
			elseif people[i].count <= random4[6] then
				random4[6] = random4[6] - people[i].count
				for j = 1, people[i].count do
					local pk = {}					--random_table4中保存来自几人表
					pk.number 	= people[i].list[j]
					pk.location	= i
					pk.sort 	= j
					table.insert(random_table4,pk)
				end
				if random4[6] < 1 then
					break
				end
			else
				f_get_number_to_table(i, people[i].count, people[i].list, random_table4, random4[6])
				random4[6] = 0
				break
			end
		end
		if random4[6] >0 then
			f_get_number_to_table(0, people[0].count, people[0].list, random_table4, random4[6])
		end
		
	end
	---------从random_table4取10个中奖号码，并从people中删掉
	local pkt = f_get_n_number(25, 10)
	if pkt then
		for i = 10, 1,-1 do
			local number   = random_table4[pkt[i]].number
			local location = random_table4[pkt[i]].location
			local sort	   = random_table4[pkt[i]].sort
			winners[4][number] = {}

			if location ~= 0 then
				winners[4][number] = self.numbers[number]:get_player_info()
			end
			people[location].count = people[location].count - 1
			table.remove(people[location].list,sort)
		end
	end
	-----------------------------------抽取3等奖
 	---------------将3等奖12个候选号码放入数组random_table3中
	local random_table3 = {}
	local random3 = {1, 1, 10, 0}

	for i = 3 , 1, -1 do
		if not people[i] then
			random3[3 + 1 - i + 1] = random3[3 + 1 - i + 1] + random3[3 + 1 - i]
		elseif people[i].count <= random3[3 + 1 - i] then
			random3[3 + 1 - i + 1] = random3[3 + 1 - i + 1] + random3[3 + 1 - i] - people[i].count
			for j = 1, people[i].count do
				local pk = {}					--random_table4中保存来自几人表
				pk.number 	= people[i].list[j]
				pk.location	= i
				pk.sort 	= j
				table.insert(random_table3,pk)
			end
		else
			f_get_number_to_table(i,people[i].count, people[i].list, random_table3, random3[3 + 1 - i])
		end
	end

	if random3[4] > 0 then
		for i = 4, 1000 do
			if not people[i] then
			elseif people[i].count <= random3[4] then
				random3[4] = random3[4] - people[i].count
				for j = 1, people[i].count do
					local pk = {}					--random_table4中保存来自几人表
					pk.number 	= people[i].list[j]
					pk.location	= i
					pk.sort 	= j
					table.insert(random_table3,pk)
				end
				if random3[4] < 1 then
					break
				end
			else
				f_get_number_to_table(i, people[i].count, people[i].list, random_table3, random3[4])
				random3[4] = 0
				break
			end
		end
		if random3[4] >0 then
			f_get_number_to_table(0, people[0].count, people[0].list, random_table3, random3[4])
		end
	end
	---------从random_table3取5个中奖号码，并从people中删掉
	local pkt = f_get_n_number(12, 5)
	if pkt then
		for i = 5, 1, -1 do
			local number   = random_table3[pkt[i]].number
			local location = random_table3[pkt[i]].location
			local sort	   = random_table3[pkt[i]].sort
			winners[3][number] = {}

			if location ~= 0 then
				winners[3][number] = self.numbers[number]:get_player_info()
			end

			people[location].count = people[location].count - 1
			table.remove(people[location].list,sort)
		end
	end

		
	-----------------------------------抽取2等奖
 	---------------将2等奖8个候选号码放入数组random_table2中
	local random_table2 = {}
	--local random2 = {1 ,1 ,4 ,2 ,0}
	local random2 = {1 ,1 ,4  ,0}
	local zero = 1
	for i = 3 , 1, -1 do
		if not people[i] then
			random2[3 + 1 - i + 1] = random2[3 + 1 - i + 1] + random2[3 + 1 - i]
		elseif people[i].count <= random2[3 + 1 - i] then
			random2[3 + 1 - i + 1] = random2[3 + 1 - i + 1] + random2[3 + 1 - i] - people[i].count
			for j = 1, people[i].count do
				local pk = {}					--random_table4中保存来自几人表
				pk.number 	= people[i].list[j]
				pk.location	= i
				pk.sort 	= j
				table.insert(random_table2,pk)
			end
		else
			f_get_number_to_table(i,people[i].count, people[i].list, random_table2, random2[3 + 1 - i])
		end
	end

	if random2[4] > 0 then
		for i = 4, 1000 do
			if not people[i] then
			elseif people[i].count <= random2[4] then
				random2[4] = random2[4] - people[i].count
				for j = 1, people[i].count do
					local pk = {}					--random_table4中保存来自几人表
					pk.number 	= people[i].list[j]
					pk.location	= i
					pk.sort 	= j
					table.insert(random_table2,pk)
				end
				if random2[4] < 1 then
					break
				end
			else
				f_get_number_to_table(i, people[i].count, people[i].list, random_table2, random2[4])
				random2[4] = 0
				break
			end
		end

	end
	zero = zero + random2[4]
	f_get_number_to_table(0, people[0].count, people[0].list, random_table2, zero)

	---------从random_table2取2个中奖号码，并从people中删掉
	local pkt = f_get_n_number(7, 2)
	if pkt then
		for i = 2, 1, -1 do
			local number   = random_table2[pkt[i]].number
			local location = random_table2[pkt[i]].location
			local sort	   = random_table2[pkt[i]].sort
			winners[2][number] = {}

			if location ~= 0 then
				winners[2][number] = self.numbers[number]:get_player_info()
			end

			people[location].count = people[location].count - 1
			table.remove(people[location].list,sort)
		end
	end

	
	-----------------------------------抽取1等奖
 	---------------将1等奖3个候选号码放入数组random_table1中
	local random_table1 = {}
	local random1 = {2, 0, 0}
	local zero0 = 1

	--将剩下注数大于2的号码都排除
	for i = 1, 1000 do
		if people[i] then
			local tmp_table = {}
			for j = 1,  people[i].count do
				if self.numbers[ people[i].list[j]]:get_count() > 2 then
					table.insert(tmp_table, j)
				end
			end
			for ii = table.getn(tmp_table), 1, -1 do
				table.remove(people[i].list, tmp_table[ii]) 
			end
			people[i].count = people[i].count - table.getn(tmp_table)
		end
	end

	for i = 2 , 1, -1 do
		if not people[i] then
			random1[2 + 1 - i + 1] = random1[2 + 1 - i + 1] + random1[2 + 1 - i]
		elseif people[i].count <= random1[2 + 1 - i] then
			random1[2 + 1 - i + 1] = random1[2 + 1 - i + 1] + random1[2 + 1 - i] - people[i].count
			for j = 1, people[i].count do
				local pk = {}					--random_table4中保存来自几人表
				pk.number 	= people[i].list[j]
				pk.location	= i
				pk.sort 	= j
				table.insert(random_table1,pk)
			end
		else
			f_get_number_to_table(i,people[i].count, people[i].list, random_table1, random1[2 + 1 - i])
		end
	end

	if random1[3] > 0 then
		for i = 3, 1000 do
			if not people[i] then
			elseif people[i].count <= random1[3] then
				random1[3] = random1[3] - people[i].count
				for j = 1, people[i].count do
					local pk = {}					--random_table4中保存来自几人表
					pk.number 	= people[i].list[j]
					pk.location	= i
					pk.sort 	= j
					table.insert(random_table1,pk)
				end
				if random1[3] < 1 then
					break
				end
			else
				f_get_number_to_table(i, people[i].count, people[i].list, random_table1, random1[3])
				random1[3] = 0
				break
			end
		end

	end
	zero0 = zero0 + random1[3]
	f_get_number_to_table(0, people[0].count, people[0].list, random_table1, zero0)

	---------从random_table1取1个中奖号码，并从people中删掉
	local pkt = f_get_n_number(3, 1)
	if pkt then
		for i = 1, 1 do
			local number   = random_table1[
			pkt[i]
			].number
			local location = random_table1[pkt[i]].location
			local sort	   = random_table1[pkt[i]].sort
			winners[1][number] = {}

			if location ~= 0 then
				winners[1][number] = self.numbers[number]:get_player_info()
			end

			people[location].count = people[location].count - 1
			table.remove(people[location].list,sort)
		end
		--print("342",j_e(people[location].list[sort]))
	end

	--for i = 1 , 4 do
		--print("\n winners =",j_e(winners[i]))
	--end
	return winners
end

------------从from_table中挑选count个元素放入to_table
function f_get_number_to_table(location , from_table_count, from_table, to_table, count)
	local pkt = f_get_n_number(from_table_count,count)

	if not pkt then
		return
	end

	for i = 1, count do
		local pk = {}
		pk.number 	= from_table[ pkt[i] ]
		pk.location	= location
		pk.sort		= pkt[i]
		table.insert(to_table,pk)
	end

	return
end

------------从total个元素的表中挑选count个元素  必须total > count
function f_get_n_number(total, count)
	if total <= count then   ----如果total < count  进入死循环
		return false
	end

	local pkt = {}
	while count > 0 do
		local tmp 	= crypto.random(1, total + 1)
		local flags = true
		--检查是否已有
		for i = 1, table.getn(pkt) do
			if pkt[i] == tmp then
				flags = false
				break
			end
		end
		--没有则插入  减1
		if flags then
			table.insert(pkt, tmp)
			count = count - 1
		end
	end

	table.sort(pkt, function(e1,e2) 
						return e1 < e2 
					end)
	return pkt    --返回从小到大排好序的pkt
end


-------------------------------------------------存盘
function Lottery_numbers:spec_serialize_to_db()
	return self
end

function Lottery_numbers:load(db_data)
	self.period		= db_data.period
	self.valid_time = db_data.valid_time
	self.numbers	= {}
	for k , v in pairs(db_data.numbers) do
		self.numbers[k] = Lottery_number(v)
	end
end
