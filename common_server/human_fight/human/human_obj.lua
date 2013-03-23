

Human_obj = oo.class(nil,"Human_obj")

function Human_obj:__init(char_id)
	self.char_id = char_id

	--属性
	self.attr_list = {}

	--技能
	self.human_skill_con = nil

	--法宝
	self.magic_skill_con = nil

	--
	self.mp = 0

	--
	self.hp = 0

	--
	self.fight = 0

	self.show = {}

	self.m_defense = 0

	self.s_defense = 0
	
	self.min_m_attack = 0
	self.max_m_attack = 0

	self.min_s_attack = 0
	self.max_s_attack = 0
end

function Human_obj:get_magic_con()
	return self.magic_skill_con
end

function Human_obj:get_show()
	return self.show
end

function Human_obj:get_fight()
	return self.fight
end

function Human_obj:set_fight(fight)
	self.fight = fight
end

function Human_obj:get_hp()
	return self.hp
end

function Human_obj:del_hp(hp)
	if self.hp < hp then
		self.hp = 0
	else
		self.hp = self.hp - hp
	end
end

function Human_obj:add_hp(hp)
	self.hp = self.hp + hp
	local max_hp = self:get_max_hp()
	if self.hp >= max_hp then
		self.hp = max_hp
	end
end

function Human_obj:get_mp()
	return self.mp
end

function Human_obj:del_mp(mp)
	if self.mp < mp then
		self.mp = 0
	else
		self.mp = self.mp - mp
	end
end

function Human_obj:get_max_hp()
	return self.attr_list.hp
end

function Human_obj:get_max_mp()
	return self.attr_list.mp
end

function Human_obj:get_occ()
	return g_player_mgr.all_player_l[self.char_id].occ
end

function Human_obj:get_level()
	return g_player_mgr.all_player_l[self.char_id].level
end

function Human_obj:get_element_de_t()
	local rate = self.attr_list.element_defense or 0	if rate >= crypto.random(1, 1001) then		return self.attr_list.element_defense_ef or 0	end	return 0
end

function Human_obj:get_fire_ak_t()
	return self.attr_list.fire_attack
end

function Human_obj:get_s_attack_t()
	return self.min_s_attack,self.max_s_attack
end

function Human_obj:get_m_attack_t()
	return self.min_m_attack,self.max_m_attack
end

function Human_obj:get_ice_ak_t()
	return self.attr_list.ice_attack
end


function Human_obj:get_poison_ak_t()
	return self.attr_list.poison_attack
end


function Human_obj:get_fire_de_t()
	return self.attr_list.fire_defense
end

function Human_obj:get_ice_de_t()
	return self.attr_list.ice_defense
end

function Human_obj:get_poison_de_t()
	return self.attr_list.poison_defense
end

function Human_obj:get_damage_add_t(obj_d, skill_cmd)
	if self:get_level() < MAGIC_SKILL_EFFECT_MIN_LEVEL then
		return {0, 0}
	end
	local damage = self:get_magic_con():get_damage_add(obj_d, skill_cmd)
	return damage or {0,0}
end

function Human_obj:get_damage_sub_t(obj_s, skill_cmd)
	if self:get_level() < MAGIC_SKILL_EFFECT_MIN_LEVEL then
		return {0, 0}
	end
	local damage = self:get_magic_con():get_damage_sub(obj_s, skill_cmd)
	return damage or {0,0}
end

function Human_obj:get_s_defense_t()
	return self.s_defense
end

function Human_obj:get_m_defense_t()
	return self.m_defense
end

function Human_obj:get_intelligence_t()
	return self.attr_list.intelligence
end

function Human_obj:get_point_t()
	return self.attr_list.point
end

function Human_obj:get_dodge_t()
	return self.attr_list.dodge
end


function Human_obj:get_critical_t()
	return self.attr_list.critical
end

function Human_obj:get_critical_df_t()
	return self.attr_list.critical_df or 0
end

function Human_obj:get_critical_ef_t()
	return self.attr_list.critical_ef
end

function Human_obj:get_d_critical_ef_t()
	return self.attr_list.critical_d_ef
end

function Human_obj:get_strengh_t()
	return self.attr_list.strengh
end


function Human_obj:get_type()
	return OBJ_TYPE_HUMAN
end

function Human_obj:get_id()
	return self.char_id
end

function Human_obj:passive_sub_attr(obj_d)
	local sub = obj_d:get_skill_con():get_skill_sub()
	self.hp = self.hp * (1 - sub[1])
	self.mp = self.mp * (1 -sub[2])
	self.s_defense = self.s_defense * (1-sub[5])
	self.m_defense = self.m_defense * (1 - sub[6])
	self.min_m_attack = self.min_m_attack *(1 - sub[4])
	self.max_m_attack = self.max_m_attack *(1 - sub[4])
	self.min_s_attack = self.min_s_attack *(1 - sub[3])
	self.max_s_attack = self.max_s_attack *(1 - sub[3])
end

function Human_obj:get_skill_con()
	--if self.human_skill_con == nil then
		--self.human_skill_con
	--end

	return self.human_skill_con
end

function Human_obj:get_skill_attr(index)
	local skill_attr = self.human_skill_con:get_skill_attr()
	return skill_attr[index] or 0
end

