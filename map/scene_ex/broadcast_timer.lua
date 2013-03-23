require("min_heap")

Broadcast_timer = oo.class(nil, "Broadcast_timer")

function Broadcast_timer:__init()
	self.min_heap = Min_heap()
end

function Broadcast_timer:add_broadcast(time, text, type)
	return self.min_heap:push(time, {text, type})
end

function Broadcast_timer:del_broadcast(id)
	self.min_heap:erase(id)
end

function Broadcast_timer:clear()
	self.min_heap:clear()
end

function Broadcast_timer:on_timer()
	local now = ev.time
	while not self.min_heap:is_empty() do
		local o = self.min_heap:top()
		if o.key > ev.time then
			break
		end
		self.min_heap:pop()
		local msg = {}
		f_construct_content(msg, o.value[1], 16)
		if 0 == o.value[2] then
			f_cmd_sysbd(msg)
		else
			f_cmd_linebd(msg)
		end
	end
end