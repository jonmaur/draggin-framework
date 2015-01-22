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

local Display = require "draggin/display"
local TextBox = require "draggin/textbox"
local Sprite = require "draggin/sprite"
local TableExt = require "draggin/tableext"


local Physics = {}


function Physics.new(_gravity, _unitsToMeters, _layer)
	local box = {}

	_gravity = _gravity or {x=0, y=-10}

	if type(_gravity) == "number" then
		_gravity = {x=0, y=_gravity}
	end

	_unitsToMeters = _unitsToMeters or 1


	local world = MOAIBox2DWorld.new()

	world:setUnitsToMeters(_unitsToMeters)
	-- this setting made it fast
	--world:setGravity(0, 9.8 / (1/19))
	world:setGravity(_gravity.x, _gravity.y)
	world:start()

	-- table to keep track of all bodies by name
	world.bodies = {}

	-- table to keep track of all joints by name
	world.joints = {}

	box.world = world

	local dbtxt
	if _layer then
		print("Debug Physics Draws on")
		_layer:setBox2DWorld(world)

		dbtxt = TextBox.new("gridblock7", 7, false)
		dbtxt:setDimensions(0, 0, Display.virtualWidth/2, Display.virtualHeight, 0, 0)
		dbtxt:insertIntoLayer(_layer)
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

	function box:loadRubeJson(_filename)

		local jsonFile = MOAIFileStream.new()
		jsonFile:open("res/rube/".._filename..".json")
		local jsonStr = jsonFile:read()

		local json = MOAIJsonParser.decode(jsonStr)

		--TableExt.print(json)
		local bodies = {}

		for _, v in ipairs(json.body) do

			local x = 0
			local y = 0


			-- "type": 2, //0 = static, 1 = kinematic, 2 = dynamic
			local bodytype = MOAIBox2DBody.STATIC
			if v.type == 1 then
				bodytype = MOAIBox2DBody.KINEMATIC
			elseif v.type == 2 then
				bodytype = MOAIBox2DBody.DYNAMIC
			end

			-- create the body
			local body = world:addBody(bodytype)


			if type(v.position) == "table" then
				x = v.position.x
				y = v.position.y
			end

			-- radians
			local angle = 0
			if type(v.angle) == "number" then
				angle = v.angle
			end
			-- "angularDamping": 0,
			local angularDamping = 0
			if type(v.angularDamping) == "number" then
				angularDamping = v.angularDamping
			end
			-- "angularVelocity": 0, //radians per second
			local angularVelocity = 0
			if type(v.angularVelocity) == "number" then
				angularVelocity = v.angularVelocity
			end
			-- "awake": true,
			if type(v.awake) == "boolean" then
				body:setAwake(v.awake)
			end
			-- "bullet": true,
			if type(v.bullet) == "boolean" then
				body:setBullet(v.bullet)
			end
			-- "fixedRotation": true,
			local fixedRotation = true
			if type(v.fixedRotation) == "boolean" then
				fixedRotation = v.fixedRotation
			end
			-- "linearDamping": 0,
			local linearDamping = 0
			if type(v.linearDamping) == "number" then
				linearDamping = v.linearDamping
			end
			-- "linearVelocity": (vector),
			local vx = 0
			local vy = 0
			if type(v.linearVelocity) == "table" then
				vx = v.linearVelocity.x
				vy = v.linearVelocity.y
			end
			-- "massData-mass": 1,
			local mass = 1
			if type(v["massData-mass"]) == "number" then
				mass = v["massData-mass"]
			end
			-- "massData-center": (vector),
			local massX = 0
			local massY = 0
			if type(v["massData-center"]) == "table" then
				massX = v["massData-center"].x
				massY = v["massData-center"].y
			end
			-- "massData-I": 1,
			local massI = 1
			if type(v["massData-I"]) == "number" then
				massI = v["massData-I"]
			end

			if type(v.fixture) == "table" then
				for _, fixture in ipairs(v.fixture) do

					local fix = nil

					if type(fixture.chain) == "table" then
						-- TODO: closed chain
						-- gather the verts
						local xs = fixture.chain.vertices.x
						local ys = fixture.chain.vertices.y
						local verts = {}
						for i = 1, #xs do
							table.insert(verts, xs[i])
							table.insert(verts, ys[i])
						end
						fix = body:addChain(verts, false)

					elseif type(fixture.polygon) == "table" then
						-- gather the verts
						local xs = fixture.polygon.vertices.x
						local ys = fixture.polygon.vertices.y
						local verts = {}
						for i = 1, #xs do
							table.insert(verts, xs[i])
							table.insert(verts, ys[i])
						end
						fix = body:addPolygon(verts)

					elseif type(fixture.circle) == "table" then
						-- "center" : 0
						local centerX = 0
						local centerY = 0
						if type(fixture.circle.center) == "table" then
							centerX = fixture.circle.center.x
							centerY = fixture.circle.center.y
						end
						-- "radius" : 1
						local radius = 0
						if type(fixture.circle.radius) == "number" then
							radius = fixture.circle.radius
						end
						fix = body:addCircle(centerX, centerY, radius)
					end

					if fix then
						if type(fixture.density) == "number" then
							fix:setDensity(fixture.density)
						end
						if type(fixture.friction) == "number" then
							fix:setFriction(fixture.friction)
						end
					end
				end
			end

			body:setMassData(mass, massI, massX, massY)
			body:setTransform(x, y, angle)

			-- insert into the bodies table which is referenced by index by the joints
			table.insert(bodies, body)

			-- keep a reference in the world by name
			world.bodies[v.name] = body

		end -- bodies

		-- joints must be done after all the bodies
		for _, j in ipairs(json.joint) do

			-- wheel type
			if j.type == "wheel" then
				-- "anchorA": (vector),
				local anchorX = 0
				local anchorY = 0
				if type(j.anchorA) == "table" then
					anchorX = j.anchorA.x
					anchorY = j.anchorA.y
				end
				-- "anchorB": (vector),
				-- "bodyA": 4, //zero-based index of body in bodies array
				local bodyA = bodies[j.bodyA + 1]
				-- "bodyB": 1, //zero-based index of body in bodies array
				local bodyB = bodies[j.bodyB + 1]
				-- "collideConnected": true,
				-- "localAxisA": (vector),
				local axisX = 0
				local axisY = 0
				if type(j.localAxisA) == "table" then
					axisX = j.localAxisA.x
					axisY = j.localAxisA.y
				end

				local bodyX, bodyY = bodyA:getPosition()
				local wheelJoint = world:addWheelJoint(bodyA, bodyB, bodyX+anchorX, bodyY+anchorY, axisX, axisY)

				-- "customProperties": //An array of zero or more custom properties.

				-- "enableMotor": true,
				if type(j.enableMotor) == "boolean" then
					wheelJoint:setMotorEnabled(j.enableMotor)
				end
				-- "motorSpeed": 0,
				if type(j.motorSpeed) == "number" then
					wheelJoint:setMotorSpeed(j.motorSpeed)
				end
				-- "maxMotorTorque": 0,
				if type(j.maxMotorTorque) == "number" then
					wheelJoint:setMaxMotorTorque(j.maxMotorTorque)
				end
				-- "springDampingRatio": 0.7,
				if type(j.springDampingRatio) == "number" then
					wheelJoint:setSpringDampingRatio(j.springDampingRatio)
				end
				-- "springFrequency": 4,
				if type(j.springFrequency) == "number" then
					wheelJoint:setSpringFrequencyHz(j.springFrequency)
				end

				-- keep a reference in the world by name
				world.joints[j.name] = wheelJoint
			end
		end -- joints

		-- images must be done after all the bodies
		for _, img in ipairs(json.image) do

			-- "aspectScale" : 1,
			local aspectScale = 1
			if type(img.aspectScale) == "number" then
				aspectScale = img.aspectScale
			end

			-- "body" : 0, zero-based index of body in bodies array
			local body = bodies[img.body + 1]

			-- "center" : 0,
			local centerX = 0
			local centerY = 0
			if type(img.center) == "table" then
				centerX = img.center.x
				centerY = img.center.y
			end

			-- "file" : "../sprites/cars/bluebody.png",
			local sprname, animname = string.match(img.file, "/(%w+)/(%w+).png$")
			local spr = Sprite.new(sprname)
			spr:playAnimation(animname)
			_layer:insertProp(spr)
			spr:setParent(body)
			local scale = 1 / 45
			spr:setScl(scale)

		end -- images


		-- test
		dbtxt:setString(TableExt.tostring(world.bodies))
		print("---joints---")
		TableExt.print(world.joints)
	end

	return box
end

return Physics