--同步更新
function Human_obj:update_list(pkt)
	self.attr_list = pkt.attr
	self.hp = pkt.attr.hp
	self.mp = pkt.attr.mp
	self.fight = pkt.fighting
	self.show = pkt.show
	self:load_skill_con()
	self:get_skill_con():update_skill_list(pkt.skill_l)
	self:get_magic_con():update_skill_list(pkt.mk_skill)

	self.s_defense = pkt.attr.s_defense * (1+self:get_skill_attr(5))
	self.m_defense = pkt.attr.m_defense * (1+self:get_skill_attr(6))
	self.min_m_attack = pkt.attr.min_m_attack * (1+self:get_skill_attr(4))
	self.max_m_attack = pkt.attr.max_m_attack * (1+self:get_skill_attr(4))
	self.min_s_attack = pkt.attr.min_s_attack * (1+self:get_skill_attr(3))
	self.max_s_attack = pkt.attr.max_s_attack * (1+self:get_skill_attr(3))
end

function Human_obj:load_skill_con()
	if self.human_skill_con == nil then
		self.human_skill_con = Human_skill_container(self.char_id)
		self.human_skill_con:load()
	end

	if self.magic_skill_con == nil then
		self.magic_skill_con = Human_skill_magic_container(self.char_id)
		self.magic_skill_con:load()
	end
end

function Human_obj:load()
	self:load_skill_con()
	
	local db = f_get_db()
	local data = "{attr:1,fighting:1,show:1,skill_l:1,mk_skill:1}"
	local condition = string.format("{char_id:%d}", self.char_id)
	local row, e_code = db:select_one("player_attr",data,condition)
	if 0 == e_code and row then
		local skill_l = row.skill_l
		local mk_skill = row.mk_skill
		local attr = row.attr
		self.show = row.show
		self.attr_list = row.attr
		self.fight = row.fighting
		self.hp = row.attr.hp
		self.mp = row.attr.mp

		self.human_skill_con = Human_skill_container(self.char_id)
		self.human_skill_con:update_skill_list(skill_l)

		self.magic_skill_con = Human_skill_magic_container(self.char_id)
		self.magic_skill_con:update_skill_list(mk_skill)

		self.s_defense = row.attr.s_defense * (1+self:get_skill_attr(5))
		self.m_defense = row.attr.m_defense * (1+self:get_skill_attr(6))
		self.min_m_attack = row.attr.min_m_attack * (1+self:get_skill_attr(4))
		self.max_m_attack = row.attr.max_m_attack * (1+self:get_skill_attr(4))
		self.min_s_attack = row.attr.min_s_attack * (1+self:get_skill_attr(3))
		self.max_s_attack = row.attr.max_s_attack * (1+self:get_skill_attr(3))
	else
		--self.hp = self.attr_list.hp
		--self.mp = self.attr_list.mp
		--self.s_defense = self.attr_list.s_defense * (1+self:get_skill_attr(5))
		--self.m_defense = self.attr_list.m_defense * (1+self:get_skill_attr(6))
		--self.min_m_attack = self.attr_list.min_m_attack * (1+self:get_skill_attr(4))
		--self.max_m_attack = self.attr_list.max_m_attack * (1+self:get_skill_attr(4))
		--self.min_s_attack = self.attr_list.min_s_attack * (1+self:get_skill_attr(3))
		--self.max_s_attack = self.attr_list.max_s_attack * (1+self:get_skill_attr(3))
	end
end

function Human_obj:reset_hp_mp()
	if table.size(self.attr_list) == 0 then
		self:load()
	else
		self.hp = self.attr_list.hp
		self.mp = self.attr_list.mp
		self.s_defense = self.attr_list.s_defense * (1+self:get_skill_attr(5))
		self.m_defense = self.attr_list.m_defense * (1+self:get_skill_attr(6))
		self.min_m_attack = self.attr_list.min_m_attack * (1+self:get_skill_attr(4))
		self.max_m_attack = self.attr_list.max_m_attack * (1+self:get_skill_attr(4))
		self.min_s_attack = self.attr_list.min_s_attack * (1+self:get_skill_attr(3))
		self.max_s_attack = self.attr_list.max_s_attack * (1+self:get_skill_attr(3))
	end
end


function Human_obj:get_attr_list()
	
	local ret = {}
	ret[1] = self.attr_list.hp
	ret[2] = self.attr_list.mp
	ret[3] = self.attr_list.strengh
	ret[4] = self.attr_list.intelligence
	ret[5] = self.attr_list.stemina
	ret[6] = self.attr_list.dexterity
	ret[7] = math.floor(self.attr_list.critical_ef)
	ret[8] = math.floor(self.s_defense)
	ret[9] = math.floor(self.m_defense)
	ret[10] = {math.floor(self.min_s_attack),math.floor(self.max_s_attack)}
	ret[11] = {math.floor(self.min_m_attack),math.floor(self.max_m_attack)}
	ret[12] = self.attr_list.fire_attack
	ret[13] = self.attr_list.poison_attack
	ret[14] = self.attr_list.ice_attack
	ret[15] = self.attr_list.fire_defense
	ret[16] = self.attr_list.poison_defense
	ret[17] = self.attr_list.ice_defense
	ret[18] = self.attr_list.critical
	ret[19] = self.attr_list.dodge
	ret[20] = self.attr_list.point
	ret[21] = self.attr_list.element_defense_ef
	ret[22] = self:get_d_critical_ef_t()
	ret[23] = g_player_mgr.all_player_l[self.char_id].char_nm
	ret[24] = g_player_mgr.all_player_l[self.char_id].level
	ret[25] = g_player_mgr.all_player_l[self.char_id].gender
	ret[26] = g_player_mgr.all_player_l[self.char_id].occ
	ret[27] = self.show

	return ret
end




