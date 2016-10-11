-- make sure the draggin framework is found
package.path = package.path .. ';' .. os.getenv("DRAGGIN_FRAMEWORK") .. '/src/?.lua'

-- makes output work better on most hosts, or when running through Sublime Text.
io.stdout:setvbuf("no")

-- ONLY WORKS IF RUNNING ON A HOST WITH IMGUI!
if not MOAIImGui then
	print("This sample requires an ImGui enabled host.")
	os.exit()
end


-- MOAISim.SIM_LOOP_FORCE_STEP
-- MOAISim.SIM_LOOP_ALLOW_BOOST
-- MOAISim.SIM_LOOP_ALLOW_SPIN
-- MOAISim.SIM_LOOP_NO_DEFICIT
-- MOAISim.SIM_LOOP_NO_SURPLUS
-- MOAISim.SIM_LOOP_RESET_CLOCK
-- MOAISim.setLoopFlags(MOAISim.LOOP_FLAGS_FIXED)

local Draggin = require "draggin/draggin"
local Display = require "draggin/display"

----------------------------------------------------------------
-- App Title
Draggin.appTitle = "Sprite Preview"

----------------------------------------------------------------
-- Display
-- params: <string> window text, <number> virtual width, <number> virtual height, <number> screen width, <number> screen height
Display:init(Draggin.appTitle, 1920/2, 1080/2, 1920/2, 1080/2, false)


local GameStateManager = require "draggin/gamestatemanager"
local SpritePreviewState = require "spritepreviewstate"
-- local ImGuiTestState = require "ImGuiTestState"

--- Main MOAIThread function of the application.
-- The whole application starts here to make sure you can always call coroutine.yield()
local function mainFunc()

	print("mainFunc")
	local spritepreviewstate = SpritePreviewState.new()
	-- local imguiteststate = ImGuiTestState.new()

	GameStateManager.pushState(spritepreviewstate)
	-- GameStateManager.pushState(imguiteststate)
	while GameStateManager.isStateOnStack(spritepreviewstate) do
	-- while GameStateManager.isStateOnStack(imguiteststate) do
		coroutine.yield()
	end

	os.exit()
end

-- Let's just run the main function in a co-routine so we can use functions like Draggin:waitForAnyInput()
-- coroutines wake up once every frame, at the end of the frame they need to yield or reach the end of
-- the main coroutine function, effectively destroying that coroutine
local mainThread = MOAIThread.new()
mainThread:run(mainFunc)

print("end main.lua")