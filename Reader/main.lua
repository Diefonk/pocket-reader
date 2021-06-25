import "CoreLibs/graphics"

local pd <const> = playdate
local gfx <const> = pd.graphics

local menu <const> = 1
local reading <const> = 2
local loading <const> = 3

local state = menu
local bookmarks
local files = {}
local selectedFile = 1
local fontHeight
local middle
local text
local textIndex
local textPosition

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

	pd.getSystemMenu():addMenuItem("reader menu", function()
		state = menu
		drawMenu()
	end)

	bookmarks = pd.datastore.read("bookmarks")
	if not bookmarks then
		bookmarks = {}
	end

	local allFiles = pd.file.listFiles("/")
	for index = 1, #allFiles do
		if allFiles[index]:sub(-#".txt") == ".txt" and allFiles[index]:sub(1, 1) ~= "." then
			table.insert(files, allFiles[index])
		elseif allFiles[index]:sub(-#".txt.json") == ".txt.json" and not pd.file.exists(allFiles[index]:sub(1, #allFiles[index] - #".json")) then
			table.insert(files, allFiles[index]:sub(1, #allFiles[index] - #".json"))
		end
	end
	drawMenu()
end

function drawText()
	gfx.clear(gfx.kColorWhite)
	local endIndex = textIndex + 11
	if #text < endIndex then
		endIndex = #text
	end
	for index = textIndex, endIndex do
		gfx.drawText(text[index], 5, textPosition + 5 + (fontHeight + 5) * (index - textIndex))
	end
end

function scroll(change)
	textPosition -= change
	while textPosition < 0 - fontHeight and textIndex < #text - 8 do
		textIndex += 1
		textPosition += fontHeight + 5
	end
	if textPosition < 0 and textIndex > #text - 9 then
		textPosition = 0
	end
	while textPosition > 0 and textIndex > 1 do
		textIndex -= 1
		textPosition -=  fontHeight + 5
	end
	if textPosition > 0 and textIndex == 1 then
		textPosition = 0
	end
	drawText()
end

function pd.update()
	if state == reading then
		if pd.buttonIsPressed("up") then
			scroll(-100 / pd.display.getRefreshRate())
		elseif pd.buttonIsPressed("down") then
			scroll(100 / pd.display.getRefreshRate())
		end
	elseif state == loading then
		if pd.file.exists(files[selectedFile] .. ".json") then
			text = pd.datastore.read(files[selectedFile])
			if bookmarks[files[selectedFile]] then
				textIndex = bookmarks[files[selectedFile]]
			else
				textIndex = 1
			end
			textPosition = 0
			drawText()
			state = reading
			return
		end

		pd.setAutoLockDisabled(true)
		pd.display.setRefreshRate(0)
		local file = pd.file.open(files[selectedFile])
		text = {}
		while true do
			local line = file:readline()
			if not line then
				break
			end
			line = line:gsub("\xe2\x80\x90", "-")
			line = line:gsub("\xe2\x80\x91", "-")
			line = line:gsub("\xe2\x80\x92", "-")
			line = line:gsub("\xe2\x80\x93", "-")
			line = line:gsub("\xe2\x80\x94", "-")
			line = line:gsub("\xe2\x80\x95", "-")
			line = line:gsub("\xe2\x80\x9c", "\"")
			line = line:gsub("\xe2\x80\x9d", "\"")
			line = line:gsub("\xe2\x80\x9e", "\"")
			line = line:gsub("\xe2\x80\x9f", "\"")
			line = line:gsub("\xe2\x9d\x9d", "\"")
			line = line:gsub("\xe2\x9d\x9e", "\"")
			line = line:gsub("\xc2\xab", "\"")
			line = line:gsub("\xc2\xbb", "\"")
			line = line:gsub("\xe2\xb9\x82", "\"")
			line = line:gsub("\xe3\x80\x9d", "\"")
			line = line:gsub("\xe3\x80\x9e", "\"")
			line = line:gsub("\xe3\x80\x9f", "\"")
			line = line:gsub("\xef\xbc\x82", "\"")
			line = line:gsub("\xe2\x80\x98", "'")
			line = line:gsub("\xe2\x80\x99", "'")
			line = line:gsub("\xe2\x80\x9a", "'")
			line = line:gsub("\xe2\x80\x9b", "'")
			line = line:gsub("\xe2\x80\xb9", "'")
			line = line:gsub("\xe2\x80\xba", "'")
			line = line:gsub("\xe2\x9d\x9b", "'")
			line = line:gsub("\xe2\x9d\x9c", "'")
			line = line:gsub("\xe2\x9d\x9f", "'")
			line = line:gsub("\xe2\x9d\xae", "'")
			line = line:gsub("\xe2\x9d\xaf", "'")
			table.insert(text, line)
			gfx.clear(gfx.kColorWhite)
			gfx.drawText("Loading... " .. #text .. " lines read", 5, middle)
			coroutine.yield()
		end
		file:close()

		local font <const> = gfx.getFont()
		local index = 1
		while index <= #text do
			if font:getTextWidth(text[index]) > 390 then
				local line = text[index]
				for index2 = 1, #line do
					if font:getTextWidth(line:sub(1, index2)) > 390 then
						local spaceIndex = index2
						while spaceIndex > 1 do
							if line:sub(spaceIndex, spaceIndex) == " " then
								break
							end
							spaceIndex -= 1
						end
						if spaceIndex > 1 then
							text[index] = line:sub(1, spaceIndex - 1)
							table.insert(text, index + 1, line:sub(spaceIndex + 1))
						else
							text[index] = line:sub(1, index2 - 1)
							table.insert(text, index + 1, line:sub(index2))
						end
						break
					end
				end
			end
			local percentage = "" .. 100 * index / #text
			percentage = percentage:sub(1, 5) .. "% processed"
			gfx.clear(gfx.kColorWhite)
			gfx.drawText("Loading... " .. percentage, 5, middle)
			index += 1
			coroutine.yield()
		end
		pd.datastore.write(text, files[selectedFile])

		if bookmarks[files[selectedFile]] then
			textIndex = bookmarks[files[selectedFile]]
		else
			textIndex = 1
		end
		textPosition = 0
		drawText()
		state = reading
		pd.setAutoLockDisabled(false)
		pd.display.setRefreshRate(30)
	end
end

function pd.cranked(change)
	if state == reading then
		scroll(change * 2)
	end
end

function pd.upButtonDown()
	if state == menu then
		if selectedFile > 1 then
			selectedFile -= 1
		else
			selectedFile = #files
		end
		drawMenu()
	end
end

function pd.downButtonDown()
	if state == menu then
		if selectedFile < #files then
			selectedFile += 1
		else
			selectedFile = 1
		end
		drawMenu()
	end
end

function pd.AButtonUp()
	if state == menu then
		gfx.clear(gfx.kColorWhite)
		gfx.drawText("Loading...", 5, middle)
		pd.display.flush()
		state = loading
	end
end

function saveBookmark()
	if state == reading then
		bookmarks[files[selectedFile]] = textIndex
		pd.datastore.write(bookmarks, "bookmarks")
	end
end

function pd.gameWillTerminate()
	saveBookmark()
end

function pd.deviceWillSleep()
	saveBookmark()
end

function pd.deviceWillLock()
	saveBookmark()
end

function pd.gameWillPause()
	saveBookmark()
end

init()
