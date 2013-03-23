
local sh_config = require("scene_ex.config.fish_config_loader")
local proto_mgr = require("item.proto_mgr")
local fish_config = sh_config.myconfig

local FISHTYPE = {}
FISHTYPE.SMALL_FISH = 1
FISHTYPE.BIG_FISH = 2

Scene_fish = oo.class(Scene_instance, "Scene_fish")

function Scene_fish:__init(map_id, instance_id, map_obj, end_time)
	Scene_instance.__init(self, map_id, instance_id, map_obj)
	
	self.char_list = {}
	self.char_count = 0
	self.char_fish_cache = {}		--暂时保存玩家钓到的大鱼

	self.fish_info = {}

	self.end_time = end_time

	self.check_time = ev.time

end


function Scene_fish:instance()
	local config = fish_config
	
	self.obj_mgr:instance(self.map_obj:get_w(), self.map_obj:get_h())
	
end

--副本出口
function Scene_fish:get_home_carry(obj)
	local home_carry = fish_config.home
	if not home_carry or not home_carry.id or not home_carry.pos 
			or not home_carry.pos[1] or not home_carry.pos[2] then
		return nil, nil
	end
	return home_carry.id, home_carry.pos
end


function Scene_fish:carry_scene(obj, pos)
	if not pos then
		pos = fish_config.entry
	end
	local obj_id = obj:get_id()
	if not self.owner_list[obj_id] then
		f_multi_web_sql(string.format("insert into copy_into set copy_id=%d, char_id=%d, time=%d, char_name='%s'"
					, self.id
					, obj_id
					, ev.time
					, obj:get_name()))
	end
	return self:push_scene(obj, pos)
end

function Scene_fish:check_in()
	if self.char_count >= fish_config.max_fish then
		return false
	end
	return true
end

function Scene_fish:on_obj_enter(obj)
	local obj_id = obj:get_id()
	local type = obj:get_type()
	if OBJ_TYPE_HUMAN == type then
		self.char_count = self.char_count + 1
		self.char_list[obj_id] = obj_id
	end
end

function Scene_fish:on_obj_leave(obj)
	local obj_id = obj:get_id()
	local type = obj:get_type()
	if OBJ_TYPE_HUMAN == type then
		self.char_list[obj_id] = nil
            self.char_fish_cache[obj_id] = nil
		self.char_count = math.max(self.char_count - 1, 0)
	end
end

function Scene_fish:end_copy()
  -- 结束时无需作其他工作
end

function Scene_fish:on_timer(tm)
	
	local now = ev.time
	if not self.close_time and self.end_time <= now then
		self.close_time =  now + 30
		self:end_copy()
	end

	if self.close_time and self.close_time <= now then
		self:close()
	end

	if self.check_time < ev.time then
		self.check_time = ev.time + 2
	end

	self.obj_mgr:on_timer(tm)
end

function Scene_fish:send_fish_info(obj_id)
	local info = {}
	local fish = self.char_fish_cache[obj_id].fish_info
	local pkt = {}
	pkt.size = fish.kind
	pkt.id = fish.item_id
	pkt.hits = fish.hits
	pkt.result = 0
	local json = Json.Encode(pkt)
	--print("fish_info:", json)
	self:send_human(obj_id, CMD_MAP_FISH_INRANGE_S, json, true)

    if pkt.size == FISHTYPE.SMALL_FISH then
        self.char_fish_cache[obj_id] = nil
    end
end

