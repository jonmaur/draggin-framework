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

-- TODO: figure out if this plays nicely with different upvales in the same callback function
local Signal = {}

--- Create a Signal.
-- A simple signal slot implementation. Can emit signals with any number of params.
-- @return a new Signal instance
function Signal.new()
	local sig = {callbacks = {}}

	--- Register a callback.
	-- @param _func callback function which gets called on emit and receives all the params passed to the emit function.
	function sig:register(_func)
		self.callbacks[_func] = _func
	end

	--- Remove a callback.
	-- @param _func the callback to remove
	function sig:remove(_func)
		self.callbacks[_func] = nil
	end

	--- Remove all the callbacks.
	function sig:removeAll()
		self.callbacks = {}
	end

	--- Emit the Signal.
	-- Calls all the callbacks and passes along all params
	function sig:emit(...)
		local done
		for _, v in pairs(self.callbacks) do
			if v(...) then
				-- if the callback returns true then that means it's done and should remove itself
				if done == nil then
					done = {v}
				else
					done[#done+1] = v
				end
			end
		end

		-- clean up all the done callbacks
		if done then
			for _, v in pairs(done) do
				self:remove(v)
			end
		end
	end

	return sig
end

return Signal
