local gobang_config = require("scene_ex.config.gobang_config_loader")
local expr = require("config.expr")
local _random = crypto.random

local lu_pos = {24, 39}
local box_pos = {31, 46}
local joint_lenght = 5		--连续的棋子个数
local chessboard_size = 6	--棋盘大小
local pos_step = 3
local pos_list = {}
for i = 1, chessboard_size do
	pos_list[i] = {}
	local pos = {lu_pos[1],  lu_pos[2] + (i - 1) * pos_step}
	for j = 1, chessboard_size do
		pos_list[i][j] = {pos[1] + (j - 1) * pos_step, pos[2]}
	end
end

Gobang = oo.class(nil, "Gobang")
function Gobang:__init(joint_lenght, chessboard_size)

	self.joint_lenght = joint_lenght or 5	--连续的棋子个数
	self.chessboard_size = chessboard_size >= joint_lenght and chessboard_size or joint_lenght --棋盘大小

	self.pieces = {}
	for i = 1, self.chessboard_size do
		self.pieces[i] = {}
		for j = 1, self.chessboard_size do
			self.pieces[i][j] = 0	-- 0为空，1为黑，2为白
		end
	end
end


local _empty_list = {}
for i = 1, chessboard_size do
	for j = 1, chessboard_size do
		table.insert(_empty_list, {i, j})
	end
end
function Gobang:create_full_board()

	--local empty_list = {}
	for i = 1, self.chessboard_size do
		self.pieces[i] = {}
		for j = 1, self.chessboard_size do
			self.pieces[i][j] = 0	-- 0为空，1为黑，2为白
			--table.insert(empty_list, {i, j})
		end
	end
	--self:insert_piece_list_ex(empty_list)
	self:insert_piece_list_ex(_empty_list)
end

function Gobang:insert_piece_list_ex(empty_list)
	for i = 1, 5 do 
		if self:insert_piece_list(empty_list) then
			break
		end
	end
end

function Gobang:insert_piece_list(empty_list)
	local list_len = #empty_list
	local now_pos = 1
	local backtrace = nil
	local i, j
	while now_pos <= list_len do
		--print("while:", now_pos, list_len)
		i = empty_list[now_pos][1]
		j = empty_list[now_pos][2]
		if now_pos == backtrace then
			local r = self:get_piece_color(i, j)
			r = r == 1 and 2 or 1
			if self:insert_piece(i, j, r) then
				--print("backtrace 1", i, j, r, backtrace)
				self.pieces[empty_list[backtrace][1]][empty_list[backtrace][2]] = 0
				backtrace = backtrace - 1
				if backtrace < 1 then
					print("warning: Gobang:insert_piece_list 1")
					return false
				end
				now_pos = backtrace
			else
				now_pos = now_pos + 1
			end
		else
			local r = _random(1, 101)
			if r <= 50 then
				r = 1
			else
				r = 2
			end
			
			if self:insert_piece(i, j, r) then
				if self:insert_piece(i, j, r == 1 and 2 or 1) then
					if backtrace == nil then
						backtrace = now_pos
					end
					for cl = backtrace, now_pos do
						self.pieces[empty_list[cl][1]][empty_list[cl][2]] = 0
					end
					--print("backtrace 2", i, j, r, backtrace)
					backtrace = backtrace - 1
					if backtrace < 1 then
						print("warning: Gobang:insert_piece_list 2")
						return false
					end
					now_pos = backtrace
				else
					now_pos = now_pos + 1
				end
			else
				now_pos = now_pos + 1
			end
		end
	end
	return true
end

function Gobang:get_piece_color(i, j)
	return self.pieces[i][j]
end

function Gobang:set_piece_color(i, j, c)
	self.pieces[i][j] = c
end

function Gobang:get_piece_color_list()
	return self.pieces
end

function Gobang:clear_piece_list(empty_list)
	local list_len = #empty_list
	local now_pos = 1
	local i, j
	while now_pos <= list_len do
		--print("while:", now_pos, list_len)
		i = empty_list[now_pos][1]
		j = empty_list[now_pos][2]
		self.pieces[i][j] = 0
		now_pos = now_pos + 1
	end
end

