
--************可序列化的类，可以转化为json对象，不能用int做key*************

Cd_time = oo.class(nil, "Cd_time")

function Cd_time:__init(skill_id, obj_id, sec)
	self.obj_id = obj_id
	self.skill_id = skill_id
	self.tm_start = 0            --开始时间
	self.tm_sec = sec or 0           --持续秒数
	self.status = true           --false不可使用，true可使用
end

function Cd_time:clone(item, sec)
	item = setmetatable(item, getmetatable(self))
	if item.tm_start + item.tm_sec <= ev.now then
		return Cd_time(item.skill_id, item.obj_id, sec)
	end
	item.tm_sec = sec         --被动技能会改变cd时间
	return item
end

function Cd_time:set_cd_time(sec)
	sec = sec > 0 and sec or 0
	self.tm_sec = sec
end
function Cd_time:get_cd_time()
	return self.tm_sec
end

function Cd_time:get_last_time()
	local num = self.tm_start + self.tm_sec
	num = math.max(num - ev.now, 0)
	if num <= 0 then
		self.status = true
	end
	return num
end

function Cd_time:is_save()
	if self.tm_start + self.tm_sec >= ev.now + 15 and 
		Obj_mgr.obj_type(self.obj_id) == OBJ_TYPE_HUMAN then
		return true
	end
	return false
end

function Cd_time:use()
	self.status = false
	self.tm_start = ev.now
	--self.tm_ustart = crypto.timeofday()
end

--允许1秒的误差
function Cd_time:get_status()
	local d = self.tm_sec > 1 and 1 or 0.5
	if not self.status then
		--local num = os.time()+crypto.timeofday() - self.tm_start - self.tm_ustart + d
		local num = ev.now - self.tm_start + d
		if num >= self.tm_sec then
			self.status = true
		end
	end
	return self.status
end
function Cd_time:set_status(b_st)
	self.status = b_st
end

