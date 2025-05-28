local position = {
	x = 0,
	y = 0,
}

local height = 25
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

local function farm()
	for x = 0, width - 1 do
		for _ = 0, height - 1 do
			turtle.placeDown()
			local success = true
			while success do
				success = turtle.suckDown()
			end
			if x % 2 == 0 then
				move("f")
			else
				move("b")
			end
		end
		turtle.placeDown()
		local success = true
		while success do
			success = turtle.suckDown()
		end
		move("r")
	end

	for _ = position.x, 0, -1 do
		move("l")
	end
	for _ = position.y, 1, -1 do
		move("b")
	end
end

local function emptyInventory()
	local empty = true
	for slot = 2, 16 do
		turtle.select(slot)
		if turtle.getItemCount() > 0 then
			empty = false
		end
	end
	return empty
end

local function loop()
	while true do
		if emptyInventory() then
			move("f")
			turtle.select(1)
			farm()
		end
	end
end

loop()
