if not turtle then
    printError( "Requires a Turtle" )
    return
end

local collected = 0

local function collect()
    collected = collected + 1
    if math.fmod(collected, 25) == 0 then
        print( "Mined " .. collected .. " items." )
    end
end

local function tryDig()
    while turtle.detect() do
        if turtle.dig() then
            collect()
            sleep(0.5)
        else
            return false
        end
    end
    return true
end

local function tryDigUp()
    while turtle.detectUp() do
        if turtle.digUp() then
            collect()
            sleep(0.5)
        else
            return false
        end
    end
    return true
end

local function tryDigDown()
    while turtle.detectDown() do
        if turtle.digDown() then
            collect()
            sleep(0.5)
        else
            return false
        end
    end
    return true
end

local function refuel()
    local fuelLevel = turtle.getFuelLevel()
    if fuelLevel == "unlimited" or fuelLevel > 0 then
        return
    end

    local function tryRefuel()
        for n = 1, 16 do
            if turtle.getItemCount(n) > 0 then
                turtle.select(n)
                if turtle.refuel(1) then
                    turtle.select(1)
                    return true
                end
            end
        end
        turtle.select(1)
        return false
    end

    if not tryRefuel() then
        print( "Add more fuel to continue." )
        while not tryRefuel() do
            os.pullEvent( "turtle_inventory" )
        end
        print( "Resuming Tunnel." )
    end
end

local function tryUp()
    refuel()
    while not turtle.up() do
        if turtle.detectUp() then
            if not tryDigUp() then
                return false
            end
        elseif turtle.attackUp() then
            collect()
        else
            sleep( 0.5 )
        end
    end
    return true
end

local function tryDown()
    refuel()
    while not turtle.down() do
        if turtle.detectDown() then
            if not tryDigDown() then
                return false
            end
        elseif turtle.attackDown() then
            collect()
        else
            sleep( 0.5 )
        end
    end
    return true
end

local function tryForward()
    refuel()
    while not turtle.forward() do
        if turtle.detect() then
            if not tryDig() then
                return false
            end
        elseif turtle.attack() then
            collect()
        else
            sleep( 0.5 )
        end
    end
    return true
end

local function isFuelLevelOkay(threshold)
    fuelThreshold = threshold or (9701/2)  -- 64 coal
    return turtle.getFuelLevel() > fuelThreshold
end

local function turnAround()
    turtle.turnLeft()
    turtle.turnLeft()
end

local function findItem(name)
    for n = 1, 16 do
        if turtle.getItemCount(n) > 0 then
            local detail = turtle.getItemDetail(n)
            if detail.name == name then
                return n
            end
        end
    end
end

local function tryPlaceTorchBehind()
    turnAround()
    if not turtle.detect() then
        local torchSlot = findItem("minecraft:torch")
        if not torchSlot then
            print("No torches found.")
            turnAround()
            return
        end
        local oldSlot = turtle.getSelectedSlot()
        turtle.select(torchSlot)
        if not turtle.place() then
            print("Could not place torch.")
        end
        turtle.select(oldSlot)
    else
        print("Found obstacle where torch belongs")
    end
    turnAround()
end

local function isLavaOrWater(inspectResult)
    return (inspectResult.name == "minecraft:lava")
        or (inspectResult.name == "minecraft:water" and inspectResult.state.level == 0)
end

local function fixLavaAndWaterInDirection(direction)
    local success = nil
    local data = nil
    if direction == nil or direction == "forward" then
        success, data = turtle.inspect()
        if success and isLavaOrWater(data) then
            return turtle.place()
        end
    elseif direction == "up" then
        success, data = turtle.inspectUp()
        if success and isLavaOrWater(data) then
            return turtle.placeUp()
        end
    elseif direction == "down" then
        success, data = turtle.inspectDown()
        if success and isLavaOrWater(data) then
            return turtle.placeDown()
        end
    else
        return nil, "Unsupported direction"
    end
end

local function fixLavaAndWater()
    turtle.turnLeft()
    for i=1,2 do
        fixLavaAndWaterInDirection("forward")
        turtle.turnRight()
    end
    turtle.turnLeft()
    fixLavaAndWaterInDirection("up")
    fixLavaAndWaterInDirection("down")
end

local function mayContinueDigging()
    if length == "unlimited" then
        return isFuelLevelOkay()
    else
        return depth <= length
    end
end

-- argument handling
length = nil
height = nil
width = nil
local tArgs = { ... }
if #tArgs > 0 then
    if tArgs[1] ~= "unlimited" then
        length = tonumber(tArgs[1])
    end
    height = tonumber(tArgs[2])
    width = tonumber(tArgs[3])
end
if length == nil then
    length = "unlimited"
end
if height == nil then
    height = 3
end
if width == nil then
    width = 1
end
if height < 1 then
    print("Tunnel height must be positive")
    return
end

local function status()
    print( "Mined " .. collected .. " items total." )
    print("Fuel level: " .. turtle.getFuelLevel())
    print("Currently at tunnel depth " .. depth .. " (max " .. (maxDepth or "0") .. ")")
end

local function error(message)
    status()
    print(message)
    return nil, message
end

-- main program

print( "Tunnelling " .. length .. " blocks to a height and width of " .. height .. "x" .. width .. "..." )

depth = 0
maxDepth = depth

while mayContinueDigging() do
    -- make sure ground is there
    turtle.placeDown()
    if tryForward() then
        depth = depth + 1
        maxDepth = depth
        fixLavaAndWater()
    else
        return error("Could not move forward")
    end
    for w=1,width do
        for h=2,height do
            tryUp()
            fixLavaAndWater()
        end
        if depth % 4 == 0 and w == width then
            tryPlaceTorchBehind()
        end
        for h=height-1,1,-1 do
            tryDown()
        end
        if width > w then
            turtle.turnRight()
            if tryForward() then
                fixLavaAndWater()
                turtle.placeDown()
            else
                return error("Could not move sideways")
            end
            turtle.turnLeft()
        end
    end
    turtle.turnLeft()
    for i=width-1,1,-1 do
        if not tryForward() then
            return error("Could not return to left side")
        end
    end
    turtle.turnRight()
end
-- back to start
print("Fuel is low, returning from a depth of " .. depth .. " blocks...")

-- Return to where we started
turnAround()
while depth > 0 do
    if tryForward() then
        depth = depth - 1
    else
        print("Encountered obstacle at " .. depth .. " blocks into the tunnel.")
        return false
    end
end
turnAround()

print( "Tunnel complete." )
status()
