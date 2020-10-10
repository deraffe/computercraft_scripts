local collected = 0

local function collect()
    collected = collected + 1
    if math.fmod(collected, 25) == 0 then
        print( "Collected " .. collected .. " items." )
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

local function error(message)
    status()
    print(message)
    return nil, message
end

local function detectBlock(name, direction)
    local ret = nil
    local data = nil
    if direction == nil or direction == "forward" then
        ret, data = turtle.inspect()
    elseif direction == "up" then
        ret, data = turtle.inspectUp()
    elseif direction == "down" then
        ret, data = turtle.inspectDown()
    else
        return nil, "Unsupported direction"
    end
    if type(name) == "string" then
        return ret and data.name == name
    elseif type(name) == "table" then
        local matches = false
        for block in name do
            if data.name == block then
                matches = true
            end
        end
        return ret and matches
    else
        return nil, "Unsupported name argument"
    end
end

return {
    collected = collected,
    tryUp = tryUp,
    tryDown = tryDown,
    tryForward = tryForward,
    turnAround = turnAround,
    findItem = findItem,
    tryPlaceTorchBehind = tryPlaceTorchBehind,
    fixLavaAndWater = fixLavaAndWater,
    error = error,
    detectBlock = detectBlock,
}
