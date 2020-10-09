turtle.refuel()
print("Refuelled.")
while turtle.detect() do
    for i=1,3 do
	print("Dig")
        turtle.dig()
	print("Up")
        turtle.up()
    end
    print("Forward")
    turtle.forward()
    for i=1,3 do
	print("Down")
        turtle.down()
    end
end
