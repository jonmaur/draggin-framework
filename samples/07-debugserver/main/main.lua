-- make sure the draggin framework is found
package.path = package.path .. ';' .. os.getenv("DRAGGIN_FRAMEWORK") .. '/src/?.lua'

-- makes output work better on most hosts, or when running through Sublime Text.
io.stdout:setvbuf("no")

local Draggin = require "draggin/draggin"
local Display = require "draggin/display"
local DebugServer = require "draggin/debugserver"

----------------------------------------------------------------
-- App Title
Draggin.appTitle = "Ninja Finite State Machine"

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
local NinjaState = require "ninjastate"
local ninjastate = NinjaState.new()


-- some global functions we'll be calling from the debug server
-- currently the debug connection can only execute code in the global space
local debugserver = DebugServer.new()

function jump()
	ninjastate.actions:injectAction("jump")
end

function attack()
	ninjastate.actions:injectAction("attack")
end

function quit()
	ninjastate.actions:injectAction("quit")
end

-- Override the print function and send it all back to any clients
local realPrint = print
print = function (...)
	realPrint(...)
	local msg = ""
	local args = { ... }
	for k, v in pairs(args) do
		msg = msg..tostring(v)
	end
	debugserver:send(msg.."\r\n")
end

GameStateManager.pushState(ninjastate)
