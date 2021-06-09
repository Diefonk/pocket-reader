import "CoreLibs/graphics"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local tmr <const> = playdate.timer

local menu <const> = 1
local reading <const> = 2

local state = menu
local bookmarks
local files = {}
local selectedFile = 1
local fontHeight
local middle
local image
local imagePosition
local imageHeight
local buttonTimer

function drawMenu()
	gfx.clear(gfx.kColorWhite)
	for index = 1, #files do
		local fileName
		if index == selectedFile then
			fileName = "*" .. files[index]:sub(1, #files[index] - #".txt") .. "*"
		else
			fileName = files[index]:sub(1, #files[index] - #".txt")
		end
		gfx.drawText(fileName, 5, middle + (fontHeight * 2) * (index - selectedFile))
	end
end

function init()
	local fontPaths = {
		[gfx.font.kVariantNormal] = "Sasser-Slab",
    	[gfx.font.kVariantBold] = "Sasser-Slab-Bold",
    	[gfx.font.kVariantItalic] = "Sasser-Slab-Italic"
	}
	local fontFamily = gfx.font.newFamily(fontPaths)
	gfx.setFontFamily(fontFamily)
	fontHeight = fontFamily[gfx.font.kVariantNormal]:getHeight()
	middle = 120 - fontHeight / 2

	playdate.getSystemMenu():addMenuItem("reader menu", function()
		state = menu
		drawMenu()
	end)

	bookmarks = playdate.datastore.read("bookmarks")
	if not bookmarks then
		bookmarks = {}
	end

	local filesList = playdate.file.listFiles("/")
	for index = 1, #filesList do
		if filesList[index]:sub(-#".txt") == ".txt" then
			table.insert(files, filesList[index])
		end
	end
	drawMenu()
end

function playdate.update()
	tmr.updateTimers()
end

function scroll(change)
	imagePosition -= change
	if imagePosition > 0 then
		imagePosition = 0
	elseif imagePosition < 240 - imageHeight then
		imagePosition = 240 - imageHeight
	end
	image:draw(0, imagePosition)
end

function playdate.cranked(change)
	if state == reading then
		scroll(change * 2)
	end
end

function playdate.upButtonDown()
	if state == menu and selectedFile > 1 then
		selectedFile -= 1
		drawMenu()
	elseif state == reading then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimerWithDelay(1, 1, scroll, -3)
	end
end

function playdate.downButtonDown()
	if state == menu and selectedFile < #files then
		selectedFile += 1
		drawMenu()
	elseif state == reading then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimerWithDelay(1, 1, scroll, 3)
	end
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

function playdate.AButtonUp()
	if state == menu then
		local file = playdate.file.open(files[selectedFile])
		local text = file:read(300000)
		local width, height = gfx.getTextSizeForMaxWidth(text, 390)
		imageHeight = height + 10
		image = gfx.image.new(400, imageHeight, gfx.kColorWhite)
		gfx.pushContext(image)
		gfx.drawTextInRect(text, 5, 5, width, height)
		gfx.popContext()
		if bookmarks[files[selectedFile]] then
			imagePosition = bookmarks[files[selectedFile]]
		else
			imagePosition = 0
		end
		image:draw(0, imagePosition)
		state = reading
	end
end

function saveBookmark()
	if state == reading then
		bookmarks[files[selectedFile]] = imagePosition
		playdate.datastore.write(bookmarks, "bookmarks")
	end
end

function playdate.gameWillTerminate()
	saveBookmark()
end

function playdate.deviceWillLock()
	saveBookmark()
end

function playdate.gameWillPause()
	saveBookmark()
end

init()
