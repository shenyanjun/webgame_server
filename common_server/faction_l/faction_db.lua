
local database = "faction"
local database_relate = "faction_relation"

Faction_db = oo.class(nil, "Faction_db")

function Faction_db:init()
end

function Faction_db:insert_faction(faction)
	local dbh = f_get_db()

	local t_faction = {}
	t_faction.faction_id = faction:get_faction_id()   
	t_faction.level	= faction:get_level()		
	t_faction.faction_name = faction:get_faction_name()
	t_faction.faction_badge	= faction:get_faction_badge()
	t_faction.territory_level = faction:get_territory_level()
	t_faction.money	= faction:get_money()
	t_faction.announcement = faction:get_announcement()
	t_faction.create_time = faction:get_create_time()		
	t_faction.factioner_id = faction:get_factioner_id()
	t_faction.post_name	= faction:get_post_name_ex()
	t_faction.rank = faction:get_rank()		
	t_faction.member_count = faction:get_member_count()
	t_faction.member = faction:get_player_list_info() 
	
	t_faction.action_level = faction:get_action_level()
	t_faction.book_level = faction:get_book_level()
	t_faction.gold_level = faction:get_gold_level()
	t_faction.action_practice = faction:get_action_practice()
	t_faction.book_practice = faction:get_book_practice()
	t_faction.book_end_time = faction.book_end_time
	t_faction.gold_end_time = faction.gold_end_time
	t_faction.faction_update_end_time = faction.faction_update_end_time
	t_faction.construct_point = faction.construct_point
	t_faction.technology_point = faction.technology_point
	t_faction.permission_list = faction.permission_list
	t_faction.irrigation = faction.irrigation
	t_faction.dissolve_flag = faction.dissolve_flag
	t_faction.fb_info = faction.fb_info
	t_faction.over_flag = faction.over_flag
	t_faction.warehouse_level= faction:get_warehouse_level() -- 帮派仓库
	t_faction.warehouse_end_time = faction.warehouse_end_time
	t_faction.resource_exchange_list = faction.resource_exchange_list -- 资源互换列表
	t_faction.resource_exchange_time = faction.resource_exchange_time -- 互换列表记录日期
	t_faction.fb_level = faction.fb_level
	t_faction.last_kick_time = faction.last_kick_time -- 保存帮派最后一次踢人时间

	local err_code = dbh:insert(database,Json.Encode(t_faction))     
	if err_code == 0 then
		return true
	end
	return false
end

function Faction_db:update_faction(faction)
	local db = f_get_db()
	local faction_id = faction:get_faction_id()
	local data ={}--[[ string.format("{level:%d,faction_name:'%s',faction_badge:%d,territory_level:%d,money:%d,announcement:'%s',factioner_id:%d,post_name:'%s',rank:%d,member_count:%d,member:'%s'}",
	faction:get_level(),faction:get_faction_name(), faction:get_faction_badge(),faction:get_territory_level(),faction:get_money(),
	faction:get_announcement(), faction:get_factioner_id(),Json.Encode(faction:get_post_name_ex()),faction:get_rank(),faction:get_member_count(),Json.Encode(faction:get_player_list_info()))]]

	data.level = faction:get_level()
	data.faction_name = faction:get_faction_name()
	data.faction_badge = faction:get_faction_badge()
	data.territory_level = faction:get_territory_level()
	data.money = faction:get_money()
	data.announcement = faction:get_announcement()
	data.factioner_id = faction:get_factioner_id()
	data.post_name = faction:get_post_name_ex()
	data.rank = faction:get_rank()
	data.member_count = faction:get_member_count()
	data.member = faction:get_player_list_info()

	data.action_level = faction:get_action_level()
	data.book_level = faction:get_book_level()
	data.gold_level = faction:get_gold_level()
	data.action_practice = faction:get_action_practice()
	data.book_practice = faction:get_book_practice()
	data.book_end_time = faction.book_end_time
	data.gold_end_time = faction.gold_end_time
	data.action_end_time = faction.action_end_time
	data.faction_update_end_time = faction.faction_update_end_time
	data.construct_point = faction.construct_point
	data.technology_point = faction.technology_point
	data.permission_list = faction.permission_list
	data.irrigation = faction.irrigation
	data.dissolve_flag = faction.dissolve_flag
	data.fb_info = faction.fb_info
	data.over_flag = faction.over_flag
	data.warehouse_level = faction:get_warehouse_level() -- 帮派仓库
	data.warehouse_end_time = faction.warehouse_end_time
	data.resource_exchange_list = faction.resource_exchange_list -- 资源互换列表
	data.resource_exchange_time = faction.resource_exchange_time -- 互换列表记录日期
	data.fb_level = faction.fb_level
	data.last_kick_time = faction.last_kick_time -- 保存帮派最后一次踢人时间

	local query = string.format("{faction_id:'%s'}",faction_id)

	local err_code = db:update(database,query,Json.Encode(data))
	if err_code == 0 then
		return true
	end
	f_faction_log("faction update failed!",faction_id)
	return false
