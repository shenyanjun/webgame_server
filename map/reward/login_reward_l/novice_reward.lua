--2010-01-21
--laojc
--新手卡礼包

local reward_t = require("config.reward_config")

Novice_reward = oo.class(nil,"Novice_reward")

function Novice_reward:init()
	self.reward_list = {}
	local dbh = f_get_db()

	local rows, e_code = dbh:select("gift_newer")
	if rs ~= nil and e_code == 0 then
		for k,v in pairs(rows) do
			local id = v.char_id
			if id ~= nil and id ~= "" then
				self.reward_list[id] = {}
				self.reward_list[id].key_id = v.key_id
				self.reward_list[id].flag = v.flag
			end
		end
	end
end


function Novice_reward:get_novice_reward()
	return reward_t.f_get_novice_reward()
end


function Novice_reward:can_be_fetch(key,char_id)
	if self.reward_list[char_id] ~= nil then
		return 27602         --已领取
	else
		--local dbh = get_dbh_web()
--
		--local rs = dbh:selectrow_ex("select * from gift_newer where char_id = ?",char_id)
		--if rs ~= nil and dbh.errcode == 0 then
			--return 27602
		--end
--
		--local dbh = get_dbh_web()
		--local rs = dbh:selectrow_ex("select char_id from gift_newer where key_id = ?", key)
		--if rs ~= nil and dbh.errcode == 0 then
			--if rs.char_id == nil or rs.char_id == "" then
				--return 0
			--end
		--end
		local dbh = f_get_db()
		local query = string.format("{char_id:%d}", char_id)
		local row, e_code = dbh:select_one("gift_newer", nil, query,"{char_id:1}")
		if 0 == e_code and row then
			return 27602
		end

		local dbh = f_get_db()
		local query = string.format("{key_id:'%s'}", key)
		local fields = "{char_id:1}"
		local row, e_code = dbh:select_one("gift_newer", fields, query,"{key_id:1}")
		if 0 == e_code and row then
			if row.char_id == nil or row.char_id == "" then
				return 0
			end
		end
	end
	return 27605
end

function Novice_reward:fetch_item(char_id,key)
	local item = self:get_novice_reward()
	if item == nil then return end 

	local player = g_obj_mgr:get_obj(char_id)
	local pack_con = player:get_pack_con()
	
	local item_id_list = {}
	for k,v in pairs(item or {})do
		item_id_list[k] = {}
		item_id_list[k].type = 1
		item_id_list[k].item_id = tonumber(v[1])
		item_id_list[k].number = v[2]
	end

	local free_slot = pack_con:get_bag_free_slot_cnt()
	if free_slot <=0  then
		return 43004
	end

	if pack_con:add_item_l(item_id_list, {['type']=ITEM_SOURCE.NOVICE}) ~= 0 then
		return 27003
	end
	local name = player:get_name()
	self:update_flag(key,name,char_id)
	return 0
end

function Novice_reward:update_flag(key,name,char_id)
	--local str = string.format("update gift_newer set flag =1,char_name = '%s',char_id = %d,time = %d where key_id = '%s'",name,char_id,ev.time,key)
	--local dbh = get_dbh_web()
	--dbh:execute(str)

	local dbh = f_get_db()
	local data = {}
	data.flag = 1
	data.char_name = name
	data.char_id = char_id
	data.time = ev.time
	local query = string.format("{key_id:'%s'}",key)
	local err_code = dbh:update("gift_newer",query,Json.Encode(data))
	if err_code == 0 then
		self.reward_list[char_id] = {}
		self.reward_list[char_id].key_id = key
		self.reward_list[char_id].flag = 1
	end
end

Novice_reward:init()
