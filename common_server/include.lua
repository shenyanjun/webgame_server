

require("server_cmd_handler")
require("server_socket_handler")
require("server_mgr")



function f_error_log(fmt, ...)
	local err_msg = string.format(" Error: %s", string.format(tostring(fmt), ...))
	g_common_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

function f_warning_log(fmt, ...)
	local err_msg = string.format(" Warning: %s", string.format(tostring(fmt), ...))
	g_common_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

function f_info_log(fmt, ...)
	local err_msg = string.format(" Info: %s", string.format(tostring(fmt), ...))
	g_common_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end

function f_faction_log(fmt, ...)
	local err_msg = string.format(" Faction: %s", string.format(tostring(fmt), ...))
	g_faction_log:write(err_msg)
	debug_print(err_msg)
	return err_msg
end