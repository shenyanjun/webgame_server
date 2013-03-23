

--怪物技能实现类
Skill_container_monster = oo.class(nil, "Skill_container_monster")

function Skill_container_monster:__init(obj_id)
	self.obj_id = obj_id  
	self.skill_obj_l = {}
end


function Skill_container_monster:get_skill_l()
	return self.skill_obj_l
end
function Skill_container_monster:get_skill(skill_id)
	return self.skill_obj_l[skill_id]
end
function Skill_container_monster:get_skill_obj(skill_id)
	if self.skill_obj_l[skill_id] ~= nil then
		return self.skill_obj_l[skill_id]["obj"]
	end
end
function Skill_container_monster:get_skill_cd(skill_id)
	if self.skill_obj_l[skill_id] ~= nil then
		return self.skill_obj_l[skill_id]["cd"]
	end
end


--成功返回0
function Skill_container_monster:use(skill_id, param)
	if skill_id == nil then return end

	--判断技能cd
	local cd = self:get_skill_cd(skill_id)
	local skill_o = self:get_skill_obj(skill_id)
	local mp
	if cd and skill_o and cd:get_status() then
		local obj = g_obj_mgr:get_obj(self.obj_id)
		if obj ~= nil then
			--判断能否使用技能
			if not obj:is_use_skill(skill_id) then
				return 
			end
			--
			if obj:get_type() == OBJ_TYPE_GHOST then
				mp = skill_o:get_expend_mp()
				if mp > obj:get_mp() then 
					return 21115
				end
			end

			local ret = skill_o:effect(self.obj_id, param)
			if ret == 0 then
				cd:use()
				--
				if obj:get_type() == OBJ_TYPE_GHOST then
					local _ = mp > 0 and obj:add_mp(-mp)
				end
			end
			return ret
		end
	end
	return 21116
end

function Skill_container_monster:add_skill_m(skill_id)
	local skill_o = g_skill_mgr:get_skill(skill_id)
	local cd = g_skill_mgr:create_cd(skill_id, self.obj_id)

	if self.skill_obj_l[skill_id] == nil then
		self.skill_obj_l[skill_id] = {}
		self.skill_obj_l[skill_id]["cd"] = cd
		self.skill_obj_l[skill_id]["obj"] = skill_o
	end
end

