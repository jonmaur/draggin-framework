--[[
Copyright (c) 2014 Jon Maur

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]]

----------------------------------------------------------------
-- Sound
-- A wrapper for untz sound objects. Adds callbacks for events.

local Signal = require "draggin/signal"
local AudioManager = require "draggin/audiomanager"

local Sound = {}

--- Create a Sound instance.
-- Uses Untz, but if Untz isn't there this still mostly works, it just
-- won't make any noise.
-- @param _strSound the name of the sound to load from the "./res/audio/" directory, include the file extention please.
-- @param _group the name of the group the Sound belongs to
-- @return a new Sound instance
function Sound.new(_strSound, _group)

	_group = _group or 'default'

	local sound = {}

	-- make a MOAIUntzSound if possible, if not just go on and make empty sound stuff
	local usound = nil
	local enabled = true

	if MOAIUntzSound then
		usound = MOAIUntzSound.new()
		print("loading audio", _strSound, _group)
		-- if you crash here, you probably forgot to do: MOAIUntzSystem.initialize(44100, 1000)   somewhere.
		usound:load("res/audio/".._strSound)
	else
		print("No MOAIUntzSound")
		enabled = false
	end

	sound.untz = usound

	print("usound", _strSound, usound)

	-- TODO: signals for looped and stopped
	local sig_played = Signal.new()
	--local sig_looped = Signal.new()
	local sig_stopped = Signal.new()

	--- Play the Sound.
	-- emits a sig_played signal sending the Sound's name
	function sound:play()

		if not enabled then
			return
		end
		--print("Play sound", _strSound)
		usound:play()
		sig_played:emit(_strSound)
	end

	--- Pause the Sound.
	function sound:pause()

		if not enabled then
			return
		end
		--print("Pause sound", _strSound)
		usound:pause()
	end

	--- Stop the Sound.
	-- emits a sig_stopped signal sending the Sound's name
	function sound:stop()

		if not enabled then
			return
		end

		usound:stop()
		sig_stopped:emit(_strSound)
	end

	--- Set the looping flag.
	-- @param _bLooping true if the Sound should loop
	function sound:setLooping(_bLooping)

		if usound == nil then
			return
		end

		usound:setLooping(_bLooping)
	end

	--- Set the volume.
	-- @param _vol the volume, 0 to 1
	function sound:setVolume(_vol)

		if usound == nil then
			return
		end

		usound:setVolume(_vol)
	end

	--- Seek the volume.
	-- @param _target the target volume, 0 to 1
	-- @param _time the time in seconds that the volume change should take
	function sound:seekVolume(_target, _time)

		if usound == nil then
			return
		end

		usound:seekVolume(_target, _time)
	end

	--- Set the enable flag.
	-- @param _bEnable true or nil to enable the Sound, false to disable the Sound
	function sound:enable(_bEnable)
		if _bEnable == nil then
			_bEnable = true
		end

		-- if there's no MOAIUntzSound at all, never enable any sounds
		if MOAIUntzSound then
			enabled = _bEnable
			if enabled == false then
				-- stop just in case
				usound:stop()
			end
		else
			enabled = false
		end
	end

	--- Remove the sound from the AudioManager.
	function sound:remove()
		sound:stop()
		AudioManager:removeSound(sound, _group)
	end

	AudioManager:addSound(sound, _group)

	return sound
end

return Sound
