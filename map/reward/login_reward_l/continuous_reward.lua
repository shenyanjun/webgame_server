--2010-01-20
--laojc
--连续登录奖励
local world_gift_loader = require("config.loader.world_gift_loader")
local reward_t = require("config.reward_config")

Continuous_reward = oo.class(Reward,"Continuous_reward")

function Continuous_reward:__init(obj_id)
	Reward.__init(self,obj_id)

	self.char_id = obj_id
	self.type = 4
	self.day = 1
	self.item_list = self:get_random_item()
end

function Continuous_reward:get_random_item()
	local item_list = reward_t.f_continuous_random_item(self.day)
	if item_list == nil then
		return {}
	else
		return item_list[1] or {}
	end
end

function Continuous_reward:get_world_gift()
	local player = g_obj_mgr:get_obj(self.char_id)
	if not player then return end

	local level = player:get_level()
	local vip = g_vip_mgr:get_vip_info(self.char_id)

	local world_level = g_world_lvl_mgr:get_average_level()
	local x_level = world_level - level
	if x_level <= 0 then return nil end

	local item_list = nil
	for k, v in pairs(world_gift_loader.gift_list) do
		if level >= k and level < tonumber(v.max) then
			for m, n in pairs(v) do
				if m ~= "max" then
					if x_level >= tonumber(m) and x_level < tonumber(n.high_level) then
						item_list = n.vip[vip + 1]
						break
					end
				end
			end
		end
	end

	return item_list
end

function Continuous_reward:fetch_item()
	local item = self.item_list
	if item == nil then return end ----------------没到制定节日时间

	local player = g_obj_mgr:get_obj(self.char_id)
	local pack_con = player:get_pack_con()
	
	local item_id_list = {}
	--for k,v in pairs(item or {})do
		item_id_list[1] = {}
		item_id_list[1].type = 1
		item_id_list[1].item_id = item[1]
		item_id_list[1].number = item[2]
	--end
	local item_list = self:get_world_gift()
	local count = 2
	if item_list ~= nil then
		for k,v in ipairs(item_list) do
			if table.size(v) ~= 0 then
				item_id_list[count] = {}
				item_id_list[count].type = 1
				item_id_list[count].item_id = v[1]
				item_id_list[count].number = v[2]
				count = count + 1
			end
		end
	end

	local free_slot = pack_con:get_bag_free_slot_cnt()
	if free_slot <=0  then
		return 43004
	end

	if pack_con:add_item_l(item_id_list, {['type']=ITEM_SOURCE.HOLIDAY}) ~= 0 then
		return 27003
	end
	self:set_flag(1)
	return 0
end




--function Continuous_reward:can_be_fetch()
	----if not self:is_day() then return end            --是否在指定的天数
	--if self:is_fetch() then return 27601 end
	--return 0
--end
--
function Continuous_reward:get_day()
	return self.day
end

function Continuous_reward:set_day(day)
	self.day = day
end

function Continuous_reward:add_day()
	self.day = self.day + 1
end

function Continuous_reward:is_day()
	local l_time = ev.time
	return false
end

--登录
function Continuous_reward:login()
	if self:is_other_day(2) then
		self:set_day(1)
		self:set_flag(0)
		self.item_list = self:get_random_item(self.day)
		self.login_time = self:get_day_time()
		self:update_char()
	elseif self:is_other_day() then	
		self:add_day()
		self:set_flag(0)
		local day_l,t_day = reward_t.f_festival_max_day()
		if self.day > day_l then
			self:set_day(t_day)
		end
		self.item_list = self:get_random_item(self.day)
		self.login_time = self:get_day_time()
		self:update_char()
	end
end


