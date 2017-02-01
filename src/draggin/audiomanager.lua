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

local AudioManager = {}
local groups = {}

function AudioManager:getGroupsTable()
	return groups
end

--- Add a Sound instance to the manager.
-- @param _sound a Sound instance made with Draggin's Sound.new()
-- @param _group string, the group the Sound goes in
function AudioManager:addSound(_sound, _group)
	if not groups[_group] then
		groups[_group] = {}
	end

	local g = groups[_group]
	g[#g+1] = _sound
end

--- Remove a Sound from a group.
-- @param _sound the Sound to remove from the group
-- @param _group the group to remove the Sound from
function AudioManager:removeSound(_sound, _group)
	local g = groups[_group]

	if g == nil then
		print("WARNING: Audio group", _group, "not found!")
		return
	end

	for k, v in ipairs(g) do
		if _sound == v then
			table.remove(g, k)
			return
		end
	end
end

--- Stop playback of a group.
-- @param _group the group to stop playback of
function AudioManager:stopGroup(_group)
	local g = groups[_group]

	if g == nil then
		print("WARNING: Audio group", _group, "not found!")
		return
	end

	for k, v in ipairs(g) do
		v:stop()
	end
end

--- Pause playback of a group.
-- @param _group the group to pause playback of
function AudioManager:pauseGroup(_group)
	local g = groups[_group]

	if g == nil then
		print("WARNING: Audio group", _group, "not found!")
		return
	end

	for k, v in ipairs(g) do
		v:stop()
	end
end

--- Enable a group of Sounds.
-- Means that play() calls on the sounds will execute
-- @param _group the Sound group to enable
function AudioManager:enableGroup(_group)
	local g = groups[_group]

	if g == nil then
		print("WARNING: Audio group", _group, "not found!")
		return
	end

	for k, v in ipairs(g) do
		v:enable(true)
	end
end

--- Disable a group of Sounds.
-- Means that play() calls on the sounds will not execute
-- @param _group the Sound group to disable
function AudioManager:disableGroup(_group)
	local g = groups[_group]

	if g == nil then
		print("WARNING: Audio group", _group, "not found!")
		return
	end

	for k, v in ipairs(g) do
		v:enable(false)
	end
end

--- Set the volume for every Sound in the group instantly.
-- @param _group the Sound group
-- @param _vol the volume to set
function AudioManager:setVolumeGroup(_group, _vol)
	local g = groups[_group]

	if g == nil then
		print("WARNING: Audio group", _group, "not found!")
		return
	end

	for k, v in ipairs(g) do
		v:setVolume(_vol)
	end
end

--- Seeks the volume for every Sound in the group over time.
-- @param _group the Sound group
-- @param _target the target volume to seek to
-- @param _time the time to take to get there, in seconds
function AudioManager:seekVolumeGroup(_group, _target, _time)
	local g = groups[_group]

	if g == nil then
		print("WARNING: Audio group", _group, "not found!")
		return
	end

	for k, v in ipairs(g) do
		v:seekVolume(_target, _time)
	end
end

--- Destory a group.
-- Does not destroy the Sounds in the group, but no longer references them.
function AudioManager:destroyGroup(_group)
	self:stopGroup(_group)
	groups[_group] = nil
end

return AudioManager
