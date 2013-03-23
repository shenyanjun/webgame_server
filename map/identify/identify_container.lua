

local config = require("config.identify_config")


Identify_container = oo.class(nil, "Identify_container")

function Identify_container:__init()

end

--进入
function Identify_container:enter_scene(args, char_id)
	if config._sence_config[args.map_id] then
		local pkt = {}
		pkt.map_id = args.map_id
		g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2C_IDENTIFY_PLAYER_ENTER_C, pkt)
	end
end

--离开
function Identify_container:leave_scene(args, char_id)
	if config._sence_config[args.map_id] then
		local pkt = {}
		pkt.map_id = args.map_id
		g_svsock_mgr:send_server_ex(COMMON_ID, char_id, CMD_M2C_IDENTIFY_PLAYER_LEAVE_C, pkt)
	end
end