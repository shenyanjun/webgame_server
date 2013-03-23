
-----------------------------------降妖记录-----------------------------
local database = "control_monster_record"

--require("authorize.authorize_db")


--定时存盘时间
local update_time = 220

Control_monster = oo.class(nil, "Control_monster")


function Control_monster:__init()
	self.list  		= {}
	self.update_time = ev.time + update_time
end

function Control_monster:get_click_param()
	return self, self.on_timer,3,nil
end

function Control_monster:on_timer()
	if ev.time > self.update_time then
		self:update_control_monster()
		self.update_time = self.update_time + update_time
	end
end


-------------------------------------与map交互命令---------
function Control_monster:record_and_broadcast(pkt)
	if table.getn(self.list) >= 50 then
		table.remove(self.list, 1)
	end
	if pkt.record and pkt.record == 1 then
		table.insert(self.list, pkt)
	end	

	local s_pkt = Json.Encode(pkt)
	for k , v in pairs(g_player_mgr.online_player_l) do
		g_svsock_mgr:send_server_ex(WORLD_ID, k, CMD_C2W_CONTROLMONSTER_RECORD_W, s_pkt, true)
	end
	return
end

function Control_monster:send_all_record()

	return self.list
end

-------------------------------------数据库操作----------
function Control_monster:load()
	local rs= self:Load_record()
	if rs then
		for k , v in pairs(rs) do
			for kk, vv in pairs(v.list) do
				self.list[kk] = vv
			end
			return
		end
	end
	return
end

--------------------------------------发送到map，更新中奖者信息
--初始化  load所有
function Control_monster:Load_record()
	local db = f_get_db()

	local query = string.format("{id:%d}",1)

	local rows, e_code = db:select(database,nil,query)

	if 0 == e_code then
		return rows
	else
		print("LoadControl_monster Error: ", e_code)
	end
	return nil
end

function Control_monster:update_control_monster()
	local db = f_get_db()
	local values = {}
	values.id 	= 1
	values.list = self.list
	local query = string.format("{id:%d}",1)
	local e_code = db:update(database, query, Json.Encode(values), true, false)
	if 0 == e_code then
		return rows
	else
		print("UpdateControl_monster Error: ", e_code)
	end
	return nil
end