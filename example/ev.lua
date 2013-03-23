function on_read(so)
	if not so.buf:recv(so) then 
		so:Destroy()
		return
	end
	ev:watch(so, ev.EV_WRITE, ev.EV_READ)
end

function on_write(so)
	if not so.buf:send(so) then
		so:Destroy()
		return
	end
	if so.buf:size() > 0 then
		return
	end
	local buf = so.buf
	buf:append("1234567890")
	ev:watch(so, ev.EV_READ, ev.EV_WRITE)
end
function on_close(so)
	so:Destroy()
end

function on_accept(so)
	local s,peer = so:accept()
	if not s then return end
	print("accept connection from", peer)
	local buf = buffer:New(s)
	buf:append("BEGIN")
	buf:append("1234567890")
	buf:append('END')
	s.buf = buf
	s.on_write = on_write
	s.on_read = on_read
	s.on_close = on_close
	ev:watch(s, ev.EV_READ, 0)
end

function run_gc()
	print("starting gc")
	collectgarbage("step", 10)
	ev:timeout(10, run_gc)
end

function sig_int(sig)
	print("\nSIGINT")
	ev:stop()
end

so = socket:New()
if not so:listen("192.168.1.243", 9000) then
	os.exit(0)
end
so.on_read = on_accept

ev:timeout(10, run_gc)
ev:watch(so, ev.EV_READ, 0)
ev:signal(2, sig_int)
ev:start()
