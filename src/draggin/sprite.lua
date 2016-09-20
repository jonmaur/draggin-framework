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


local Signal = require "draggin/signal"
local SpriteManager = require "draggin/spritemanager"

local Sprite = {}


--- Create a Sprite instance.
-- A Sprite is a MOAIProp2D with extra stuff like animation.
-- @param _strSprite the name of the sprite data to load
-- @return the new Sprite instance
function Sprite.new(_strSprite)

	local spriteData = SpriteManager.getSpriteData(_strSprite)

	-- make a sprite, it's also a MOAIProp2D so make that first, then just tack on the "sprite" stuff
	local sprite = MOAIProp2D.new()
	sprite:setDeck(spriteData.deck)

	sprite.anim = MOAIAnim:new()
	sprite.anim:reserveLinks(1)

	sprite.spriteData = spriteData

	local currAnimationName = ""


	-- event signals
	sprite.sig_spritechanged = Signal.new()
	sprite.sig_animationchanged = Signal.new()
	sprite.sig_animationcomplete = Signal.new()

	--- Set the sprite data to use for this Sprite.
	-- Emits a sig_spritechanged signal with the name of the new sprite data
	-- @param _strSpriteData the name of the new sprite data to use
	-- @param _strAnim name of an animation in the new sprite data to play
	-- @param _speed optional speed of the animation
	-- @param _mode optional mode of the animation, eg MOAITimer.LOOP
	function sprite:setSpriteData(_strSpriteData, _strAnim, _speed, _mode)

		--self.anim:stop()
		self.spriteData = SpriteManager.getSpriteData(_strSpriteData)
		self:setDeck(self.spriteData.deck)

		sprite.sig_spritechanged:emit(_strSpriteData)

		if not _strAnim then
			if self.spriteData.curves[currAnimationName] then
				_strAnim = currAnimationName
			else
				for k, v in pairs(self.spriteData.curves) do
					_strAnim = k
					break
				end
			end
		end

		self:playAnimation(_strAnim, _speed, _mode)
	end

	--- Plays an animtion of this Sprite.
	-- Emits a sig_animationchanged signal with the new animation name
	-- @param _strAnim the name of the animation to play
	-- @param _speed optional speed of the animation 1 = normal speed, 0 = paused
	-- @param _mode optional mode of the animation, eg MOAITimer.LOOP
	function sprite:playAnimation(_strAnim, _speed, _mode)

		_speed = _speed or 1
		_mode = _mode or MOAITimer.LOOP

		if _mode == MOAITimer.LOOP and currAnimationName == _strAnim then
			self.anim:setSpeed(_speed)
			return
		end

		self.anim:stop()

		self.anim = MOAIAnim:new()
		self.anim:reserveLinks(1)

		assert(self.spriteData.curves[_strAnim] ~= nil, "Cannot find animation "..tostring(_strAnim))
		self.anim:setLink(1, self.spriteData.curves[_strAnim], self, MOAIProp2D.ATTR_INDEX)
		self.anim:setMode(_mode)
		self.anim:setSpeed(_speed)
		self.anim:start()

		self.anim:setListener(MOAITimer.EVENT_TIMER_END_SPAN, function() sprite.sig_animationcomplete:emit() end)


		currAnimationName = _strAnim

		sprite.sig_animationchanged:emit(_strAnim)
	end

	--- Get the current animation name.
	-- @return string, the current animation name of this Sprite.
	function sprite:getCurrentAnimationName()
		return currAnimationName
	end

	--- Get the bounds.
	-- The bound is determined by only the first frame of the current animation.
	-- The bounding box is already cropped to the pixels of the frame.
	-- @return the bounding box of the first frame of the current animation scaled by the Sprite's scale.
	function sprite:getBounds()
		local bounds = {unpack(self.spriteData.bounds[currAnimationName])}

		-- scale the bounds
		local sx, sy = self:getScl()

		bounds[1] = bounds[1] * sx
		bounds[2] = bounds[2] * sy
		bounds[3] = bounds[3] * sx
		bounds[4] = bounds[4] * sy

		return bounds
	end

	return sprite
end

return Sprite
