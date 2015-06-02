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


local GameStateManager = {}

local states = {}

-- functions of state manager
-- pushState
-- popState
-- switchState
-- popAllStates


-- functions of states
-- init
-- gotFocus
-- lostFocus
-- destroy


-- game state management
-- switch to this game state, passing on the args
local topState = nil

function GameStateManager.pushState(_state, ...)
	print("pushState", _state.name)
	if topState then
		if topState.lostFocus then
			-- let the top state know which state is getting focus
			topState:lostFocus(_state)
		end
	end

	local oldTop = topState

	topState = _state
	table.insert(states, _state)

	if _state.init then
		_state:init()
		_state.init = nil	-- you'll never be able to call init twice if I delete the function, haha!
	end

	if _state.gotFocus then
		_state:gotFocus(oldTop, ...)
	end
end


function GameStateManager.popState(...)
	local poppedState = topState

	print("popState", topState.name)

	if poppedState then
		--table.remove(states)
		states[#states] = nil

		if poppedState.lostFocus then
			poppedState:lostFocus(states[#states])
		end

		topState = states[#states]

		if topState and topState.gotFocus then
			topState:gotFocus(poppedState, ...)
		end
	end

	if topState then
		print("popState new top", topState.name)
	else
		print("popState stack empty")
	end


	-- caller is expected to destroy the state, if it wants to
	return poppedState
end


-- swap the top state with this new one
function GameStateManager.switchState(_to, ...)

	local oldTop = topState

	if topState then
		print("switchState from", topState.name)
		table.remove(states)

		if topState.lostFocus then
			topState:lostFocus(_to)
		end

		topState = states[#states]
	end

	print("switchState to", _to.name, ...)

	topState = _to
	table.insert(states, _to)

	if _to.init then
		_to:init()
		_to.init = nil	-- you'll never be able to call init twice if I delete the function, haha!
	end

	if _to.gotFocus then
		_to:gotFocus(oldTop, ...)
	end

	return oldTop
end

function GameStateManager.getTopName()
	if topState then
		return topState.name
	else
		return ""
	end
end

function GameStateManager.isStateOnStack(_state)
	for i = 1, #states do
		if states[i] == _state then
			return true, i
		end
	end
	
	return false
end

return GameStateManager
