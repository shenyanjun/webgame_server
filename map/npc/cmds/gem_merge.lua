--local debug_print = print
local debug_print = function () end

local ITEM_COUNT = 5
local post = {11,41,51}   ---用来随机职位
local part = {'01','02','03','04','05','06','07','08','09','10'}  --随机部位
local COLOR = 4                 --装备品质
local MERGE_SALE = 0.95

local tool_merge_loader = require("npc.config.tool_merge_loader")
local formula_loader = require("config.loader.formula_loader")

local strip_loader = require("npc.config.strip_loader")
local embed_loader = require("npc.config.embed_loader")


--宝石合成
Clt_commands[1][CMD_NPC_MERGE_GEM_C] =
	function(conn, pkt)
		if pkt == nil then return end
		local item_list = pkt.list
		if not item_list or not item_list[1] then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()

		local ret ={}

			

		local gem = pack_con:get_item_by_bag_slot(item_list[1][1], item_list[1][2])

		--判断物品数目
		local slot_l = {}
		for k,v in pairs(item_list or {}) do
			if pack_con:check_item_lock_by_bag_slot(v[1],v[2]) then 
				return 
			end --上锁

			if v[1] ~= SYSTEM_BAG or v[3] <= 0 then return end
			local t_gem = pack_con:get_item_by_bag_slot(v[1], v[2])
			if t_gem == nil then return end
			
			if slot_l[v[2]] == nil then
				slot_l[v[2]] = {}
			end
			slot_l[v[2]][t_gem.item_id] = (slot_l[v[2]][t_gem.item_id] or 0) + v[3]
		end
		--判断每个slot中是否满足个数
		for slt,list in pairs(slot_l) do
			for it_id,c in pairs(list) do
				local item = pack_con:get_item_by_bag_slot(SYSTEM_BAG, slt)
				if item.item_id ~= it_id or item.number < c then
					ret.result = 200045		--物品个数不对
					g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
					return 
				end
			end
		end

		if gem.item:get_m_class() ~= ItemClass.ITEM_CLASS_EQUIP then    ---非装备
			if pack_con:get_bag_free_slot_cnt() <= 0 then
				ret.result = 43004		
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
				return 
			end

			local gem_id = gem.item_id
			gem_id = string.sub(gem_id,1,11)

			local gem_count = 0       --宝石个数
			local bind = 1            --是否绑定
			local bind_str = 1
			local count_bind = 0
			for k,v in pairs(item_list or {}) do
				local t_gem = pack_con:get_item_by_bag_slot(v[1], v[2])
				if t_gem == nil then return end
				if gem_id ~= string.sub(t_gem.item_id,1,11) then 
					ret.result = 200046		--物品类型不对
					g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
					return 
				end
				local item_bind = t_gem.item:get_bind()
				if not item_bind or item_bind ~= 1 then 
					count_bind = count_bind + v[3]
					bind = 0 
				end
				gem_count = gem_count + tonumber(v[3])
			end

			local time_l = math.floor(gem_count / ITEM_COUNT)
			if time_l < 1 then 
				ret.result = 200045		--物品个数不对
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
				return 
			end -- 个数不是5个
			
			--判断gem_id是否在配置文件中存在
			local next_gem_id = 0
			local next_name 
			for k,v in pairs(tool_merge_loader.Merge_config_tbl or {})do
				local k_str = tostring(k)
				if string.sub(k_str,1,11) == gem_id then
					next_gem_id = string.sub(tostring(v.next_id),1,11)
					next_name = v.next_name
					break
				end
			end
			if next_gem_id == 0 then 
				ret.result = 200047		--物品个数不对
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
				return 
			end     ---配置文件中没有对应的gem_id

			local t_bind_count = math.ceil(count_bind / 5)
			
			--根据next_gem_id生成对应合成物品

			pack_con:del_item_by_bags_slots(item_list,{['type']=ITEM_SOURCE.MERGE_ITEM},0)
			local flag = false
			local next_id = next_gem_id .. "1"

			local list = {}
			list[1] ={}
			list[1].type = 1
			list[1].item_id = tonumber(next_id)
			list[1].number = time_l - t_bind_count

			pack_con:add_item_l(list,{['type']=ITEM_SOURCE.MERGE_ITEM})

			if t_bind_count > 0 then
				next_id = next_gem_id .. "0"
				list[1].type = 1
				list[1].item_id = tonumber(next_id)
				list[1].number = t_bind_count

				pack_con:add_item_l(list,{['type']=ITEM_SOURCE.MERGE_ITEM})
			end

			--广播
			if tonumber(string.sub(next_id,1,1)) == 6 and tonumber(string.sub(next_id,7,9)) > 60 then
				local sys_l = {}
				sys_l[1] = player:get_name()
				sys_l[2] = next_name
				local str_json = f_get_sysbd_format(10010, sys_l)
				f_cmd_sysbd(str_json)
			end


			ret.result = 0		
			g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
			
		else
			local flag_level = tonumber(pkt.flag)
			if not flag_level then return end

			local gem_id = gem.item_id
			local level = string.sub(gem_id,8,10)
			local low_item = gem_id
			local color = string.sub(gem_id,11,11)

			local t_level = math.floor(tonumber(level) / 10)       ---等级，而不是使用等级
			if t_level == nil then return end

			
			local gem_count = 0       --宝石个数
			local bind = 1            --是否绑定
			local bind_str = 1
			local count_bind = 0
			for k,v in pairs(item_list or {}) do
				local t_gem = pack_con:get_item_by_bag_slot(v[1], v[2])
				if t_gem == nil then return end
				if t_gem.item:get_m_class() ~= ItemClass.ITEM_CLASS_EQUIP then return end

				if color ~= string.sub(t_gem.item_id,11,11) then 
					ret.result = 200049
					g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
					return 
				end      --装备品质不相同

				if flag_level == 0 then          --非跨级
					low_item = t_gem.item_id
					if t_level ~= math.floor(tonumber(string.sub(t_gem.item_id,8,10))/10) then 
						ret.result = 200048
						g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
						return 
					end      
				else							--跨级
					if tonumber(level) > t_gem.item:get_level() then
						level = string.sub(t_gem.item_id,8,10)
						low_item = t_gem.item_id
					end
				end
				
				local item_bind = t_gem.item:get_bind()
				if not item_bind or item_bind ~= 1 then 
					count_bind = count_bind + v[3]
					bind = 0 
				end
				gem_count = gem_count + tonumber(v[3])
				
			end

			local time_l = math.floor(gem_count / ITEM_COUNT)
			if time_l < 1 then  
				ret.result = 200045		--物品个数不对
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
				return 
			end -- 个数不是5个

			local t_bind_count = math.ceil(count_bind / 5)

			local flag = false
			pack_con:del_item_by_bags_slots(item_list,{['type']=ITEM_SOURCE.MERGE_ITEM},0)

			--t_level = math.floor(tonumber(level) / 10)       ---等级，而不是使用等级
			for i=1,time_l do
				local post_index = post[crypto.random(1,table.getn(post)+1)]   --获取职位
				local part_index = part[crypto.random(1,table.getn(part)+1)]  --获取部位
				local next_color = color
				if tonumber(color) < COLOR then
					next_color = next_color + 1 
				end
			
				local next_gem_id
				if i <= t_bind_count then
					next_gem_id = string.sub(gem_id,1,1) .. post_index .. part_index .. string.sub(gem_id,6,7) ..string.sub(low_item,8,10)..tostring(next_color) .. "0"
				else
					next_gem_id = string.sub(gem_id,1,1) .. post_index .. part_index .. string.sub(gem_id,6,7) ..string.sub(low_item,8,10)..tostring(next_color) .. "1"
				end
				local e_code,new_item = Item_factory.create(tonumber(next_gem_id))
				pack_con:add_by_item(new_item,{['type']=ITEM_SOURCE.MERGE_ITEM})
				flag = true	
			end
			if flag then
				ret.result = 0		
				g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
			end
		end
	end

