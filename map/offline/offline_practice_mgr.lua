--2010-12-2
--laojc
--离线修炼管理类

--根据等级每小时获得的经验
local lvl_expr = {}
lvl_expr[1] = {8028,30,39}        --30到39级 经验为8028（每小时）
lvl_expr[2] = {13612,40,49}       --40到49级
lvl_expr[3] = {20393,50,59}		  --50到59级
lvl_expr[4] = {71086,60,69}		  --60到60级	

--最大修练点
local MAX_POINT = 240

--玩家每天最多修练点 8点
local MAX_POINT_DAILY = 8

--玩家获取修炼点的开始等级
local B_LEVEL = 30


Off_pr_mgr = oo.class(nil,"Off_pr_mgr")

function Off_pr_mgr:__init()
	self.off_list = {}
end

function Off_pr_mgr:create_off(char_id)
	self.off_list[char_id] = Off_pr_obj(char_id)
end

function Off_pr_mgr:can_be_fetch(char_id)
	return self.off_list[char_id]:can_be_fetch()
end

function Off_pr_mgr:get_expr(char_id)
	return self.off_list[char_id]:get_expr()
end

function Off_pr_mgr:fetch_point(char_id,type)
	return self.off_list[char_id]:fetch_point(type)
end

function Off_pr_mgr:get_obj(char_id)
	return self.off_list[char_id]
end

function Off_pr_mgr:login(char_id)
	self:select_char(char_id)

	self.off_list[char_id]:login()
end

function Off_pr_mgr:level_up_init(char_id)
	self:create_off(char_id)

	self.off_list[char_id]:login()
end

function Off_pr_mgr:logout(char_id)
	if self.off_list[char_id] ~= nil then
		self.off_list[char_id]:update_char()
		self.off_list[char_id] = nil
	end
end

function Off_pr_mgr:click_return()
	for k,v in pairs(self.off_list or {}) do
		v:login()
	end
end

function Off_pr_mgr:get_net_info(char_id)
	if self.off_list[char_id] ~= nil then
		return self.off_list[char_id]:get_net_info()
	end
end

function Off_pr_mgr:update_level(char_id)
	if self.off_list[char_id] ~= nil then
		self.off_list[char_id]:update_level()
	end
end



function Off_pr_mgr:select_char(char_id)
	local player = g_obj_mgr:get_obj(char_id)
	if not player then return end

	if not player:is_first_login() then
		local dbh = f_get_db()
		local data = "{char_id:1,point:1,login_time:1,flag:1}"
		local query = string.format("{char_id:%d}",char_id)
		
		local rs,err_code = dbh:select_one("offline_practice", data, query, nil, "{char_id:1}")
		if err_code ~= 0 then return end
		if rs ~= nil then
			self:create_off(char_id)
			self.off_list[char_id].point = rs.point
			self.off_list[char_id].login_time = rs.login_time
			self.off_list[char_id].flag = rs.flag
		else
			self:create_off(char_id,i)
			self.off_list[char_id]:insert_char()
		end
	else
		self:create_off(char_id)
	end
end