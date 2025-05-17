local home = { x = 304, y = 58, z = -139 }
local currentPos = home
local checkpoint = currentPos
local undesirables = {
	"minecraft:stone",
	"minecraft:granite",
	"minecraft:diorite",
	"minecraft:andesite",
	"minecraft:dirt",
	"minecraft:gravel",
	"minecraft:clay",
	"minecraft:cobblestone",
	"byg:soapstone",
	"byg:rocky_stone",
}
local level = 50
local moves = {}

local fuelLimit = turtle.getFuelLimit()

local function savePosition()
	local file = fs.open("programs/position.txt", "w")
	if file then
		file.writeLine("x: " .. currentPos.x)
		file.writeLine("y: " .. currentPos.y)
		file.writeLine("z: " .. currentPos.z)
		file.close()
	else
		print("Error saving position")
	end
end

local function move(direction, movesList)
	print("Moving " .. direction)
	if direction == "u" then
		currentPos.y = currentPos.y + 1
		turtle.up()
	elseif direction == "d" then
		currentPos.y = currentPos.y - 1
		turtle.down()
	elseif direction == "f" then
		currentPos.x = currentPos.x + 1
		turtle.forward()
	elseif direction == "b" then
		currentPos.x = currentPos.x - 1
		turtle.back()
	elseif direction == "l" then
		currentPos.z = currentPos.z - 1
		turtle.turnLeft()
		turtle.forward()
		turtle.turnRight()
	elseif direction == "r" then
		currentPos.z = currentPos.z + 1
		turtle.turnRight()
		turtle.forward()
		turtle.turnLeft()
	end

	table.insert(movesList, direction)
	savePosition()
end

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

local function moveBack(movesList)
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

local function tableContains(table, value)
	for i = 1, #table do
		if table[i] == value then
			return true
		end
	end
	return false
end

local function advancedMine()
	local hasFoundMinable
	local done
	local mineMoves = {}
	local firstMinableFound = false

	repeat
		hasFoundMinable = false

		if turtle.detectUp() then
			local _, item = turtle.inspectUp()
			if item and item.name and not tableContains(undesirables, item.name) then
				turtle.digUp()
				if not firstMinableFound then
					checkpoint = currentPos
					firstMinableFound = true
				end
				hasFoundMinable = true
				move("u", mineMoves)
			end
		end

		if turtle.detectDown() then
			local _, item = turtle.inspectDown()
			if item and item.name and not tableContains(undesirables, item.name) then
				turtle.digDown()
				if not firstMinableFound then
					checkpoint = currentPos
					firstMinableFound = true
				end
				hasFoundMinable = true
				move("d", mineMoves)
			end
		end

		turtle.turnLeft()
		if turtle.detect() then
			local _, item = turtle.inspect()
			if item and item.name and not tableContains(undesirables, item.name) then
				turtle.digDown()
				if not firstMinableFound then
					checkpoint = currentPos
					firstMinableFound = true
				end
				hasFoundMinable = true
				move("f", mineMoves)
			end
		end
		turtle.turnRight()

		turtle.turnRight()
		if turtle.detect() then
			local _, item = turtle.inspect()
			if item and item.name and not tableContains(undesirables, item.name) then
				turtle.digDown()
				if not firstMinableFound then
					checkpoint = currentPos
					firstMinableFound = true
				end
				hasFoundMinable = true
				move("f", mineMoves)
			end
		end
		turtle.turnLeft()

		if not hasFoundMinable then
			moveBack(mineMoves)
		end

		if currentPos == checkpoint then
			done = true
		end

	until done
end

local function checkGoBackHome()
	local distance = 0
	local margin = 25
	distance = distance + math.abs(home.x - currentPos.x)
	distance = distance + math.abs(home.y - currentPos.y)
	distance = distance + math.abs(home.z - currentPos.z)

	print(getMovementLeft())
	return getMovementLeft() - distance + margin <= 0
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

local function loadPosition()
	local file = fs.open("programs/position.txt", "r")
	if file then
		local x = tonumber(file.readLine():match("x: (%d+)"))
		local y = tonumber(file.readLine():match("y: (%d+)"))
		local z = tonumber(file.readLine():match("z: (%d+)"))
		file.close()

		if x and y and z then
			currentPos.x = x
			currentPos.y = y
			currentPos.z = z
			print("Loaded position: " .. currentPos.x .. ", " .. currentPos.y .. ", " .. currentPos.z)
		else
			print("Error loading position")
		end
	else
		print("No saved position found")
	end
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
				turtle.digUp()
				move("u", moves)
			else
				turtle.digDown()
				move("d", moves)
			end
		else
			print("Mining")
			advancedMine()
			-- mine()
			move("f", moves)
		end
	end
end

loadPosition()
loop()