--获取宝石合成后的类型
Clt_commands[1][CMD_NPC_MERGE_GEM_ID_C] =
	function(conn, pkt)
		local gem_id = pkt.gem_id

		--是否存在这个物品
		if ItemsTable[tonumber(gem_id)] == nil then     --注意tonumber
			NpcContainerMgr:SendError(conn.char_id, 200048)
			return
		end
		--检查这个类型是否符合合成条件
		local m_class = string.sub(gem_id,1,1)
		local s_class = string.sub(gem_id,2,3)
		if tonumber(m_class) ~= 6  or tonumber(s_class)~=1 then  --(5) 不是可以合成的宝石
			NpcContainerMgr:SendError(conn.char_id, 200048)
			return
		end

		--检查是否十级了
		level = string.sub(gem_id,6,8)
		if tonumber(level) == 10 then
			NpcContainerMgr:SendError(conn.char_id, 200049)
			return
		end

		--获取生成品的id
		local ret_code, new_gem_id = GemTemplate:NextGemID(gem_id, false)
		--返回合成结果
		local ret = {}
		ret.result = 0
		ret.gem_id = new_gem_id	   --宝石合成后的类型ID
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_ID_S, ret)
	end

--按配方合成宝石
Clt_commands[1][CMD_MAP_GEM_FORMULA_MERGE_B] =
	function(conn, pkt)
		if not pkt or not pkt.formula_id or not pkt.gem_list then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if not pack_con then return end

		--检查配方
		local formula = formula_loader.GetFormula(pkt.formula_id)
		if not formula then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S, {['result'] = 200131})
			return
		end

		--检查物品是否够
		local item_list = {}
		local gem_lvl
		local bind = false			--是否需绑定
		for k, v in pairs(formula.gem_list) do
			local gem_slot = 0	--默认没有宝石
			local tmp_cnt = 0			
			for kk, vv in pairs(pkt.gem_list) do
				local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , vv)
				local item = slot and slot.item
				if not item then
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 43001})
					return
				end
				if item:get_m_class() ~= 6 or item:get_s_class() ~= 1 then
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200132})
					return
				end
				if item:get_t_class() == v.t_class then			--找到配方所需材料
					if not gem_lvl then
						gem_lvl = item:get_item_lvl()
					else
						if gem_lvl ~= item:get_item_lvl() then
							g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200134})
							return 
						end
					end
					if not bind and item:get_bind() ~= 1 then
						bind = true
					end
					tmp_cnt = slot.number
					gem_slot = vv
					break
				end
			end

			--材料没找到
			if gem_slot == 0 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200133})
				return
			end 
			if tmp_cnt < v.count then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200133})
				return
			end 
			--
			local tmp_table = {}
			tmp_table.slot = gem_slot
			tmp_table.count = v.count
			table.insert(item_list, tmp_table)
		end

		--检查是否能加
		local gain_id = formula_loader.GetGainItemId(pkt.formula_id, gem_lvl)
		if bind then
			gain_id = gain_id - 1
		end
		local e_code, item_obj = Item_factory.create(gain_id)
		if not item_obj then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = ERROR_NPC_NOT_FIND_ITEM})
			return
		end
		local item_l = {}
		item_l[1] = {}
		item_l[1].type 	= 2
		item_l[1].item	= item_obj
		item_l[1].number = 1
		e_code = pack_con:check_add_item_l_inter_face(item_l)
		if e_code ~= 0 then 
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = e_code})
			return 
		end

		--检查钱是否够并扣除
		local need_type = formula_loader.AdditionTable[gem_lvl].currency.id
		local need_money = formula_loader.AdditionTable[gem_lvl].currency.count
		if need_type == 3 then
			local money_list = {}
			money_list[MoneyType.GIFT_GOLD] = need_money
			e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.GEM_FORMULA}, 1)
		else
			return 
		end
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = e_code})
			return
		end

		--扣物品
		for k, v in pairs(item_list) do
			pack_con:del_item_by_bag_slot(SYSTEM_BAG, v.slot, v.count, {['type']=ITEM_SOURCE.GEM_FORMULA})
		end

		--加物品
		pack_con:add_item_l(item_l, {['type']=ITEM_SOURCE.GEM_FORMULA})

		--返回合成结果
		local ret = {}
		ret.result = 0
		--ret.gem_id = new_gem_id	   --宝石合成后的类型ID
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S, ret)
	end

