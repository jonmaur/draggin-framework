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


local FontManager = {}

local fonts = {}

local charcodes = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?()&amp;/-"\'\\'

--- Get a font.
-- If the font is already loaded, no need to load it again.
-- @param _strFont string, the font filename without the directory or the extention
-- @param _size the size of the font
-- @return the font
function FontManager.getFont(_strFont, _size)

	_strFont = _strFont or "gridblock"
	_size = _size or 24

	local font = fonts[_strFont]

	if font == nil then
		-- load the font
		print("Creating new font:", _strFont, _size)

		font = MOAIFont.new()
		if MOAIFileSystem.checkFileExists('res/fonts/'.._strFont..'.ttf') then
			font:loadFromTTF('res/fonts/'.._strFont..'.ttf', charcodes, _size)
		elseif MOAIFileSystem.checkFileExists('res/fonts/'.._strFont..'.fnt') then
			font:loadFromBMFont('res/fonts/'.._strFont..'.fnt')
		end

		fonts[_strFont] = {}
		fonts[_strFont][_size] = font
	elseif font[_size] == nil then
		-- have the font but it's a new size
		-- load the font
		print("Creating new font:", _strFont, _size)

		font = MOAIFont.new()
		if MOAIFileSystem.checkFileExists('res/fonts/'.._strFont..'.ttf') then
			font:loadFromTTF('res/fonts/'.._strFont..'.ttf', charcodes, _size)
		elseif MOAIFileSystem.checkFileExists('res/fonts/'.._strFont..'.fnt') then
			font:loadFromBMFont('res/fonts/'.._strFont..'.fnt')
		end

		fonts[_strFont][_size] = font
	else
		-- found it
		font = font[_size]
	end

	return font
end

--- Clear the font and all sizes from the FontManager
-- it doesn't matter if there are things still using it, lua will gc it later
-- BUT this does mean the font will be re-loaded if asked for again, regardless of
-- whether or not some other thing is using the same font
-- @param _strFont the same font filename you used with getFont()
function FontManager.clearFont(_strFont)
	fonts[_strFont] = nil
end


return FontManager
