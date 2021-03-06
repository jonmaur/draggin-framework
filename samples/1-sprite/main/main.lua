-- make sure the draggin framework is found
package.path = package.path .. ';' .. os.getenv("DRAGGIN_FRAMEWORK") .. '/src/?.lua'

-- makes output work better on most hosts, or when running through Sublime Text.
io.stdout:setvbuf("no")

local Draggin = require "draggin/draggin"
local Display = require "draggin/display"

----------------------------------------------------------------
-- App Title
Draggin.appTitle = "Run Ninja, run!"

----------------------------------------------------------------
-- Display
-- params: <string> window text, <number> virtual width, <number> virtual height, <number> screen width, <number> screen height
Display:init(Draggin.appTitle, 1920/8, 1080/8, 1920/2, 1080/2, false)


local GameStateManager = require "draggin/gamestatemanager"
local NinjaState = require "ninjastate"

--- Main MOAIThread function of the application.
-- The whole application starts here to make sure you can always call coroutine.yield()
local function mainFunc()

	print("mainFunc")
	local ninjastate = NinjaState.new()

	GameStateManager.pushState(ninjastate)

	Draggin:waitForAnyInput()

	os.exit()
end

-- Let's just run the main function in a co-routine so we can use functions like Draggin:waitForAnyInput()
-- coroutines wake up once every frame, at the end of the frame they need to yield or reach the end of
-- the main coroutine function, effectively destroying that coroutine
local mainThread = MOAIThread.new()
mainThread:run(mainFunc)

print("end main.lua")