
local _config = require("config.xml.human_fight.magic_skill_config")
Human_skill_magic_container = oo.class(nil, "Human_skill_magic_container")

function Human_skill_magic_container:__init(char_id)
	self.char_id = char_id

	--法宝技能
	self.skill_list = {}
end

--附加伤害
function Human_skill_magic_container:get_damage_add(obj_d, skill_cmd)
	local damage_add = {0, 0}
	local skill_t = self:get_skill_list()
	local trigger = _config._trigger
	local human_skill_mgr = g_human_skill_mgr
	local param = {}
	param.obj_d = obj_d
	param.obj_s = g_human_vs_mgr:get_container(self.char_id):get_human_obj()
	for _, v in pairs(skill_t) do
		local skill_o = human_skill_mgr:get_skill(v)
		local use_skill_type = human_skill_mgr:get_skill(skill_cmd+1):get_type()
		if skill_o ~= nil and skill_o:get_type() == SKILL_MAGIC_DAMAGE_ADD 
			and (trigger[skill_o.cmd_id][use_skill_type] ~= nil	or trigger[skill_o.cmd_id][skill_cmd] ~= nil)  then
			local t = skill_o:effect(self.char_id, param)
			if t ~= nil then
				damage_add[1] = damage_add[1] + t[1]
				damage_add[2] = damage_add[2] + t[2]
			end
		end
	end
	--print("damage_add", j_e(damage_add))
	return damage_add
end

--减免伤害
function Human_skill_magic_container:get_damage_sub(obj_s, skill_cmd)
	local damage_sub = {0, 0}
	local skill_t = self:get_skill_list()
	local human_skill_mgr = g_human_skill_mgr
	local param = {}
	param.obj_d = g_human_vs_mgr:get_container(self.char_id):get_human_obj()
	param.obj_s = obj_s
	local trigger = _config._trigger
	for _, v in pairs(skill_t) do
		local skill_o = human_skill_mgr:get_skill(v)
		local use_skill_type = human_skill_mgr:get_skill(skill_cmd+1):get_type()
		if skill_o ~= nil and skill_o:get_type() == SKILL_MAGIC_DAMAGE_SUB 
			and (trigger[skill_o.cmd_id][use_skill_type] ~= nil	or trigger[skill_o.cmd_id][skill_cmd] ~= nil) then
			local t = skill_o:effect(self.char_id, param)
			if t ~= nil then
				damage_sub[1] = damage_sub[1] + t[1]
				damage_sub[2] = damage_sub[2] + t[2]
			end
		end
	end
	--print("damage_sub", j_e(damage_sub))
	return damage_sub
end

--触发被攻击类法宝技能
function Human_skill_magic_container:trigger_be_attack_magic_skill(skill_id, killer)
end

----触发攻击类法宝技能
function Human_skill_magic_container:trigger_attack_magic_skill(skill_id, des_obj, damage)
	
end

function Human_skill_magic_container:get_skill_list()
	return self.skill_list
end


function Human_skill_magic_container:update_skill_list(skill_l)
	self.skill_list = skill_l or {}
end

function Human_skill_magic_container:load()
end


