-- cailizhong
-- 手机绑定礼包

local bind_gift_loader = require("bind_gift.bind_gift_loader")

Bind_gift_container = oo.class(nil, "Bind_gift_container")

function Bind_gift_container:__init(char_id)
	self.char_id   = char_id
	self.flag      = nil
	self.bind_list = {} -- 用户已经绑定过的类型列表，以绑定类型为键
	self:load_db() -- 从数据库加载领取绑定状态信息
end

-- 返回奖励物品列表
function Bind_gift_container:get_gift_list(bind_type)
	return bind_gift_loader.get_reward_list(bind_type)
end

-- 判读是否能够获取手机绑定礼包
function Bind_gift_container:can_get_gift(acc_id, bind_type, key)
	if self.bind_list[bind_type] then
		return 31043 -- 已经领取过手机绑定礼包
	end

	if not bind_gift_loader.bind_type_isExist(bind_type) then return 31044 end -- 绑定类型不存在

	local e_code, myKey = self:create_key(acc_id, bind_type) -- 内部生成key
	if e_code ~= 0 then return e_code end -- key产生错误
	if myKey ~= key then -- 用户输入的key值错误
		return 31042
	end
	return 0
end

-- 获取手机绑定礼包
function Bind_gift_container:get_gift(bind_type)
	local gift_list = self:get_gift_list(bind_type)
	local item_list = {}
	for k, v in pairs(gift_list or {}) do
		local item = {}
		item.type    = 1
		item.item_id = v.item_id
		item.number  = v.item_count
		table.insert(item_list, item)
	end

	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()

	local free_slot = pack_con:get_bag_free_slot_cnt()
	if free_slot < table.getn(item_list)  then
		return 20301
	end

	self:set_flag(bind_type,bind_type) -- 先设置已经领取物品
	if pack_con:add_item_l(item_list,{['type']=ITEM_SOURCE.SJ_BIND_GIFT}) ~= 0 then -- 添加物品失败
		self:set_flag(bind_type, nil) -- 重置为未领取状态  
		return 27003
	end

	self.flag = true
	local err_code = Bind_gift_db:update_one(self.char_id, self.bind_list) -- 更新数据库记录
	return err_code
end

-- 设置绑定标记
function Bind_gift_container:set_flag(bind_type, val)
	self.bind_list[bind_type] = val
end

-- 从数据库加载信息
function Bind_gift_container:load_db()
	local e_code, rows = Bind_gift_db:load(self.char_id)
	if e_code ~= 0 then
		return e_code
	end
	if rows then
		for k, v in pairs(rows.list) do
			self.bind_list[v] = v
		end
	end
end


-- 生成key
function Bind_gift_container:create_key(acc_id, bind_type)
	local bind_game = bind_gift_loader.get_bind_game(bind_type)
	local bind_name = bind_gift_loader.get_bind_name(bind_type)
	local e_code = 0
	if bind_game==nil or bind_name==nil then return 31044 end

	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end
	local svr_id = player:get_server_id()
	if not svr_id then return end

	local code = RSA_PUBKEY..bind_game..svr_id..acc_id..bind_name
	local key = crypto.md5(code)
	return e_code, key
end

-- 下线保存
function Bind_gift_container:serialize()
	if self.flag ~= nil then
		Bind_gift_db:update_one(self.char_id, self.bind_list)
	end
end