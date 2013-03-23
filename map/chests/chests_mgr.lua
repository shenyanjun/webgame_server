


Chests_mgr = oo.class(nil, "Chests_mgr")

function Chests_mgr:__init()
	self.chests_list = {}
end

function Chests_mgr:get_chests(char_id)
    if self.chests_list[char_id] == nil then
        self.chests_list[char_id] = Chests_func()
		self.chests_list[char_id]:chests_player_record_init(char_id)
    end
	return self.chests_list[char_id]
end
