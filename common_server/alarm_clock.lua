
Alarm_clock = oo.class(nil, "Alarm_clock")

function Alarm_clock:__init(tm)
	self.tm = tm or 1
	self.time_ret_l = {}
	self.alarm_list = {}
end

--obj:对象 proc:函数 slice:时间间隔 count:解发次数, nil为无限
function Alarm_clock:register(obj, proc, slice, count)
	if not obj or not proc or not slice then
		return nil
	end
	
	if count and count < 1 then
		return nil
	end
	
	local alarmer = {}
	alarmer.obj = obj
	alarmer.proc = proc
	alarmer.slice = slice
	alarmer.time = ev.time + alarmer.slice
	alarmer.count = count
	
	local index = table.freeindex(self.alarm_list)
	self.alarm_list[index] = alarmer
	return index
end
function Alarm_clock:unregister(id)
	self.alarm_list[id] = nil
end

function Alarm_clock:start()
	f_time_regster_3(self.tm, self.time_ret_l, "time_id", self.time_proc, self)
end

function Alarm_clock:time_proc()
	local now = ev.time
	for k, v in pairs(self.alarm_list) do
		if v.time <= now then					--已经超时
			v.proc(v.obj, v.time)
			v.count = v.count and (v.count - 1)
			if v.count and v.count <= 0 then
				self.alarm_list[k] = nil
			else
				v.time = now + v.slice
			end
		end
	end
end