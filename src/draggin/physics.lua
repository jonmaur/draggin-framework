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

local RADIANS_TO_DEGREES = 180 / math.pi

local Physics = {}


function Physics.new(_gravity, _unitsToMeters, _debuglayer)
	local Phys = {}

	_gravity = _gravity or {x=0, y=-10}

	if type(_gravity) == "number" then
		_gravity = {x=0, y=_gravity}
	end

	_unitsToMeters = _unitsToMeters or 1


	local world = MOAIBox2DWorld.new()

	world:setUnitsToMeters(_unitsToMeters)
	world.unitsToMeters = _unitsToMeters
	world.metersToUnits = 1/_unitsToMeters

	world:setGravity(_gravity.x, _gravity.y)
	world:start()

	-- table to keep track of all bodies by name
	world.bodies = {}

	-- table to keep track of all joints by name
	world.joints = {}

	-- table to keep track of all images by name
	world.images = {}

	Phys.world = world

	if _debuglayer then
		print("Debug Physics Draws on")
		_debuglayer:setBox2DWorld(world)
	end

	function Phys:addRect(_type, x, y, w, h, r)

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

	function Phys:addSpriteBody(_sprite, _type, _bounds)

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

	function Phys:addSpriteBodyCircle(_sprite, _type, _radius, _fixedrotation)

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

	function Phys:addCircle(_type, x, y, r)
		local physBody = {}
		_type = _type or MOAIBox2DBody.STATIC

		local body = world:addBody(_type)

		local fixture = body:addCircle(x, y, r)
		fixture:setFriction(0.5)

		physBody.body = body
		physBody.fixture = fixture

		return physBody
	end

	function Phys:addChain(_verts, _close)
		assert(type(_verts) == "table")

		local physBody = {}

		local body = world:addBody(MOAIBox2DBody.STATIC)

		local chain = body:addChain(_verts, _close)

		physBody.body = body
		physBody.chain = chain

		chain:setFilter(2, 4)

		return physBody
	end

	function Phys:loadRubeJson(_filename, _layer)

		local jsonFile = MOAIFileStream.new()
		jsonFile:open("res/rube/".._filename..".json")
		local jsonStr = jsonFile:read()

		local json = MOAIJsonParser.decode(jsonStr)
		--TableExt.print(json)

		-- World settings
		-- "allowSleep" : true, BETTER ALWAYS BE TRUE!
		-- "autoClearForces" : true,
		if type(json.autoClearForces) == "boolean" then
			world:setAutoClearForces(json.autoClearForces)
		end
		-- "continuousPhysics" : true,
		-- "gravity" : 
		local gx = 0
		local gy = 0
		if type(json.gravity) == "table" then
			gx = json.gravity.x
			gy = json.gravity.y
		end
		world:setGravity(gx, gy)
		--"velocityIterations" : 8,
		--"positionIterations" : 3,
		world:setIterations(json.velocityIterations, json.positionIterations)
		--"stepsPerSecond" : 60.0, I guess this is framerate?
		--"subStepping" : false, -- always false, it's a box2d debug feature
		--"warmStarting" : true

		
		local bodies = {}

		if type(json.body) == "table" then
			for _, v in ipairs(json.body) do

				-- "type": 2, //0 = static, 1 = kinematic, 2 = dynamic
				local bodytype = MOAIBox2DBody.STATIC
				if v.type == 1 then
					bodytype = MOAIBox2DBody.KINEMATIC
				elseif v.type == 2 then
					bodytype = MOAIBox2DBody.DYNAMIC
				end

				-- create the body
				local body = world:addBody(bodytype)

				local x = 0
				local y = 0
				if type(v.position) == "table" then
					x = v.position.x
					y = v.position.y
				end
				
				if type(v.fixture) == "table" then
					body.fixtures = {}

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
							-- print("polygon", fixture.name)

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
							-- print("circle", fixture.name)
						end

						if fix then
							local density = 1 / (world.metersToUnits * world.metersToUnits)
							if type(fixture.density) == "number" then
								density = fixture.density / (world.metersToUnits * world.metersToUnits)
							end
							fix:setDensity(density)

							if type(fixture.friction) == "number" then
								fix:setFriction(fixture.friction)
							end
							if type(fixture.restitution) == "number" then
								fix:setRestitution(fixture.restitution)
							end
							if type(fixture.sensor) == "boolean" then
								fix:setSensor(fixture.sensor)
							end

							local categoryBits = 1
							if type(fixture["filter-categoryBits"]) == "number" then
								categoryBits = fixture["filter-categoryBits"]
							end
							local maskBits = 65535
							if type(fixture["filter-maskBits"]) == "number" then
								maskBits = fixture["filter-maskBits"]
							end
							local groupIndex = 0
							if type(fixture["filter-groupIndex"]) == "number" then
								groupIndex = fixture["filter-groupIndex"]
							end
							fix:setFilter(categoryBits, maskBits, groupIndex)

							fix.name = fixture.name
							fix.body = body

							-- Rube likes to handle complex fixtures as one, 
							-- but they are actually multiple fixtures with the same name
							if body.fixtures[fixture.name] == nil then
								-- we're fine, there's only the one fixture by this name so far
								body.fixtures[fixture.name] = fix
							elseif type(body.fixtures[fixture.name]) == "userdata" then
								-- turn it into a table
								local t = {body.fixtures[fixture.name], fix}
								body.fixtures[fixture.name] = t
								
							elseif type(body.fixtures[fixture.name]) == "table" then
								-- it's already a table of fixtures by this name
								body.fixtures[fixture.name][#body.fixtures[fixture.name]+1] = fix
							end
						end
					end
				end

				-- radians
				local angle = 0
				if type(v.angle) == "number" then
					angle = v.angle * RADIANS_TO_DEGREES
				end
				-- "angularDamping": 0,
				local angularDamping = 0
				if type(v.angularDamping) == "number" then
					angularDamping = v.angularDamping
				end
				body:setAngularDamping(angularDamping)
				-- "angularVelocity": 0, //radians per second
				local angularVelocity = 0
				if type(v.angularVelocity) == "number" then
					angularVelocity = v.angularVelocity * RADIANS_TO_DEGREES
				end
				body:setAngularVelocity(angularVelocity)
				-- "awake": true,
				if type(v.awake) == "boolean" then
					body:setAwake(v.awake)
				end
				-- "bullet": true,
				if type(v.bullet) == "boolean" then
					body:setBullet(v.bullet)
				end
				-- "fixedRotation": false,
				local fixedRotation = false
				if type(v.fixedRotation) == "boolean" then
					fixedRotation = v.fixedRotation
				end
				body:setFixedRotation(fixedRotation)
				-- "linearDamping": 0,
				local linearDamping = 0
				if type(v.linearDamping) == "number" then
					linearDamping = v.linearDamping
				end
				body:setLinearDamping(linearDamping)
				-- "linearVelocity": (vector),
				local lvx = 0
				local lvy = 0
				if type(v.linearVelocity) == "table" then
					-- TODO: do I need to convert these using meters to units?
					lvx = v.linearVelocity.x
					lvy = v.linearVelocity.y
				end
				body:setLinearVelocity(lvx, lvy)
				-- "massData-mass": 1,
				local mass = nil
				if type(v["massData-mass"]) == "number" then
					mass = v["massData-mass"]
				end
				-- "massData-center": (vector),
				local massX = nil
				local massY = nil
				if type(v["massData-center"]) == "table" then
					massX = v["massData-center"].x * world.metersToUnits
					massY = v["massData-center"].y * world.metersToUnits
				end
				-- "massData-I": 1,
				local massI = nil
				if type(v["massData-I"]) == "number" then
					massI = v["massData-I"] * world.metersToUnits * world.metersToUnits
				end

				body:setTransform(x, y, angle)
				body:resetMassData()
				if mass ~= nil then
					body:setMassData(mass, massI, massX, massY)
				end

				-- insert into the bodies table which is referenced by index by the joints
				table.insert(bodies, body)

				-- keep a reference in the world by name
				world.bodies[v.name] = body
				body.name = v.name

			end -- bodies
		end

		-- joints must be done after all the bodies
		if type(json.joint) == "table" then
			for _, j in ipairs(json.joint) do

				-- Common to all joints
				-- "anchorA": (vector),
				local anchorAX = 0
				local anchorAY = 0
				if type(j.anchorA) == "table" then
					anchorAX = j.anchorA.x
					anchorAY = j.anchorA.y
				end
				-- "anchorB": (vector),
				local anchorBX = 0
				local anchorBY = 0
				if type(j.anchorB) == "table" then
					anchorBX = j.anchorB.x
					anchorBY = j.anchorB.y
				end
				-- "bodyA": 4, //zero-based index of body in bodies array
				local bodyA = bodies[j.bodyA + 1]
				-- "bodyB": 1, //zero-based index of body in bodies array
				local bodyB = bodies[j.bodyB + 1]
				-- "localAxisA": (vector),
				local axisX = 0
				local axisY = 0
				if type(j.localAxisA) == "table" then
					axisX = j.localAxisA.x
					axisY = j.localAxisA.y
				end

				-- "collideConnected" : false,
				local collideConnected = false
				if type(j.collideConnected) == "boolean" then
					collideConnected = j.collideConnected
				end

				local bodyAX, bodyAY = bodyA:getPosition()
				local bodyBX, bodyBY = bodyB:getPosition()
				
				-- wheel type
				if j.type == "wheel" then
					local wheelJoint = world:addWheelJoint(bodyA, bodyB, bodyAX+anchorAX, bodyAY+anchorAY, axisX, axisY)

					-- "customProperties": //An array of zero or more custom properties.
					
					-- "enableMotor": true,
					if type(j.enableMotor) == "boolean" then
						wheelJoint:setMotorEnabled(j.enableMotor)
					end
					-- "motorSpeed": 0,
					if type(j.motorSpeed) == "number" then
						-- these are radians, MOAI needs degrees
						wheelJoint:setMotorSpeed(j.motorSpeed * RADIANS_TO_DEGREES)
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
				
				elseif j.type == "revolute" then
					-- NOTE: This requires MOAI changes
					-- NOTE: world:addRevoluteJoint didn't work so well for me.
					local revoluteJoint = world:addRevoluteJointLocal(bodyA, bodyB, anchorAX, anchorAY, 
						anchorBX, anchorBY, collideConnected)

					-- "lowerLimit": 0,
					local lowerLimit = 0
					if type(j.lowerLimit) == "number" then
						lowerLimit = j.lowerLimit * RADIANS_TO_DEGREES
					end
					-- "upperLimit": 0,
					local upperLimit = 0
					if type(j.upperLimit) == "number" then
						upperLimit = j.upperLimit * RADIANS_TO_DEGREES
					end
					revoluteJoint:setLimit(lowerLimit, upperLimit)
					-- "enableLimit": false,
					local enableLimit = false
					if type(j.enableLimit) == "boolean" then
						enableLimit = j.enableLimit
						revoluteJoint:setLimitEnabled(enableLimit)
					end

					-- "jointSpeed": 0,
					if type(j.jointSpeed) == "number" then
						-- TODO: anything to do with this??
					end

					-- "refAngle": 0,
					if type(j.refAngle) == "number" then
						-- TODO
					end

					-- "enableMotor": true,
					if type(j.enableMotor) == "boolean" then
						revoluteJoint:setMotorEnabled(j.enableMotor)
					end
					-- "motorSpeed": 0,
					if type(j.motorSpeed) == "number" then
						-- these are radians, MOAI needs degrees
						revoluteJoint:setMotorSpeed(j.motorSpeed * RADIANS_TO_DEGREES)
					end
					-- "maxMotorTorque": 0,
					if type(j.maxMotorTorque) == "number" then
						revoluteJoint:setMaxMotorTorque(j.maxMotorTorque)
					end

					-- keep a reference in the world by name
					world.joints[j.name] = revoluteJoint

				elseif j.type == "distance" then

					-- "dampingRatio" : 0,
					local dampingRatio = 0
					if type(j.dampingRatio) == "number" then
						dampingRatio = j.dampingRatio
					end
					-- "frequency" : 0,
					local frequency = 0
					if type(j.frequency) == "number" then
						frequency = j.frequency
					end

					local distanceJoint = world:addDistanceJoint(bodyA, bodyB, bodyAX+anchorAX, bodyAY+anchorAY, 
						frequency, dampingRatio, collideConnected)
					
					-- "length" : 0,
					if type(j.length) == "number" then
						distanceJoint:setLength(j.length * world.metersToUnits)
					end

					-- keep a reference in the world by name
					world.joints[j.name] = distanceJoint
				elseif j.type == "prismatic" then
					local prismaticJoint = world:addPrismaticJoint(bodyA, bodyB, bodyAX+anchorAX, bodyAY+anchorAY, 
						axisX, axisY, collideConnected)

					-- "lowerLimit": 0,
					local lowerLimit = 0
					if type(j.lowerLimit) == "number" then
						lowerLimit = j.lowerLimit * RADIANS_TO_DEGREES
					end
					-- "upperLimit": 0,
					local upperLimit = 0
					if type(j.upperLimit) == "number" then
						upperLimit = j.upperLimit * RADIANS_TO_DEGREES
					end
					prismaticJoint:setLimit(lowerLimit, upperLimit)
					-- "enableLimit": false,
					local enableLimit = false
					if type(j.enableLimit) == "boolean" then
						enableLimit = j.enableLimit
						prismaticJoint:setLimitEnabled(enableLimit)
					end
					
					-- "enableMotor": true,
					if type(j.enableMotor) == "boolean" then
						prismaticJoint:setMotorEnabled(j.enableMotor)
					end
					-- "motorSpeed": 0,
					if type(j.motorSpeed) == "number" then
						prismaticJoint:setMotorSpeed(j.motorSpeed * world.metersToUnits)
					end
					-- "maxMotorForce": 0,
					if type(j.maxMotorForce) == "number" then
						prismaticJoint:setMaxMotorForce(j.maxMotorForce * world.metersToUnits)
					end

					-- "refAngle": 0,
					if type(j.refAngle) == "number" then
						-- TODO
					end

					-- keep a reference in the world by name
					world.joints[j.name] = prismaticJoint
				end
			end -- joints
		end

		-- images must be done after all the bodies
		if type(json.image) == "table" then
			for _, img in ipairs(json.image) do

				-- "aspectScale" : 1,
				local aspectScale = 1
				if type(img.aspectScale) == "number" then
					aspectScale = img.aspectScale
				end

				-- "body" : 0, zero-based index of body in bodies array
				-- img.body might be -1 which results in body being nil
				local body = bodies[img.body + 1]

				-- "center" : 0,
				local centerX = 0
				local centerY = 0
				if type(img.center) == "table" then
					centerX = img.center.x
					centerY = img.center.y
				end

				-- "file" : "../sprites/cars/bluebody.png",
				local sprname, animname, framenum = string.match(img.file, "/(%w+)/([%a_-]+)(%d-).png$")
				-- print("image", sprname, animname, framenum)
				local spr = Sprite.new(sprname)
				local speed = 1
				if type(img.customProperties) == "table" then
					for _, prop in ipairs(img.customProperties) do
						if type(prop) == "table" then
							if prop.name == "speed" then
								if type(prop.float) == "number" then
									speed = prop.float
								end
							end
						end
					end
				end
				spr:playAnimation(animname, speed)
				_layer:insertProp(spr)
				spr:setParent(body)
				spr:setLoc(centerX, centerY)

				if type(img.glVertexPointer) == "table" then

					local orgw = spr.spriteData.originalWidths[animname]
					local rubew = img.glVertexPointer[3] - img.glVertexPointer[1]
					local scale = 1 / (orgw / rubew)
					spr:setScl(scale)
				end

				if type(img.flip) == "boolean" then
					if img.flip then
						local sx, sy = spr:getScl()
						spr:setScl(-sx, sy)
					end
				end

				local r = 1
				local g = 1
				local b = 1
				local a = 1
				if type(img.colorTint) == "table" then
					r = img.colorTint[1] / 255
					g = img.colorTint[2] / 255
					b = img.colorTint[3] / 255
					a = img.colorTint[4] / 255
				end
				if type(img.opacity) == "number" then
					a = a * img.opacity
				end

				spr:setColor(r, g, b, a)

				if body then
					body.sprites = body.sprites or {}
					body.sprites[#body.sprites+1] = spr
				end

				-- keep a reference in the world by name
				world.images[img.name] = spr

			end -- images
		end
	end

	return Phys
end

return Physics
