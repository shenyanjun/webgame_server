
Ai_time = oo.class(nil, "Ai_time")

function Ai_time:__init(sec)
	self.sec = sec
	self.start = ev.time
end

function Ai_time:is_time()
	if os.time() >= self.start + self.sec then
		self.start = ev.time
		return true
	end
	return false
end

function Ai_time:set_time(sec)
	self.sec = sec
	self.start = ev.time
end