--在i行j列插入c色的棋子，返回true表示有连续的棋子, nil表示没有
function Gobang:insert_piece(i, j, c)
	--print("Gobang:insert_piece:", i, j, c)
	--self:check_border(i)
	--self:check_border(j)
	self.pieces[i][j] = c

	local ret = {}
	local is_t = nil --是否有连棋
	local l = j - self.joint_lenght + 1 > 0 and j - self.joint_lenght + 1 or 1
	local r = j + self.joint_lenght - 1 < self.chessboard_size and j + self.joint_lenght - 1 or self.chessboard_size
	local count = 0
	for jj = l, r do
		if self.pieces[i][jj] == c then
			count = count + 1
			if count == self.joint_lenght then
				is_t = true
				for j2 = jj - count + 1, jj do
					table.insert(ret, {i, j2})
				end
			elseif count > self.joint_lenght then
				table.insert(ret, {i, jj})
			end
		else
			if count >= self.joint_lenght then
				break
			end
			count = 0
		end
	end
	--
	local u = i - self.joint_lenght + 1 > 0 and i - self.joint_lenght + 1 or 1
	local d = i + self.joint_lenght - 1 < self.chessboard_size and i + self.joint_lenght - 1 or self.chessboard_size
	count = 0
	for ii = u, d do
		if self.pieces[ii][j] == c then
			count = count + 1
			if count == self.joint_lenght then
				for i2 = ii - count + 1, ii do
					if not is_t or i2 ~= i then
						table.insert(ret, {i2, j})
					end
				end
				is_t = true
			elseif count > self.joint_lenght then
				table.insert(ret, {ii, j})
			end
		else
			if count >= self.joint_lenght then
				break
			end
			count = 0
		end
	end
	--
	local lu = math.min(i - u, j - l)
	local rd = math.min(d - i, r - j)
	local xl = lu + rd + 1
	count = 0
	if xl >= self.joint_lenght then
		for x = 0, xl - 1 do
			if self.pieces[i - lu + x][j - lu + x] == c then
				count = count + 1
				if count == self.joint_lenght then
					for temp = count - 1, 0, -1 do
						if not is_t or i - lu + x - temp ~= i or j - lu + x - temp ~= j then
							table.insert(ret, {i - lu + x - temp, j - lu + x - temp})
						end
					end
					is_t = true
				elseif count > self.joint_lenght then
					table.insert(ret, {i - lu + x, j - lu + x})
				end
			else
				if count >= self.joint_lenght then
					break
				end
				count = 0
			end
		end
	end
	--
	local ld = math.min(d - i, j - l)
	local ru = math.min(i - u, r - j)
	--print("border:", l,r,u,d, lu, rd, ld, ru)
	xl = ld + ru + 1
	count = 0
	if xl >= self.joint_lenght then
		for x = 0, xl - 1 do
			if self.pieces[i + ld - x][j - ld + x] == c then
				count = count + 1
				if count == self.joint_lenght then
					for temp = count - 1, 0, -1 do
						if not is_t or i + ld - x - temp ~= i or j - ld + x - temp ~= j then
							table.insert(ret, {i + ld - x + temp, j - ld + x - temp})
						end
					end
					is_t = true
				elseif count > self.joint_lenght then
					table.insert(ret, {i + ld - x, j - ld + x})
				end
			else
				if count >= self.joint_lenght then
					break
				end
				count = 0
			end
		end
	end

	return is_t and ret
end

function Gobang:check_border(i)
	if i <= 0 or i > self.chessboard_size then
		print("error chessboard_size:", self.chessboard_size, i)
	end
end

function Gobang:print_board()
	for i = 1, self.chessboard_size do
		local str = string.format("%d\t", i)
		for j = 1, self.chessboard_size do
			str = str .. "%d  "
			str = string.format(str, self.pieces[i][j])
		end
		print(str)
	end
end

