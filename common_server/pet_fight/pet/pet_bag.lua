
local pet_bag_table = "pet_bag"

Pet_bag = oo.class(nil, "Pet_bag")

function Pet_bag:__init(pet_id, owner_id)
	self.pet_id = pet_id
	self.owner_id = owner_id

	self.slot_list = {}

	--装备属性总和
	self.attr ={}

	--装备技能总和
	self.skill_list = {}
end


function Pet_bag:set_slot_list(slot,uuid,number,item)
	self.slot_list[slot] = {}
	self.slot_list[slot].uuid = uuid
	self.slot_list[slot].number = number
	self.slot_list[slot].item = item
	--self:set_skill_attr_list()
end

function Pet_bag:get_slot_list(slot)
	return self.slot_list[slot]
end

function Pet_bag:set_skill_attr_list()
	local ret = {}
	for k,v in pairs(self.slot_list) do
		--技能
		local skill_list = v.item:get_skill_list_ex()
		for m, n in pairs(skill_list or {}) do
			local skill_id = math.floor(n[1] / 100) * 100
			if self.skill_list[skill_id] == nil then
				self.skill_list[skill_id] = 0
			end
			self.skill_list[skill_id] = self.skill_list[skill_id] + n[3]
		end
		--属性
		local t_attr = v.item:get_attribute()
		for m, n in pairs(t_attr) do
			if self.attr[m] == nil then
				self.attr[m] = 0
			end
			self.attr[m] = self.attr[m] + n
		end
	end
end

function Pet_bag:get_skill_list()
	return self.skill_list
end

function Pet_bag:get_attr()
	return self.attr
end

function Pet_bag:clear()
	self.slot_list = {}
	--装备属性总和
	self.attr ={}

	--装备技能总和
	self.skill_list = {}
end

--玩家在线的情况下战斗的时候同步数据
function Pet_bag:update_bag(item_l)
	self:clear()
	for k,v in pairs (item_l) do
		local e_code, item = Item_factory.clone(v[3],v[4])
		if e_code ~= 0 then
			print("item clone error:",Json.Encode(v))
		else 
			self:set_slot_list(v[1],v[2],1,item)
		end
	end
	self:set_skill_attr_list()
end

--获取背包信息
function Pet_bag:net_get_bag_info()
	local info = {}
	local item_info
	for k,v in pairs(self.slot_list or {}) do
		if v ~= nil and table.size(v) ~= 0 then
			item_info = {}
			item_info[1] = self.slot_list[k].uuid
			item_info[2] = nil
			item_info[3] = PET_BAG
			item_info[4] = k
			item_info[5] = self.slot_list[k].number or 1
			item_info[6] = self.slot_list[k].item:serialize_to_net()
			item_info[7] = nil

			table.insert(info, item_info)
		end
	end
	return info
end


function Pet_bag:load()
	local dbh = f_get_db()
	local condition = string.format("{char_id:%d,pet_id:%d}", self.owner_id, self.pet_id)
	local db_items = dbh:select_one(pet_bag_table, nil, condition, nil, "{char_id:1,pet_id:1}")

	if db_items then
		for k,v in pairs(db_items.item_l or {}) do 
			local e_code, item = Item_factory.clone(v[3],v[4])
			if e_code ~= 0 then
				print("item clone error:",Json.Encode(v))
			else 
				self:set_slot_list(v[1],v[2],1,item)
			end
		end
		self:set_skill_attr_list()
	end
end