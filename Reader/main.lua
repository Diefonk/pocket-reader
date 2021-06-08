import "CoreLibs/graphics"

local gfx <const> = playdate.graphics

local y = 0
local text
local image
local width, height
local fonts = {
	[gfx.font.kVariantNormal] = "Sasser-Slab",
    [gfx.font.kVariantBold] = "Sasser-Slab-Bold",
    [gfx.font.kVariantItalic] = "Sasser-Slab-Italic"
}

function init()
	local fontFamily = gfx.font.newFamily(fonts)
	gfx.setFontFamily(fontFamily)
	--local filesList = playdate.file.listFiles("/")
	--for index = 1, table.getsize(filesList) do
		--print(filesList[index])
	--end
	local file = playdate.file.open("text.txt")
	text = file:read(300000)
	width, height = gfx.getTextSizeForMaxWidth(text, 390)
	image = gfx.image.new(400, height + 10, gfx.kColorWhite)
	gfx.pushContext(image)
	gfx.drawTextInRect(text, 5, 5, width, height)
	gfx.popContext()
	image:draw(0, y)
end

function playdate.update()
end

function playdate.cranked(change, accChange)
	y -= change * 2
	if y > 0 then
		y = 0
	elseif y < 230 - height then
		y = 230 - height
	end
	image:draw(0, y)
end

init()
