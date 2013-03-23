
if MUDRV_VERSION == nil then
	require("svsock_mgr")
else
	require("svsock_mgr_gcc")
end

Map_svsock_mgr = oo.class(Svsock_mgr, "Map_svsock_mgr")

function Map_svsock_mgr:__init(sv_list)
	Svsock_mgr.__init(self, sv_list)
end

function Map_svsock_mgr:on_add_servsock(sv_id, conn)
	if sv_id == COMMON_ID then
		local obj_l = g_obj_mgr:get_list(OBJ_TYPE_HUMAN)
		local new_pkt = {}
		new_pkt.line = SELF_SV_ID
		new_pkt.player_list = {}
		local count = 0
		for k,v in pairs(obj_l) do
			local t = {}
			t.obj_id = k
			t.char_nm = v:get_name()
			t.sex = v:get_sex()
			t.level = v:get_level()
			t.occ = v:get_occ()
			count = count + 1
			new_pkt.player_list[count] = t
		end
		new_pkt.count = count
		if new_pkt ~= nil then
			g_svsock_mgr:send_server_ex(sv_id,0,CMD_M2P_PLAYER_INFO_S, new_pkt)
		end
	end
end