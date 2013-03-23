function on_read(so)
	buf = buffer:New(so)
	if not buf:recv(so) then
		ev:stop()
	end
	io.write(tostring(buf))
end

function on_write(so)
	so.buf:send(so)
	if (so.buf:size() == 0) then
		ev:watch(so, ev.EV_READ, ev.EV_WRITE)
	end
end
function on_close(so)
	ev:stop()
end

local so = socket:New()
so.on_read = on_read
so.on_write = on_write
so.on_close = on_close
so.buf = buffer:New(so)
so.buf:append("GET / HTTP/1.0\r\nHost: www.google.com\r\n\r\n");
if so:connect("www.google.com", 80) then
	ev:watch(so, ev.EV_WRITE, 0)
else
	print("cannot connect to host")
	os.exit()
end

ev:start()