end

function Faction_db:update_faction_ex(faction)
	if faction:is_time_ok() then
		local db = f_get_db()
		local faction_id = faction:get_faction_id()
		local data ={}--[[ string.format("{level:%d,faction_name:'%s',faction_badge:%d,territory_level:%d,money:%d,announcement:'%s',factioner_id:%d,post_name:'%s',rank:%d,member_count:%d,member:'%s'}",
		faction:get_level(),faction:get_faction_name(), faction:get_faction_badge(),faction:get_territory_level(),faction:get_money(),
		faction:get_announcement(), faction:get_factioner_id(),Json.Encode(faction:get_post_name_ex()),faction:get_rank(),faction:get_member_count(),Json.Encode(faction:get_player_list_info()))]]

		data.level = faction:get_level()
		data.faction_name = faction:get_faction_name()
		data.faction_badge = faction:get_faction_badge()
		data.territory_level = faction:get_territory_level()
		data.money = faction:get_money()
		data.announcement = faction:get_announcement()
		data.factioner_id = faction:get_factioner_id()
		data.post_name = faction:get_post_name_ex()
		data.rank = faction:get_rank()
		data.member_count = faction:get_member_count()
		data.member = faction:get_player_list_info()

		data.action_level = faction:get_action_level()
		data.book_level = faction:get_book_level()
		data.gold_level = faction:get_gold_level()
		data.action_practice = faction:get_action_practice()
		data.book_practice = faction:get_book_practice()
		data.book_end_time = faction.book_end_time
		data.gold_end_time = faction.gold_end_time
		data.action_end_time = faction.action_end_time
		data.faction_update_end_time = faction.faction_update_end_time
		data.construct_point = faction.construct_point
		data.technology_point = faction.technology_point
		data.permission_list = faction.permission_list
		data.irrigation = faction.irrigation
		data.dissolve_flag = faction.dissolve_flag
		data.fb_info = faction.fb_info
		data.over_flag = faction.over_flag
		data.warehouse_level = faction:get_warehouse_level() -- 帮派仓库
		data.warehouse_end_time = faction.warehouse_end_time
		data.resource_exchange_list = faction.resource_exchange_list -- 资源互换列表
		data.resource_exchange_time = faction.resource_exchange_time -- 互换列表记录日期
		data.fb_level = faction.fb_level
		data.last_kick_time = faction.last_kick_time -- 保存帮派最后一次踢人时间

		faction:set_db_time(ev.time)

		local query = string.format("{faction_id:'%s'}",faction_id)

		local err_code = db:update(database,query,Json.Encode(data))
		if err_code == 0 then
			return true
		end
		f_faction_log("faction update failed!",faction_id)
		return false
	end
end



function Faction_db:select_all_faction()
	local dbh = f_get_db()

	local rows, e_code = dbh:select(database)
	if e_code == 0 then
		return rows
	end 
	return nil
end

function Faction_db:select_faction_relate()
	local dbh = f_get_db()

	local rows, e_code = dbh:select(database_relate)
	if e_code == 0 then
		return rows
	end 
	return nil
end