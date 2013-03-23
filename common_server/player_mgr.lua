
Player_mgr = oo.class(nil, "Player_mgr")

function Player_mgr:__init()
	self.all_player_l = {}      	--所有玩家列表id-》info
	self.all_player_nm_l = {}  		--所有玩家列表name-》id

	--在线玩家
	self.online_player_l = {}
	
	--不在线玩家属性
	self.ouline_player_attr_l = {}

	--线玩家列表
	self.line_player = {}
end

function Player_mgr:load()
	--加载数据库所有玩家
	local dbh = f_get_db()
	local query = nil --string.format("{del_flag:%d}",0)
	local data = "{id:1,name:1,class:1,level:1,gender:1, qlevel:1, account_name:1}"

	--local str = string.format("select id,name,class,level,gender from characters where flag =0")
	local row, err_code = dbh:select("characters",data, query)
	if err_code == 0 then
		for k,v in pairs(row or {}) do
			self.all_player_l[v.id] = {}
			self.all_player_l[v.id]["occ"] = v.class
			self.all_player_l[v.id]["char_nm"] = v.name
			self.all_player_l[v.id]["level"] = v.level
			self.all_player_l[v.id]["gender"] = v.gender
			self.all_player_l[v.id]["qlevel"] = v.qlevel
			self.all_player_l[v.id]["account_name"] = v.account_name
			self.all_player_nm_l[v.name]  = v.id
		end
	end
end

--改名
function Player_mgr:change_name(char_id,name)
	if self.all_player_l[char_id] ~= nil then
		self.all_player_l[char_id]["char_nm"] = name
		self.all_player_nm_l[name] = char_id
	end

	if self.online_player_l[char_id] ~= nil then
		self.online_player_l[char_id]["char_nm"] = name
	end
end

--转职
function Player_mgr:change_occ(char_id,occ)
	if self.all_player_l[char_id] ~= nil then
		self.all_player_l[char_id]["occ"] = occ
	end

	if self.online_player_l[char_id] ~= nil then
		self.online_player_l[char_id]["occ"] = name
	end
end

--转性
function Player_mgr:change_gender(char_id,gender)
	if self.all_player_l[char_id] ~= nil then
		self.all_player_l[char_id]["gender"] = gender
	end
end

function Player_mgr:join_in(char_id, pkt, line)
	--print("Player_mgr:join_in", char_id, j_e(pkt), line)
	--所有玩家
	--if self.all_player_l[char_id] == nil then
		self.all_player_l[char_id] = {}
		self.all_player_l[char_id]["char_nm"] = pkt.char_nm
		self.all_player_l[char_id]["occ"] = pkt.occ
		self.all_player_l[char_id]["level"] = pkt.level
		self.all_player_l[char_id]["gender"] = pkt.sex
		self.all_player_l[char_id]["qlevel"] = pkt.qlevel
		self.all_player_l[char_id]["account_name"] = pkt.account_name
		self.all_player_nm_l[pkt.char_nm] = char_id
	--end

	--在线玩家
	self.online_player_l[char_id] = {}
	self.online_player_l[char_id]["char_nm"] = pkt.char_nm
	self.online_player_l[char_id]["line"] = line 
	self.online_player_l[char_id]["server_id"] = line

	if self.line_player[line] == nil then
		self.line_player[line] = {}
	end

	for k, v in pairs(self.line_player) do
		for m,n in pairs(v) do
			if m == char_id then
				self.line_player[k][m] = nil
				break
			end
		end
	end
	self.line_player[line][char_id] = 1
	
	self.ouline_player_attr_l[char_id] = nil
end

--获取角色信息
function Player_mgr:get_info(char_id)
	return self.all_player_l[char_id]
end

--级别更新
function Player_mgr:change_level(char_id, level)
	if self.all_player_l[char_id] ~= nil then
		self.all_player_l[char_id]["level"] = level
	end
end

function Player_mgr:quit(char_id)
	if self.online_player_l[char_id] ~= nil then
		self.online_player_l[char_id] = nil
	end

	for k,v in pairs(self.line_player) do
		for m, n in pairs(v) do
			if m == char_id then
				self.line_player[k][m] = nil
				break
			end
		end
	end
end

function Player_mgr:char_id2acn(char_id)
	if self.all_player_l[char_id]~=nil then
		return self.all_player_l[char_id]["account_name"]
	end
	return nil
end
function Player_mgr:char_id2nm(char_id)
	if self.all_player_l[char_id]~=nil then
		return self.all_player_l[char_id]["char_nm"]
	end
	return nil
end
function Player_mgr:char_nm2id(char_nm)
	return self.all_player_nm_l[char_nm]
end
function Player_mgr:is_exist(char_id)
	return self.all_player_l[char_id] ~= nil
end

--所有角色列表
function Player_mgr:get_all_player()
	return self.all_player_nm_l 
end
--在线角色列表
function Player_mgr:get_online_player()
	return self.online_player_l
end

function Player_mgr:get_online_player_char(char_id)
	if self:is_online_char(char_id) then
		return self.online_player_l[char_id]["char_nm"]
	end
end
function Player_mgr:is_online_char(char_id)
	return self.online_player_l[char_id] ~= nil
end

--分线和地图
function Player_mgr:get_char_line(char_id)
	if self.online_player_l[char_id] ~= nil then
		return self.online_player_l[char_id]["line"]
	end
end

--获取全服人数
function Player_mgr:get_all_char()
	return self.all_player_l
end

--服务器重启重新获取数据
function Player_mgr:reset_online_l(line, player_l,conn)
	self:clear_line(line)
	for k,v in pairs(player_l) do
		self:join_in(v.obj_id, v, line,conn)
	end
end

function Player_mgr:clear_line(line)
	if self.line_player[line] ~= nil then
		for k, v in pairs(self.line_player[line]) do
			self.online_player_l[k] = nil
			--g_faction_mgr:outline(nil,k)
			g_char_mgr:outline(k)
		end

		self.line_player[line] = {}
	end
end

function Player_mgr:clear()
	self.online_player_l = {}
	self.all_player_l = {}    
	self.all_player_nm_l = {} 
	self.line_player = {}
end

function Player_mgr:get_map_id(obj_id)
	if self.online_player_l[obj_id] ~= nil then
		return self.online_player_l[obj_id].server_id
	end
end

--获取不在线玩家属性
function Player_mgr:get_player_attr(char_id)
	if self.ouline_player_attr_l[char_id] == nil then
		local m_db = f_get_db()
		local data = "{info:1,attribute:1,equip:1}"
		local query = string.format("{char_id:%d}", char_id)
		local info, e_code = m_db:select_one("player_attr", data, query, nil, "{char_id:1}")
		if info == nil then return end
		
		if info.info ~= nil and info.attribute ~= nil and info.equip ~= nil then
			local attr_l = {}
			attr_l.info = info.info
			attr_l.attribute = info.attribute
			attr_l.equip = info.equip
			self.ouline_player_attr_l[char_id] = attr_l
		end
	end
	
	return self.ouline_player_attr_l[char_id]
end

--[[function Player_mgr:add_player_attr(char_id, attr_l)
	self.ouline_player_attr_l[char_id] = attr_l
end

function Player_mgr:load_player_attr(char_id)
end]]