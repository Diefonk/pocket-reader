import "CoreLibs/graphics"

local y = 0
local carmilla
local width, height

function init()
	local filesList = playdate.file.listFiles("/")
	for index = 1, table.getsize(filesList) do
		print(filesList[index])
	end
	local carmillaFile = playdate.file.open("Carmilla.txt")
	carmilla = carmillaFile:read(1000000)
	width, height = playdate.graphics.getTextSizeForMaxWidth(carmilla, 400)
	playdate.graphics.drawTextInRect(carmilla, 0, 0, width, height)
end

function playdate.update()
end

function playdate.cranked(change, accChange)
	y -= change
	if y > 0 then
		y = 0
	end
	--playdate.graphics.clear()
	--playdate.graphics.drawTextInRect(carmilla, 0, y, width, height)
	playdate.display.setOffset(0, y)
end

init()