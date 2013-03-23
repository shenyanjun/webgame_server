--答题任务，可以直接完成
local Quest_answer = oo.class(Quest_base, "Quest_answer")

function Quest_answer:on_complete(char_id, select_list, bonus)
	local status = self.status
	self.status = MISSION_STATUS_COMMIT
	
	local e_code, next_quest_chain = Quest_base.on_complete(self, char_id, select_list, bonus)
	if E_SUCCESS ~= e_code then
		self.status = status
	end
	
	return e_code, next_quest_chain
end

Mission_mgr.register_class(MISSION_FLAG_ANSWER, Quest_answer)