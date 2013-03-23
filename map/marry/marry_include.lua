--2011-10-26
--chenxidu
--婚姻系统头文件及定义

require("marry.marry")
require("marry.marry_process")
g_marry_mgr = Marry()


function f_marry_error_log(fmt, ...)
	local err_msg = string.format(" Error: %s", string.format(tostring(fmt), ...))
	g_marry_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end