--庄园巧匠合成
Clt_commands[1][CMD_MAP_FINCA_GEM_MERGE_B] =
	function(conn, pkt)
		if not pkt or not pkt.formula_id or not pkt.gem_list then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if not pack_con then return end

		--检查配方
		local formula = formula_loader.GetFormula(pkt.formula_id)
		if not formula then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S, {['result'] = 200131})
			return
		end

		if not g_faction_manor_mgr:check_formula_by_cid(conn.char_id, tonumber(pkt.formula_id)) then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S, {['result'] = 200138})
			return
		end



		--检查物品是否够
		local item_list = {}
		local gem_lvl
		local bind = false			--是否需绑定
		for k, v in pairs(formula.gem_list) do
			local gem_slot = 0	--默认没有宝石
			local tmp_cnt = 0			
			for kk, vv in pairs(pkt.gem_list) do
				local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , vv)
				local item = slot and slot.item
				if not item then
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 43001})
					return
				end
				if item:get_m_class() ~= 6 or item:get_s_class() ~= 1 then
					g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200132})
					return
				end
				if item:get_t_class() == v.t_class and item:get_c_class() == v.c_class then			--找到配方所需材料
					if not gem_lvl then
						gem_lvl = item:get_item_lvl()
					else
						if gem_lvl ~= item:get_item_lvl() then
							g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200134})
							return 
						end
					end
					if not bind and item:get_bind() ~= 1 then
						bind = true
					end
					tmp_cnt = slot.number
					gem_slot = vv
					break
				end
			end

			--材料没找到
			if gem_slot == 0 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200133})
				return
			end 
			if tmp_cnt < v.count then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200133})
				return
			end 
			--
			local tmp_table = {}
			tmp_table.slot = gem_slot
			tmp_table.count = v.count
			table.insert(item_list, tmp_table)
		end

		--检查是否能加
		local gain_id = formula_loader.GetGainItemId(pkt.formula_id, gem_lvl)
		if bind then
			gain_id = gain_id - 1
		end
		local e_code, item_obj = Item_factory.create(gain_id)
		if not item_obj then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = ERROR_NPC_NOT_FIND_ITEM})
			return
		end
		local item_l = {}
		item_l[1] = {}
		item_l[1].type 	= 2
		item_l[1].item	= item_obj
		item_l[1].number = 1
		e_code = pack_con:check_add_item_l_inter_face(item_l)
		if e_code ~= 0 then 
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = e_code})
			return 
		end

		--检查帮贡
		local f_contribution = formula_loader.AdditionTable[gem_lvl].contribution
		local faction_obj
		if f_contribution then
			faction_obj = g_faction_mgr:get_faction_by_cid(conn.char_id)
			if not faction_obj then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200101})
				return 
			end
			if faction_obj:get_contribution(conn.char_id) < f_contribution then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = 200139})
				return
			end
		end
		--检查钱是否够并扣除
		local need_type = formula_loader.AdditionTable[gem_lvl].currency.id
		local need_money = formula_loader.AdditionTable[gem_lvl].currency.count
		if need_type == 3 then
			local money_list = {}
			money_list[MoneyType.GIFT_GOLD] = need_money
			e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.FINCA_GEM_FORMULA}, 1)
		else
			return 
		end
		if e_code ~= 0 then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S ,{['result'] = e_code})
			return
		end
		--扣帮贡
		if f_contribution then
			local t_pkt = {}
			t_pkt.type = 14
			t_pkt.param	= -f_contribution
			t_pkt.flag	= 6
			g_faction_mgr:update_faction_level( conn.char_id, t_pkt)
		end

		--扣物品
		for k, v in pairs(item_list) do
			pack_con:del_item_by_bag_slot(SYSTEM_BAG, v.slot, v.count, {['type']=ITEM_SOURCE.FINCA_GEM_FORMULA})
		end

		--加物品
		pack_con:add_item_l(item_l, {['type']=ITEM_SOURCE.FINCA_GEM_FORMULA})

		--返回合成结果
		local ret = {}
		ret.result = 0
		--ret.gem_id = new_gem_id	   --宝石合成后的类型ID
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_MERGE_S, ret)
	end