function Gobang:find_joint(lenght)
	local joint_lenght = lenght or self.joint_lenght
	local f = {}
	for i = 1, self.chessboard_size do
		local t1 = 1
		local c = self.pieces[i][1]
		for j = 2, self.chessboard_size do
			if c == self.pieces[i][j] then
				t1 = t1 + 1
				if t1 >= joint_lenght then
					print("joint 1", i, j, t1)
					break
				end
			else
				t1 = 1
				c = self.pieces[i][j]
			end
		end
	end
	--
	for i = 1, self.chessboard_size do
		local t1 = 1
		local c = self.pieces[1][i]
		for j = 2, self.chessboard_size do
			if c == self.pieces[j][i] then
				t1 = t1 + 1
				if t1 >= joint_lenght then
					print("joint 2", j, i, t1)
					break
				end
			else
				t1 = 1
				c = self.pieces[j][i]
			end
			
		end
	end

	for i = 1, self.chessboard_size do
		local t1 = 0
		local c = nil
		for j = 1, self.chessboard_size - i + 1 do
			if c == self.pieces[i + j - 1][j] then
				t1 = t1 + 1
				if t1 >= joint_lenght then
					print("joint 31", i + j - 1, j, t1)
					break
				end
			else
				t1 = 1
				c = self.pieces[i + j - 1][j]
			end
		end
	end
	--
	for j = 2, self.chessboard_size do
		local t1 = 0
		local c = nil
		for i = 1, self.chessboard_size - j + 1 do
			if c == self.pieces[i][j + i - 1] then
				t1 = t1 + 1
				if t1 >= joint_lenght then
					print("joint 31", i, j + i - 1, t1)
					break
				end
			else
				t1 = 1
				c = self.pieces[i][j + i - 1]
			end
		end
	end
	--
	for i = self.chessboard_size, 1, -1 do
		local t1 = 0
		local c = nil
		for j = 1, i do
			if c == self.pieces[i - j + 1][j] then
				t1 = t1 + 1
				if t1 >= joint_lenght then
					print("joint 41", i - j + 1, j, t1)
					break
				end
			else
				t1 = 1
				c = self.pieces[i - j + 1][j]
			end
		end
	end
	--
	for j = 2, self.chessboard_size do
		local t1 = 0
		local c = nil
		for i = self.chessboard_size, j - 1, -1 do
			if c == self.pieces[i][j + self.chessboard_size - i] then
				t1 = t1 + 1
				if t1 >= joint_lenght then
					print("joint 42", i, j + self.chessboard_size - i, t1)
					break
				end
			else
				t1 = 1
				c = self.pieces[i][j + self.chessboard_size - i]
			end
		end
	end
end


---------------------------------
Scene_gobang = oo.class(Scene_instance, "Scene_gobang")

function Scene_gobang:__init(map_id, instance_id, map_obj)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.end_time = -1
	self.close_time = nil
	self.start_time = ev.time
	self.show_time = ev.time + 1000

	self.gobang = Gobang(5, 6)
	self.gobang_monster = {}
	self.monster_id_to_pos = {}
	for i = 1, chessboard_size do
		self.gobang_monster[i] = {}
	end
	self.wait_create = {}
	self.joint_count = 0
	self.point = 0
end

--
function Scene_gobang:get_self_config()
	return gobang_config.config[self.id]
end

function Scene_gobang:get_self_limit_config()
	return self:get_self_config().init.limit
end

--副本出口
function Scene_gobang:get_home_carry(obj)
	local config = self:get_self_config()
	local home_carry = config and config.init.home
	if not home_carry or not home_carry.id
		or not home_carry.pos or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end

function Scene_gobang:carry_scene(obj, pos)
	local config = self:get_self_config()
	local new_pos = config.init.entry
	return Scene_instance.carry_scene(self, obj, {new_pos[1], new_pos[2]})
