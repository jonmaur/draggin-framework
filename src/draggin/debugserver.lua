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


-- TODO: handle clients disconnecting properly!

local Socket = require "socket"
local TableExt = require "draggin/tableext"


local DebugServer = {}

--- Create a new DebugServer.
-- The name is confusing. It's actually just a server which accepts raw telenet
-- connections. The client can send lua code which will be executed here.
function DebugServer.new()

	local dbServer = {}

	local maxClients = 4
	local clients = {}
	local clientThreads = {}

	local port = "localhost", 12345
	local server = Socket.bind("*", 12345)

	local ip, port = server:getsockname()
	server:settimeout(0)

	-- print a message informing what's up
	print("telnet to localhost on port " .. port)

	--- Handles client connections.
	-- Executes anything received from the client as if it were lua code.
	local function handleClient(_client)
		while 1 do
			local line, err = _client:receive()
			-- if there was no error, send it back to the client
			if not err then
				_client:send(string.char(27)..'[31m'.."ECHO "..line.."\r\n"..string.char(27)..'[0m')

				local chunk = loadstring(line)
				if chunk then
					print("Executing:", line)
					chunk()
				else
					print("Failed:", line)
				end

			elseif err ~= "timeout" then
				print("receive error:", err)
			end

			coroutine.yield()
		end
	end

	--- Accept new clients thread.
	local function acceptFunc()
		while 1 do
			local client = server:accept()

			if client then
				for i = 1, maxClients do
					if clients[i] == nil then
						print("Accepted new client number", i)
						clients[i] = client

						client:settimeout(0)

						clientThreads[i] = MOAIThread.new()
						clientThreads[i]:run(handleClient, client)
						break
					end
				end
			end

			coroutine.yield()
		end
	end

	function dbServer:send(_msg)
		for _, client in pairs(clients) do
			client:send(_msg)
		end
	end

	dbServer.acceptThread = MOAIThread.new()
	dbServer.acceptThread:run(acceptFunc)

	return dbServer
end

return DebugServer
