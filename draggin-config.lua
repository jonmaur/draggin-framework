-- Add the path to the draggin lua files.
-- When building for release you won't/can't do it this way. You should copy the src/draggin
-- directory into your program's main directory.
package.path = package.path .. ';' .. os.getenv("DRAGGIN_FRAMEWORK") .. '/src/?.lua'
