import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local tmr <const> = playdate.timer

local y = 0
local image
local imageHeight
local buttonTimer

function init()
	local fontPaths = {
		[gfx.font.kVariantNormal] = "Sasser-Slab",
    	[gfx.font.kVariantBold] = "Sasser-Slab-Bold",
    	[gfx.font.kVariantItalic] = "Sasser-Slab-Italic"
	}
	local fontFamily = gfx.font.newFamily(fontPaths)
	gfx.setFontFamily(fontFamily)
	--local filesList = playdate.file.listFiles("/")
	--for index = 1, table.getsize(filesList) do
		--print(filesList[index])
	--end
	local file = playdate.file.open("text.txt")
	local text = file:read(300000)
	local width, height = gfx.getTextSizeForMaxWidth(text, 390)
	imageHeight = height + 10
	image = gfx.image.new(400, imageHeight, gfx.kColorWhite)
	gfx.pushContext(image)
	gfx.drawTextInRect(text, 5, 5, width, height)
	gfx.popContext()
	image:draw(0, y)
end

function playdate.update()
	tmr.updateTimers()
end

function scroll(change)
	y -= change
	if y > 0 then
		y = 0
	elseif y < 240 - imageHeight then
		y = 240 - imageHeight
	end
	image:draw(0, y)
end

function playdate.cranked(change)
	scroll(change * 2)
end

function playdate.upButtonDown()
	if buttonTimer then
		buttonTimer:remove()
	end
	buttonTimer = tmr.keyRepeatTimerWithDelay(1, 1, scroll, -3)
end

function playdate.downButtonDown()
	if buttonTimer then
		buttonTimer:remove()
	end
	buttonTimer = tmr.keyRepeatTimerWithDelay(1, 1, scroll, 3)
end

function playdate.upButtonUp()
	if buttonTimer then
		buttonTimer:remove()
	end
end

function playdate.downButtonUp()
	if buttonTimer then
		buttonTimer:remove()
	end
end

init()
