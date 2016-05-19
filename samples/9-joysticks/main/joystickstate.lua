local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local Sprite = require "draggin/sprite"
local TextBox = require "draggin/textbox"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local joystickstate = {}

function joystickstate.new()

	local state = {}

	state.name = "JoystickState"

	-- layers
	local layers = {}
	local mainlayer

	-- threads
	local joyThread

	-- sprites
	local ninja
	local circle
	local stick
	local circleright
	local stickright
	local boxrtrigger
	local rtrigger
	local boxltrigger
	local ltrigger
	local buttons = {}
	local numbuttons = 15

	-- textboxes
	local labels = {}

	function state:init()

		-- create the main layer
		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)
		layers[#layers+1] = mainlayer

		ninja = Sprite.new("ninja")
		ninja:setScl(4, 4)

		circle = Sprite.new("gamepad")
		stick = Sprite.new("gamepad")
		stick:setColor(1, 0, 0)

		circleright = Sprite.new("gamepad")
		stickright = Sprite.new("gamepad")
		stickright:setColor(1, 0, 0)

		boxrtrigger = Sprite.new("gamepad")
		rtrigger = Sprite.new("gamepad")
		rtrigger:setColor(1, 0, 0)

		boxltrigger = Sprite.new("gamepad")
		ltrigger = Sprite.new("gamepad")
		ltrigger:setColor(1, 0, 0)

		for i = 1, numbuttons do
			buttons[i] = Sprite.new("gamepad")
			labels[i] = TextBox.new("LiberationSansNarrow-Regular", 42)
			labels[i]:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
			labels[i]:setShadowOffset(-2, -2)
			-- labels[i]:setColor(0, 1, 0, 1)
		end

		print(state.name.." init() done.")
	end

	function state:gotFocus()

		print(state.name.." got focus")

		-- the ninja sprite
		ninja:playAnimation("runRight")
		ninja:setLoc(virtualWidth/2, 64)
		mainlayer:insertProp(ninja)

		-- the circle sprite
		circle:playAnimation("circle")
		circle:setLoc(128, 128)
		mainlayer:insertProp(circle)

		-- the stick sprite
		stick:playAnimation("stick")
		stick:setLoc(128, 128)
		mainlayer:insertProp(stick)

		-- the right circle sprite
		circleright:playAnimation("circle")
		circleright:setLoc(virtualWidth - 128, 128)
		mainlayer:insertProp(circleright)

		-- the right stick sprite
		stickright:playAnimation("stick")
		stickright:setLoc(virtualWidth - 128, 128)
		mainlayer:insertProp(stickright)

		-- the right box sprite
		boxrtrigger:playAnimation("box")
		boxrtrigger:setLoc(virtualWidth/2 + 200, 128)
		mainlayer:insertProp(boxrtrigger)

		-- the right trigger sprite
		rtrigger:playAnimation("stick")
		rtrigger:setLoc(virtualWidth/2 + 200, 128)
		mainlayer:insertProp(rtrigger)

		-- the left box sprite
		boxltrigger:playAnimation("box")
		boxltrigger:setLoc(virtualWidth/2 - 200, 128)
		mainlayer:insertProp(boxltrigger)

		-- the left trigger sprite
		ltrigger:playAnimation("stick")
		ltrigger:setLoc(virtualWidth/2 - 200, 128)
		mainlayer:insertProp(ltrigger)

		-- setup the button sprites
		for k, v in ipairs(buttons) do
			v:playAnimation("button")
			local xoffset = 32
			if k >= 13 then
				xoffset = 256-32
			end
			v:setLoc(128 * (((k-1) % 6)+1) + xoffset, (virtualHeight + 32) - (128 * (math.floor((k-1) / 6) + 1)))
			mainlayer:insertProp(v)
		end
		
		-- setup the button text labels
		for k, v in ipairs(labels) do
			local xoffset = 32
			if k >= 13 then
				xoffset = 256-32
			end
			v:setDimensions(128 * (((k-1) % 6)+1) + xoffset, (virtualHeight + 32) - (128 * (math.floor((k-1) / 6) + 1)), 128, 128, 0.5, 0.5)
			v:setString(tostring(k))
			v:insertIntoLayer(mainlayer)
		end

		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)

		local function joyFunc()
			while true do
				if Draggin.joysticks[1] then
					local lx, ly = Draggin.joysticks[1].stickLeft:getVector()
					local rx, ry = Draggin.joysticks[1].stickRight:getVector()
					local lt, rt = Draggin.joysticks[1].triggers:getVector()
					-- print("joy0", lx, ly, rx, ry)

					stick:setLoc(128 + (lx * 96), 128 + (-ly * 96))
					stickright:setLoc((virtualWidth - 128) + (rx * 96), 128 + (-ry * 96))

					rtrigger:setLoc(virtualWidth/2 + 200, 128 + (rt * 96))
					ltrigger:setLoc(virtualWidth/2 - 200, 128 + (lt * 96))
				end
				coroutine.yield()
			end
		end

		joyThread = MOAIThread.new()
		joyThread:run(joyFunc)

		local function joystickInputFunc(_padnumber, _index, _state)
			-- print("joystickInputFunc", _padnumber, _index, _state)
			if _padnumber == 1 then
				if _state == "up" then
					buttons[_index]:setColor(1, 1, 1)
				elseif _state == "down" then
					buttons[_index]:setColor(1, 0, 0)
				end
			end
		end

		-- and do all the joysticks
		Draggin:registerJoystickCallback(1, joystickInputFunc)

	end

	function state:lostFocus()
		print(state.name.." lost focus")
		mainlayer:removeProp(ninja)
		mainlayer:removeProp(circle)
		mainlayer:removeProp(stick)

		for k, v in ipairs(buttons) do
			mainlayer:removeProp(v)
		end
		
		for k, v in ipairs(labels) do
			v:removeFromLayer()
		end

		joyThread:stop()
		joyThread = nil
	end


	return state
end

return joystickstate
