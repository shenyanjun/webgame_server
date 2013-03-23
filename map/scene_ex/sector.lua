
--扇形计算
local _tan = {0, math.pi/4, math.pi/2, math.pi*3/4, math.pi, math.pi/4, math.pi/2, math.pi*3/4}

local _sector = {}

_sector.get_direct = function(pos, des_pos)
	if pos[1] == des_pos[1] then
		if pos[2] <= des_pos[2] then
			return 3
		else 
			return 7
		end
	end

	local t = math.atan((des_pos[2]-pos[2])/(des_pos[1]-pos[1]))
	t = t>=0 and t or t+math.pi
	local area
	if t <= math.pi/2 then --1,3区域
		--print("ector:get_direct", 1, t, math.pi/4, math.pi/8)
		if math.abs(t - math.pi/4) < math.pi/8 then
			return des_pos[1]-pos[1]>=0 and 2 or 6
		elseif t > math.pi/4 then 
			return des_pos[1]-pos[1]>=0 and 3 or 7
		else
			return des_pos[1]-pos[1]>=0 and 1 or 5
		end                       
	else
		--print("ector:get_direct", 2, t, math.pi/4, math.pi/8)
		if math.abs(t - math.pi*3/4) < math.pi/8 then
			return des_pos[1]-pos[1]<=0 and 4 or 8
		elseif t > math.pi*3/4 then 
			return des_pos[1]-pos[1]<=0 and 5 or 1
		else
			return des_pos[1]-pos[1]<=0 and 3 or 7
		end
	end
end

_sector.is_area = function(pos, des_pos, area)
	local ae = _sector.get_direct(pos, des_pos)
	if ae == area then
		return true
	end
	if math.abs(ae-area) <= 1 or math.abs(ae-area) == 7 then
		local t = math.atan((des_pos[2]-pos[2])/(des_pos[1]-pos[1]))
		t = t>=0 and t or t+math.pi
		if math.abs(t-_tan[area]) < math.pi/4 then
			return true
		end
	end
	return false
end

--接口函数
function f_scene_sector()
	return _sector
end


--test
--[[local s = f_scene_sector()
print("))))))))))))))))", s.get_direct({0,0},{2,-10}))
print("((((((((((((", s.is_area({0,0},{-2,7}, 4))--]]
