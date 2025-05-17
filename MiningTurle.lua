local home = { x = 0, y = 0, z = 0 }
local currentPos = { x = 0, y = 0, z = 0 }
local undesirables = {
	"minecraft:stone",
	"minecraft:granite",
	"minecraft:diorite",
	"minecraft:andesite",
	"minecraft:dirt",
	"minecraft:gravel",
	"minecraft:clay",
}
local level = 0
local moves = {}

local fuelLimit = turtle.getFuelLimit()

local function getFuelAmount(slot)
	local item = turtle.getItemDetail(slot)
	if not item then
		return 0
	end

	if item.name == "minecraft:coal" or item.name == "minecraft:charcoal" then
		return 80
	elseif item.name == "minecraft:lava_bucket" then
		return 1000
	end

	return 0
end

local function refuel()
	local fuelLevel = turtle.getFuelLevel()
	if fuelLevel >= fuelLimit then
		return true
	end

	local fuelNeeded = fuelLimit - fuelLevel

	for i = 1, 16 do
		turtle.select(i)
		if turtle.refuel(0) then
			local fuelPerItem = getFuelAmount(i)
			if fuelPerItem > 0 then
				local itemsToUse = math.min(math.ceil(fuelNeeded / fuelPerItem), turtle.getItemCount(i))

				if itemsToUse > 0 then
					turtle.refuel(itemsToUse)
					fuelLevel = turtle.getFuelLevel()
					if fuelLevel >= fuelLimit then
						return true
					end
					fuelNeeded = fuelLimit - fuelLevel
				end
			end
		end
	end

	return fuelLevel > 0
end

local function getMovementLeft()
	return (turtle.getFuelLevel() / 100) * 6
end

local function dropUndesirables()
	for i = 1, 16 do
		turtle.select(i)
		local item = turtle.getItemDetail(i)
		if item and item.name then
			for _, undesirable in pairs(undesirables) do
				if item.name == undesirable then
					turtle.drop(item.count)
					break
				end
			end
		end
	end
end

local function mine()
	local hasMinedSomething

	repeat
		hasMinedSomething = false

		if turtle.detectUp() then
			turtle.digUp()
			hasMinedSomething = true
		end

		if turtle.detectDown() then
			turtle.digDown()
			hasMinedSomething = true
		end

		if turtle.detect() then
			turtle.dig()
			hasMinedSomething = true
		end

		turtle.turnLeft()
		if turtle.detect() then
			turtle.dig()
			hasMinedSomething = true
		end
		turtle.turnRight()

		turtle.turnRight()
		if turtle.detect() then
			turtle.dig()
			hasMinedSomething = true
		end
		turtle.turnLeft()

		turtle.turnRight()
		turtle.turnRight()
		if turtle.detect() then
			turtle.dig()
			hasMinedSomething = true
		end
		turtle.turnRight()
		turtle.turnRight()

	until not hasMinedSomething

	dropUndesirables()
end

local function checkGoBackHome()
	local distance = 0
	local margin = 25
	distance = distance + math.abs(home.x - currentPos.x)
	distance = distance + math.abs(home.y - currentPos.y)
	distance = distance + math.abs(home.z - currentPos.z)
	return distance - (getMovementLeft() + margin) <= 0
end

local function moveTowardsHome()
	while #moves > 0 do
		local lastMove = moves[#moves]

		local success = false
		if lastMove == "f" then
			success = turtle.back()
		elseif lastMove == "b" then
			success = turtle.forward()
		elseif lastMove == "u" then
			success = turtle.down()
		elseif lastMove == "d" then
			success = turtle.up()
		elseif lastMove == "l" then
			turtle.turnRight()
			success = turtle.forward()
			turtle.turnLeft()
		elseif lastMove == "r" then
			turtle.turnLeft()
			success = turtle.forward()
			turtle.turnRight()
		end

		if not success then
			mine()
		else
			table.remove(moves, #moves)
		end
	end
end

local function levelReached()
	return currentPos.y == level
end

local function move(direction)
	if direction == "u" then
		turtle.up()
	elseif direction == "d" then
		turtle.down()
	elseif direction == "f" then
		turtle.forward()
	elseif direction == "b" then
		turtle.back()
	elseif direction == "l" then
		turtle.turnLeft()
		turtle.forward()
		turtle.turnRight()
	elseif direction == "r" then
		turtle.turnRight()
		turtle.forward()
		turtle.turnLeft()
	end

	table.insert(moves, direction)
end

local function loop()
	while true do
		if refuel() then
			print("Refuelling")
		end

		if checkGoBackHome() then
			print("Returning home")
			moveTowardsHome()
		elseif not levelReached() then
			print("Moving to level")
			if currentPos.y < level then
				move("u")
			else
				move("d")
			end
		else
			print("Mining")
			mine()
			print("Moving forward")
			move("f")
		end
	end
end

loop()
