
local _hour = {1300, 1330}  --小时+分钟1625为16:25
local _team_a = {1, 1.05, 1.1, 1.5, 2.2}
local _level = 20

Reward_exp = oo.class(nil,"Reward_exp")

function Reward_exp:__init()
	self.reward_flag = 0    --0关闭 1开启
end


function Reward_exp:reward(obj)
	if self.reward_flag == 1 and obj:get_map_id() == MAP_INFO_3 and obj:get_level() >= _level then
		local lv = obj:get_level()
		local double = obj:get_double_exp()
		local team = 1
		local team_obj = g_team_mgr:get_team_obj(obj:get_team())
		if team_obj ~= nil then
			team = team*_team_a[team_obj:get_line_count() or 1]
		end
		local exp = math.floor((lv+75)/88*(lv*1.5+140)*team*double)
		obj:add_exp(exp)
	end
end

---------------timer----------
function Reward_exp:get_click_param()
	return self, self.on_timer, 10, nil
end

function Reward_exp:on_timer(tm)
	local h = tonumber(os.date("%H%M"))
	if h >= _hour[1] and h <= _hour[2] then
		if self.reward_flag == 0 then
			--开启广播
			local str_json = f_get_sysbd_format(10004)
			f_cmd_linebd(str_json)

			for id,obj in pairs(g_obj_mgr:get_list(OBJ_TYPE_HUMAN)) do
				if obj:get_map_id() ~= MAP_INFO_3 and obj:get_level() >= _level then
					g_cltsock_mgr:send_client(id, CMD_MAP_REWARD_EXP_S, {})
				end
			end
		end
		self.reward_flag = 1
	elseif self.reward_flag == 1 then
		self.reward_flag = 0
		local str_json = f_get_sysbd_format(10005)
		f_cmd_linebd(str_json)
	end
end