end
--
function Scene_gobang:on_timer(tm)
	local now = ev.time
	if (self.end_time > 0 and self.end_time <= now) then
		self.end_time = -1
		self.close_time = ev.time + 60
		self:to_end()
		return
	end
	if (self.close_time and self.close_time <= now) then
		self:close()
		return
	end
	
	if self.show_time <= ev.time and not self.is_end then
		
		if self.new_list then
			self.joint_count = self.joint_count + math.ceil(#self.new_list / 6)
			local r_c1, r_c2 = 0, 0
			local temp_test = {}
			local obj_mgr = g_obj_mgr
			--local pkt = {}
			--pkt.id_list = {}
			self.gobang:clear_piece_list(self.new_list)
			self.gobang:insert_piece_list_ex(self.new_list)
			local pieces = self.gobang:get_piece_color_list()
			for k, v in pairs(self.new_list) do
				local i, j = v[1], v[2]
				local r = _random(1, 101)
				if r <= 50 then
					r = 1
					r_c1 = r_c1 + 1
					if r_c1 >= 4 then
						r = 2
						r_c1 = 0
					end
				else
					r = 2
					r_c2 = r_c2 + 1
					if r_c2 >= 4 then
						r = 1
						r_c2 = 0
					end
				end
				self.gobang:set_piece_color(i, j, r)
				--
				
				local pos = pos_list[i][j]
				--local c = pieces[i][j]
				local monster_id = self.gobang_monster[i][j]
				local old = obj_mgr:get_obj(monster_id)
				if old then
					old:leave()
					self.monster_id_to_pos[monster_id] = nil
					--table.insert(pkt.id_list, monster_id)
				end
				local obj_id = self:create_piece(pos, r)
				self.gobang_monster[i][j] = obj_id
				self.monster_id_to_pos[obj_id] = {i, j}
			end
			--g_cltsock_mgr:send_client(self.char_id, CMD_MAP_GOBANG_LEAVE_ID_S, pkt)
			--for k, v in pairs(pkt.id_list) do
				--local old = obj_mgr:get_obj(v)
				--if old then
					--old:leave()
				--end
			--end
			--
			local new_list = {}
			for k, v in pairs(self.new_list) do
				local i, j = v[1], v[2]
				
				local c = pieces[i][j]
				local list = self.gobang:insert_piece(i, j, c)				
				if list then
					--print(" hey had now ")
					for k, v in ipairs(list) do
						if temp_test[v[1]] == nil or temp_test[v[1]][v[2]] == nil then
							table.insert(new_list, v)
							if temp_test[v[1]] == nil then
								temp_test[v[1]] = {}
							end
							temp_test[v[1]][v[2]] = 1
						end
					end
				end
			end
			if not table.is_empty(new_list) then
				self.new_list = new_list
				self.show_time = ev.time + 2
				--self.joint_count = self.joint_count + math.floor(#new_list / 6)
			else
				self.new_list = nil
				self.show_time = ev.time + 2000
				--
				self.point = math.floor(10 * self.joint_count * math.max(1, self.joint_count * 0.55)) + self.point
				g_cltsock_mgr:send_client(self.char_id, CMD_MAP_GOBANG_SCORE_S, {["score"] = self.point})
				self.joint_count = 0
				--print(" point =", self.point)
			end
		end

		if self.new_list == nil then
			self.joint_count = 0
			while true do
				local e = table.remove(self.wait_create, 1)
				if e ~= nil then
					--print(" remove monster")
					local i, j = e[1], e[2]
					local pos = pos_list[i][j]
					local c = self.gobang:get_piece_color(i, j)
					local obj_id = self:create_piece(pos, c)
					self.gobang_monster[i][j] = obj_id
					self.monster_id_to_pos[obj_id] = {i, j}
					--print("self.gobang:insert_piece",i, j, c)
					local list = self.gobang:insert_piece(i, j, c)
					if list ~= nil then
						if self.new_list == nil then self.new_list = {} end
						for k, v in pairs(list) do
							table.insert(self.new_list, v)
						end
					end
					
					
				else
					break
				end
			end
		end

		if self.new_list == nil then
			self.joint_count = 0	
			self.show_time = ev.time + 1000
		end
	end
	--self.obj_mgr:on_timer(tm)

end

function Scene_gobang:carry_scene(obj, pos)
	--print("Scene_gobang:carry_scene")
	local obj_id = obj:get_id()
	if self.char_id ~= nil and self.char_id ~= obj_id then
		return SCENE_ERROR.E_EXISTS_COPY
	end
	local config = self:get_self_config()
	local new_pos = config.init.entry
	return Scene_instance.carry_scene(self, obj, new_pos)
end

function Scene_gobang:instance()
	local config = self:get_self_limit_config()
	self.end_time = ev.time + config.time
	self.class_type = config.class
	if self.class_type == 1 then
		self.check_close_time = ev.time + 60
	end

	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())


	self:init_random_pieces()
end

function Scene_gobang:create_piece(pos, c)
	--print("Scene_gobang:create_piece:", j_e(pos), c)
	if pos then
		local id = c == 1 and 1191 or 1192
		local obj = g_obj_mgr:create_monster(id, pos, self.key)
		if obj and SCENE_ERROR.E_SUCCESS == self:enter_scene(obj) then
			return obj:get_id()
		end
	end
end

function Scene_gobang:init_random_pieces()
	self.gobang = Gobang(joint_lenght, chessboard_size)
	self.gobang:create_full_board()
	local pieces = self.gobang:get_piece_color_list()
	for i = 1, chessboard_size do
		for j = 1, chessboard_size do
			local pos = pos_list[i][j]
			local c = pieces[i][j]
			local obj_id = self:create_piece(pos, c)
			self.gobang_monster[i][j] = obj_id
			self.monster_id_to_pos[obj_id] = {i, j}
		end
	end
end

function Scene_gobang:on_obj_enter(obj)
	if obj:get_type() == OBJ_TYPE_HUMAN then
		local obj_id = obj:get_id()
		g_scene_mgr_ex:register_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id, self, self.kill_monster_event)
		self.char_id = obj_id
	end
end

