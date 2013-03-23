
local pet_trigger_skill_config = require("skill.passive_skill.pet.pet_trigger_skill_loader")
local pro_base = 10000
local _random =  crypto.random
--触发类型：	trigger_type: 1.触发嘲讽, 2.封步(定身), 3.禁法(沉默), 4.截脉(禁用有益技能)
local handle_fun_list = {}

Pet_trigger_skill = oo.class(Skill_passive, "Pet_trigger_skill");

function Pet_trigger_skill:__init(skill_type, level, trigger_type, cd, duration, protect, pro)
	Skill_passive.__init(self, skill_type + level, SKILL_PET_ATTACK_TRIGGER, skill_type, level);
	self.cd_time = cd
	self.trigger_type = trigger_type
	self.duration = duration or 5
	self.protect = protect or 0
	self.pro = pro * pro_base
end

function Pet_trigger_skill:get_effect(param)
	return nil;
end

function Pet_trigger_skill:effect(sour_id, param)
	--print("Pet_trigger_skill:effect()")
	local trigger_type = self.trigger_type
	if not param.obj_d:check_safety_time(trigger_type, self.protect) or _random(0, pro_base) >= self.pro then
		return nil
	end

	param.obj_d:set_safety_time(trigger_type)
	local handle_fun = handle_fun_list[trigger_type]
	return handle_fun(self, param.obj_s, param.obj_d, param.param)
end

local skill_builder = function ()
	local skill_name_format = "Skill_%d"
	local skill_param = pet_trigger_skill_config.skill_trigger_config
	for skill_type, skill_params in pairs(skill_param) do
		for level, params in pairs(skill_params) do
			local skill_name = string.format(skill_name_format, skill_type + level)
			_G[skill_name] = Pet_trigger_skill(skill_type, level, params.trigger_type, params.cd, params.duration, params.protect, params.pro)
			--print("Pet_trigger_skill", skill_name, skill_type + level, params.trigger_type, params.cd, params.duration, params.protect, params.pro)
		end
	end
end

skill_builder()


--1.触发嘲讽
handle_fun_list[1] = function(self, obj_s, obj_d, param)
	--print("handle_fun_list[1]")
	local sour_id = obj_s:get_id()

	local scene_o = obj_s:get_scene_obj()
	local map_obj = scene_o:get_map_obj()
	local obj_list = map_obj:scan_obj_rect(obj_s:get_pos(), 8, OBJ_TYPE_MONSTER)

	for k,v in pairs(obj_list) do
		local obj_o = g_obj_mgr:get_obj(k)
		if obj_o ~= nil and scene_o:is_attack(sour_id, k) == 0 then
			local ret = obj_o:on_beskill(self.id, obj_s)
			if ret == 2 then
				local impact_o = Impact_1281(k)
				local param = {}
				param.sour_id = sour_id
				param.skill_id = self.id
				param.pos = nil
				impact_o:set_count(self.duration)
				impact_o:effect(param)
			end
		end
	end
	self:send_syn(obj_s, obj_d:get_id(), nil, 2)
	return 0
end

--2.封步(定身)
handle_fun_list[2] = function(self, obj_s, obj_d, param)
	--print("handle_fun_list[2]")
	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return
	end
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		if obj_d:is_alive() and obj_d:on_beimpact(IMPACT_OBJ_1211, obj_s) == 1 then
			local per, val = 0, 0
			if obj_d:get_type() == OBJ_TYPE_HUMAN then
				per, val = obj_d:get_passive_effect(EXTRA_STOP_DE, nil)
			end
			local count_time = math.floor(self.duration - val)
			local impact_o = Impact_1211(des_id)
			impact_o:set_count(math.max(1, count_time))
			impact_o:effect()
		end
		self:send_syn(obj_s, des_id, nil, ret)
	end
	return 0
end

--3.禁法(沉默)
handle_fun_list[3] = function(self, obj_s, obj_d, param)
	--print("handle_fun_list[3]")
	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return
	end
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		if obj_d:is_alive() and obj_d:on_beimpact(IMPACT_OBJ_1291, obj_s) == 1 then
			local per, val = 0, 0
			if obj_d:get_type() == OBJ_TYPE_HUMAN then
				per, val = obj_d:get_passive_effect(EXTRA_SILENCE_DE, nil)
			end
			local count_time = math.floor(self.duration - val)
			local impact_o = Impact_1291(des_id)
			impact_o:set_count(math.max(1, count_time))
			impact_o:effect()
		end
		self:send_syn(obj_s, des_id, nil, ret)
	end
	return 0
end

--4.截脉(禁用有益技能)
handle_fun_list[4] = function(self, obj_s, obj_d, param)
	--print("handle_fun_list[4]")
	local sour_id = obj_s:get_id()
	local des_id = obj_d:get_id()
	local scene_o = obj_s:get_scene_obj()
	local md_ret = scene_o:is_attack(sour_id, des_id)
	if md_ret ~= 0 then
		return
	end
	local ret = obj_d:on_beskill(self.id, obj_s)
	if ret == 2 then
		if obj_d:is_alive() and obj_d:on_beimpact(IMPACT_OBJ_1292, obj_s) == 1 then
			local count_time = math.floor(self.duration)
			local impact_o = Impact_1292(des_id)
			impact_o:set_count(math.max(1, count_time))
			impact_o:effect()
		end
		self:send_syn(obj_s, des_id, nil, ret)
	end
	return 0
end