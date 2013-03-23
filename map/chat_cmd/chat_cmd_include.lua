


local chat_cmd_config=require("config.chat_cmd_config")
local _sf = require("scene_ex.scene_process")


Clt_commands[1][CMD_CHAT_CHANNAL_CMD_C] =
function(conn, pkt)
	if not _DEBUG then return end
	if conn.char_id == nil or pkt == nil then return end

    local ret={}
	local cmd_id=chat_cmd_config._chat_cmd[pkt[1]]          --命令
	if cmd_id == nil then 
		ret.result=28000
		g_cltsock_mgr:send_client(conn.char_id, CMD_CHAT_CHANNAL_CMD_S, ret)
		return 
	end

	local e_code=f_chat_cmd(conn.char_id,cmd_id,pkt)
	ret.result=e_code
	g_cltsock_mgr:send_client(conn.char_id, CMD_CHAT_CHANNAL_CMD_S, ret)

end

--功能：判断cmd
--参数：玩家id，命令，数组包
--返回：
function f_chat_cmd(char_id,cmd_id,pkt)
	--print("f_chat_cmd", char_id,cmd_id, j_e(pkt))
    if cmd_id < 0 then return 28001 end
	local player=g_obj_mgr:get_obj(char_id)
	local bag_con=player:get_pack_con()
    local e_code

	if cmd_id == 1 then                       --人物经验
		local ex = tonumber(pkt[2])
		if ex == nil then return 28001 end
		if ex > 1000000000 then 
			ex = 1000000000
		end
		e_code=player:add_exp(ex)

	elseif cmd_id == 2 then                   --宠物经验
		local ex = tonumber(pkt[2])
		if ex == nil then return 28001 end
		if ex > 10000000 then 
			ex = 10000000
		end
		local pet_con = player:get_pet_con()
		local pet = pet_con:get_combat_pet()
		e_code = pet and pet:add_exp(ex) or 28001

	elseif cmd_id == 3 then                   --物品
		local item_l = {}
		local item_id 
		local item_count
		local item_index = 1

		for k,v in pairs(pkt or {}) do
		    if k%2 == 0 then
				item_id	= tonumber(pkt[k])
			    item_count = tonumber(pkt[k+1])
				if item_id == nil or item_count == nil then break end
				if item_count > 64 then 
					item_count = 64
				end
				item_l[item_index]={}
				item_l[item_index].type = 1
				item_l[item_index].number = item_count
				item_l[item_index].item_id = item_id
				item_index=item_index + 1
			end
		end
		e_code = bag_con:add_item_l(item_l,{['type']=ITEM_SOURCE.DEBUG_CMD})

	elseif cmd_id == 4 then                   --货币
	    local currency_type = tonumber(pkt[2])
		local total_count = tonumber(pkt[3])
		if currency_type == nil or total_count ==  nil or total_count < 0 or currency_type > 9 or currency_type < 1 then return 28001 end
		e_code = bag_con:add_money(currency_type, math.min(total_count,10000000), {['type']=MONEY_SOURCE.DEBUG_CMD})

	elseif cmd_id == 5 then                   --场景传送
	    if chat_cmd_config._chat_cmd_scence[pkt[2]] == nil then return 28001 end
	    local map_id =  chat_cmd_config._chat_cmd_scence[pkt[2]][1]
	    local point_x = tonumber(pkt[3])
		local point_y = tonumber(pkt[4])

		if map_id == nil then return 28001 end
		if point_x == nil or point_y ==nil then
		    point_x = chat_cmd_config._chat_cmd_scence[pkt[2]][2]
			point_y = chat_cmd_config._chat_cmd_scence[pkt[2]][3]
		end
		local pos={point_x,point_y}
	    _sf.change_scene_cm(char_id, map_id, pos)

	elseif cmd_id == 6 then                    --发套装
		local equipment_l=chat_cmd_config._chat_cmd_equipment[pkt[2]]
		local rank=tonumber(pkt[3])
		local gem_l=chat_cmd_config._chat_cmd_gem[pkt[4]]
	    local equipment

		if equipment_l ==nil then return 28001 end

		for k,v in pairs(equipment_l or {}) do
		     e_code,equipment = Item_factory.create(tonumber(v))
			 if rank > 0 then
	             for init=1,rank do
				     equipment:intensify_equip()
				 end
			 end
		     if gem_l then
			 	 for init=1,6 do
				      equipment:drill_equip()
				 end
			     equipment:embed_equip(gem_l)
			 end
			 e_code=bag_con:add_by_item(equipment,{['type']=ITEM_SOURCE.DEBUG_CMD})
		end
	elseif cmd_id == 7 then						--发技能书
	   local skill_id_l = chat_cmd_config._chat_skill_book[pkt[2]]
	   if skill_id_l == nil then return 28001 end
	   local skill_book
	   for k,v in pairs(skill_id_l or {}) do
	       e_code,skill_book = Item_factory.create(tonumber(v))
		   e_code=bag_con:add_by_item(skill_book,{['type']=ITEM_SOURCE.DEBUG_CMD})
	   end
	elseif cmd_id == 8 then						--删除背包
		local id = tonumber(pkt[2])
		if not id then return end
		local count = bag_con:get_item_count(id)
		if count < 1 then return end
		e_code = bag_con:del_item_by_item_id(id,count,{['type'] = ITEM_SOURCE.DEBUG_CMD})
	elseif cmd_id == 9 then 
		local type = tonumber(pkt[2])
		local count = tonumber(pkt[3])
		if not type or not count then print("Error:dec money falied!") return end
		if type > 9 or type < 1  or count < 0 then return 28001 end
		local money = bag_con:get_money()
		local bag_money = 0
		if type == MoneyType.GOLD then
			bag_money = money.gold
		elseif type == MoneyType.GIFT_GOLD then
			bag_money = money.gift_gold
		elseif type == MoneyType.JADE then
			bag_money = money.jade
		elseif type == MoneyType.GIFT_JADE then
			bag_money = money.gift_jade
		elseif type == MoneyType.BANK_GOLD then
			bag_money = money.bank_gold
		elseif type == MoneyType.INTEGRAL then
			bag_money = money.integral
		elseif type == MoneyType.BONUS then
			bag_money = money.gift_gold
		elseif type == MoneyType.HONOR then
			bag_money = money.honor
		elseif type == MoneyType.GLORY then
			bag_money = money.glory
		end
		e_code = bag_con:dec_money(type,math.min(count,bag_money),{['type']=MONEY_SOURCE.DEBUG_CMD})
	elseif cmd_id == 10 then
		if tonumber(pkt[2]) > 100 then pkt[2] = 100 end
		player.db.level = tonumber(pkt[2])
		player.db.levle_time = ev.time
		player:on_upgrade(player:get_level())
	end
		
	return e_code

end