function Scene_gobang:on_obj_leave(obj)
	local obj_id = obj:get_id()
	if obj:get_type() == OBJ_TYPE_HUMAN then
		g_scene_mgr_ex:unregister_event(EVENT_SET.EVENT_KILL_MONSTER, obj_id)

	elseif obj:get_type() == OBJ_TYPE_MONSTER then
		
	end
end

function Scene_gobang:kill_monster_event(monster_occ, obj_id, monster_id)
	--print("kill_monster_event:", monster_occ, obj_id, monster_id)
	
	local pos = self.monster_id_to_pos[monster_id]
	if pos then
		local c = self.gobang:get_piece_color(pos[1], pos[2]) == 1 and 2 or 1
		self.gobang:set_piece_color(pos[1], pos[2], c)
		--self.new_list = self.gobang:insert_piece(pos[1], pos[2], c)
		--if self.new_list == nil then
			table.insert(self.wait_create, pos)
		--else
			--print("self.new_list", j_e(self.new_list))
		--end
		local pos = self.monster_id_to_pos[monster_id]
		self.gobang_monster[pos[1]][pos[2]] = nil
		self.monster_id_to_pos[monster_id] = nil
		self.show_time = ev.time + 0.5
		--
		--self.gobang:print_board()
	end
end

function Scene_gobang:close()
	if self.instance_id then
		
		local data = {}
		local obj_mgr = g_obj_mgr
		local obj = obj_mgr:get_obj(self.char_id)
		if obj then
			table.insert(data, {["id"] = self.char_id, ["name"] = obj:get_name()})

			g_public_sort_mgr:update_record(
			PUBLIC_SORT_TYPE.SCENE
			, self.point
			, {["scene_id"] = self.id, ["id"] = 0, ["data"] = data}
			, PUBLIC_SORT_ORDER.DESC)
		end
		
		Scene_instance.close(self)
	end
end

function Scene_gobang:to_end()
	self.is_end = true
	local obj_mgr = g_obj_mgr
	for k, v in pairs(self.monster_id_to_pos) do
		local obj = obj_mgr:get_obj(k)
		local _ = obj and obj:leave()
	end

	local obj_h = obj_mgr:get_obj(self.char_id)
	local reward = self:get_self_config().reward
	for k, v in pairs(reward.exp.list) do
		if self.point >= v.point then
			local exp = math.floor(reward.exp.base * v.factor)
			local _ = obj_h and obj_h:add_exp(exp)
			break
		end
	end
	local owner_obj = g_obj_mgr:get_obj(self.char_id)
	for k, v in pairs(reward.box.list) do
		if self.point >= v.point and owner_obj then
			if v.occ1 then
				--print("create occ1:", v.occ1)
				--local obj = obj_mgr:create_monster(v.occ1, {box_pos[1] - 3, box_pos[2]-2}, self.key)
				local obj = expr.create_lost_boxs(owner_obj, false, v.occ1, {box_pos[1] - 3, box_pos[2]-2}, self.key)
				local _ = obj and self:enter_scene(obj) 
			end
			if v.occ2 then
				--print("create occ2:", v.occ2)
				--local obj2 = obj_mgr:create_monster(v.occ2, {box_pos[1], box_pos[2]+3}, self.key)
				local obj2 = expr.create_lost_boxs(owner_obj, false, v.occ2, {box_pos[1], box_pos[2]+3}, self.key)
				local _ = obj2 and self:enter_scene(obj2) 
			end
			if v.occ3 then
				--print("create occ3:", v.occ3)
				--local obj3 = obj_mgr:create_monster(v.occ3, {box_pos[1] + 3, box_pos[2]-2}, self.key)
				local obj3 = expr.create_lost_boxs(owner_obj, false, v.occ3, {box_pos[1] + 3, box_pos[2]-2}, self.key)
				local _ = obj3 and self:enter_scene(obj3)
			end
			g_cltsock_mgr:send_client(self.char_id, CMD_MAP_COPY_END_S, {})
			break
		end
	end
	--写流水
	local obj = g_obj_mgr:get_obj(self.char_id)
	local str = string.format("insert log_gobang set char_id=%d, char_name='%s', level=%d, score=%d, time=%d",
					self.char_id, obj and obj:get_name() or "", obj and obj:get_level() or 1, self.point, ev.time)
	--print(str)
	g_web_sql:write(str)
	--
	local args = {}
	args.point = self.point
	g_event_mgr:notify_event(EVENT_SET.EVENT_GOBANG, self.char_id, args)
end