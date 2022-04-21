import "CoreLibs/graphics"
import "CoreLibs/timer"

local pd <const> = playdate
local gfx <const> = pd.graphics
local tmr <const> = pd.timer

local menu <const> = 1
local reading <const> = 2
local loading <const> = 3
local editSpeed <const> = 4
local editMargin <const> = 5

local state = menu
local data
local files = {}
local selectedFile = 1
local fontHeight
local fontHalf
local middle
local text
local textIndex
local textPosition
local linesToDraw
local textEnd = {}
local jumpIndex
local buttonTimer

function drawMenu()
	gfx.clear(gfx.kColorWhite)
	if #files <= 0 then
		gfx.drawText("No files found\n\nPut txt-files in *Data/net.diefonk.Reader/*\nto start reading", data.xMargin, data.yMargin)
	end
	for index = 1, #files do
		local fileName = files[index].menuName
		if index == selectedFile then
			fileName = "*" .. fileName .. "* "
			if files[index].source then
				fileName = fileName .. "[S]"
			end
			if files[index].loaded then
				fileName = fileName .. "[L]"
			end
		end
		gfx.drawText(fileName, data.xMargin, middle + (fontHeight + data.yMargin) * (index - selectedFile))
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
	fontHalf = fontHeight / 2
	gfx.setColor(gfx.kColorBlack)

	pd.getSystemMenu():addMenuItem("reader menu", function()
		if buttonTimer then
			buttonTimer:remove()
		end
		state = menu
		drawMenu()
	end)

	data = pd.datastore.read()
	if not data then
		data = {
			xMargin = 5,
			yMargin = 5,
			crankSpeed = 2,
			dPadSpeed = 100
		}
		local bookmarks = pd.datastore.read("bookmarks")
		if bookmarks then
			data.bookmarks = bookmarks
			pd.datastore.delete("bookmarks")
		else
			data.bookmarks = {}
		end
	end
	linesToDraw = math.ceil(240 / (fontHeight + data.yMargin))
	textEnd.offset = math.floor((240 - data.yMargin) / (fontHeight + data.yMargin))
	textEnd.position = 240 - data.yMargin - (textEnd.offset + 1) * (fontHeight + data.yMargin)

	local allFiles = pd.file.listFiles("/")
	for index = 1, #allFiles do
		if allFiles[index]:sub(1, 1) == "." then
			--nothing
		elseif allFiles[index]:sub(-#".txt") == ".txt" then
			table.insert(files, {
				name = allFiles[index],
				menuName = allFiles[index]:sub(1, -1 - #".txt"),
				source = true,
				loaded = false
			})
		elseif allFiles[index]:sub(-#".txt.json") == ".txt.json" then
			local name = allFiles[index]:sub(1, -1 - #".json")
			if files[#files].name == name then
				files[#files].loaded = true
			else
				table.insert(files, {
					name = name,
					menuName = name:sub(1, -1 - #".txt"),
					source = false,
					loaded = true
				})
			end
		end
	end
	drawMenu()
end

function drawText()
	gfx.clear(gfx.kColorWhite)
	local endIndex = textIndex + linesToDraw
	if #text < endIndex then
		endIndex = #text
	end
	local font <const> = gfx.getFont()
	for index = textIndex, endIndex do
		font:drawText(text[index], data.xMargin, textPosition + data.yMargin + (fontHeight + data.yMargin) * (index - textIndex))
	end
end

function scroll(change)
	textPosition -= change
	while textIndex < textEnd.index and textPosition < 0 - fontHeight do
		textIndex += 1
		textPosition += fontHeight + data.yMargin
	end
	if textIndex > textEnd.index then
		textIndex = textEnd.index
	end
	if textIndex == textEnd.index and textPosition < textEnd.position then
		textPosition = textEnd.position
	end
	while textIndex > 1 and textPosition > 0 do
		textIndex -= 1
		textPosition -= fontHeight + data.yMargin
	end
	if textIndex < 1 then
		textIndex = 1
	end
	if textIndex == 1 and textPosition > 0 then
		textPosition = 0
	end
	jumpIndex = textIndex
	drawText()
end

function startReading()
	if data.bookmarks[files[selectedFile].name] then
		textIndex = data.bookmarks[files[selectedFile].name]
	else
		textIndex = 1
	end
	jumpIndex = textIndex
	textPosition = 0
	textEnd.index = #text - textEnd.offset
	if textEnd.index < 1 then
		textEnd.index = 1
	end
	drawText()
	state = reading
end

function pd.update()
	tmr.updateTimers()
	if state == reading then
		if pd.buttonIsPressed("up") then
			scroll(-data.dPadSpeed / pd.display.getRefreshRate())
		elseif pd.buttonIsPressed("down") then
			scroll(data.dPadSpeed / pd.display.getRefreshRate())
		end
	elseif state == loading then
		if files[selectedFile].loaded then
			text = pd.datastore.read(files[selectedFile].name)
			startReading()
			return
		end

		pd.setAutoLockDisabled(true)
		pd.display.setRefreshRate(0)
		local file = pd.file.open(files[selectedFile].name)
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
			gfx.drawText("Loading... " .. #text .. " lines read", data.xMargin, middle)
			coroutine.yield()
		end
		file:close()

		local font <const> = gfx.getFont()
		local maxWidth <const> = 400 - data.xMargin * 2
		local index = 1
		while index <= #text do
			if font:getTextWidth(text[index]) > maxWidth then
				local line = text[index]
				for index2 = 1, #line do
					if font:getTextWidth(line:sub(1, index2)) > maxWidth then
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
			gfx.drawText("Loading... " .. percentage, data.xMargin, middle)
			index += 1
			coroutine.yield()
		end
		pd.datastore.write(text, files[selectedFile].name)
		files[selectedFile].loaded = true

		startReading()
		pd.setAutoLockDisabled(false)
		pd.display.setRefreshRate(30)
	end
end

function drawSpeed()
	drawText()
	gfx.fillRect(0, 240 - fontHeight * 2, 400, fontHeight * 2)
	gfx.setImageDrawMode(gfx.kDrawModeInverted)
	gfx.drawText("Crank speed: " .. data.crankSpeed, fontHalf, 240 - fontHalf * 3)
	gfx.drawText("D-pad speed: " .. data.dPadSpeed, 200 + fontHalf, 240 - fontHalf * 3)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function changeCrankSpeed(change)
	data.crankSpeed += change
	if data.crankSpeed < 0.1 then
		data.crankSpeed = 0.1
	elseif data.crankSpeed > 20 then
		data.crankSpeed = 20
	end
	drawSpeed()
end

function changeDPadSpeed(change)
	data.dPadSpeed += change
	if data.dPadSpeed < 10 then
		data.dPadSpeed = 10
	elseif data.dPadSpeed > 1000 then
		data.dPadSpeed = 1000
	end
	drawSpeed()
end

function drawMargin()
	drawText()
	gfx.fillRect(0, 240 - fontHeight * 2, 400, fontHeight * 2)
	gfx.setImageDrawMode(gfx.kDrawModeInverted)
	gfx.drawText("X-margin: " .. data.xMargin, fontHalf, 240 - fontHalf * 3)
	gfx.drawText("Y-margin: " .. data.yMargin, 200 + fontHalf, 240 - fontHalf * 3)
	gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function changeXMargin(change)
	data.xMargin += change
	if data.xMargin < 0 then
		data.xMargin = 0
	elseif data.xMargin > 50 then
		data.xMargin = 50
	end
	drawMargin()
end

function changeYMargin(change)
	data.yMargin += change
	if data.yMargin < 0 then
		data.yMargin = 0
	elseif data.yMargin > 50 then
		data.yMargin = 50
	end
	linesToDraw = math.ceil(240 / (fontHeight + data.yMargin))
	textEnd.offset = math.floor((240 - data.yMargin) / (fontHeight + data.yMargin))
	textEnd.position = 240 - data.yMargin - (textEnd.offset + 1) * (fontHeight + data.yMargin)
	textEnd.index = #text - textEnd.offset
	if textEnd.index < 1 then
		textEnd.index = 1
	end
	drawMargin()
end

function pd.cranked(change)
	if state == reading then
		scroll(change * data.crankSpeed)
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
	elseif state == editSpeed then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimer(changeDPadSpeed, 10)
	elseif state == editMargin then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimer(changeYMargin, 1)
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
	elseif state == editSpeed then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimer(changeDPadSpeed, -10)
	elseif state == editMargin then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimer(changeYMargin, -1)
	end
end

function pd.leftButtonDown()
	if state == reading then
		if textIndex > jumpIndex then
			textIndex = jumpIndex
		else
			textIndex = 1
		end
		textPosition = 0
		drawText()
	elseif state == editSpeed then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimer(changeCrankSpeed, -0.1)
	elseif state == editMargin then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimer(changeXMargin, -1)
	end
end

function pd.rightButtonDown()
	if state == reading then
		if textIndex < jumpIndex then
			textIndex = jumpIndex
			textPosition = 0
		else
			textIndex = textEnd.index
			textPosition = textEnd.position
		end
		drawText()
	elseif state == editSpeed then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimer(changeCrankSpeed, 0.1)
	elseif state == editMargin then
		if buttonTimer then
			buttonTimer:remove()
		end
		buttonTimer = tmr.keyRepeatTimer(changeXMargin, 1)
	end
end

function pd.upButtonUp()
	if buttonTimer then
		buttonTimer:remove()
	end
end

function pd.downButtonUp()
	if buttonTimer then
		buttonTimer:remove()
	end
end

function pd.leftButtonUp()
	if buttonTimer then
		buttonTimer:remove()
	end
end

function pd.rightButtonUp()
	if buttonTimer then
		buttonTimer:remove()
	end
end

function pd.AButtonDown()
	if state == reading then
		state = editSpeed
		drawSpeed()
	end
end

function pd.BButtonDown()
	if state == reading then
		state = editMargin
		drawMargin()
	end
end

function pd.AButtonUp()
	if state == menu then
		gfx.clear(gfx.kColorWhite)
		gfx.drawText("Loading...", data.xMargin, middle)
		pd.display.flush()
		state = loading
	elseif state == editSpeed then
		if buttonTimer then
			buttonTimer:remove()
		end
		pd.datastore.write(data)
		state = reading
		drawText()
	end
end

function pd.BButtonUp()
	if state == editMargin then
		if buttonTimer then
			buttonTimer:remove()
		end
		pd.datastore.write(data)
		state = reading
		scroll(0)
	end
end

function pd.BButtonHeld()
	if state == menu and files[selectedFile].source and files[selectedFile].loaded then
		pd.datastore.delete(files[selectedFile].name)
		files[selectedFile].loaded = false
		data.bookmarks[files[selectedFile].name] = 1
		pd.datastore.write(data)
		drawMenu()
	end
end

function saveBookmark()
	if state == reading then
		data.bookmarks[files[selectedFile].name] = textIndex
		pd.datastore.write(data)
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
