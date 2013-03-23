--2010-7-12
--zhengyg
--活动树活动子类 ， 以后为方便各种活动的个性化时间控制特征，也可以这样搞

local database = "gm_activity"

Gm_activity_item_achi_tree = oo.class(Gm_activity_item,'Gm_activity_item_achi_tree')

function Gm_activity_item_achi_tree:__init(type)
	Gm_activity_item.__init(self,type)
end

function Gm_activity_item_achi_tree:check_update_time(type)
	local db = f_get_db()

	local query = string.format("{type:%d}",type)

	local rows, e_code = db:select(database, nil, query)
	if 0 == e_code then
		rows = rows or {}
		table.sort(rows, function(e1,e2) 
						return e1.set_time > e2.set_time --只要最后一个设定，方便关活动
					end)
		for k, v in ipairs(rows) do
			if v.end_t >= ev.time then
				if v.start_t <= ev.time then		--活动中
					self.param = {}
					self.param.start_t = v.start_t
					self.param.end_t = v.end_t
					self.param.param = v.param
					self.param.id = v.id
					return 2, v.end_t
				else								--活动倒计时
					self.param = {}
					self.param.start_t = v.start_t
					self.param.end_t = v.end_t
					self.param.param = v.param
					self.param.id = v.id
					return 1, v.start_t
				end
			end
			break --只看第一个就行了，方便后台关闭活动
		end
		return 0									--没有任何活动
	else
		return 0
	end
end

function Gm_activity_item_achi_tree:get_update_time(type)
	local db = f_get_db()

	local query = string.format("{type:%d}",type)

	local rows, e_code = db:select(database, nil, query)
	if 0 == e_code then
		rows = rows or {}
		table.sort(rows, function(e1,e2) 
						return e1.set_time > e2.set_time 
					end)
		for k, v in ipairs(rows or {}) do
			if v.end_t >= ev.time then
				if v.start_t <= ev.time then		--活动中
					return 2, v.end_t, v.id
				else								--活动倒计时
					return 1, v.start_t, v.id
				end
			end
		end
		return 0									--没有任何活动
	else
		return 0
	end
end

reg_activity_item_builder(ACTIVITY_TYPE.ACHIEVE_ACHI_TREE,Gm_activity_item_achi_tree)