-- makes output work better on most hosts, or when running through Sublime Text.
io.stdout:setvbuf("no")

local Draggin = require "draggin/draggin"
local Display = require "draggin/display"

----------------------------------------------------------------
-- App Title
Draggin.appTitle = "Today's Specials"

----------------------------------------------------------------
-- Display
-- params: <string> window text, <number> virtual width, <number> virtual height, <number> screen width, <number> screen height
Display:init(Draggin.appTitle, 1920/2, 1080/2, 1920/2, 1080/2, false)

----------------------------------------------------------------
-- AUDIO
if MOAIUntzSystem then
	MOAIUntzSystem.initialize(44100, 1000)
	print("Untz audio initialized")
end

local GameStateManager = require "draggin/gamestatemanager"
local MenuState = require "menustate"

--- Main MOAIThread function of the application.
-- The whole application starts here to make sure you can always call coroutine.yield()
local function mainFunc()

	local fb = MOAIGfxDevice:getFrameBuffer()
	fb:setClearColor(0, 1, 1)

	local menustate = MenuState.new()

	GameStateManager.pushState(menustate)
end

-- Let's just run the main function in a co-routine so we can use functions like Draggin:waitForAnyInput()
-- coroutines wake up once every frame, at the end of the frame they need to yield or reach the end of
-- the main coroutine function, effectively destroying that coroutine
local mainThread = MOAIThread.new()
mainThread:run(mainFunc)
