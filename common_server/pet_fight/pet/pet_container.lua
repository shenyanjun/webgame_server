
local pet_table = "pet"
local _pet_off = 1000000000

Pet_container = oo.class(nil, "Pet_container")

function Pet_container:__init(obj_id)
	self.obj_id = obj_id
	
	self.pet_list = {}
end

function Pet_container:get_pet_obj(pet_id)
	return self.pet_list[pet_id]
end

function Pet_container:set_pet_obj(pet_obj)
	local pet_id = pet_obj:get_pet_id()
	self.pet_list[pet_id] = pet_obj
end

function Pet_container:del_pet_obj(pet_id)
	self.pet_list[pet_id] = nil
end

function Pet_container:is_in_pet_con(pet_id)
	if self.pet_list[pet_id] == nil then 
		return false
	end

	return true
end

function Pet_container:get_net_info()
	local ret = {}
	for k, v in pairs(self.pet_list or {}) do
		local pet_id = v:get_pet_id()
		table.insert(ret, pet_id)
	end

	return ret
end

function Pet_container:get_pet_count()
	return table.size(self.pet_list)
end

--function Pet_container:create_pet_obj(pet_info)
	--local pet_obj = Pet_obj(pet_info.pet_id)
	--pet_obj:set_level(pet_info.level)
	--pet_obj:set_pullulate(pet_info.pullulate)
	--pet_obj:set_fighting(pet_info.fighting)
	--pet_obj:set_occ(pet_info.occ)
	--pet_obj:set_exp(pet_info.exp)
	--pet_obj:load_base_attr(pet_info.init_strengh,pet_info.init_intelligence,pet_info.init_stemina, pet_info.init_dexterity)
	--pet_obj:init_load()
--
	--self:set_pet_obj(pet_obj)
--end

function Pet_container:clear()
	self.pet_list = {}
end

function Pet_container:get_pet_info()
	local ret ={}
	for k,v in pairs(self.pet_list) do
		local t = {}
		t[1] = v:get_name()
		t[2] = v:get_level()
		t[3] = v:get_pet_id()
		table.insert(ret, t)
	end
	return ret
end

--玩家更新数据同步
function Pet_container:update_pet_list(item_l)
	--self:clear()
	local container = g_pet_vs_mgr:get_container(self.obj_id)
	local strategy_con = container:get_strategy_con()
	local item_size = table.size(item_l)

	for m,n in pairs(self.pet_list or {}) do
		local count = 0
		for b,c in pairs(item_l) do
			if c.pet_id ~= m then
				count = count + 1
			else
				count = 0 
				break
			end
		end
		if count == item_size then
			self.pet_list[m] = nil
		end
	end

	for k, v in pairs(item_l) do
		local pet_id = v.pet_id
		local pet_obj
		if not self:is_in_pet_con(pet_id) then
			pet_obj = Pet_obj(pet_id,self.obj_id)
		else
			pet_obj = self:get_pet_obj(pet_id)
		end
		pet_obj:set_level(v.level)
		pet_obj:set_name(v.name)
		pet_obj:set_pullulate(v.pullulate)
		pet_obj:set_fighting(v.fighting)
		pet_obj:set_occ(v.occ)
		pet_obj:set_exp(v.exp)
		pet_obj:load_base_attr(v.init_strengh,v.init_intelligence, v.init_stemina, v.init_dexterity)
		pet_obj:init_load()
		pet_obj:get_equip_con():update_bag(v.bag)
		pet_obj:get_skill_con():update_skill(v.skill)
		pet_obj:set_hp(v.hp)
		pet_obj:set_current_hp(v.cur_hp)
		pet_obj:set_current_mp(v.cur_mp)
		pet_obj:set_combat_status(v.combat_status)
		pet_obj:set_init_strengh(v.init_strengh)
		pet_obj:set_init_intelligence(v.init_intelligence)
		pet_obj:set_init_stemina(v.init_stemina)
		pet_obj:set_init_dexterity(v.init_dexterity)
		pet_obj:set_possess(v.possess)
		self:set_pet_obj(pet_obj)
	end
	--更新策略
	strategy_con:update_strategy(self.pet_list)

end


function Pet_container:load(item_l)
	local db = f_get_db()
	local rows, e_code = db:select(pet_table, nil, string.format("{owner_id:%d, flag:0}", self.obj_id), nil, 0, 0, "{owner_id:1, flag:1}")
	if 0 == e_code and rows then
		for k, v in pairs(rows) do
			local pet_id = _pet_off + v.id
			local pet_obj = Pet_obj(pet_id,self.obj_id)
			pet_obj:set_level(v.level)
			pet_obj:set_name(v.name)
			pet_obj:set_pullulate(v.pullulate)
			pet_obj:set_fighting(v.fighting)
			pet_obj:set_occ(v.occ)
			pet_obj:set_exp(v.exp)
			pet_obj:load_base_attr(v.init_strengh,v.init_intelligence, v.init_stemina, v.init_dexterity)
			pet_obj:init_load()
			pet_obj:set_hp()
			pet_obj:set_bind(v.bind)
			pet_obj:set_current_hp(v.hp)
			pet_obj:set_current_mp(v.mp)
			pet_obj:set_combat_status(v.combat_status)
			pet_obj:set_init_strengh(v.init_strengh)
			pet_obj:set_init_intelligence(v.init_intelligence)
			pet_obj:set_init_stemina(v.init_stemina)
			pet_obj:set_init_dexterity(v.init_dexterity)
			pet_obj:set_possess(v.possess)

			self:set_pet_obj(pet_obj)
		end
	end
	--if item_l ~= nil then
		--local container = g_pet_vs_mgr:get_container(self.obj_id)
		--container:load_strategy_con(item_l.strategy or {})
	--end
end