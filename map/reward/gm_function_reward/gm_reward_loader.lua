

module("reward.gm_function_reward.gm_reward_loader",package.seeall)

local database = "gm_reward_function"
OnlineRewardTable = {}


function update_gm_reward()
	OnlineRewardTable = {}	
	local dbh = f_get_db()
	local fields = "{_id:0}"
	local query = "{function_id:{$exists:true},function_l:{$exists:true},min_level:{$exists:true},max_level:{$exists:true},start_time:{$exists:true},end_time:{$exists:true}}"
	local row,error = dbh:select(database,fields,query)
	if error == 0 and row then
		for k,v in pairs(row or {}) do
			if k and v then
				local list = {}
				list.online = {}
				list.total = {}
				OnlineRewardTable[v.function_id] = {}
				OnlineRewardTable[v.function_id].function_id = tonumber(v.function_id)
				OnlineRewardTable[v.function_id].min_level = tonumber(v.min_level)
				OnlineRewardTable[v.function_id].max_level = tonumber(v.max_level)
				OnlineRewardTable[v.function_id].start_time = tonumber(v.start_time)
				OnlineRewardTable[v.function_id].end_time = tonumber(v.end_time)
				
				for k,v in pairs(v.function_l or {}) do
					if v.type == 1 or v.type == 2 then
						local obj = {}
						obj.need_time = tonumber(v.need_time)
						
						local item_l = {}
						for key,value in pairs(v.item_l or {}) do
							local obj = {}
							obj.id = tonumber(value.item_id)
							obj.count = tonumber(value.number)
							obj.name = value.item_name or ""
							table.insert(item_l, obj)
						end
						obj.item_l = item_l
						
						local occ_item_l = {}
						for key,value in pairs(v.occ_item_l or {}) do
							local occ = tonumber(key)
							if occ then
								local list = {}
								occ_item_l[occ] = list
								for _, item in pairs(value) do
									table.insert(
										list
										, {
											 ['id'] = tonumber(item.item_id)
											 , ['count'] = tonumber(item.number)
											 , ['name'] = item.item_name or ""
										})
								end
							end
						end

						obj.occ_item_l = occ_item_l
						
						local money_l = {}
						for key,value in pairs(v.money_l or {}) do
							money_l[value.money] = tonumber(value.number)
						end
						obj.money_l = money_l
						
						if v.type == 1 then
							table.insert(list.online, obj)
						else
							table.insert(list.total,obj)
						end
					end
--[[				
					if v.type == 1 then
						local obj = {}
						obj.need_time = tonumber(v.need_time)
						local money_l = {}
						local item_l = {}
						for key,value in pairs(v.item_l or {}) do
							local obj = {}
							obj.id = tonumber(value.item_id)
							obj.count = tonumber(value.number)
							obj.name = value.item_name or ""
							table.insert(item_l,obj)
						end
						for key,value in pairs(v.money_l or {}) do
							money_l[value.money] = tonumber(value.number)
						end
						obj.item_l = item_l
						obj.money_l = money_l
						table.insert(list.online,obj)
					elseif v.type == 2 then
						local obj = {}
						obj.need_time = tonumber(v.need_time)
						local money_l = {}
						local item_l = {}
						for key,value in pairs(v.item_l or {}) do
							local obj = {}
							obj.id = tonumber(value.item_id)
							obj.count = tonumber(value.number)
							obj.name = value.item_name or ""
							table.insert(item_l,obj)
						end
						for key,value in pairs(v.money_l or {}) do
							money_l[value.money] = tonumber(value.number)
						end
						obj.item_l = item_l
						obj.money_l = money_l
						table.insert(list.total,obj)
					end
]]
				end

				table.sort(list.online,function(a,b)
											return a.need_time <= b.need_time
									   end)
				table.sort(list.total,function(a,b)
											return a.need_time <= b.need_time
									   end)
				OnlineRewardTable[v.function_id].online = list.online
				OnlineRewardTable[v.function_id].total = list.total
			end
		end
	end
end

update_gm_reward()
