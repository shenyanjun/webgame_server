--对话任务
local Quest_speak = oo.class(Quest_base, "Quest_speak")

function Quest_speak:on_accept(char_id)
	local e_code = Quest_base.on_accept(self, char_id)
	if E_SUCCESS == e_code then
		self:set_status(MISSION_STATUS_COMMIT)
	end
	return e_code
end

Mission_mgr.register_class(MISSION_FLAG_SPEAK, Quest_speak)