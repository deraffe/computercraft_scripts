local t = require("lib_turtle")

if not turtle then
    printError( "Requires a Turtle" )
    return
end

local function status()
    print( "Cut " .. t.collected .. " items total." )
    print("Fuel level: " .. turtle.getFuelLevel())
    print("Currently at tree height " .. height)
end

local function error(message)
    status()
    print(message)
    return nil, message
end

-- main program

height = 0

-- climb tree
while t.detectBlock("minecraft:spruce_log") do
    t.tryUp()
    height = height + 1
end
-- go one additional up for good measure
t.tryUp()
-- clear 4x4
t.tryForward()
t.tryForward()
turtle.turnLeft()
t.tryForward()
turtle.turnLeft()
t.tryForward()
turtle.turnLeft()
t.tryForward()
turtle.turnLeft()
while t.detectBlock({"minecraft:spruce_log", "minecraft:spruce_leaves"}, "down") do
    t.tryDown()
    t.tryForward()
    t.tryForward()
    turtle.turnLeft()
    t.tryForward()
    turtle.turnLeft()
    t.tryForward()
    turtle.turnLeft()
    t.tryForward()
    turtle.turnLeft()
end
turtle.back()
print("Felled tree.")
-- plant new big spruce
local saplingSlot = t.findItem("minecraft:spruce_sapling")
if not saplingSlot then
    print("No saplings found.")
else
    local oldSlot = turtle.getSelectedSlot()
    turtle.select(saplingSlot)
    t.tryForward()
    t.tryForward()
    turtle.turnLeft()
    turtle.place()
    turtle.turnRight()
    turtle.back()
    turtle.turnLeft()
    turtle.place()
    turtle.turnRight()
    turtle.place()
    turtle.back()
    turtle.place()
    turtle.select(oldSlot)
end
status()
