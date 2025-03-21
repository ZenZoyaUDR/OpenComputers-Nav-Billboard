-- Enhanced Railway System Display for OpenComputers
-- Displays a sleek interface showing your server's railway system

local component = require("component")
local computer = require("computer")
local term = require("term")
local unicode = require("unicode")
local colors = require("colors")
local gpu = component.gpu
local keyboard = require("keyboard")
local event = require("event")
local filesystem = require("filesystem")

-- Default configuration (will be overridden by config file if it exists)
local config = {
  updateInterval = 10,
  screenWidth = 80,
  screenHeight = 30,
  defaultBackground = 0x000000,
  defaultForeground = 0xFFFFFF,
  titleColor = 0x00FF00,
  stationColor = 0xFFFF00,
  railColor = 0x808080,
  mainStationColor = 0xFF0000,
  borderColor = 0x555555,
  scrollBarColor = 0x444444,
  scrollHandleColor = 0xAAAAAA,
  useColorsIfAvailable = true,
  windowTitle = "Railway Network Display",
  animationChars = {"|", "/", "-", "\\"},
  scrollSpeed = 3,
  showScrollbarNumbers = true,
  railwayMap = {
    "                            RAILWAY NETWORK                            ",
    "                                                                       ",
    "    [A]-------[B]------[C]                                             ",
    "     |         |         |                                             ",
    "    [D]-------[E]------[F]                                             ",
    "                                                                       ",
  },
  stations = {}
}

-- Scrolling state
local scrollX = 0
local scrollY = 0
local maxScrollX = 0
local maxScrollY = 0

-- Update max scroll values
local function updateScrollLimits(mapWidth, mapHeight, viewWidth, viewHeight)
  maxScrollX = math.max(0, mapWidth - viewWidth)
  maxScrollY = math.max(0, mapHeight - viewHeight)
  scrollX = math.max(0, math.min(scrollX, maxScrollX))
  scrollY = math.max(0, math.min(scrollY, maxScrollY))
end

-- Draw the railway map
local function drawMap()
  term.clear()
  gpu.setForeground(config.railColor)
  for i = 1, #config.railwayMap do
    gpu.set(2, i + 1, config.railwayMap[i])
  end
end

-- Improved scrolling function
local function handleScroll(direction, isHorizontal)
  local scrollAmount = direction * config.scrollSpeed
  if isHorizontal then
    scrollX = math.max(0, math.min(scrollX + scrollAmount, maxScrollX))
  else
    scrollY = math.max(0, math.min(scrollY + scrollAmount, maxScrollY))
  end
  drawMap()
end

-- Fix mouse scroll interpretation
local function handleMouseScroll(direction, isAlt)
  if isAlt then
    handleScroll(-direction, true) -- Alt+Scroll for horizontal
  else
    handleScroll(-direction, false) -- Normal scroll for vertical
  end
end

-- Improved scrollbar click handling
local function handleScrollbarDrag(x, y, windowX, windowY, viewWidth, viewHeight, mapWidth, mapHeight)
  if maxScrollY > 0 and x == windowX + viewWidth + 2 then
    local clickRatio = (y - (windowY + 2)) / viewHeight
    scrollY = math.max(0, math.min(math.floor(clickRatio * maxScrollY), maxScrollY))
    drawMap()
    return true
  elseif maxScrollX > 0 and y == windowY + viewHeight + 2 then
    local clickRatio = (x - (windowX + 2)) / viewWidth
    scrollX = math.max(0, math.min(math.floor(clickRatio * maxScrollX), maxScrollX))
    drawMap()
    return true
  end
  return false
end

-- Event handling loop
local function main()
  drawMap()
  while true do
    local eventData = {event.pull(config.updateInterval)}
    local eventType = eventData[1]
    if eventType == "key_down" then
      local _, _, _, code, isAlt = table.unpack(eventData)
      if code == keyboard.keys.q then break
      elseif code == keyboard.keys.i then showStationInfo()
      elseif code == keyboard.keys.r then drawMap()
      elseif code == keyboard.keys.up then handleScroll(-1, false)
      elseif code == keyboard.keys.down then handleScroll(1, false)
      elseif code == keyboard.keys.left then handleScroll(-1, true)
      elseif code == keyboard.keys.right then handleScroll(1, true)
      elseif code == keyboard.keys.pageUp then handleScroll(-math.floor(config.screenHeight / 2), false)
      elseif code == keyboard.keys.pageDown then handleScroll(math.floor(config.screenHeight / 2), false)
      elseif code == keyboard.keys.home then scrollY = 0; drawMap()
      elseif code == keyboard.keys["end"] then scrollY = maxScrollY; drawMap()
      end
    elseif eventType == "scroll" then
      local _, _, _, direction, isAlt = table.unpack(eventData)
      handleMouseScroll(direction, isAlt)
    elseif eventType == "touch" then
      local _, eX, eY = table.unpack(eventData)
      handleScrollbarDrag(eX, eY, 1, 1, config.screenWidth, config.screenHeight, #config.railwayMap[1], #config.railwayMap)
    end
  end
end

-- Run the program
main()
