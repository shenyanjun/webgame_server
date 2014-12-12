
TRADE_PREPARE = 0  --准备
TRADE_START = 1    --建立交易
TRADE_LOCK = 2     --锁定
TRADE_OK = 3       --交易状态

Obj_trade = oo.class(nil, "Obj_trade")

function Obj_trade:__init(sour_id, des_id)
	self.id = crypto.uuid()
	self.state = TRADE_PREPARE

	self.sour_id = sour_id
	self.des_id = des_id

	self.obj_l = {}
	self.obj_l[sour_id] = {}
	self.obj_l[sour_id]["item_l"] = {}
	self.obj_l[sour_id]["state"] = TRADE_PREPARE

	self.obj_l[des_id] = {}
	self.obj_l[des_id]["item_l"] = {}
	self.obj_l[des_id]["state"] = TRADE_PREPARE
end

function Obj_trade:get_id()
	return self.id
end

function Obj_trade:get_state()
	return self.state
end
function Obj_trade:set_state(state)
	self.state = state
	self.obj_l[self.sour_id]["state"] = state
	self.obj_l[self.des_id]["state"] = state
end
function Obj_trade:get_member()
	return {self.sour_id, self.des_id}
end

--获取角色当前状态
function Obj_trade:get_obj_state(obj_id)
	return self.obj_l[obj_id]["state"]
end

function Obj_trade:get_other_obj_id(obj_id)
	if obj_id == self.sour_id then
		return self.des_id
	else
		return self.sour_id
	end
end

--锁定
function Obj_trade:lock_item_l(obj_id, item_l)
	if self.obj_l[obj_id]["state"] < TRADE_LOCK then
		self.obj_l[obj_id]["item_l"] = item_l
		self.obj_l[obj_id]["state"] = TRADE_LOCK

		if self.obj_l[self.des_id]["state"] == TRADE_LOCK and 
			self.obj_l[self.sour_id]["state"] == TRADE_LOCK then

			if self:is_empty() then 
				return 21413
			end

			self.state = TRADE_LOCK
			return 0
		end
		return 0
	end
	return 21402
end

--是否空交易
function Obj_trade:is_empty()
	local s_item_l = self.obj_l[self.sour_id]["item_l"]
	local d_item_l = self.obj_l[self.des_id]["item_l"]

	if table.size(s_item_l.item_l or {}) > 0 or s_item_l.money_l.gold > 0 then
		return false
	end

	if table.size(d_item_l.item_l or {}) > 0 or d_item_l.money_l.gold > 0 then
		return false
	end

	return true
end

--交易
function Obj_trade:ok(obj_id)
	if self.obj_l[obj_id]["state"] == TRADE_LOCK then
		self.obj_l[obj_id]["state"] = TRADE_OK

		if self.obj_l[self.des_id]["state"] == TRADE_OK and self.obj_l[self.sour_id]["state"] == TRADE_OK then
			self.state = TRADE_OK
		end
		return true
	end
	return false
end

function Obj_trade:get_item_l(obj_id)
	return self.obj_l[obj_id]["item_l"]
end