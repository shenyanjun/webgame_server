----2011-10-26
--chenxidu
--婚姻系统单条item


Marry_item = oo.class(nil, "Marry_item")

function Marry_item:__init(param_l)
	self.char_id = param_l.char_id
	self.tm = param_l.tm or (ev.time + 3600 * 24 * 7 )	
	self.ts = param_l.ts 
	self.tz = param_l.tz
end

function Marry_item:is_expiredtime()
	return self.tm < ev.time
end

--征婚信息是否到了时间删除  7 天
function Marry_item:is_expired()
	if self.tm < ev.time then
		return true
	end
	return false
end