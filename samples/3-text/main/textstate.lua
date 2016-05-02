local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local TextBox = require "draggin/textbox"

local viewport = Display.viewport
local virtualWidth = Display.virtualWidth
local virtualHeight = Display.virtualHeight

local textstate = {}

function textstate.new()

	--Draggin:debugDraw(true)

	local state = {}

	state.name = "TextState"

	local layers = {}
	local mainlayer

	local textboxes = {}

	function state:init()

		-- create the main layer
		mainlayer = MOAILayer2D.new()
		mainlayer:setViewport(viewport)
		layers[#layers+1] = mainlayer

		-- create the text boxes
		local txt = TextBox.new("LiberationSansNarrow-Regular", 42)
		-- txt:setRect(virtualWidth/4, virtualHeight/2, virtualWidth - virtualWidth/4, virtualHeight - virtualHeight/8)
		txt:setDimensions(virtualWidth*0.5, virtualHeight*0.75, virtualWidth/2, virtualHeight/3, 0.5, 0.5)
		txt:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
		txt:setSpeed(15)
		txt:insertIntoLayer(mainlayer)
		table.insert(textboxes, txt)


		txt = TextBox.new("PressStart16")
		txt:setColor(0, 1, 0, 1)
		txt:setShadowOffset(2, 2)
		txt:setDimensions(0, 0, virtualWidth/4, virtualHeight/8, 0, 0)
		txt:setAlignment(MOAITextBox.LEFT_JUSTIFY, MOAITextBox.BOTTOM_JUSTIFY)
		txt:setString('BOTTOM LEFT')
		table.insert(textboxes, txt)


		txt = TextBox.new("PressStart16")
		txt:setColor(0, 1, 0, 1)
		txt:setShadowColor(1, 0, 0, 0.75)
		txt:setShadowOffset(-2, 2)
		txt:setDimensions(virtualWidth, 0, virtualWidth/4, virtualHeight/8, 1, 0)
		txt:setAlignment(MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.BOTTOM_JUSTIFY)
		txt:setString('BOTTOM RIGHT')
		table.insert(textboxes, txt)


		txt = TextBox.new("PressStart16")
		txt:setColor(0.75, 0, 0, 1)
		txt:setShadowColor(0, 0, 0, 0.75)
		txt:setShadowOffset(2, -2)
		txt:setDimensions(0, virtualHeight, virtualWidth/4, virtualHeight/8, 0, 1)
		txt:setAlignment(MOAITextBox.LEFT_JUSTIFY, MOAITextBox.TOP_JUSTIFY)
		txt:setString('TOP LEFT')
		table.insert(textboxes, txt)


		txt = TextBox.new("PressStart16")
		txt:setColor(0, 0, 1, 1)
		txt:setShadowColor(0, 0, 0.5, 1)
		txt:setShadowOffset(-2, -2)
		txt:setDimensions(virtualWidth, virtualHeight, virtualWidth/4, virtualHeight/8, 1, 1)
		txt:setAlignment(MOAITextBox.RIGHT_JUSTIFY, MOAITextBox.TOP_JUSTIFY)
		txt:setString('TOP RIGHT')
		table.insert(textboxes, txt)


		txt = TextBox.new("LiberationSansNarrow-Regular", 24)
		txt:setColor(1, 1, 0, 1)
		txt:setDimensions(virtualWidth/2, virtualHeight/8, virtualWidth/4, virtualHeight/16, 0.5, 0.5)
		txt:setAlignment(MOAITextBox.CENTER_JUSTIFY, MOAITextBox.CENTER_JUSTIFY)
		txt:setString('Press something to exit')
		table.insert(textboxes, txt)

		print(state.name.." init() done.")
	end

	function state:gotFocus()

		print(state.name.." got focus")

		local function introFunc()

			textboxes[1]:setString('I guess this is the\n"HELLO WORLD!"\nexample.')

			local spoolAction = textboxes[1]:spool()
			MOAIThread.blockOnAction(spoolAction)

			Draggin:wait(1)

			for i = 2, #textboxes - 1 do
				textboxes[i]:insertIntoLayer(mainlayer)
			end

			Draggin:wait(1)

			textboxes[#textboxes]:insertIntoLayer(mainlayer)
			textboxes[#textboxes]:blink(1)
		end


		state.introThread = MOAIThread.new()
		state.introThread:run(introFunc)

		-- Make this state's layers the current render table
		-- Only one render table can be actively rendered
		MOAIRenderMgr.setRenderTable(layers)
	end

	function state:lostFocus()
		print(state.name.." lost focus")

		for i = 1, #textboxes do
			textboxes[i]:removeFromLayer()
		end
	end


	return state
end

return textstate
