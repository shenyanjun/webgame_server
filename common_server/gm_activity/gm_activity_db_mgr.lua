--公共服的活动如果没有直接收到GM的通知开启，是没办法自动开启初始化的
--公共服功能启动时在这里查询是否有活动


local database_fun = "gm_activity"  --记录活动信息
Common_active_mgr = oo.class(nil, "common_active_mgr")

function Common_active_mgr:init()
end

function Common_active_mgr:load_active_info( type )
	local active_info = {}
	local dbh = f_get_db()
	local row,e_code = dbh:select(database_fun,nil,nil)
	local now = ev.time
	if row and e_code == 0 then
		--只加载有效活动(每次保证只加载唯一一个有效的活动)
		for _,v in pairs(row or {}) do
			if ev.time >= v.start_t and ev.time < v.end_t and v.type == type then 			
				if type == 3 then
					active_info = {}
					active_info.start_t = v.start_t
					active_info.end_t   = v.end_t
					active_info.type    = v.type
					active_info.id      = v.param.active_id or 1
					active_info.uuid    = v.id
					return active_info
				end
			end	
		end
	end
	return nil
end