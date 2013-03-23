
local debug_print = print
--local debug_print = function() end

--[[function InitNpcScene(npc_id, map_id, pos_list)
	if not NpcTable[npc_id] then
		debug_print("InitNpcScene Npc isn't exsit", npc_id)
		return
	end
	local t_InitScene = NpcTable[npc_id].InitScene
	NpcTable[npc_id].InitScene = function(self)
		if t_InitScene then
			t_InitScene(self)
		end
		self.scene[map_id] = {}
		self.scene[map_id].pos_list = pos_list
	end
end]]