--[[
功能：判断上钩的是什么鱼，保存鱼的信息，如果是小鱼直接掉背包
参数：obj_id --  角色ID
      hook -- 鱼钩类型
返回：0：正常
--]]
function Scene_fish:fish_inrange(obj_id, hook)
	local obj = g_obj_mgr:get_obj(obj_id)
	if not obj then	return 31361 end

    -- 背包
    local pack_con = obj:get_pack_con()

    -- 是否还有钓鱼次数
    local con = obj:get_copy_con()
    if  fish_config.max_count and 
		con:get_count_copy(self.id) >= fish_config.max_count then 
		    return 31364
	end

    --是否有相应鱼钩
    local hook_count = pack_con:get_all_item_count(hook)
    if hook_count <= 0 then print( "hook count:", hook_count, hook, type(hook) ) return 31363 end

    if not fish_config.fish[hook] then print("not match hook info", hook ) return 31363 end
    local type = #fish_config.fish[hook];
    if type <= 0 then 
        print( "Scene_fish:fish_inrange:no fish config" ) 
        return 31363
    end
        
    local randnum = math.random(1,100)  
    local typeindex = 0
    local totalrate = 0
    for k, v in ipairs( fish_config.fish[hook] ) do
        totalrate = totalrate + v.rate
        if randnum < totalrate then
            typeindex = k
            break
        end
    end

	local fish_info = fish_config.fish[hook][typeindex]
	--[[
	for k, v in pairs(fish_config.fish) do
		print("kv", k, j_e(v))
	end
	--]]
	if not fish_info then 
		print( "no fish_info" )
		return 31363
	end

    -- 暂时保存鱼的信息
	self.char_fish_cache[obj_id] = {}
	self.char_fish_cache[obj_id].fish_info = fish_info
	self.char_fish_cache[obj_id].hook = hook

    if fish_info.kind == FISHTYPE.SMALL_FISH then
        -- 小鱼直接入背包
        local reward_l = {}
        table.insert( reward_l, fish_info )
        local err = pack_con:check_add_item_l_inter_face(reward_l)
        if err == 0 then
             -- 扣除鱼钩
            err = pack_con:del_item_by_item_id_inter_face(hook, 1, {['type']=ITEM_SOURCE.FISH}, 1)
    		if err == 0 then
				con:add_count_copy(self.id)
				pack_con:add_item_l(reward_l, {['type']=ITEM_SOURCE.FISH})
           		return 0
			end
        end
              
        self.char_fish_cache[obj_id] = nil
        -- 发送背包已满错误码
        return err
    end

    return 0
end


--[[
function: 处理已上钩的大鱼
@para: obj_id --  角色ID
       getflag -- 是否放背包，1：是，2：否
@ret: 对应大鱼信息，没有返回nil
--]] 
function Scene_fish:handle_fish(obj_id, getflag)
    local obj = g_obj_mgr:get_obj(obj_id) 
	if not obj then  return 31361 end
    local con = obj:get_copy_con()

    -- 背包 
	local pack_con = obj:get_pack_con() 
    if getflag ~= 1 then
        self.char_fish_cache[obj_id] = nil
        return 0
    end

    if not self.char_fish_cache[obj_id] then
        return 31362
    end

    local hook = self.char_fish_cache[obj_id].hook
    --是否有相应鱼钩
    local hook_count = pack_con:get_all_item_count(hook)
    if hook_count <= 0 then return 31363 end

    -- 入背包
    local reward_l = {}
    table.insert( reward_l, self.char_fish_cache[obj_id].fish_info )
    local err = pack_con:check_add_item_l_inter_face(reward_l)
    if err == 0 then
        -- 扣除鱼钩
        err = pack_con:del_item_by_item_id_inter_face( hook, 1, {['type']=ITEM_SOURCE.FISH}, 1)
		if err == 0 then
			con:add_count_copy(self.id)
     	    pack_con:add_item_l(reward_l, {['type']=ITEM_SOURCE.FISH})
            return 0, self.char_fish_cache[obj_id].fish_info.item_id
		end
    end
          
    self.char_fish_cache[obj_id] = nil
    -- 发送背包已满错误码
    return err
end

--[[
function: 获取可钓鱼次数
@para:    obj_id -- 角色ID
@ret:     可钓鱼次数
--]]
function Scene_fish:get_leftcount(obj_id)
    local obj = g_obj_mgr:get_obj(obj_id)
	if not obj then	return 0 end
        local con = obj:get_copy_con()
	if not con then	return 0 end

    return fish_config.max_count - con:get_count_copy(self.id)
end

function Scene_fish:get_count_copy(char_id)
	return 0
end

