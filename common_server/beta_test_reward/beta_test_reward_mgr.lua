
local beta_reward_table = "beta_reward"

Beta_test_reward_mgr = oo.class(nil, "Beta_test_reward_mgr")

function Beta_test_reward_mgr:__init()

	self.reward_list = {}
end


function Beta_test_reward_mgr:load()

	local dbh = f_get_db()
	local rows, e_code = dbh:select(beta_reward_table)
	if rows ~= nil and e_code == 0 then
		for k, v in pairs(rows) do
			local account_name = v.account_name
			local type = v.type or 0
			if type == 0 then
				self.reward_list[account_name] = 0
			end
		end
	end
	--
end

function Beta_test_reward_mgr:save(account_name)
	if self.reward_list[account_name] == nil then return end
	local dbh = f_get_db()
	local query = string.format("{account_name:'%s'}", account_name)
	local data = {}
	data.account_name = account_name
	data.type = self.reward_list[account_name]
	local err_code = dbh:update(beta_reward_table, query, Json.Encode(data))

end

function Beta_test_reward_mgr:check_send_reward(char_id, account_name)
	--print("check_send_reward 1:", char_id, account_name)
	if self.reward_list[account_name] ~= 0 then return end
	--
	local email = {}
	email.sender = -1
	email.recevier = char_id
	email.title = f_get_string(2970)
	email.content = f_get_string(2971)
	email.box_title = f_get_string(2970)
	email.money_list = {}
	
	email.item_list = {}
	local item = {}
	item.id = 104100003940
	item.name = f_get_string(2970)
	item.count = 1
	table.insert(email.item_list, item)
	g_email_mgr:send_email_interface(email)
	self.reward_list[account_name] = 1
	self:save(account_name)
end