--按配方分解宝石
Clt_commands[1][CMD_MAP_GEM_FORMULA_SPLIT_B] =
	function(conn, pkt)
		if not pkt or not pkt.formula_id or not pkt.slot then return end

		local player = g_obj_mgr:get_obj(conn.char_id)
		local pack_con = player:get_pack_con()
		if not pack_con then return end

		local s_pkt = {}
		--检查配方
		local formula = formula_loader.GetFormula(pkt.formula_id)
		if not formula then
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_SPLIT_S, {['result'] = 200131})
			return
		end

		--检查物品是否够
		local slot = pack_con:get_item_by_bag_slot(SYSTEM_BAG , pkt.slot)
		local item = slot and slot.item
		if not item then
			s_pkt.result = 43001
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_SPLIT_S ,s_pkt)
			return
		end
		local gem_id = item:get_item_id()
		local gem_lvl = item:get_item_lvl()
		local last_id = tostring(gem_id % 100)
		if not formula_loader.CheckGainItemId(pkt.formula_id, gem_id) then
			s_pkt.result = 200131
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_SPLIT_S ,s_pkt)
			return
		end

		local gem_list = formula_loader.GetGemIdList(pkt.formula_id, gem_lvl, last_id)
		
		--检查拆分条件,背包能否加
		local item_l = {}
		for i = 1, table.getn(gem_list) do
			item_l[i] = {}
			item_l[i].type = 1
			item_l[i].item_id = tonumber(gem_list[i].id)
			item_l[i].number = gem_list[i].cnt
		end
		e_code = pack_con:check_add_item_l_inter_face(item_l)
		if e_code ~= 0 then 
			g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_SPLIT_S ,{['result'] = e_code})
			return 
		end
		--是否够钱
		local need_type = formula_loader.AdditionTable[gem_lvl].currency.id
		local need_money = formula_loader.AdditionTable[gem_lvl].currency.count
		if need_type == 3 then
			local money_list = {}
			money_list[MoneyType.GIFT_GOLD] = need_money
			e_code = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.GEM_SPLIT}, 1)
			if e_code ~= 0 then
				g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_SPLIT_S ,{['result'] = e_code})
				return
			end
		else
			return 
		end
		
		--扣物品
		pack_con:del_item_by_bag_slot(SYSTEM_BAG, pkt.slot, 1, {['type']=ITEM_SOURCE.GEM_SPLIT})

		--加物品
		pack_con:add_item_l(item_l, {['type']=ITEM_SOURCE.GEM_SPLIT})

		--返回合成结果
		local ret = {}
		ret.result = 0
		g_cltsock_mgr:send_client(conn.char_id, CMD_MAP_GEM_FORMULA_SPLIT_S, ret)
	end

