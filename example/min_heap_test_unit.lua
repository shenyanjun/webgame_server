require("min_heap")

function assert_equal(left, right)
	assert(left == right, string.format("left = %s, right = %s", tostring(left), tostring(right)))
end

function run_test(count)
	for k, v in pairs(_G) do
		if type(v) == "function" and 1 == string.find(k, "test_") then
			print("run", k, count)
			v()
		end
	end
end

--[[function test_top()
	local m = Min_heap:init()
	local limit = math.random(500, 10000)
	
	for i = limit, 1, -1 do
		m:push(i, i)
		assert_equal(i, m:top().key)
	end	
end

function test_push()
	local m = Min_heap:init()
	local limit = math.random(500, 10000)
	
	for i = 1, limit do
		m:push(i, i)
	end
	
	local count = 0
	local last = m:top().key
	local l = {}
	while (not m:is_empty()) do
		local e = m:top()
		m:pop()
		assert(last <= e.key, string.format("%d, %d, %d", last, e.key, e.value))
		l[e.value] = (l[e.value] or 0) + 1
		last = e.key
		count = count + 1
	end
	
	assert_equal(count, limit)
	assert_equal(0, m:size())
	
	for i = 1, limit do
		assert(1 == l[i], i)
	end
	
	for i = 1, limit do
		assert(not m.heap[i], i)
	end
end

function test_erase_all()
	local limit = math.random(500, 10000)
	local m = Min_heap:init()
	
	local t = {}
	for i = 1, limit do
		local id = m:push(os.time() + math.random(1, 100000), i)
		table.insert(t, id)
	end
	
	for _, id in ipairs(t) do
		m:erase(id)
	end
	
	assert_equal(0, m:size())
end]]

function test_erase()
	local limit = math.random(500, 10000)
	local m = Min_heap:init()
	
	local t = {}
	for i = 1, limit do
		local id = m:push(os.time() + math.random(1, 1000000), i)
		table.insert(t, id)
	end
	
	local c = math.random(math.floor(limit / 10), math.floor(limit / 2))
	for i = 1, c do
		m:erase(t[i])
	end
	
	local last = m:top().key
	while (not m:is_empty()) do
		local e = m:top()
		m:pop()
		assert(last <= e.key, string.format("%d, %d, %d", last, e.key, e.value))
		last = e.key
	end
end

--[[function test_spc()
	local data = {
		15, 9, 9, 19, 19
		, 10, 19, 4, 1, 6
	}
	local m = Min_heap:init()
	
	for k, v in ipairs(data) do
		m:push(v, k)
	end
	
	local c = m:size()
	while c > 1 do
		c = math.floor(c/2)
		m:erase(c)
	end
	
	local last = m:top().key
	while (not m:is_empty()) do
		local e = m:top()
		m:pop()
		assert(last <= e.key, string.format("%d, %d, %d", last, e.key, e.value))
		last = e.key
	end
end]]

for i = 1, 10000 do
	run_test(i)
	--test_erase()
end