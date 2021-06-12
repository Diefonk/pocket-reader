import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

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

function drawMenu()
	gfx.clear(gfx.kColorWhite)
	if #files <= 0 then
		gfx.drawText("No files found\n\nPut txt-files in Data/net.diefonk.Reader/\nto start reading", 5, 5)
	end
	for index = 1, #files do
		local fileName = files[index]:sub(1, #files[index] - #".txt")
		if index == selectedFile then
			fileName = "*" .. fileName .. "*"
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

	local allFiles = playdate.file.listFiles("/")
	for index = 1, #allFiles do
		if allFiles[index]:sub(-#".txt") == ".txt" and allFiles[index]:sub(1, 1) ~= "." then
			table.insert(files, allFiles[index])
		end
	end
	drawMenu()
end

function scroll(change)
	if imageHeight < 240 then
		return
	end
	imagePosition -= change
	if imagePosition > 0 then
		imagePosition = 0
	elseif imagePosition < 240 - imageHeight then
		imagePosition = 240 - imageHeight
	end
	image:draw(0, imagePosition)
end

function playdate.update()
	if state == reading then
		if playdate.buttonIsPressed("up") then
			scroll(-100 / playdate.display.getRefreshRate())
		elseif playdate.buttonIsPressed("down") then
			scroll(100 / playdate.display.getRefreshRate())
		end
	end
end

function playdate.cranked(change)
	if state == reading then
		scroll(change * 2)
	end
end

function playdate.upButtonDown()
	if state == menu then
		if selectedFile > 1 then
			selectedFile -= 1
		else
			selectedFile = #files
		end
		drawMenu()
	end
end

function playdate.downButtonDown()
	if state == menu then
		if selectedFile < #files then
			selectedFile += 1
		else
			selectedFile = 1
		end
		drawMenu()
	end
end

function playdate.AButtonUp()
	if state == menu then
		gfx.clear(gfx.kColorWhite)
		gfx.drawText("_Loading..._", 5, middle)
		playdate.display.flush()
		local file = playdate.file.open(files[selectedFile])
		local text = file:read(1000000)

		text = text:gsub("\xe2\x80\x90", "-")
		text = text:gsub("\xe2\x80\x91", "-")
		text = text:gsub("\xe2\x80\x92", "-")
		text = text:gsub("\xe2\x80\x93", "-")
		text = text:gsub("\xe2\x80\x94", "-")
		text = text:gsub("\xe2\x80\x95", "-")
		text = text:gsub("\xe2\x80\x9c", "\"")
		text = text:gsub("\xe2\x80\x9d", "\"")
		text = text:gsub("\xe2\x80\x9e", "\"")
		text = text:gsub("\xe2\x80\x9f", "\"")
		text = text:gsub("\xe2\x9d\x9d", "\"")
		text = text:gsub("\xe2\x9d\x9e", "\"")
		text = text:gsub("\xc2\xab", "\"")
		text = text:gsub("\xc2\xbb", "\"")
		text = text:gsub("\xe2\xb9\x82", "\"")
		text = text:gsub("\xe3\x80\x9d", "\"")
		text = text:gsub("\xe3\x80\x9e", "\"")
		text = text:gsub("\xe3\x80\x9f", "\"")
		text = text:gsub("\xef\xbc\x82", "\"")
		text = text:gsub("\xe2\x80\x98", "'")
		text = text:gsub("\xe2\x80\x99", "'")
		text = text:gsub("\xe2\x80\x9a", "'")
		text = text:gsub("\xe2\x80\x9b", "'")
		text = text:gsub("\xe2\x80\xb9", "'")
		text = text:gsub("\xe2\x80\xba", "'")
		text = text:gsub("\xe2\x9d\x9b", "'")
		text = text:gsub("\xe2\x9d\x9c", "'")
		text = text:gsub("\xe2\x9d\x9f", "'")
		text = text:gsub("\xe2\x9d\xae", "'")
		text = text:gsub("\xe2\x9d\xaf", "'")

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
		gfx.clear(gfx.kColorWhite)
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

function playdate.deviceWillSleep()
	saveBookmark()
end

function playdate.deviceWillLock()
	saveBookmark()
end

function playdate.gameWillPause()
	saveBookmark()
end

init()