--快速魔石合成
Clt_commands[1][CMD_NPC_FAST_DIMENSITY_GEM_C] =
function(conn,pkt)
	if not pkt.slot and pkt.bag then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	local pack_con = player:get_pack_con()
	if not pack_con then return end
	if pack_con:check_item_lock_by_bag_slot(pkt.bag, pkt.slot) then --上锁
		return 
	end 
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then --上锁
		return 
	end 
		
	local equip = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)

	if not equip then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
		return
	end

	local need_money = 0
	local gem_cnt = 4

	--是否能拆
	local gem_id, gem_lvl = equip.item:get_rage_embed_id()
	if not gem_id then
		NpcContainerMgr:SendError(conn.char_id, 201015)
		return
	end

	--所需金钱
	need_money = math.floor(1000 * gem_lvl * MERGE_SALE)
	local money = pack_con:get_money()
	if money.gift_gold + money.gold  < need_money then
		item_obj = nil
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_ENOUGH_GOLD)
		return
	end

	local del_gem_list = {}
	local t_gem_id = gem_id
	local t_bind_count = equip.item:get_bind()
	local pack_gem_num = pack_con:get_item_count(gem_id)

	if pack_gem_num > 0 then
		if pack_gem_num >= gem_cnt then
			del_gem_list[t_gem_id] = gem_cnt			
			gem_cnt = 0
		else
			gem_cnt = gem_cnt - pack_gem_num
			del_gem_list[t_gem_id] = pack_gem_num
		end

	end	

	if gem_cnt > 0 then
		if t_bind_count == 0 then
			t_gem_id = t_gem_id + 1
		else
			t_gem_id = t_gem_id - 1
		end		
		pack_gem_num = pack_con:get_item_count(t_gem_id)

		if pack_gem_num > 0 then
			if pack_gem_num >= gem_cnt then
				del_gem_list[t_gem_id] = gem_cnt
				gem_cnt = 0
			else
				gem_cnt = gem_cnt - pack_gem_num
				del_gem_list[t_gem_id] = gem_cnt
			end
		end
		equip.item:set_bind()
	end
	
	if gem_cnt > 0 then 
		NpcContainerMgr:SendError(conn.char_id, 200045)
		return 
	end

	--------------------是否有下一级------------------------
	local next_gem_id = 0
	--local next_name 
	if gem_id%2 == 0 then
		gem_id = gem_id + 1
	end

	if not tool_merge_loader.Merge_config_tbl then
		return 
	end
	if tool_merge_loader.Merge_config_tbl[gem_id] then
		next_gem_id = tool_merge_loader.Merge_config_tbl[gem_id].next_id
		--next_name	= tool_merge_loader.Merge_config_tbl[gem_id].next_name
	end

	if next_gem_id == 0 then 
		local ret = {}
		ret.result = 200047		-- 没有下一级宝石了
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
		return 
	end  

	local ret = {}
	ret.result = 0
	--扣钱
	local money_list = {}
	money_list[MoneyType.GIFT_GOLD] = need_money
	ret.result = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.GEM_FAST_LEVELUP}, 1)	

	for k, v in pairs(del_gem_list) do
		ret.result = pack_con:del_item_by_item_id(k, v, {['type']=ITEM_SOURCE.GEM_FAST_LEVELUP})
	end	

	--拆卸
	pack_con:dis_rage_embed_equip(equip)
	pack_con:rage_embed_equip(equip, next_gem_id)
	g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_FAST_DIMENSITY_GEM_S, ret)

	--更新人物
	if pkt.bag == EQUIPMENT_BAG then
		player:on_update_attribute(2)
	end
