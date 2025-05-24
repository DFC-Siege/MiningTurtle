local function shallowCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = v
	end
	return copy
end

local home = { x = 256, y = 69, z = -148 }
local currentPos = shallowCopy(home)
local checkpoint = shallowCopy(currentPos)
local undesirables = {
	"minecraft:stone",
	"minecraft:grass",
	"minecraft:grass_block",
	"minecraft:granite",
	"minecraft:diorite",
	"minecraft:andesite",
	"minecraft:dirt",
	"minecraft:gravel",
	"minecraft:clay",
	"minecraft:cobblestone",
	"byg:soapstone",
	"byg:rocky_stone",
	"astralsorcery:marble_raw",
	"byg:scoria_stone",
}
local level = 50
local moves = {}

local fuelLimit = turtle.getFuelLimit()

local shouldEmpty = true

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
		local success = turtle.up()
		if success then
			currentPos.y = currentPos.y + 1
		end
	elseif direction == "d" then
		local success = turtle.down()
		if success then
			currentPos.y = currentPos.y - 1
		end
	elseif direction == "f" then
		local success = turtle.forward()
		if success then
			currentPos.x = currentPos.x + 1
		end
	elseif direction == "b" then
		local success = turtle.back()
		if success then
			currentPos.x = currentPos.x - 1
		end
	elseif direction == "l" then
		turtle.turnLeft()
		local success = turtle.forward()
		turtle.turnRight()
		if success then
			currentPos.z = currentPos.z - 1
		end
	elseif direction == "r" then
		turtle.turnRight()
		local success = turtle.forward()
		turtle.turnLeft()
		if success then
			currentPos.z = currentPos.z + 1
		end
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
	if #movesList == 0 then
		print("No moves to go back")
		return
	end

	local lastMove = movesList[#movesList]

	local success = false
	if lastMove == "f" then
		success = turtle.back()
		if success then
			currentPos.x = currentPos.x - 1
		end
	elseif lastMove == "b" then
		success = turtle.forward()
		if success then
			currentPos.x = currentPos.x + 1
		end
	elseif lastMove == "u" then
		success = turtle.down()
		if success then
			currentPos.y = currentPos.y - 1
		end
	elseif lastMove == "d" then
		success = turtle.up()
		if success then
			currentPos.y = currentPos.y + 1
		end
	elseif lastMove == "l" then
		turtle.turnRight()
		success = turtle.forward()
		if success then
			currentPos.z = currentPos.z + 1
		end
		turtle.turnLeft()
	elseif lastMove == "r" then
		turtle.turnLeft()
		success = turtle.forward()
		if success then
			currentPos.z = currentPos.z - 1
		end
		turtle.turnRight()
	end

	print("Moving " .. lastMove)

	if not success then
		mine()
	else
		table.remove(movesList, #movesList)
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
				print("Found: " .. item.name)
				turtle.digUp()
				if not firstMinableFound then
					checkpoint = shallowCopy(currentPos)
					firstMinableFound = true
				end
				hasFoundMinable = true
				move("u", mineMoves)
			end
		end

		if turtle.detectDown() then
			local _, item = turtle.inspectDown()
			if item and item.name and not tableContains(undesirables, item.name) then
				print("Found: " .. item.name)
				turtle.digDown()
				if not firstMinableFound then
					checkpoint = shallowCopy(currentPos)
					firstMinableFound = true
				end
				hasFoundMinable = true
				move("d", mineMoves)
			end
		end

		turtle.turnLeft()
		local turnedRight = false
		if turtle.detect() then
			local _, item = turtle.inspect()
			if item and item.name and not tableContains(undesirables, item.name) then
				print("Found: " .. item.name)
				turtle.dig()
				if not firstMinableFound then
					checkpoint = shallowCopy(currentPos)
					firstMinableFound = true
				end
				hasFoundMinable = true
				turtle.turnRight()
				turnedRight = true
				move("l", mineMoves)
			end
		end
		if not turnedRight then
			turtle.turnRight()
		end

		turtle.turnRight()
		local turnedLeft = false
		if turtle.detect() then
			local _, item = turtle.inspect()
			if item and item.name and not tableContains(undesirables, item.name) then
				print("Found: " .. item.name)
				turtle.dig()
				if not firstMinableFound then
					checkpoint = shallowCopy(currentPos)
					firstMinableFound = true
				end
				hasFoundMinable = true
				turtle.turnLeft()
				turnedLeft = true
				move("r", mineMoves)
			end
		end
		if not turnedLeft then
			turtle.turnLeft()
		end

		if turtle.detect() then
			local _, item = turtle.inspect()
			if item and item.name and not tableContains(undesirables, item.name) then
				print("Found: " .. item.name)
				turtle.dig()
				if not firstMinableFound then
					checkpoint = shallowCopy(currentPos)
					firstMinableFound = true
				end
				hasFoundMinable = true
				move("f", mineMoves)
			end
		end

		turtle.turnLeft()
		turtle.turnLeft()
		local turnedBack = false
		if turtle.detect() then
			local _, item = turtle.inspect()
			if item and item.name and not tableContains(undesirables, item.name) then
				print("Found: " .. item.name)
				turtle.dig()
				if not firstMinableFound then
					checkpoint = shallowCopy(currentPos)
					firstMinableFound = true
				end
				hasFoundMinable = true
				turtle.turnRight()
				turtle.turnRight()
				turnedBack = true
				move("b", mineMoves)
			end
		end
		if not turnedBack then
			turtle.turnRight()
			turtle.turnRight()
		end

		if firstMinableFound and not hasFoundMinable then
			print("No more minable blocks found, moving back")
			moveBack(mineMoves)
		end

		if not firstMinableFound then
			print("No minable blocks found continue")
			done = true
		end

		print("Current position: " .. currentPos.x .. ", " .. currentPos.y .. ", " .. currentPos.z)
		print("Checkpoint position: " .. checkpoint.x .. ", " .. checkpoint.y .. ", " .. checkpoint.z)
		print(currentPos.x == checkpoint.x and currentPos.y == checkpoint.y and currentPos.z == checkpoint.z)
		if
			firstMinableFound
			and currentPos.x == checkpoint.x
			and currentPos.y == checkpoint.y
			and currentPos.z == checkpoint.z
		then
			print("Checkpoint reached")
			firstMinableFound = false
		end

	until done
end

local function inventoryFull()
	local full = true
	for i = 1, 16 do
		local item = turtle.getItemDetail(i)
		if not item then
			full = false
			break
		end
	end

	return full
end

local function inventoryEmpty()
	local empty = true
	for i = 1, 16 do
		local item = turtle.getItemDetail(i)
		if item then
			empty = false
			break
		end
	end

	return empty
end

local function isHome()
	local distance = 0
	distance = distance + math.abs(home.x - currentPos.x)
	distance = distance + math.abs(home.y - currentPos.y)
	distance = distance + math.abs(home.z - currentPos.z)

	return distance == 0
end

local function checkGoBackHome()
	local distance = 0
	local margin = 25
	distance = distance + math.abs(home.x - currentPos.x)
	distance = distance + math.abs(home.y - currentPos.y)
	distance = distance + math.abs(home.z - currentPos.z)

	print(getMovementLeft())
	local notEnoughFuel = getMovementLeft() - distance + margin <= 0
	local isInventoryFull = inventoryFull()

	if isInventoryFull then
		shouldEmpty = true
	end

	return isInventoryFull or notEnoughFuel
end

local function moveTowardsHome()
	while #moves > 0 do
		local lastMove = moves[#moves]

		local success = false
		if lastMove == "f" then
			success = turtle.back()
			if success then
				currentPos.x = currentPos.x - 1
			end
		elseif lastMove == "b" then
			success = turtle.forward()
			if success then
				currentPos.x = currentPos.x + 1
			end
		elseif lastMove == "u" then
			success = turtle.down()
			if success then
				currentPos.y = currentPos.y - 1
			end
		elseif lastMove == "d" then
			success = turtle.up()
			if success then
				currentPos.y = currentPos.y + 1
			end
		elseif lastMove == "l" then
			turtle.turnRight()
			success = turtle.forward()
			if success then
				currentPos.z = currentPos.z + 1
			end
			turtle.turnLeft()
		elseif lastMove == "r" then
			turtle.turnLeft()
			success = turtle.forward()
			if success then
				currentPos.z = currentPos.z - 1
			end
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

		if shouldEmpty and isHome() and not inventoryEmpty() then
			print("Emptying inventory")
		elseif checkGoBackHome() then
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
			turtle.dig()
			move("f", moves)
		end
	end
end

loadPosition()
loop()
