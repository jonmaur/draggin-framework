-- A ninja player
local Draggin = require "draggin/draggin"
local Sprite = require "draggin/sprite"
local Sound = require "draggin/sound"
local StateMachine = require "draggin/statemachine/statemachine"

-- globals to locals
local abs = math.abs
local floor = math.floor
local mod = math.mod
local lerp = Draggin.lerp

local Ninja = {}

function Ninja.new()
	local ninja = Sprite.new("ninja")
	ninja:setScl(4, 4)
	ninja:playAnimation("idleRight")

	----------------------------------------------------------------
	-- sounds
	local sndjump = Sound.new('jump.wav', 'fx')
	local sndattack = Sound.new('laser.wav', 'fx')

	----------------------------------------------------------------
	-- FSM setup
	local fsm = StateMachine:new(ninja)

	local function onEnterStateIdle(_event)
		ninja:playAnimation("idleRight")
		print("fsm idle!")
	end

	local function onEnterStateJump(_event)
		ninja:playAnimation("jumpRight", 1, MOAITimer.PING_PONG)
		sndjump:play()
		print("fsm jump!")

		ninja.sig_animationcomplete:register(function()
				fsm:changeState("idle")
				return true
			end)
	end

	local function onEnterStateAttack(_event)
		ninja:playAnimation("attackRight", 1, MOAITimer.NORMAL)
		sndattack:play()
		print("fsm attack!")
		ninja.sig_animationcomplete:register(function()
				fsm:changeState("idle")
				-- TODO: it would be super usefull for signals to be able to remove the
				-- current callback right here

				-- HACK: I hope no one else was registered...
				ninja.sig_animationcomplete:removeAll()
			end)
	end

	function ninja:tryJumpState()
		if fsm.state == "idle" then
			fsm:changeState("jump")
		end
	end

	function ninja:tryAttackState()
		if fsm.state == "idle" then
			fsm:changeState("attack")
		end
	end

	fsm:addState("idle", {from="*", enter=onEnterStateIdle})
	fsm:addState("jump", {from={"idle"}, enter=onEnterStateJump})
	fsm:addState("attack", {from={"idle"}, enter=onEnterStateAttack})

	fsm:setInitialState("idle")

	ninja.fsm = fsm


	function ninja:update()

		fsm:tick()
	end

	return ninja
end

return Ninja