end

-- 快速合成宝石
Clt_commands[1][CMD_NPC_FAST_MERGE_GEM_C] = 
function (conn, pkt)
	if not pkt.slot or not pkt.bag or not pkt.material or not pkt.embed_slot then return end
	local player = g_obj_mgr:get_obj(conn.char_id)
	if not player then return end
	local pack_con = player:get_pack_con()
	if not pack_con then return end

	if pack_con:check_item_lock_by_bag_slot(pkt.bag, pkt.slot) then --上锁
		return 
	end 
	--if pack_con:check_item_lock_by_bag_slot(SYSTEM_BAG, pkt.material) then --上锁
		--return 
	--end 
	if pack_con:check_money_lock(MoneyType.GOLD) or pack_con:check_money_lock(MoneyType.GIFT_GOLD) then --上锁
		return 
	end 

	local equip = pack_con:get_item_by_bag_slot(pkt.bag, pkt.slot)

	if not equip then
		NpcContainerMgr:SendError(conn.char_id, ERROR_NPC_NOT_FIND_ITEM)
		return
	end
	 -------------------------------------------宝石 拆卸---------------------
	local gem_obj = equip.item.hole_t[pkt.embed_slot]
	if not gem_obj then return end
	--local mat_obj   = pack_con:get_item_by_bag_slot(SYSTEM_BAG, pkt.material)
	--if not mat_obj then return end

	local need_money = 0  --所需钱财			
	local gem_cnt = 4     --升级所需宝石数量			
	--local tool_id = 0	  --拆卸工具
	--local tool_id_num = 0 --拆卸工具数量

	local t_strip = nil
	t_strip = strip_loader.StripTable[tonumber(gem_obj[1].proto.value.item_lvl)] --多少级宝石
	if not t_strip then return end
	
	need_money = t_strip.price     --所需金钱
	--if mat_obj.number <= 0 then return end
	--[[--去掉扣虎钳
	tool_id    = mat_obj.item_id
	local sure = false
	for i,v in pairs(t_strip.material_list or {}) do    --验证对应拆卸物品id  （虎钳）
		if v.item_id and v.item_id == tool_id then
			if v.req_num <= mat_obj.number then
				tool_id_num = v.req_num
				sure = true
				break
			end
		end
	end
	if not sure then
		NpcContainerMgr:SendError(conn.char_id, 200047)
		return 
	end 
	]]	
	 -------------------------------------------宝石 合成---------------------
	local del_gem_list = {}
	local gem_id = tonumber(gem_obj[1].proto.value.id)
	local t_gem_id = gem_id
	local t_bind_count = tonumber(gem_obj[1].proto.value.bind)
	local pack_gem_num = pack_con:get_item_count(gem_id)

	if pack_gem_num > 0 then
		if pack_gem_num >= gem_cnt then
			del_gem_list[t_gem_id] = gem_cnt			
			gem_cnt = 0
		else
			gem_cnt = gem_cnt - pack_gem_num
			del_gem_list[t_gem_id] = pack_gem_num
		end

	end	

	if gem_cnt > 0 then
		if t_bind_count == 0 then
			t_gem_id = t_gem_id + 1
		else
			t_gem_id = t_gem_id - 1
		end		
		pack_gem_num = pack_con:get_item_count(t_gem_id)

		if pack_gem_num > 0 then
			if pack_gem_num >= gem_cnt then
				del_gem_list[t_gem_id] = gem_cnt
				gem_cnt = 0
			else
				gem_cnt = gem_cnt - pack_gem_num
				del_gem_list[t_gem_id] = gem_cnt
			end
		end
		equip.item:set_bind()
	end
	
	if gem_cnt > 0 then 
		NpcContainerMgr:SendError(conn.char_id, 200045)
		return 
	end
	-------------------------------------------宝石 镶嵌---------------------
	local t_embed = embed_loader.EmbedTable[equip.item.proto.value.t_class]      -- 获得当前类型的 配置文件
	local match_level = math.floor(equip.item.proto.value.level/10+1)
	local lvl_node = t_embed.lvl_list[match_level]        
	need_money = need_money + lvl_node.price        				-- 对应等级 镶嵌需要的钱   
	--------------------是否有下一级------------------------
	local next_gem_id = 0
	--local next_name 
	if gem_id%2 == 0 then
		gem_id = gem_id + 1
	end

	if not tool_merge_loader.Merge_config_tbl then
		return
	end

	if tool_merge_loader.Merge_config_tbl[gem_id] then
		next_gem_id = tool_merge_loader.Merge_config_tbl[gem_id].next_id
		--next_name	= tool_merge_loader.Merge_config_tbl[gem_id].next_name
	end

	if next_gem_id == 0 then 
		local ret = {}
		ret.result = 200047		-- 没有下一级宝石了
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_MERGE_GEM_S, ret)
		return 
	end  	
	--------------------扣除对应东西------------------------
	local ret_code = 0
	local ret = {}
	ret.result = 0
	--扣钱
	local money_list = {}
	money_list[MoneyType.GIFT_GOLD] = math.floor(need_money * MERGE_SALE)
	ret_code = pack_con:dec_money_l_inter_face(money_list, {['type']=MONEY_SOURCE.GEM_FAST_LEVELUP}, 1)
	if ret_code ~= 0 then 
		ret.result = 43066
		g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_FAST_MERGE_GEM_S, ret)
		return 
	end
	--去掉扣虎钳
	--ret_code = pack_con:del_item_by_item_id(tool_id, tool_id_num, {['type']=ITEM_SOURCE.GEM_FAST_LEVELUP})
	--扣工具
	if ret_code ~= 0 then return end
	for k, v in pairs(del_gem_list) do
		ret_code = pack_con:del_item_by_item_id(k, v, {['type']=ITEM_SOURCE.GEM_FAST_LEVELUP})
		if ret_code ~= 0 then return end
	end	
	-------------------------------------------
	--需要添加 是否有下一级宝石
	local dis_gem = {}
	dis_gem[pkt.embed_slot] = pkt.embed_slot
	ret_code = pack_con:dis_all_embed_equip(equip, dis_gem)
	
	local gem_l = {}
	gem_l[pkt.embed_slot] = tonumber(next_gem_id)

	ret_code = pack_con:embed_equip(equip, gem_l)

	if ret_code ~= 0 then
		ret.result = 200038
	end
	g_cltsock_mgr:send_client(conn.char_id, CMD_NPC_FAST_MERGE_GEM_S, ret)

	--更新人物
	if pkt.bag == EQUIPMENT_BAG then
		player:on_update_attribute(2)
		--宝石事件通知
		local args = {}
		args.item = equip.item
		g_event_mgr:notify_event(EVENT_SET.EVENT_GEM_EQUIPMENT, conn.char_id, args)
	end
end