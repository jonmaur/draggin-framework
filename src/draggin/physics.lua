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

-- Box2D Physics!

local Physics = {}

function Physics.new(_gravity, _unitsToMeters, _layer)
	local box = {}

	_gravity = _gravity or {x=0, y=9.8}

	if type(_gravity) == "number" then
		_gravity = {x=0, y=_gravity}
	end

	_unitsToMeters = _unitsToMeters or 1/19

	local world = MOAIBox2DWorld.new()

	world:setUnitsToMeters(_unitsToMeters)
	-- this setting made it fast
	--world:setGravity(0, 9.8 / (1/19))
	world:setGravity(_gravity.x, _gravity.y)
	world:start()

	box.world = world

	if _layer then
		print("Debug Physics Draws on")
		_layer:setBox2DWorld(world)
	end


	function box:addRect(_type, x, y, w, h, r)

		local physBody = {}
		_type = _type or MOAIBox2DBody.STATIC
		r = r or 0

		local body = world:addBody(_type)

		local fixture = body:addRect(x, y, x+w, y+h)
		fixture:setFriction(0.1)

		body:setTransform(0, 0, r)
		physBody.body = body
		physBody.fixture = fixture

		return physBody
	end

	function box:addSpriteBody(_sprite, _type, _bounds)

		assert(_sprite)

		_type = _type or MOAIBox2DBody.DYNAMIC

		local body = world:addBody(_type)

		-- move to the sprite's position
		body:setTransform(_sprite:getLoc())

		_bounds = _bounds or _sprite:getBounds()

		local fixture = body:addRect(_bounds[1], _bounds[2], _bounds[3], _bounds[4])
		fixture:setFriction(0.5)
		fixture:setDensity(0.0001)
		fixture:setRestitution(0.2)
		--body:setMassData(320)

		-- hook it up to the sprite
		_sprite.body = body
		_sprite:setParent(body)
		_sprite.fixture = fixture

		body:resetMassData()
	end

	function box:addSpriteBodyCircle(_sprite, _type, _radius, _fixedrotation)

		assert(_sprite)

		_type = _type or MOAIBox2DBody.DYNAMIC
		_fixedrotation = _fixedrotation or false

		local body = world:addBody(_type)

		-- move to the sprite's position
		body:setTransform(_sprite:getLoc())
		body:setFixedRotation(_fixedrotation)

		local bounds = _sprite:getBounds()
		local midx = (bounds[3]-bounds[1])/2
		local midy = (bounds[4]-bounds[2])/2

		if not _radius then
			_radius = midx+0.5
		end

		local fixture = body:addCircle(0, 0, _radius-2)
		fixture:setFriction(0.5)
		fixture:setDensity(0.0001)
		fixture:setRestitution(0.2)
		--body:setMassData(320)

		-- hook it up to the sprite
		_sprite.body = body
		_sprite:setParent(body)
		_sprite.fixture = fixture

		body:resetMassData()
	end

	function box:addCircle(_type, x, y, r)
		local physBody = {}
		_type = _type or MOAIBox2DBody.STATIC

		local body = world:addBody(_type)

		local fixture = body:addCircle(x, y, r)
		fixture:setFriction(0.5)

		physBody.body = body
		physBody.fixture = fixture

		return physBody
	end

	function box:addChain(_verts, _close)
		assert(type(_verts) == "table")

		local physBody = {}

		local body = world:addBody(MOAIBox2DBody.STATIC)

		local chain = body:addChain(_verts, _close)

		physBody.body = body
		physBody.chain = chain

		chain:setFilter(2, 4)

		return physBody
	end

	return box
end

return Physics
