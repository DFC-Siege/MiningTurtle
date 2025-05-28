local position = {
	x = 0,
	y = 0,
}

local height = 26
local width = 14

local function move(direction)
	local success = false
	if direction == "f" then
		success = turtle.forward()
		if success then
			position.y = position.y + 1
		end
	elseif direction == "b" then
		success = turtle.back()
		if success then
			position.y = position.y - 1
		end
	elseif direction == "l" then
		turtle.turnLeft()
		success = turtle.forward()
		if success then
			position.x = position.x - 1
		end
		turtle.turnRight()
	elseif direction == "r" then
		turtle.turnRight()
		success = turtle.forward()
		if success then
			position.x = position.x + 1
		end
		turtle.turnLeft()
	end
end

move("r")
