--$Id: mark.lua 61965 2013-03-21 06:41:28Z cenyx $

-- map服广播
local msg = {}
f_construct_content(msg, obj:get_name(), 53)
f_construct_content(msg, f_get_string(2071), 12)
f_construct_content(msg, _kalpa._need_a[level][11], 53)
f_construct_content(msg, f_get_string(2072), 12)
f_cmd_sysbd(msg)

-- 公共服广播
	local msg = {}
	f_construct_content(msg, f_get_string(2226), 12)
	f_construct_content(msg, win_name, 53)
	f_send_bdc(bdc_type, 3, msg)
	--bdc_type:广播方式
	--只在世界广播 -- 1
	--只在横屏广播 -- 2
	--世界+横屏广播 -- 3
	--帮派 -- 4
	--队伍 -- 5
	


--map 插入道具进背包
	local reward_list = sign_in_config.get_reward_day_info(pkt.type, pkt.day)
	local new_item_list = {}
	local count = 1
	for k,v in pairs(reward_list or {}) do
		new_item_list[count] = {}
		new_item_list[count]["item_id"]     = v.item_id
		new_item_list[count]["type"]   		= 1
		new_item_list[count]["number"] 		= v.number
		count = count + 1
	end
	local pack_con = player:get_pack_con()	
	if pack_con then
		ret.result = pack_con:add_item_l(new_item_list, {['type']=ITEM_SOURCE.SIGN_IN_REWARD})
		if ret.result ~= 0 then
			return ret.result
		end
	end

--map 取得某道具数量
local pack_con = obj:get_pack_con()
local prop_s = pack_con:get_all_item_count(202002306020)

--map 扣道具
	--根据id
	pack_con:del_item_by_item_id(202002406020, v.number, {['type'] = ITEM_SOURCE.TASK})
	--根据背包格
	pack_con:del_item_by_bag_slot(SYSTEM_BAG, slot, 1, {['type']=ITEM_SOURCE.KALPA_PROP})
	--按item_id删物品：type为nil时删此ID；type=1时先删绑定, bag_id为nil时为背包
	pack_con:del_item_by_item_id_inter_face(item_id, cnt, src_log, type, bag_id)

--公共服发邮件
	local email = {}
	email.sender = -1
	email.recevier = recevier
	email.title = title
	email.content = content
	email.box_title = box_title
	email.money_list = {}
	
	email.item_list = {}
	if gift.item_id then
		local item = {}
		item.id = gift.item_id
		item.name = gift.name or ""
		item.count = gift.num
		table.insert(email.item_list, item)
	end
	g_email_mgr:send_email_interface(email)